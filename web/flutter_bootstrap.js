{{flutter_js}}
{{flutter_build_config}}

const markRuntime = (name) => window.performance?.mark(name);
const measureRuntime = (name, start, end) => {
  if (
    !window.performance?.getEntriesByName(start, 'mark').length ||
    !window.performance?.getEntriesByName(end, 'mark').length
  ) {
    return;
  }
  window.performance.measure(name, start, end);
};

markRuntime('flutter-bootstrap-start');

const flutterBootstrapSurface = document.getElementById('bootstrap-surface');
let revealStarted = false;
let bootstrapFailed = false;
let removalTimer;

const removeBootstrapSurface = () => {
  if (bootstrapFailed) return;
  markRuntime('flutter-surface-reveal-start');
  measureRuntime(
    'flutter-first-frame-to-reveal',
    'flutter-first-frame-signal',
    'flutter-surface-reveal-start',
  );
  const splash = flutterBootstrapSurface;
  if (!splash) return;
  splash.setAttribute('aria-busy', 'false');
  splash.classList.add('bootstrap-surface--done');
  removalTimer = window.setTimeout(() => {
    if (bootstrapFailed) return;
    splash.remove();
    markRuntime('flutter-bootstrap-surface-removed');
    measureRuntime(
      'flutter-bootstrap-to-surface-removed',
      'flutter-bootstrap-start',
      'flutter-bootstrap-surface-removed',
    );
  }, 220);
};

// Flutter dispatches its first-frame event while the browser is still
// compositing that frame. Keeping the matching HTML surface for two browser
// frames prevents a one-frame blank flash on cold GPU/Wasm starts.
const revealFlutterSurface = () => {
  if (revealStarted || bootstrapFailed) return;
  revealStarted = true;
  window.removeEventListener('flutter-first-frame', onFlutterFirstFrame);
  markRuntime('flutter-first-frame-signal');
  // The observable first surface can come from Flutter's event or from one of
  // the guarded WebKit/CanvasKit fallbacks below. Record the primary measure
  // at the shared signal so every successful reveal has exactly one timing
  // entry, regardless of which supported source won the race.
  measureRuntime(
    'flutter-bootstrap-to-first-frame',
    'flutter-bootstrap-start',
    'flutter-first-frame-signal',
  );
  measureRuntime(
    'flutter-bootstrap-to-reveal-signal',
    'flutter-bootstrap-start',
    'flutter-first-frame-signal',
  );
  window.requestAnimationFrame(() => {
    if (bootstrapFailed) return;
    markRuntime('flutter-reveal-frame-1');
    window.requestAnimationFrame(removeBootstrapSurface);
  });
};

const onFlutterFirstFrame = () => {
  markRuntime('flutter-first-frame-event');
  revealFlutterSurface();
};

const revealAfterRunApp = () => {
  window.setTimeout(() => {
    window.requestAnimationFrame(() => {
      window.requestAnimationFrame(() => {
        if (revealStarted || bootstrapFailed) return;
        markRuntime('flutter-run-app-fallback');
        revealFlutterSurface();
      });
    });
  }, 250);
};

const showFailureWithoutStaticScript = () => {
  markRuntime('flutter-bootstrap-failed');
  const copy = window.__portfolioBootstrapLocale ?? {
    loadFailure: 'The portfolio could not load. Please try again.',
    retry: 'Retry',
  };
  const staticDocument = document.getElementById('static-document');
  if (staticDocument) {
    staticDocument.lang = 'en';
    staticDocument.dir = 'ltr';
    staticDocument.hidden = false;
    staticDocument.inert = false;
  }
  document.documentElement.classList.add('bootstrap-failed');
  if (!flutterBootstrapSurface) return;
  flutterBootstrapSurface.classList.remove('bootstrap-surface--done');
  flutterBootstrapSurface.setAttribute('aria-busy', 'false');
  flutterBootstrapSurface.removeAttribute('role');
  flutterBootstrapSurface.removeAttribute('aria-label');
  const status = document.createElement('div');
  status.className = 'bootstrap-error';
  status.setAttribute('role', 'alert');
  status.textContent = copy.loadFailure;
  const retry = document.createElement('button');
  retry.type = 'button';
  retry.className = 'bootstrap-retry';
  retry.textContent = copy.retry;
  retry.addEventListener('click', () => window.location.reload());
  status.appendChild(retry);
  flutterBootstrapSurface.replaceChildren(status);
  staticDocument?.before(flutterBootstrapSurface);
};

const showBootstrapFailure = (error) => {
  if (bootstrapFailed) return;
  bootstrapFailed = true;
  window.clearTimeout(removalTimer);
  window.removeEventListener('flutter-first-frame', onFlutterFirstFrame);
  console.error('Flutter bootstrap failed', error);
  document.dispatchEvent(new Event('portfolio-bootstrap-failed'));
  if (!document.documentElement.classList.contains('bootstrap-failed')) {
    showFailureWithoutStaticScript();
  }
};

const engineConfig = {
  // Flutter's engine revision becomes part of the renderer URL. This lets the
  // server cache large SkWasm/CanvasKit binaries for a year without a future
  // Flutter upgrade reusing stale bytes at the same path.
  canvasKitBaseUrl: new URL(
    `canvaskit/${_flutter.buildConfig.engineRevision}/`,
    document.baseURI,
  ).toString(),
  // Keep Flutter's implicit Roboto/emoji fallback fonts on the same origin.
  // The application typography is bundled through pubspec fonts; this path
  // covers glyphs outside those families without a fonts.gstatic.com fetch.
  // An absolute URL avoids both document-relative `/fallback_fonts` requests
  // and renderer-side duplication of the `assets/` prefix. `document.baseURI`
  // also preserves repository subpaths in GitHub Pages builds.
  fontFallbackBaseUrl: new URL(
    'assets/fallback_fonts/',
    document.baseURI,
  ).toString(),
  // Multi-threaded Skwasm in this Flutter release shares its glyph cache
  // between the page and the raster worker; concurrent text layout and raster
  // can wedge both threads and freeze the page behind the loading surface.
  forceSingleThreadedSkwasm: true,
};

_flutter.loader.load({
  config: engineConfig,
  onEntrypointLoaded: async function onEntrypointLoaded(engineInitializer) {
    markRuntime('flutter-entrypoint-loaded');
    window.addEventListener('flutter-first-frame', onFlutterFirstFrame, {
      once: true,
    });
    // The loader drops this promise, so a rejection here must reach the
    // recovery surface explicitly instead of leaving the loading state.
    try {
      const appRunner = await engineInitializer.initializeEngine(engineConfig);
      markRuntime('flutter-engine-initialized');
      await appRunner.runApp();
    } catch (error) {
      showBootstrapFailure(error);
      return;
    }
    markRuntime('flutter-run-app-complete');
    revealAfterRunApp();
  },
}).catch(showBootstrapFailure);

// Older WebKit/CanvasKit combinations can paint the application without
// dispatching Flutter's web first-frame event. Keep the generated critical
// shell until Flutter owns a glass pane, then retire it instead of trapping
// those browsers behind an otherwise healthy loading surface.
window.setTimeout(() => {
  if (revealStarted || bootstrapFailed || !document.querySelector('flt-glass-pane')) return;
  markRuntime('flutter-glass-pane-fallback');
  revealFlutterSurface();
}, 12000);
