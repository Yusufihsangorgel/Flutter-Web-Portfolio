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

let revealStarted = false;

const removeBootstrapSurface = () => {
  markRuntime('flutter-surface-reveal-start');
  measureRuntime(
    'flutter-first-frame-to-reveal',
    'flutter-first-frame-signal',
    'flutter-surface-reveal-start',
  );
  const splash = document.getElementById('bootstrap-surface');
  if (!splash) return;
  splash.setAttribute('aria-busy', 'false');
  splash.classList.add('bootstrap-surface--done');
  window.setTimeout(() => {
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
  if (revealStarted) return;
  revealStarted = true;
  window.removeEventListener('flutter-first-frame', onFlutterFirstFrame);
  markRuntime('flutter-first-frame-signal');
  measureRuntime(
    'flutter-bootstrap-to-reveal-signal',
    'flutter-bootstrap-start',
    'flutter-first-frame-signal',
  );
  window.requestAnimationFrame(() => {
    markRuntime('flutter-reveal-frame-1');
    window.requestAnimationFrame(removeBootstrapSurface);
  });
};

const onFlutterFirstFrame = () => {
  markRuntime('flutter-first-frame-event');
  measureRuntime(
    'flutter-bootstrap-to-first-frame',
    'flutter-bootstrap-start',
    'flutter-first-frame-event',
  );
  revealFlutterSurface();
};

const revealAfterRunApp = () => {
  window.setTimeout(() => {
    window.requestAnimationFrame(() => {
      window.requestAnimationFrame(() => {
        if (revealStarted) return;
        markRuntime('flutter-run-app-fallback');
        revealFlutterSurface();
      });
    });
  }, 250);
};

const showBootstrapFailure = (error) => {
  markRuntime('flutter-bootstrap-failed');
  console.error('Flutter bootstrap failed', error);
  const splash = document.getElementById('bootstrap-surface');
  if (!splash) return;

  splash.setAttribute('aria-busy', 'false');
  splash.setAttribute('aria-label', 'The portfolio could not start');
  splash.replaceChildren();
  const status = document.createElement('div');
  status.className = 'bootstrap-error';
  status.setAttribute('role', 'alert');
  status.textContent = 'The portfolio could not load. Please try again.';
  const retry = document.createElement('button');
  retry.type = 'button';
  retry.className = 'bootstrap-retry';
  retry.textContent = 'Retry';
  retry.addEventListener('click', () => window.location.reload());
  status.appendChild(retry);
  splash.appendChild(status);
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
};

_flutter.loader.load({
  config: engineConfig,
  onEntrypointLoaded: async function onEntrypointLoaded(engineInitializer) {
    markRuntime('flutter-entrypoint-loaded');
    window.addEventListener('flutter-first-frame', onFlutterFirstFrame, {
      once: true,
    });
    const appRunner = await engineInitializer.initializeEngine(engineConfig);
    markRuntime('flutter-engine-initialized');
    await appRunner.runApp();
    markRuntime('flutter-run-app-complete');
    revealAfterRunApp();
  },
}).catch(showBootstrapFailure);

// Older WebKit/CanvasKit combinations can paint the application without
// dispatching Flutter's web first-frame event. Keep the generated critical
// shell until Flutter owns a glass pane, then retire it instead of trapping
// those browsers behind an otherwise healthy loading surface.
window.setTimeout(() => {
  if (revealStarted || !document.querySelector('flt-glass-pane')) return;
  markRuntime('flutter-glass-pane-fallback');
  revealFlutterSurface();
}, 12000);
