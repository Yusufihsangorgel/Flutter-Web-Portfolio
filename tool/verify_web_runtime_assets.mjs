import { readFile, stat } from 'node:fs/promises';
import path from 'node:path';

export function verifyBootstrapSource(bootstrap) {
  const failures = [];
  if (!bootstrap.includes('"compileTarget":"dart2wasm"')) {
    failures.push('flutter_bootstrap.js does not advertise a dart2wasm build');
  }
  const localRenderer = bootstrap.includes('"useLocalCanvasKit":true') || (
    bootstrap.includes('canvasKitBaseUrl: new URL(') &&
    bootstrap.includes('`canvaskit/${_flutter.buildConfig.engineRevision}/`')
  );
  if (!localRenderer) failures.push('renderer binaries are not configured for self-hosting');
  for (const artifact of ['main.dart.wasm', 'main.dart.mjs', 'main.dart.js']) {
    if (!bootstrap.includes(`${artifact}?v=`)) failures.push(`${artifact} does not have a release-versioned URL`);
  }
  return [...failures, ...verifyBootstrapLifecycle(bootstrap), ...verifyBootstrapTimeline(bootstrap)];
}

function verifyBootstrapLifecycle(bootstrap) {
  const checks = [
    [bootstrap.includes("window.addEventListener('flutter-first-frame'"), 'custom first-frame bootstrap cleanup is missing'],
    [bootstrap.includes("markRuntime('flutter-run-app-fallback')") && bootstrap.includes("document.querySelector('flt-glass-pane')"), 'the CanvasKit/WebKit first-frame fallback is missing'],
    [bootstrap.includes('window.requestAnimationFrame(() => {') && bootstrap.includes('window.requestAnimationFrame(removeBootstrapSurface)'), 'the first-frame reveal is not compositor-safe'],
    [bootstrap.includes('fontFallbackBaseUrl: new URL(') && bootstrap.includes("'assets/fallback_fonts/'") && bootstrap.includes('document.baseURI'), 'Flutter fallback fonts are not configured for same-origin loading'],
    [bootstrap.includes('}).catch(showBootstrapFailure);'), 'the bootstrap failure recovery surface is missing'],
    [bootstrap.includes("splash.setAttribute('aria-busy', 'false')"), 'the bootstrap does not resolve its accessible busy state'],
    [!/_flutter\.loader\.load\(\{\s*serviceWorkerSettings/.test(bootstrap), 'the application bootstrap re-enabled the service worker'],
  ];
  return checks.filter(([valid]) => !valid).map(([, message]) => message);
}

function verifyBootstrapTimeline(bootstrap) {
  const timeline = [
    'flutter-bootstrap-start', 'flutter-entrypoint-loaded', 'flutter-engine-initialized',
    'flutter-first-frame-event', 'flutter-first-frame-signal', 'flutter-surface-reveal-start',
    'flutter-bootstrap-surface-removed', 'flutter-bootstrap-to-first-frame',
    'flutter-bootstrap-to-reveal-signal', 'flutter-first-frame-to-reveal',
  ];
  return timeline.filter((entry) => !bootstrap.includes(`'${entry}'`)).map((entry) =>
    `the runtime timeline is missing ${entry}`,
  );
}

async function verifyRendererFiles({ webRoot, bootstrap, expectedEngine }) {
  const failures = [];
  const revision = bootstrap.match(/"engineRevision":"([0-9a-f]{40})"/)?.[1];
  if (!revision) failures.push('flutter_bootstrap.js does not expose an engine revision');
  else {
    if (revision !== expectedEngine) failures.push(`the release engine revision is ${revision}; expected ${expectedEngine}`);
    try {
      const renderer = await stat(path.join(webRoot, 'canvaskit', revision, 'skwasm.wasm'));
      if (!renderer.isFile() || renderer.size === 0) failures.push('the versioned SkWasm renderer is empty');
    } catch {
      failures.push('the versioned SkWasm renderer is missing');
    }
  }
  try {
    await stat(path.join(webRoot, 'canvaskit', 'skwasm.wasm'));
    failures.push('an unversioned SkWasm renderer is still publicly shippable');
  } catch {
    // Renderer binaries belong below their engine revision.
  }
  return failures;
}

export async function verifyRuntimeAssets({ webRoot, expectedEngine }) {
  const failures = await verifyDeclaredFonts(webRoot);
  try {
    const header = await readFile(path.join(webRoot, 'main.dart.wasm'));
    if (![0x00, 0x61, 0x73, 0x6d].every((byte, index) => header[index] === byte)) {
      failures.push('main.dart.wasm has an invalid Wasm header');
    }
  } catch {
    // The entrypoint budget check reports missing Wasm files.
  }
  let bootstrap;
  try {
    bootstrap = await readFile(path.join(webRoot, 'flutter_bootstrap.js'), 'utf8');
  } catch {
    return failures;
  }
  failures.push(...verifyBootstrapSource(bootstrap));
  failures.push(...await verifyRendererFiles({ webRoot, bootstrap, expectedEngine }));
  return failures;
}

async function verifyDeclaredFonts(webRoot) {
  const failures = [];
  try {
    const manifest = JSON.parse(await readFile(path.join(webRoot, 'assets/FontManifest.json'), 'utf8'));
    const fonts = manifest.flatMap((family) => family.fonts.map((font) => font.asset));
    await Promise.all(fonts.map(async (asset) => {
      try {
        const metadata = await stat(path.join(webRoot, 'assets', asset));
        if (!metadata.isFile() || metadata.size === 0) failures.push(`declared font ${asset} is not a non-empty file`);
      } catch {
        failures.push(`declared font ${asset} is missing from the release`);
      }
    }));
  } catch {
    failures.push('assets/FontManifest.json is missing or invalid');
  }
  return failures;
}
