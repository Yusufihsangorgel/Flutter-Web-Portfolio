import { readFile } from 'node:fs/promises';
import process from 'node:process';

import { chromium } from '@playwright/test';
import { measureRun } from './measure_run.mjs';
import {
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

const [budget, budgetSchema] = await Promise.all(
  ['./performance_budget.json', './performance_budget.schema.json'].map(async (path) =>
    JSON.parse(await readFile(new URL(path, import.meta.url), 'utf8')),
  ),
);
validateJsonSchema(budget, budgetSchema, 'performance budget');
validateBudgetContract(budget);

const localTarget = 'http://127.0.0.1:4173';
const target = process.env.PERF_URL ?? localTarget;
const enforce = process.argv.includes('--enforce');
const runCount = Number(process.env.PERF_RUNS ?? budget.runs);
const startupTimeoutMs = Number(process.env.PERF_STARTUP_TIMEOUT_MS ?? budget.startup_timeout_ms);
const chromiumArgs = parseChromiumArgs(process.env.PERF_CHROMIUM_ARGS);
const throttledProfile = {
  download_mbps: 9,
  upload_mbps: 1.5,
  latency_ms: 60,
  cpu_throttling_rate: 4,
};

if (!Number.isInteger(runCount) || runCount < 1 || runCount > 10) {
  throw new Error('PERF_RUNS must be an integer between 1 and 10.');
}
if (!Number.isFinite(startupTimeoutMs) || startupTimeoutMs < 1000) {
  throw new Error('PERF_STARTUP_TIMEOUT_MS must be at least 1000.');
}

const server = process.env.PERF_URL ? null : await startLocalServer(localTarget);
let browser;
let graphicsBackend;
const runs = [];
const throttledRuns = [];

try {
  browser = await chromium.launch({ headless: true, args: chromiumArgs });
  graphicsBackend = await readGraphicsBackend(browser);
  for (let index = 0; index < runCount; index += 1) {
    const run = index + 1;
    const options = { budget, startupTimeoutMs, target };
    runs.push(await measureRun(browser, run, options));
    throttledRuns.push(await measureRun(browser, run, { ...options, profile: throttledProfile }));
  }
} finally {
  await browser?.close();
  server?.kill('SIGTERM');
}

const median = summarize(runs, budget.maximum_median);
const throttledMedian = summarize(throttledRuns, budget.throttled.maximum_median);
const enforcementSkips = getEnforcementSkips(budget, graphicsBackend, median);
const throttledEnforced = enforce && budget.throttled.enforce;
const summary = {
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
    enforced: throttledEnforced,
    median: throttledMedian,
    transferred_bytes_by_resource_type: summarizeTransferredBytes(throttledRuns),
    samples: throttledRuns,
  },
};

console.log(JSON.stringify(summary, null, 2));

if (enforce) {
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

  if (throttledEnforced) {
    const throttledFailures = getBudgetFailures(budget.throttled.maximum_median, throttledMedian);
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
