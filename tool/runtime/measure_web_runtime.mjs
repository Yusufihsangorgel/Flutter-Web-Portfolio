import { readFile } from 'node:fs/promises';
import process from 'node:process';
import { pathToFileURL } from 'node:url';

import { chromium } from '@playwright/test';
import { measureRun } from './measure_run.mjs';
import {
  closeLocalServer,
  getBudgetFailures,
  getEnforcementSkips,
  parseChromiumArgs,
  readGraphicsBackend,
  startLocalServer,
  summarize,
  summarizeTransferredBytes,
  validateBudgetContract,
  validateJsonSchema,
} from './runtime_support.mjs';

async function readConfiguration() {
  const [budget, budgetSchema] = await Promise.all(
    ['./performance_budget.json', './performance_budget.schema.json'].map(async (path) =>
      JSON.parse(await readFile(new URL(path, import.meta.url), 'utf8')),
    ),
  );
  validateJsonSchema(budget, budgetSchema, 'performance budget');
  validateBudgetContract(budget);
  const runCount = Number(process.env.PERF_RUNS ?? budget.runs);
  const startupTimeoutMs = Number(process.env.PERF_STARTUP_TIMEOUT_MS ?? budget.startup_timeout_ms);
  if (!Number.isInteger(runCount) || runCount < 1 || runCount > 10) {
    throw new Error('PERF_RUNS must be an integer between 1 and 10.');
  }
  if (!Number.isFinite(startupTimeoutMs) || startupTimeoutMs < 1000) {
    throw new Error('PERF_STARTUP_TIMEOUT_MS must be at least 1000.');
  }
  return {
    budget,
    target: process.env.PERF_URL ?? 'http://127.0.0.1:4173',
    externalTarget: Boolean(process.env.PERF_URL),
    enforce: process.argv.includes('--enforce'),
    runCount,
    startupTimeoutMs,
    chromiumArgs: parseChromiumArgs(process.env.PERF_CHROMIUM_ARGS),
  };
}
const throttledProfile = {
  download_mbps: 9,
  upload_mbps: 1.5,
  latency_ms: 60,
  cpu_throttling_rate: 4,
};

export async function collectRuntimeRuns(options, dependencies = {}) {
  const handles = { serverStart: null, browserLaunch: null, closing: null };
  const abort = new AbortController();
  const handlers = ['SIGINT', 'SIGTERM'].map((signal) => ({
    signal,
    handler: () => {
      if (abort.signal.aborted) return;
      process.exitCode = signal === 'SIGINT' ? 130 : 143;
      abort.abort(
        Object.assign(new Error(`Runtime measurement interrupted by ${signal}.`), {
          runtimeSignal: signal,
        }),
      );
    },
  }));
  for (const { signal, handler } of handlers) process.on(signal, handler);
  const interrupted = new Promise((_, reject) => {
    abort.signal.addEventListener('abort', () => reject(abort.signal.reason), { once: true });
  });
  let result;
  let failure;
  try {
    result = await Promise.race([
      measureRuntimeRuns(options, dependencies, handles, abort.signal),
      interrupted,
    ]);
  } catch (error) {
    failure = error;
  }
  try {
    await closeRuntimeHandles(handles, failure);
  } catch (error) {
    failure = failure
      ? new AggregateError([failure, error], 'Runtime operation and cleanup failed.', {
          cause: failure,
        })
      : error;
  } finally {
    for (const { signal, handler } of handlers) process.removeListener(signal, handler);
  }
  if (abort.signal.aborted && failure !== abort.signal.reason) {
    failure = new AggregateError(
      [abort.signal.reason, failure].filter(Boolean),
      'Runtime measurement interrupted during cleanup.',
      { cause: abort.signal.reason },
    );
  }
  if (failure) throw failure;
  return result;
}

async function measureRuntimeRuns(options, dependencies, handles, signal) {
  const { budget, startupTimeoutMs, target, runCount, chromiumArgs } = options;
  const { launchBrowser = (settings) => chromium.launch(settings), measure = measureRun } =
    dependencies;
  handles.serverStart = options.externalTarget
    ? null
    : startLocalServer(target, {
        ...options.serverOptions,
        signal,
      });
  await handles.serverStart;
  signal.throwIfAborted();
  handles.browserLaunch = launchBrowser({ headless: true, args: chromiumArgs });
  const browser = await handles.browserLaunch;
  signal.throwIfAborted();
  const graphicsBackend = await readGraphicsBackend(browser);
  const runs = [];
  const throttledRuns = [];
  for (let index = 0; index < runCount; index += 1) {
    signal.throwIfAborted();
    const run = index + 1;
    const runOptions = { budget, startupTimeoutMs, target };
    runs.push(await measure(browser, run, runOptions));
    signal.throwIfAborted();
    throttledRuns.push(await measure(browser, run, { ...runOptions, profile: throttledProfile }));
  }
  return { runs, throttledRuns, graphicsBackend };
}

async function closeRuntimeHandles(handles, primaryError) {
  handles.closing ??= (async () => {
    const acquisitions = [
      handles.serverStart?.then(closeLocalServer, (error) => {
        if (error !== primaryError) throw error;
      }),
      handles.browserLaunch?.then(
        (browser) => browser.close(),
        (error) => {
          if (error !== primaryError) throw error;
        },
      ),
    ];
    const settled = await Promise.allSettled(acquisitions);
    const errors = settled.flatMap((result) =>
      result.status === 'rejected' ? [result.reason] : [],
    );
    if (errors.length === 1) throw errors[0];
    if (errors.length > 1) throw new AggregateError(errors, 'Owned runtime handles did not close.');
  })();
  await handles.closing;
}

function summarizeRuns(options, collection) {
  const { budget, target, runCount, chromiumArgs, enforce } = options;
  const { runs, throttledRuns, graphicsBackend } = collection;
  const median = summarize(runs, budget.maximum_median);
  const throttledMedian = summarize(throttledRuns, budget.throttled.maximum_median);
  const enforcementSkips = getEnforcementSkips(budget, graphicsBackend, median);
  return {
    target,
    runs: runCount,
    chromium_args: chromiumArgs,
    graphics_backend: graphicsBackend,
    median,
    transferred_bytes_by_resource_type: summarizeTransferredBytes(runs),
    enforcement_skips: enforcementSkips,
    samples: runs,
    throttled: {
      profile: throttledProfile,
      enforce: budget.throttled.enforce,
      enforced: enforce && budget.throttled.enforce,
      median: throttledMedian,
      transferred_bytes_by_resource_type: summarizeTransferredBytes(throttledRuns),
      samples: throttledRuns,
    },
  };
}

function enforceBudgets(budget, summary) {
  const {
    median,
    enforcement_skips: enforcementSkips,
    graphics_backend: graphicsBackend,
  } = summary;
  const skippedMetrics = new Set(enforcementSkips.map(({ metric }) => metric));
  if (enforcementSkips.length > 0) {
    console.warn('\nRuntime performance enforcement warning:');
    for (const skip of enforcementSkips) {
      console.warn(
        `- ${skip.metric}: measured ${skip.measured_value}, hardware-only ` +
          `maximum ${skip.maximum_median}; not enforced on the detected ` +
          'software graphics backend.',
      );
    }
  }

  const failures = getBudgetFailures(budget.maximum_median, median, skippedMetrics);
  if (failures.length > 0) {
    console.error('\nRuntime performance budget failed:');
    for (const failure of failures) console.error(`- ${failure}`);
    console.error(
      `Graphics backend: ${graphicsBackend.renderer} ` +
        `(software: ${graphicsBackend.software_rendering})`,
    );
    process.exitCode = 1;
  }

  if (summary.throttled.enforced) {
    const throttledFailures = getBudgetFailures(
      budget.throttled.maximum_median,
      summary.throttled.median,
    );
    for (const [resourceType, maximum] of Object.entries(
      budget.throttled.maximum_transferred_bytes_by_resource_type,
    )) {
      const measured = summary.throttled.transferred_bytes_by_resource_type[resourceType] ?? 0;
      if (measured > maximum) {
        throttledFailures.push(`transferred_bytes.${resourceType}: ${measured} exceeds ${maximum}`);
      }
    }
    if (throttledFailures.length > 0) {
      console.error('\nThrottled runtime performance budget failed:');
      for (const failure of throttledFailures) console.error(`- ${failure}`);
      process.exitCode = 1;
    }
  }
}

async function main() {
  try {
    const options = await readConfiguration();
    const summary = summarizeRuns(options, await collectRuntimeRuns(options));
    console.log(JSON.stringify(summary, null, 2));
    if (options.enforce) enforceBudgets(options.budget, summary);
  } catch (error) {
    if (!error.runtimeSignal && !error.cause?.runtimeSignal) throw error;
    console.error(error.message);
  }
}

if (process.argv[1] && import.meta.url === pathToFileURL(process.argv[1]).href) {
  await main();
}
