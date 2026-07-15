import { spawn } from 'node:child_process';
import { readFile } from 'node:fs/promises';
import process from 'node:process';

import { chromium } from '@playwright/test';

const [budget, budgetSchema] = await Promise.all(
  ['./performance_budget.json', './performance_budget.schema.json'].map(
    async (path) =>
      JSON.parse(await readFile(new URL(path, import.meta.url), 'utf8')),
  ),
);
validateJsonSchema(budget, budgetSchema, 'performance budget');
validateBudgetContract(budget);
const localTarget = 'http://127.0.0.1:4173';
const target = process.env.PERF_URL ?? localTarget;
const enforce = process.argv.includes('--enforce');
const runCount = Number(process.env.PERF_RUNS ?? budget.runs);
const startupTimeoutMs = Number(
  process.env.PERF_STARTUP_TIMEOUT_MS ?? budget.startup_timeout_ms,
);
const chromiumArgs = parseChromiumArgs(process.env.PERF_CHROMIUM_ARGS);

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

try {
  browser = await chromium.launch({ headless: true, args: chromiumArgs });
  graphicsBackend = await readGraphicsBackend(browser);
  for (let index = 0; index < runCount; index += 1) {
    runs.push(await measureRun(browser, index + 1));
  }
} finally {
  await browser?.close();
  server?.kill('SIGTERM');
}

const median = summarize(runs);
const enforcementSkips = getEnforcementSkips(
  budget,
  graphicsBackend,
  median,
);
const summary = {
  target,
  runs: runCount,
  chromium_args: chromiumArgs,
  graphics_backend: graphicsBackend,
  median,
  enforcement_skips: enforcementSkips,
  samples: runs,
};

console.log(JSON.stringify(summary, null, 2));

if (enforce) {
  const skippedMetrics = new Set(
    enforcementSkips.map(({ metric }) => metric),
  );
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
  const failures = Object.entries(budget.maximum_median)
    .filter(([metric]) => !skippedMetrics.has(metric))
    .filter(([metric, maximum]) => summary.median[metric] > maximum)
    .map(
      ([metric, maximum]) =>
        `${metric}: ${summary.median[metric]} exceeds ${maximum}`,
    );
  if (failures.length > 0) {
    console.error('\nRuntime performance budget failed:');
    for (const failure of failures) console.error(`- ${failure}`);
    console.error(
      `Graphics backend: ${graphicsBackend.renderer} ` +
        `(software: ${graphicsBackend.software_rendering})`,
    );
    process.exitCode = 1;
  }
}

function validateJsonSchema(value, schema, path) {
  if ('const' in schema && !deepEqual(value, schema.const)) {
    throw new Error(
      `${path} must equal ${JSON.stringify(schema.const)}.`,
    );
  }
  if (
    schema.enum &&
    !schema.enum.some((candidate) => deepEqual(value, candidate))
  ) {
    throw new Error(
      `${path} must be one of ${JSON.stringify(schema.enum)}.`,
    );
  }
  if (schema.type && !matchesJsonType(value, schema.type)) {
    throw new Error(`${path} must be of type ${schema.type}.`);
  }

  if (schema.type === 'object') {
    const properties = schema.properties ?? {};
    for (const required of schema.required ?? []) {
      if (!Object.hasOwn(value, required)) {
        throw new Error(`${path}.${required} is required.`);
      }
    }
    if (schema.additionalProperties === false) {
      for (const property of Object.keys(value)) {
        if (!Object.hasOwn(properties, property)) {
          throw new Error(`${path}.${property} is not allowed.`);
        }
      }
    }
    for (const [property, propertySchema] of Object.entries(properties)) {
      if (Object.hasOwn(value, property)) {
        validateJsonSchema(
          value[property],
          propertySchema,
          `${path}.${property}`,
        );
      }
    }
  }

  if (schema.type === 'array') {
    if (schema.minItems !== undefined && value.length < schema.minItems) {
      throw new Error(
        `${path} must contain at least ${schema.minItems} item(s).`,
      );
    }
    if (schema.uniqueItems) {
      const uniqueItems = new Set(value.map((item) => JSON.stringify(item)));
      if (uniqueItems.size !== value.length) {
        throw new Error(`${path} must not contain duplicate items.`);
      }
    }
    if (schema.items) {
      value.forEach((item, index) =>
        validateJsonSchema(item, schema.items, `${path}[${index}]`),
      );
    }
  }

  if (schema.type === 'number' || schema.type === 'integer') {
    if (schema.minimum !== undefined && value < schema.minimum) {
      throw new Error(`${path} must be at least ${schema.minimum}.`);
    }
    if (schema.maximum !== undefined && value > schema.maximum) {
      throw new Error(`${path} must be at most ${schema.maximum}.`);
    }
  }
}

function matchesJsonType(value, type) {
  return switchJsonType(type, {
    array: () => Array.isArray(value),
    integer: () => Number.isInteger(value),
    number: () => typeof value === 'number' && Number.isFinite(value),
    object: () =>
      value !== null && typeof value === 'object' && !Array.isArray(value),
    string: () => typeof value === 'string',
  });
}

function switchJsonType(type, handlers) {
  const handler = handlers[type];
  if (!handler) throw new Error(`Unsupported JSON Schema type: ${type}.`);
  return handler();
}

function deepEqual(left, right) {
  return JSON.stringify(left) === JSON.stringify(right);
}

function validateBudgetContract(value) {
  for (const metric of value.hardware_only_metrics) {
    if (!Object.hasOwn(value.maximum_median, metric)) {
      throw new Error(
        `Hardware-only metric ${metric} has no maximum_median threshold.`,
      );
    }
  }
}

function getEnforcementSkips(value, backend, measuredMedian) {
  // Fail closed: an unavailable/unknown backend diagnostic enforces the full
  // hardware budget instead of silently opting out.
  if (backend.software_rendering !== true) return [];
  return value.hardware_only_metrics.map((metric) => ({
    metric,
    measured_value: measuredMedian[metric],
    maximum_median: value.maximum_median[metric],
    reason: 'software_graphics_backend',
  }));
}

function parseChromiumArgs(value) {
  if (!value) return [];

  let parsed;
  try {
    parsed = JSON.parse(value);
  } catch (error) {
    throw new Error(
      'PERF_CHROMIUM_ARGS must be a JSON array of Chromium arguments.',
      { cause: error },
    );
  }
  if (
    !Array.isArray(parsed) ||
    parsed.some((argument) => typeof argument !== 'string')
  ) {
    throw new Error(
      'PERF_CHROMIUM_ARGS must be a JSON array containing only strings.',
    );
  }
  return parsed;
}

async function readGraphicsBackend(browserInstance) {
  let session;
  try {
    session = await browserInstance.newBrowserCDPSession();
    const { gpu } = await session.send('SystemInfo.getInfo');
    const device = gpu.devices?.[0] ?? {};
    const attributes = gpu.auxAttributes ?? {};
    const renderer =
      attributes.glRenderer ?? device.deviceString ?? 'unavailable';
    const backendSignals = [
      attributes.glRenderer,
      device.deviceString,
      attributes.displayType,
      attributes.glImplementationParts,
      gpu.featureStatus?.gpu_compositing,
      gpu.featureStatus?.webgl,
    ].filter(Boolean);
    const diagnostics = backendSignals.join(' ').toLowerCase();
    return {
      renderer,
      vendor: attributes.glVendor ?? device.vendorString ?? 'unavailable',
      display_type: attributes.displayType ?? 'unavailable',
      implementation: attributes.glImplementationParts ?? 'unavailable',
      software_rendering:
        backendSignals.length === 0
          ? null
          : /swiftshader|llvmpipe|software/.test(diagnostics),
    };
  } catch (error) {
    return {
      renderer: 'unavailable',
      vendor: 'unavailable',
      display_type: 'unavailable',
      implementation: 'unavailable',
      software_rendering: null,
      diagnostic_error: error instanceof Error ? error.message : String(error),
    };
  } finally {
    try {
      await session?.detach();
    } catch {
      // The browser may already be closing after a failed diagnostic request.
    }
  }
}

async function measureRun(browserInstance, run) {
  const context = await browserInstance.newContext({
    viewport: { width: 1440, height: 900 },
    reducedMotion: 'no-preference',
    serviceWorkers: 'block',
  });
  const page = await context.newPage();
  await page.addInitScript(() => {
    window.__runtimeVitals = {
      cumulativeLayoutShift: 0,
      largestContentfulPaint: 0,
      longTasks: [],
    };
    const observe = (type, callback) => {
      if (!PerformanceObserver.supportedEntryTypes.includes(type)) return;
      new PerformanceObserver((list) => callback(list.getEntries())).observe({
        type,
        buffered: true,
      });
    };
    observe('layout-shift', (entries) => {
      for (const entry of entries) {
        if (!entry.hadRecentInput) {
          window.__runtimeVitals.cumulativeLayoutShift += entry.value;
        }
      }
    });
    observe('largest-contentful-paint', (entries) => {
      const last = entries.at(-1);
      if (last) window.__runtimeVitals.largestContentfulPaint = last.startTime;
    });
    observe('longtask', (entries) => {
      window.__runtimeVitals.longTasks.push(
        ...entries.map((entry) => entry.duration),
      );
    });
  });

  try {
    await page.goto(target, { waitUntil: 'domcontentloaded' });
    await page.waitForSelector('flt-semantics-host', {
      state: 'attached',
      timeout: startupTimeoutMs,
    });
    await page.waitForFunction(
      () =>
        performance.getEntriesByName('flutter-surface-reveal-start', 'mark')
          .length === 1 && !document.querySelector('#bootstrap-surface'),
      undefined,
      { timeout: startupTimeoutMs },
    );
    await page
      .getByRole('button', { name: 'Work', exact: true })
      .first()
      .waitFor({ state: 'attached', timeout: startupTimeoutMs });

    await page.evaluate((sampleMs) => {
      const sample = {
        done: false,
        intervals: [],
        routeHashes: [window.location.hash],
      };
      window.__flutterScrollSample = sample;
      const startedAt = performance.now();
      let previousFrame;
      const sampleFrame = (now) => {
        if (previousFrame !== undefined) {
          sample.intervals.push(now - previousFrame);
        }
        previousFrame = now;
        const currentHash = window.location.hash;
        if (sample.routeHashes.at(-1) !== currentHash) {
          sample.routeHashes.push(currentHash);
        }
        if (now - startedAt < sampleMs) {
          window.requestAnimationFrame(sampleFrame);
        } else {
          sample.done = true;
        }
      };
      window.requestAnimationFrame(sampleFrame);
    }, budget.scroll_sample_ms);

    const scrollTargets = ['Work', 'About'];
    const segmentDuration = Math.floor(
      budget.scroll_sample_ms / scrollTargets.length,
    );
    for (const label of scrollTargets) {
      const controls = page.getByRole('button', { name: label, exact: true });
      const controlCount = await controls.count();
      if (controlCount < 1) {
        throw new Error(`Flutter scroll control is missing: ${label}`);
      }
      await controls.first().click();
      await page.waitForTimeout(segmentDuration);
    }
    await page.waitForFunction(() => window.__flutterScrollSample?.done === true);
    const scrollSample = await page.evaluate(() => window.__flutterScrollSample);
    const frameIntervals = scrollSample.intervals;
    const visitedSections = [...new Set(scrollSample.routeHashes)].filter(
      (hash) => hash && hash !== '#/',
    );
    if (visitedSections.length === 0) {
      throw new Error(
        'Runtime performance sample did not move the Flutter scroll view.',
      );
    }

    const pageMetrics = await page.evaluate(() => {
      const mark = (name) =>
        performance.getEntriesByName(name, 'mark').at(-1)?.startTime ?? null;
      const measure = (name) =>
        performance.getEntriesByName(name, 'measure').at(-1)?.duration ?? null;
      const navigation = performance.getEntriesByType('navigation').at(-1);
      const wasm = performance
        .getEntriesByType('resource')
        .find((entry) => entry.name.includes('/main.dart.wasm'));
      return {
        marks: {
          bootstrapStart: mark('flutter-bootstrap-start'),
          entrypointLoaded: mark('flutter-entrypoint-loaded'),
          engineInitialized: mark('flutter-engine-initialized'),
          runAppComplete: mark('flutter-run-app-complete'),
          firstFrameEvent: mark('flutter-first-frame-event'),
          firstFrameSignal: mark('flutter-first-frame-signal'),
          runAppFallback: mark('flutter-run-app-fallback'),
          glassPaneFallback: mark('flutter-glass-pane-fallback'),
          revealStart: mark('flutter-surface-reveal-start'),
          surfaceRemoved: mark('flutter-bootstrap-surface-removed'),
        },
        bootstrapToFirstFrame:
          measure('flutter-bootstrap-to-first-frame'),
        bootstrapToRevealSignal:
          measure('flutter-bootstrap-to-reveal-signal'),
        firstFrameToReveal: measure('flutter-first-frame-to-reveal'),
        domContentLoaded: navigation?.domContentLoadedEventEnd ?? null,
        wasmDuration: wasm?.duration ?? null,
        wasmTransferBytes: wasm?.transferSize ?? null,
        vitals: window.__runtimeVitals,
        renderQuality: document.documentElement.getAttribute(
          'data-render-quality',
        ),
        renderQualityReason: document.documentElement.getAttribute(
          'data-render-quality-reason',
        ),
      };
    });

    assertTimeline(pageMetrics.marks);
    const sortedIntervals = [...frameIntervals].sort((a, b) => a - b);
    const medianFrameInterval = percentile(sortedIntervals, 0.5);
    const p95FrameInterval = percentile(sortedIntervals, 0.95);
    const firstFrameToReveal = pageMetrics.firstFrameToReveal;
    const longTaskTotal = pageMetrics.vitals.longTasks.reduce(
      (total, duration) => total + duration,
      0,
    );
    return {
      run,
      navigation_to_first_frame_ms: round(
        pageMetrics.marks.firstFrameEvent ?? pageMetrics.marks.firstFrameSignal,
      ),
      bootstrap_to_first_frame_ms: round(
        pageMetrics.bootstrapToFirstFrame ??
          pageMetrics.bootstrapToRevealSignal,
      ),
      first_frame_to_reveal_ms: round(firstFrameToReveal),
      first_frame_to_reveal_frame_intervals: round(
        medianFrameInterval > 0
          ? firstFrameToReveal / medianFrameInterval
          : 0,
        3,
      ),
      bootstrap_start_ms: round(pageMetrics.marks.bootstrapStart),
      bootstrap_to_entrypoint_ms: round(
        pageMetrics.marks.entrypointLoaded -
          pageMetrics.marks.bootstrapStart,
      ),
      entrypoint_to_engine_initialized_ms: round(
        pageMetrics.marks.engineInitialized -
          pageMetrics.marks.entrypointLoaded,
      ),
      engine_initialized_to_render_signal_ms: round(
        pageMetrics.marks.firstFrameSignal -
          pageMetrics.marks.engineInitialized,
      ),
      first_frame_event_observed:
        pageMetrics.marks.firstFrameEvent !== null,
      reveal_source: pageMetrics.marks.firstFrameEvent !== null
        ? 'flutter-first-frame'
        : pageMetrics.marks.runAppFallback !== null
        ? 'run-app-fallback'
        : 'glass-pane-fallback',
      render_quality: pageMetrics.renderQuality,
      render_quality_reason: pageMetrics.renderQualityReason,
      scroll_sections_visited: visitedSections,
      dom_content_loaded_ms: round(pageMetrics.domContentLoaded),
      wasm_duration_ms: round(pageMetrics.wasmDuration),
      wasm_transfer_bytes: pageMetrics.wasmTransferBytes,
      scroll_frame_median_ms: round(medianFrameInterval),
      scroll_frame_p95_ms: round(p95FrameInterval),
      scroll_frame_p95_over_median_ratio: round(
        medianFrameInterval > 0 ? p95FrameInterval / medianFrameInterval : 0,
        3,
      ),
      scroll_frames_over_50_ms: frameIntervals.filter((value) => value > 50)
        .length,
      long_task_total_ms: round(longTaskTotal),
      longest_task_ms: round(Math.max(0, ...pageMetrics.vitals.longTasks)),
      cumulative_layout_shift: round(
        pageMetrics.vitals.cumulativeLayoutShift,
        4,
      ),
      largest_contentful_paint_ms: round(
        pageMetrics.vitals.largestContentfulPaint,
      ),
    };
  } finally {
    await context.close();
  }
}

async function startLocalServer(url) {
  const child = spawn(process.execPath, ['tool/serve_web.mjs'], {
    cwd: process.cwd(),
    stdio: 'ignore',
  });
  child.unref();
  const deadline = Date.now() + 15000;
  while (Date.now() < deadline) {
    if (child.exitCode !== null) {
      throw new Error(`Local performance server exited with ${child.exitCode}.`);
    }
    try {
      const response = await fetch(url);
      if (response.ok) return child;
    } catch {
      // The server is still starting.
    }
    await new Promise((resolve) => setTimeout(resolve, 100));
  }
  child.kill('SIGTERM');
  throw new Error(`Local performance server did not start at ${url}.`);
}

function assertTimeline(marks) {
  const ordered = [
    marks.bootstrapStart,
    marks.entrypointLoaded,
    marks.engineInitialized,
    marks.firstFrameSignal,
    marks.revealStart,
    marks.surfaceRemoved,
  ];
  if (ordered.some((value) => value === null)) {
    throw new Error(`Runtime timeline is incomplete: ${JSON.stringify(marks)}`);
  }
  for (let index = 1; index < ordered.length; index += 1) {
    if (ordered[index] < ordered[index - 1]) {
      throw new Error(`Runtime timeline is out of order: ${JSON.stringify(marks)}`);
    }
  }
  if (
    marks.firstFrameEvent !== null &&
    marks.firstFrameEvent > marks.firstFrameSignal
  ) {
    throw new Error(
      `First-frame event followed its reveal signal: ${JSON.stringify(marks)}`,
    );
  }
}

function summarize(samples) {
  const metrics = [
    ...new Set([
      ...Object.keys(budget.maximum_median),
      'first_frame_to_reveal_ms',
      'scroll_frame_median_ms',
      'scroll_frame_p95_ms',
    ]),
  ];
  return Object.fromEntries(
    metrics.map((metric) => [
      metric,
      round(
        percentile(
          samples.map((sample) => sample[metric]).sort((a, b) => a - b),
          0.5,
        ),
        metric === 'cumulative_layout_shift' ? 4 : 2,
      ),
    ]),
  );
}

function percentile(sortedValues, percentileValue) {
  if (sortedValues.length === 0) return 0;
  const index = Math.min(
    sortedValues.length - 1,
    Math.ceil(sortedValues.length * percentileValue) - 1,
  );
  return sortedValues[index];
}

function round(value, digits = 2) {
  if (value === null || value === undefined || !Number.isFinite(value)) {
    return 0;
  }
  return Number(value.toFixed(digits));
}
