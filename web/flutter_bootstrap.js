{{flutter_js}}
{{flutter_build_config}}

const removeBootstrapSurface = () => {
  const splash = document.getElementById('bootstrap-surface');
  if (!splash) return;
  splash.setAttribute('aria-busy', 'false');
  splash.classList.add('bootstrap-surface--done');
  window.setTimeout(() => splash.remove(), 220);
};

// Flutter dispatches its first-frame event while the browser is still
// compositing that frame. Keeping the matching HTML surface for two browser
// frames prevents a one-frame dark flash on cold GPU/Wasm starts.
const revealFlutterSurface = () => {
  window.requestAnimationFrame(() => {
    window.requestAnimationFrame(removeBootstrapSurface);
  });
};

const showBootstrapFailure = (error) => {
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
    window.addEventListener('flutter-first-frame', revealFlutterSurface, {
      once: true,
    });
    const appRunner = await engineInitializer.initializeEngine(engineConfig);
    await appRunner.runApp();
  },
}).catch(showBootstrapFailure);
