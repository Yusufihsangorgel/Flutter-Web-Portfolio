export async function measureRun(browserInstance, run, options) {
  const { budget, profile, startupTimeoutMs, target } = options;
  const context = await browserInstance.newContext({
    viewport: { width: 1440, height: 900 },
    reducedMotion: 'no-preference',
    serviceWorkers: 'block',
  });
  const page = await context.newPage();
  const byteState = { requestTypes: new Map(), totals: new Map() };
  let session;

  try {
    session = await context.newCDPSession(page);
    await prepareRun(page, session, profile, byteState);
    await waitForReveal(page, { target, startupTimeoutMs });
    const scroll = await sampleScroll(page, budget.scroll_sample_ms);
    const pageMetrics = await readPageMetrics(page);
    assertTimeline(pageMetrics.marks);
    return buildRunResult({
      run,
      pageMetrics,
      frameIntervals: scroll.intervals,
      visitedSections: scroll.visitedSections,
      transferredBytesByResourceType: sortResourceTotals(byteState.totals),
    });
  } finally {
    try {
      await session?.detach();
    } catch {
      // The page context may close the session first.
    }
    await context.close();
  }
}

function sortResourceTotals(totals) {
  return Object.fromEntries(
    [...totals.entries()].sort(([left], [right]) => left.localeCompare(right)),
  );
}

async function prepareRun(page, session, profile, byteState) {
  await session.send('Network.enable');
  listenForTransfers(session, byteState);
  if (profile) await applyThrottleProfile(session, profile);
  await page.addInitScript(installRuntimeVitals);
}

function listenForTransfers(session, byteState) {
  session.on('Network.requestWillBeSent', ({ requestId, type }) => {
    byteState.requestTypes.set(requestId, type ?? 'Other');
  });
  session.on('Network.responseReceived', ({ requestId, type }) => {
    byteState.requestTypes.set(requestId, type ?? 'Other');
  });
  session.on('Network.loadingFinished', ({ encodedDataLength, requestId }) => {
    const resourceType = byteState.requestTypes.get(requestId) ?? 'Other';
    const bytes = Number.isFinite(encodedDataLength)
      ? Math.max(0, Math.round(encodedDataLength))
      : 0;
    byteState.totals.set(
      resourceType,
      (byteState.totals.get(resourceType) ?? 0) + bytes,
    );
    byteState.requestTypes.delete(requestId);
  });
}

async function applyThrottleProfile(session, profile) {
  await session.send('Network.emulateNetworkConditions', {
    offline: false,
    latency: profile.latency_ms,
    downloadThroughput: (profile.download_mbps * 1_000_000) / 8,
    uploadThroughput: (profile.upload_mbps * 1_000_000) / 8,
  });
  await session.send('Emulation.setCPUThrottlingRate', {
    rate: profile.cpu_throttling_rate,
  });
}

function installRuntimeVitals() {
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
}

async function waitForReveal(page, options) {
  const { startupTimeoutMs, target } = options;
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
}

async function sampleScroll(page, sampleMs) {
  await page.evaluate(startFrameSampling, sampleMs);
  await visitScrollTargets(page, sampleMs);
  await page.waitForFunction(() => window.__flutterScrollSample?.done === true);
  return page.evaluate(readScrollSample);
}

function startFrameSampling(sampleMs) {
  const sample = { done: false, intervals: [], routeHashes: [window.location.hash] };
  window.__flutterScrollSample = sample;
  const startedAt = performance.now();
  let previousFrame;
  const sampleFrame = (now) => {
    if (previousFrame !== undefined) sample.intervals.push(now - previousFrame);
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
}

async function visitScrollTargets(page, sampleMs) {
  const scrollTargets = ['Work', 'About'];
  const segmentDuration = Math.floor(sampleMs / scrollTargets.length);
  for (const label of scrollTargets) {
    const controls = page.getByRole('button', { name: label, exact: true });
    if ((await controls.count()) < 1) {
      throw new Error(`Flutter scroll control is missing: ${label}`);
    }
    await controls.first().click();
    await page.waitForTimeout(segmentDuration);
  }
}

function readScrollSample() {
  const sample = window.__flutterScrollSample;
  const visitedSections = [...new Set(sample.routeHashes)].filter(
    (hash) => hash && hash !== '#/',
  );
  if (visitedSections.length === 0) {
    throw new Error('Runtime performance sample did not move the Flutter scroll view.');
  }
  return { intervals: sample.intervals, visitedSections };
}

async function readPageMetrics(page) {
  return page.evaluate(readMetricsFromDocument);
}

function readMetricsFromDocument() {
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
      firstFrameSignal: mark('flutter-first-frame-signal'),
      runAppFallback: mark('flutter-run-app-fallback'),
      revealStart: mark('flutter-surface-reveal-start'),
      surfaceRemoved: mark('flutter-bootstrap-surface-removed'),
    },
    bootstrapToFirstFrame: measure('flutter-bootstrap-to-first-frame'),
    bootstrapToRevealSignal: measure('flutter-bootstrap-to-reveal-signal'),
    firstFrameToReveal: measure('flutter-first-frame-to-reveal'),
    domContentLoaded: navigation?.domContentLoadedEventEnd ?? null,
    wasmDuration: wasm?.duration ?? null,
    wasmTransferBytes: wasm?.transferSize ?? null,
    vitals: window.__runtimeVitals,
    renderQuality: document.documentElement.getAttribute('data-render-quality'),
    renderQualityReason: document.documentElement.getAttribute(
      'data-render-quality-reason',
    ),
  };
}

function buildRunResult(input) {
  const frameMetrics = summarizeFrames(input.frameIntervals);
  return {
    run: input.run,
    ...summarizeTiming(input.pageMetrics, frameMetrics.median),
    ...frameMetrics.values,
    ...summarizeVitals(input.pageMetrics.vitals),
    render_quality: input.pageMetrics.renderQuality,
    render_quality_reason: input.pageMetrics.renderQualityReason,
    scroll_sections_visited: input.visitedSections,
    dom_content_loaded_ms: round(input.pageMetrics.domContentLoaded),
    wasm_duration_ms: round(input.pageMetrics.wasmDuration),
    wasm_transfer_bytes: input.pageMetrics.wasmTransferBytes,
    total_transferred_bytes: [...Object.values(
      input.transferredBytesByResourceType,
    )].reduce((total, bytes) => total + bytes, 0),
    transferred_bytes_by_resource_type: input.transferredBytesByResourceType,
  };
}

function summarizeTiming(pageMetrics, medianFrameInterval) {
  const marks = pageMetrics.marks;
  const firstFrameToReveal = pageMetrics.firstFrameToReveal;
  return {
    navigation_to_first_frame_ms: round(
      marks.firstFrameEvent ?? marks.firstFrameSignal,
    ),
    bootstrap_to_first_frame_ms: round(
      pageMetrics.bootstrapToFirstFrame ?? pageMetrics.bootstrapToRevealSignal,
    ),
    first_frame_to_reveal_ms: round(firstFrameToReveal),
    first_frame_to_reveal_frame_intervals: round(
      medianFrameInterval > 0 ? firstFrameToReveal / medianFrameInterval : 0,
      3,
    ),
    bootstrap_start_ms: round(marks.bootstrapStart),
    bootstrap_to_entrypoint_ms: round(marks.entrypointLoaded - marks.bootstrapStart),
    entrypoint_to_engine_initialized_ms: round(
      marks.engineInitialized - marks.entrypointLoaded,
    ),
    engine_initialized_to_render_signal_ms: round(
      marks.firstFrameSignal - marks.engineInitialized,
    ),
    first_frame_event_observed: marks.firstFrameEvent !== null,
    reveal_source: getRevealSource(marks),
  };
}

function getRevealSource(marks) {
  if (marks.firstFrameEvent !== null) return 'flutter-first-frame';
  if (marks.runAppFallback !== null) return 'run-app-fallback';
  return 'glass-pane-fallback';
}

function summarizeFrames(intervals) {
  const sorted = [...intervals].sort((left, right) => left - right);
  const median = percentile(sorted, 0.5);
  const p95 = percentile(sorted, 0.95);
  return {
    median,
    values: {
      scroll_frame_median_ms: round(median),
      scroll_frame_p95_ms: round(p95),
      scroll_frame_p95_over_median_ratio: round(median > 0 ? p95 / median : 0, 3),
      scroll_frames_over_50_ms: intervals.filter((value) => value > 50).length,
    },
  };
}

function summarizeVitals(vitals) {
  const longTaskTotal = vitals.longTasks.reduce(
    (total, duration) => total + duration,
    0,
  );
  return {
    long_task_total_ms: round(longTaskTotal),
    longest_task_ms: round(Math.max(0, ...vitals.longTasks)),
    cumulative_layout_shift: round(vitals.cumulativeLayoutShift, 4),
    largest_contentful_paint_ms: round(vitals.largestContentfulPaint),
  };
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
