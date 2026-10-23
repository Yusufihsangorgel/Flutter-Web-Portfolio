import assert from 'node:assert/strict';
import { test } from 'node:test';

import { getBudgetFailures, summarize, summarizeTransferredBytes } from './runtime_support.mjs';
import * as measureRun from './measure_run.mjs';

const buildRunResult = measureRun.buildRunResult;

function summarySample(overrides = {}) {
  return {
    requested_metric: 0,
    first_frame_to_reveal_ms: 0,
    scroll_frame_median_ms: 0,
    scroll_frame_p95_ms: 0,
    ...overrides,
  };
}

function runInput(overrides = {}) {
  const pageOverrides = overrides.pageMetrics ?? {};
  return {
    run: 1,
    frameIntervals: [10, 20, 30],
    visitedSections: ['#/work'],
    transferredBytesByResourceType: { Document: 0 },
    ...overrides,
    pageMetrics: {
      bootstrapToFirstFrame: 30,
      bootstrapToRevealSignal: 30,
      firstFrameToReveal: 10,
      domContentLoaded: 5,
      wasmDuration: null,
      wasmTransferBytes: null,
      renderQuality: 'balanced',
      renderQualityReason: 'fixture-free unit input',
      ...pageOverrides,
      marks: {
        bootstrapStart: 0,
        entrypointLoaded: 10,
        engineInitialized: 20,
        firstFrameEvent: 25,
        firstFrameSignal: 30,
        runAppFallback: null,
        revealStart: 40,
        surfaceRemoved: 50,
        ...pageOverrides.marks,
      },
      vitals: {
        cumulativeLayoutShift: 0,
        largestContentfulPaint: 0,
        longTasks: [],
        ...pageOverrides.vitals,
      },
    },
  };
}

function runBuilderCase(name, callback) {
  test(name, callback);
}

test('summary rejects empty samples instead of manufacturing zero metrics', () => {
  assert.throws(() => summarize([], { requested_metric: 100 }), /sample/i);
  const sparseSamples = [summarySample(), summarySample({ requested_metric: 1 }), summarySample()];
  delete sparseSamples[1];
  assert.throws(() => summarize(sparseSamples, { requested_metric: 100 }), /sample/i);
});

test('summary rejects missing, null, nonfinite, coerced, and negative budget values', () => {
  const invalid = [undefined, null, Number.NaN, Number.POSITIVE_INFINITY, '1', true, -1];
  for (const value of invalid) {
    assert.throws(
      () => summarize([summarySample({ requested_metric: value })], { requested_metric: 100 }),
      /requested_metric/i,
    );
  }
  const missing = summarySample();
  delete missing.requested_metric;
  assert.throws(() => summarize([missing], { requested_metric: 100 }), /requested_metric/i);
});

test('budget enforcement requires a measured value and keeps exact threshold boundaries', () => {
  const thresholds = { requested_metric: 100 };
  assert.deepEqual(getBudgetFailures(thresholds, { requested_metric: 0 }), []);
  assert.deepEqual(getBudgetFailures(thresholds, { requested_metric: 99.99 }), []);
  assert.deepEqual(getBudgetFailures(thresholds, { requested_metric: 100 }), []);
  assert.deepEqual(getBudgetFailures(thresholds, { requested_metric: 100.01 }), [
    'requested_metric: 100.01 exceeds 100',
  ]);
  assert.deepEqual(
    getBudgetFailures(thresholds, { requested_metric: 100.01 }, new Set(['requested_metric'])),
    [],
  );
  assert.throws(
    () => getBudgetFailures(thresholds, {}, new Set(['requested_metric'])),
    /requested_metric/i,
  );
  assert.throws(() => getBudgetFailures(thresholds, {}), /requested_metric/i);
  for (const value of [null, Number.NaN, Number.POSITIVE_INFINITY, '100', true, -1]) {
    assert.throws(
      () => getBudgetFailures(thresholds, { requested_metric: value }),
      /requested_metric/i,
    );
  }
});

test('byte summaries reject absent samples or measurement maps but retain actual zero totals', () => {
  assert.throws(() => summarizeTransferredBytes([]), /sample/i);
  const sparseSamples = [
    { transferred_bytes_by_resource_type: { Document: 1 } },
    { transferred_bytes_by_resource_type: { Document: 2 } },
    { transferred_bytes_by_resource_type: { Document: 3 } },
  ];
  delete sparseSamples[1];
  assert.throws(() => summarizeTransferredBytes(sparseSamples), /sample/i);
  assert.throws(() => summarizeTransferredBytes([{}]), /transferred_bytes_by_resource_type/i);
  assert.deepEqual(
    summarizeTransferredBytes([{ transferred_bytes_by_resource_type: { Document: 0 } }]),
    { Document: 0 },
  );
  for (const bytes of [undefined, null, Number.NaN, Number.POSITIVE_INFINITY, '0', true, -1]) {
    assert.throws(
      () =>
        summarizeTransferredBytes([{ transferred_bytes_by_resource_type: { Document: bytes } }]),
      /Document bytes/i,
    );
  }
});

runBuilderCase(
  'result builder preserves supported zero values, fallback timings, and optional Wasm',
  () => {
    const result = buildRunResult(
      runInput({
        pageMetrics: {
          bootstrapToFirstFrame: null,
          bootstrapToRevealSignal: 30,
          marks: { firstFrameEvent: null, runAppFallback: 25 },
          vitals: { cumulativeLayoutShift: 0, largestContentfulPaint: 0, longTasks: [] },
        },
      }),
    );
    assert.equal(result.navigation_to_first_frame_ms, 30);
    assert.equal(result.bootstrap_to_first_frame_ms, 30);
    assert.equal(result.reveal_source, 'run-app-fallback');
    assert.equal(result.cumulative_layout_shift, 0);
    assert.equal(result.largest_contentful_paint_ms, 0);
    assert.equal(result.long_task_total_ms, 0);
    assert.equal(result.longest_task_ms, 0);
    assert.equal(result.wasm_duration_ms, null);
    assert.equal(result.wasm_transfer_bytes, null);
  },
);

runBuilderCase('result builder rejects missing and invalid required timeline marks', () => {
  const missing = runInput();
  delete missing.pageMetrics.marks.engineInitialized;
  assert.throws(() => buildRunResult(missing), /timeline/i);
  for (const value of [undefined, null, Number.NaN, Number.POSITIVE_INFINITY, '20', true, -1]) {
    assert.throws(
      () => buildRunResult(runInput({ pageMetrics: { marks: { engineInitialized: value } } })),
      /timeline/i,
    );
  }
  assert.throws(
    () => buildRunResult(runInput({ pageMetrics: { marks: { firstFrameEvent: undefined } } })),
    /timeline/i,
  );
  assert.throws(
    () => buildRunResult(runInput({ pageMetrics: { marks: { surfaceRemoved: 30 } } })),
    /timeline is out of order/i,
  );
});

runBuilderCase('result builder rejects missing and invalid required timing measurements', () => {
  for (const value of [undefined, null, Number.NaN, Number.POSITIVE_INFINITY, '10', true, -1]) {
    assert.throws(
      () => buildRunResult(runInput({ pageMetrics: { firstFrameToReveal: value } })),
      /firstFrameToReveal/i,
    );
  }
  assert.throws(
    () =>
      buildRunResult(
        runInput({ pageMetrics: { bootstrapToFirstFrame: null, bootstrapToRevealSignal: null } }),
      ),
    /bootstrapToRevealSignal/i,
  );
  assert.throws(
    () => buildRunResult(runInput({ pageMetrics: { wasmDuration: Number.NaN } })),
    /wasmDuration/i,
  );
  assert.throws(
    () => buildRunResult(runInput({ pageMetrics: { wasmTransferBytes: '0' } })),
    /wasmTransferBytes/i,
  );
});

runBuilderCase('result builder rejects empty and invalid frame intervals', () => {
  assert.throws(() => buildRunResult(runInput({ frameIntervals: [] })), /frame/i);
  const sparseIntervals = Array(20).fill(16);
  delete sparseIntervals[19];
  assert.throws(() => buildRunResult(runInput({ frameIntervals: sparseIntervals })), /frame/i);
  for (const value of [0, -1, Number.NaN, Number.POSITIVE_INFINITY, null, '16', true]) {
    assert.throws(() => buildRunResult(runInput({ frameIntervals: [16, value] })), /frame/i);
  }
});

runBuilderCase('result builder rejects unsupported or missing vital measurements', () => {
  for (const key of ['cumulativeLayoutShift', 'largestContentfulPaint']) {
    for (const value of [undefined, null, Number.NaN, Number.POSITIVE_INFINITY, '0', true, -1]) {
      assert.throws(
        () => buildRunResult(runInput({ pageMetrics: { vitals: { [key]: value } } })),
        /vitals/i,
      );
    }
  }
  const sparseLongTasks = [1, 2, 3];
  delete sparseLongTasks[1];
  for (const longTasks of [
    undefined,
    null,
    [Number.NaN],
    [Number.POSITIVE_INFINITY],
    ['1'],
    [true],
    [-1],
    sparseLongTasks,
  ]) {
    assert.throws(
      () => buildRunResult(runInput({ pageMetrics: { vitals: { longTasks } } })),
      /longTasks/i,
    );
  }
});
