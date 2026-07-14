{{flutter_js}}
{{flutter_build_config}}

const removeBootstrapSurface = () => {
  const splash = document.getElementById('bootstrap-surface');
  if (!splash) return;
  splash.classList.add('bootstrap-surface--done');
  window.setTimeout(() => splash.remove(), 220);
};

const showBootstrapFailure = (error) => {
  console.error('Flutter bootstrap failed', error);
  const splash = document.getElementById('bootstrap-surface');
  if (!splash) return;

  splash.setAttribute('aria-label', 'The Flutter experience could not start');
  const label = splash.querySelector('.bootstrap-label');
  if (label) label.textContent = 'FLUTTER WEB / BOOT FAILED';
  const track = splash.querySelector('.bootstrap-track');
  if (track) {
    const retry = document.createElement('button');
    retry.type = 'button';
    retry.className = 'bootstrap-retry';
    retry.textContent = 'RETRY';
    retry.addEventListener('click', () => window.location.reload());
    track.replaceWith(retry);
  }
};

const engineConfig = {
  // Keep Flutter's implicit Roboto/emoji fallback fonts on the same origin.
  // The application typography is bundled through pubspec fonts; this path
  // covers glyphs outside those families without a fonts.gstatic.com fetch.
  fontFallbackBaseUrl: 'assets/fallback_fonts/',
};

_flutter.loader.load({
  config: engineConfig,
  onEntrypointLoaded: async function onEntrypointLoaded(engineInitializer) {
    window.addEventListener('flutter-first-frame', removeBootstrapSurface, {
      once: true,
    });
    const appRunner = await engineInitializer.initializeEngine(engineConfig);
    await appRunner.runApp();
  },
}).catch(showBootstrapFailure);
