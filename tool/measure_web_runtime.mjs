import { readFile } from 'node:fs/promises';
import process from 'node:process';

import { chromium } from '@playwright/test';

const budget = JSON.parse(
  await readFile(new URL('./performance_budget.json', import.meta.url), 'utf8'),
);
const target = process.env.PERF_URL ?? 'http://127.0.0.1:4173';
const enforce = process.argv.includes('--enforce');
const runCount = Number(process.env.PERF_RUNS ?? budget.runs);

if (!Number.isInteger(runCount) || runCount < 1 || runCount > 10) {
  throw new Error('PERF_RUNS must be an integer between 1 and 10.');
}

const browser = await chromium.launch({ headless: true });
const runs = [];

try {
  for (let index = 0; index < runCount; index += 1) {
    runs.push(await measureRun(browser, index + 1));
  }
} finally {
  await browser.close();
}

const summary = {
  target,
  runs: runCount,
  median: summarize(runs),
  samples: runs,
};

console.log(JSON.stringify(summary, null, 2));

if (enforce) {
  const failures = Object.entries(budget.maximum_median)
    .filter(([metric, maximum]) => summary.median[metric] > maximum)
    .map(
      ([metric, maximum]) =>
        `${metric}: ${summary.median[metric]} exceeds ${maximum}`,
    );
  if (failures.length > 0) {
    console.error('\nRuntime performance budget failed:');
    for (const failure of failures) console.error(`- ${failure}`);
    process.exitCode = 1;
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
      timeout: budget.startup_timeout_ms,
    });
    await page.waitForFunction(
      () =>
        performance.getEntriesByName('flutter-surface-reveal-start', 'mark')
          .length === 1 && !document.querySelector('#bootstrap-surface'),
      undefined,
      { timeout: budget.startup_timeout_ms },
    );

    const frameIntervals = await page.evaluate(async (sampleMs) => {
      const intervals = [];
      const maxScroll = Math.max(
        0,
        document.documentElement.scrollHeight - window.innerHeight,
      );
      const startedAt = performance.now();
      let previousFrame;

      await new Promise((resolve) => {
        const sampleFrame = (now) => {
          if (previousFrame !== undefined) intervals.push(now - previousFrame);
          previousFrame = now;
          const progress = Math.min(1, (now - startedAt) / sampleMs);
          const eased = 0.5 - Math.cos(Math.PI * progress) / 2;
          window.scrollTo(0, maxScroll * eased);
          if (progress < 1) {
            window.requestAnimationFrame(sampleFrame);
          } else {
            resolve();
          }
        };
        window.requestAnimationFrame(sampleFrame);
      });
      window.scrollTo(0, 0);
      return intervals;
    }, budget.scroll_sample_ms);

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
          firstFrameEvent: mark('flutter-first-frame-event'),
          revealStart: mark('flutter-surface-reveal-start'),
          surfaceRemoved: mark('flutter-bootstrap-surface-removed'),
        },
        bootstrapToFirstFrame:
          measure('flutter-bootstrap-to-first-frame'),
        firstFrameToReveal: measure('flutter-first-frame-to-reveal'),
        domContentLoaded: navigation?.domContentLoadedEventEnd ?? null,
        wasmDuration: wasm?.duration ?? null,
        wasmTransferBytes: wasm?.transferSize ?? null,
        vitals: window.__runtimeVitals,
      };
    });

    assertTimeline(pageMetrics.marks);
    const sortedIntervals = [...frameIntervals].sort((a, b) => a - b);
    const longTaskTotal = pageMetrics.vitals.longTasks.reduce(
      (total, duration) => total + duration,
      0,
    );
    return {
      run,
      navigation_to_first_frame_ms: round(pageMetrics.marks.firstFrameEvent),
      bootstrap_to_first_frame_ms: round(
        pageMetrics.bootstrapToFirstFrame,
      ),
      first_frame_to_reveal_ms: round(pageMetrics.firstFrameToReveal),
      dom_content_loaded_ms: round(pageMetrics.domContentLoaded),
      wasm_duration_ms: round(pageMetrics.wasmDuration),
      wasm_transfer_bytes: pageMetrics.wasmTransferBytes,
      scroll_frame_p95_ms: round(percentile(sortedIntervals, 0.95)),
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

function assertTimeline(marks) {
  const ordered = [
    marks.bootstrapStart,
    marks.entrypointLoaded,
    marks.engineInitialized,
    marks.firstFrameEvent,
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
}

function summarize(samples) {
  const metrics = Object.keys(budget.maximum_median);
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
