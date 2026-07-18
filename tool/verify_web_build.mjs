import { readFile, readdir, stat } from 'node:fs/promises';
import path from 'node:path';
import process from 'node:process';

import { renderSourceManifest } from './source_manifest.mjs';
import {
  resolveContainedPublicPath,
  resolveSafePublicPngPath,
} from './safe_public_asset_path.mjs';
import { assertRasterDimensions, inspectRaster } from './raster_inspector.mjs';

const webRoot = path.resolve(process.env.WEB_ROOT ?? 'build/web');
const budgets = {
  'main.dart.wasm': 3 * 1024 * 1024,
  'main.dart.js': 4 * 1024 * 1024,
  'flutter_bootstrap.js': 64 * 1024,
};

const failures = [];
// Flutter 3.44's self-hosted dual-runtime bundle carries mutually exclusive
// CanvasKit, SkWasm, and fallback renderer variants. Only one is requested by
// a browser; the entrypoint budgets above guard actual user payload while this
// aggregate budget guards the deployment footprint.
const releaseBudget = 40 * 1024 * 1024;
const sourcePortfolio = JSON.parse(
  await readFile(path.resolve('assets', 'content', 'portfolio.json'), 'utf8'),
);
const expectedToolchain = JSON.parse(
  await readFile(path.resolve('tool', 'toolchain.json'), 'utf8'),
);
const socialImagePath = resolveSafePublicPngPath(
  sourcePortfolio.site.social_image,
);

try {
  const [embeddedManifest, currentManifest] = await Promise.all([
    readFile(
      path.join(
        webRoot,
        'assets',
        'assets',
        'build',
        'source_manifest.sha256',
      ),
      'utf8',
    ),
    renderSourceManifest(),
  ]);
  if (embeddedManifest !== currentManifest) {
    failures.push(
      'the release was built from stale sources; run npm run prepare:source before flutter build',
    );
  }
} catch {
  failures.push('the release source manifest is missing or invalid');
}

async function inspectArtifact(fileName, budget) {
  const filePath = path.join(webRoot, fileName);
  try {
    const metadata = await stat(filePath);
    if (!metadata.isFile()) {
      failures.push(`${fileName} is not a file`);
      return null;
    }
    if (metadata.size > budget) {
      failures.push(
        `${fileName} is ${formatBytes(metadata.size)}; budget is ${formatBytes(budget)}`,
      );
    }
    return metadata.size;
  } catch {
    failures.push(`${fileName} is missing`);
    return null;
  }
}

const entries = await Promise.all(
  Object.entries(budgets).map(async ([fileName, budget]) => ({
    fileName,
    budget,
    size: await inspectArtifact(fileName, budget),
  })),
);

try {
  const releaseToolchain = JSON.parse(
    await readFile(path.join(webRoot, 'release-toolchain.json'), 'utf8'),
  );
  if (JSON.stringify(releaseToolchain) !== JSON.stringify(expectedToolchain)) {
    failures.push('release-toolchain.json is stale');
  }
} catch {
  failures.push('release-toolchain.json is missing or invalid');
}

const releaseFiles = await collectFiles(webRoot);
for (const sidecar of ['_headers', '_redirects']) {
  try {
    const [source, release] = await Promise.all([
      readFile(path.resolve('web', sidecar), 'utf8'),
      readFile(path.join(webRoot, sidecar), 'utf8'),
    ]);
    if (source !== release) failures.push(`${sidecar} is stale in the release`);
    if (
      sidecar === '_headers' &&
      ![
        'Cross-Origin-Opener-Policy: same-origin',
        'Cross-Origin-Embedder-Policy: credentialless',
        'Content-Security-Policy:',
      ].every((header) => release.includes(header))
    ) {
      failures.push('the release _headers file is missing isolation or CSP policy');
    }
    if (sidecar === '_redirects' && !release.includes('/*  /index.html  200')) {
      failures.push('the release _redirects file is missing the SPA fallback');
    }
  } catch {
    failures.push(`${sidecar} is missing from the release; run npm run prepare:bundle`);
  }
}
const symbolFiles = releaseFiles.filter((file) => file.endsWith('.symbols'));
if (symbolFiles.length > 0) {
  failures.push(
    `${symbolFiles.length} renderer symbol files are still publicly shippable; run npm run prepare:bundle`,
  );
}

// These renderer variants are only reachable through engine configuration
// (`enableWimp`, `canvasKitVariant`) that this release never sets.
const unreachableRendererFiles = releaseFiles.filter((file) => {
  const segments = path.relative(webRoot, file).split(path.sep);
  if (segments[0] !== 'canvaskit') return false;
  return (
    segments.includes('experimental_webparagraph') ||
    segments.at(-1).startsWith('wimp.')
  );
});
if (unreachableRendererFiles.length > 0) {
  failures.push(
    `${unreachableRendererFiles.length} unreachable renderer variant files are still publicly shippable; run npm run prepare:bundle`,
  );
}

const releaseBytes = (
  await Promise.all(
    releaseFiles.map(async (file) => (await stat(file)).size),
  )
).reduce((total, size) => total + size, 0);
if (releaseBytes > releaseBudget) {
  failures.push(
    `the public release is ${formatBytes(releaseBytes)}; budget is ${formatBytes(releaseBudget)}`,
  );
}

const fallbackAssets = [
  'assets/fallback_fonts/roboto/v32/KFOmCnqEu92Fr1Me4GZLCzYlKw.woff2',
  'assets/fallback_fonts/notocoloremoji/v32/Yq6P-KqIXTD0t4D9z1ESnKM3-HpFabsE4tq3luCC7p-aXxcn.0.woff2',
];

await Promise.all(
  fallbackAssets.map(async (asset) => {
    try {
      const metadata = await stat(path.join(webRoot, asset));
      if (!metadata.isFile() || metadata.size === 0) {
        failures.push(`${asset} is not a non-empty file`);
      }
    } catch {
      failures.push(`${asset} is missing`);
    }
  }),
);

const authoredWorkAssets = [];
for (const [index, system] of (sourcePortfolio.systems ?? []).entries()) {
  for (const [variant, artifact] of [
    ['primary', system.artifact],
    ['compact', system.artifact?.compact],
  ]) {
    const asset = artifact?.asset;
    if (typeof asset !== 'string' || !asset.startsWith('assets/work/')) {
      failures.push(`systems[${index}] ${variant} work artifact is missing or unsafe`);
      continue;
    }
    if (!Number.isSafeInteger(artifact.width) || !Number.isSafeInteger(artifact.height)) {
      failures.push(`systems[${index}] ${variant} work artifact dimensions are invalid`);
      continue;
    }
    authoredWorkAssets.push({
      asset,
      width: artifact.width,
      height: artifact.height,
    });
  }
}

let assetManifestBytes = null;
try {
  const encodedManifest = JSON.parse(
    await readFile(
      path.join(webRoot, 'assets', 'AssetManifest.bin.json'),
      'utf8',
    ),
  );
  if (typeof encodedManifest !== 'string') throw new Error('not encoded');
  assetManifestBytes = Buffer.from(encodedManifest, 'base64');
} catch {
  failures.push('assets/AssetManifest.bin.json is missing or invalid');
}

const canonicalReleaseAssets = [
  'assets/content/portfolio.json',
  'assets/presentation/narrative.json',
  ...(sourcePortfolio.site.locales ?? []).flatMap((locale) => [
    `assets/i18n/${locale}.json`,
    ...(locale === 'en' ? [] : [`assets/content/locales/${locale}.json`]),
  ]),
];
await Promise.all(
  canonicalReleaseAssets.map(async (asset) => {
    try {
      const [source, release] = await Promise.all([
        readFile(path.resolve(asset)),
        readFile(path.resolve(webRoot, 'assets', asset)),
      ]);
      if (!source.equals(release)) {
        failures.push(`canonical asset ${asset} is stale in the release`);
      }
      if (
        assetManifestBytes &&
        !assetManifestBytes.includes(Buffer.from(asset, 'utf8'))
      ) {
        failures.push(`canonical asset ${asset} is absent from AssetManifest`);
      }
    } catch {
      failures.push(`canonical asset ${asset} is missing from the release`);
    }
  }),
);

await Promise.all(
  authoredWorkAssets.map(async ({ asset, width, height }) => {
    const outputPath = path.resolve(webRoot, 'assets', ...asset.split('/'));
    const assetsRoot = path.resolve(webRoot, 'assets');
    if (!outputPath.startsWith(`${assetsRoot}${path.sep}`)) {
      failures.push(`work artifact escapes the release root: ${asset}`);
      return;
    }
    try {
      const [metadata, bytes] = await Promise.all([
        stat(outputPath),
        readFile(outputPath),
      ]);
      if (!metadata.isFile() || metadata.size === 0) {
        failures.push(`work artifact ${asset} is not a non-empty release file`);
      } else {
        const raster = inspectRaster(bytes, `work artifact ${asset}`);
        assertRasterDimensions(raster, width, height, `work artifact ${asset}`);
      }
    } catch (error) {
      failures.push(
        `work artifact ${asset} is missing, corrupt, or dimensionally stale: ${error.message}`,
      );
    }
    if (
      assetManifestBytes &&
      !assetManifestBytes.includes(Buffer.from(asset, 'utf8'))
    ) {
      failures.push(`work artifact ${asset} is absent from AssetManifest`);
    }
  }),
);

try {
  const releaseSocialPath = resolveContainedPublicPath(
    webRoot,
    socialImagePath,
    'site.social_image',
  );
  const sourceSocialPath = resolveContainedPublicPath(
    path.resolve('web'),
    socialImagePath,
    'site.social_image',
  );
  const [releaseSocialCard, sourceSocialCard] = await Promise.all([
    readFile(releaseSocialPath),
    readFile(sourceSocialPath),
  ]);
  if (!releaseSocialCard.equals(sourceSocialCard)) {
    failures.push('the release social preview is stale');
  }
  const releaseRaster = inspectRaster(
    releaseSocialCard,
    'release social preview',
  );
  const sourceRaster = inspectRaster(sourceSocialCard, 'source social preview');
  assertRasterDimensions(releaseRaster, 1200, 630, 'release social preview');
  assertRasterDimensions(sourceRaster, 1200, 630, 'source social preview');
} catch (error) {
  failures.push(`the generated social preview is missing or corrupt: ${error.message}`);
}

try {
  const fontManifest = JSON.parse(
    await readFile(path.join(webRoot, 'assets', 'FontManifest.json'), 'utf8'),
  );
  const declaredFonts = fontManifest.flatMap((family) =>
    family.fonts.map((font) => font.asset),
  );

  await Promise.all(
    declaredFonts.map(async (asset) => {
      const outputPath = path.join(webRoot, 'assets', asset);
      try {
        const metadata = await stat(outputPath);
        if (!metadata.isFile() || metadata.size === 0) {
          failures.push(`declared font ${asset} is not a non-empty file`);
        }
      } catch {
        failures.push(`declared font ${asset} is missing from the release`);
      }
    }),
  );
} catch {
  failures.push('assets/FontManifest.json is missing or invalid');
}

try {
  const wasmHeader = await readFile(path.join(webRoot, 'main.dart.wasm'));
  const expectedHeader = [0x00, 0x61, 0x73, 0x6d];
  const hasWasmHeader = expectedHeader.every(
    (byte, index) => wasmHeader[index] === byte,
  );
  if (!hasWasmHeader) failures.push('main.dart.wasm has an invalid Wasm header');
} catch {
  // The missing-file failure above is more actionable.
}

try {
  const killSwitch = await readFile(
    path.join(webRoot, 'flutter_service_worker.js'),
    'utf8',
  );
  if (!killSwitch.includes('self.skipWaiting()')) {
    failures.push('the legacy service-worker does not activate immediately');
  }
  if (!killSwitch.includes('self.registration.unregister()')) {
    failures.push('the legacy service-worker does not unregister itself');
  }
  if (/addEventListener\(['"]fetch['"]/.test(killSwitch)) {
    failures.push('the legacy service-worker must not intercept fetches');
  }
} catch {
  failures.push('flutter_service_worker.js kill switch is missing');
}

try {
  const index = await readFile(path.join(webRoot, 'index.html'), 'utf8');
  if (index.includes('bootstrap-progress')) {
    failures.push('the critical shell must not add a synthetic loading cue');
  }
  if (!index.includes('aria-busy="true"')) {
    failures.push('the critical shell does not expose loading state');
  }
  if (!index.includes('class="bootstrap-shell" aria-hidden="true"')) {
    failures.push('the generated critical rendering shell is missing');
  }
  if ((index.match(/<!-- bootstrap-content:start -->/g) ?? []).length !== 1) {
    failures.push('index.html must contain exactly one bootstrap content block');
  }
  try {
    const portfolio = JSON.parse(
      await readFile(
        path.join(
          webRoot,
          'assets',
          'assets',
          'content',
          'portfolio.json',
        ),
        'utf8',
      ),
    );
    const generatedValues = [
      portfolio.content_version,
      portfolio.profile?.name,
      portfolio.profile?.role,
      portfolio.profile?.headline,
      portfolio.profile?.location,
      portfolio.profile?.since,
      portfolio.profile?.focus?.[0],
    ];
    for (const value of generatedValues) {
      if (typeof value !== 'string' || !index.includes(escapeHtml(value))) {
        failures.push(`the critical shell is not synchronized with ${value}`);
      }
    }
    if (
      !index.includes("localStorage.getItem('flutter.selected_language')") ||
      !index.includes('decoded = JSON.parse(stored)') ||
      !index.includes('document.documentElement.dir = locales[selected].direction')
    ) {
      failures.push('the critical shell does not restore its locale before paint');
    }
    for (const locale of portfolio.site?.locales ?? []) {
      const localePortfolio = locale === 'en'
        ? portfolio
        : JSON.parse(
            await readFile(
              path.join(
                webRoot,
                'assets',
                'assets',
                'content',
                'locales',
                `${locale}.json`,
              ),
              'utf8',
            ),
          );
      const interfaceLocale = JSON.parse(
        await readFile(
          path.join(webRoot, 'assets', 'assets', 'i18n', `${locale}.json`),
          'utf8',
        ),
      );
      const localizedValues = [
        localePortfolio.site?.title,
        localePortfolio.profile?.role,
        localePortfolio.profile?.location,
        localePortfolio.profile?.headline,
        localePortfolio.profile?.focus?.[0],
        interfaceLocale.home_section?.based_in,
        interfaceLocale.home_section?.working_since,
        interfaceLocale.home_section?.focus,
        interfaceLocale.accessibility?.loading_portfolio,
        interfaceLocale.accessibility?.load_failure,
        interfaceLocale.accessibility?.retry,
      ];
      if (Array.isArray(localePortfolio.systems) && localePortfolio.systems.length > 0) {
        localizedValues.push(interfaceLocale.home_section?.view_work);
      }
      if (localePortfolio.profile?.email?.includes('@')) {
        localizedValues.push(interfaceLocale.home_section?.email);
      }
      for (const value of localizedValues) {
        if (typeof value !== 'string' || !index.includes(escapeHtml(value))) {
          failures.push(`the critical shell is missing ${locale} locale content`);
          break;
        }
      }
    }
  } catch {
    failures.push('the critical shell portfolio source is missing or invalid');
  }
  const bootstrap = await readFile(
    path.join(webRoot, 'flutter_bootstrap.js'),
    'utf8',
  );
  const releaseId = bootstrap.match(
    /"mainWasmPath":"main\.dart\.wasm\?v=([0-9a-f]{16})"/,
  )?.[1];
  const engineRevision = bootstrap.match(
    /"engineRevision":"([0-9a-f]{40})"/,
  )?.[1];
  if (!releaseId || !engineRevision) {
    failures.push('critical preload identifiers cannot be derived');
  } else {
    const expectedHints = [
      `rel="preload" href="main.dart.wasm?v=${releaseId}" as="fetch" type="application/wasm" crossorigin fetchpriority="high"`,
      `rel="modulepreload" href="main.dart.mjs?v=${releaseId}" crossorigin fetchpriority="high"`,
      `rel="preload" href="canvaskit/${engineRevision}/skwasm.wasm" as="fetch" type="application/wasm" crossorigin fetchpriority="high"`,
    ];
    for (const hint of expectedHints) {
      if (!index.includes(hint)) {
        failures.push(`index.html is missing critical hint: ${hint}`);
      }
    }
    if ((index.match(/<!-- release-preloads:start -->/g) ?? []).length !== 1) {
      failures.push('index.html must contain exactly one critical preload block');
    }
  }
} catch {
  failures.push('index.html is missing');
}

try {
  const bootstrap = await readFile(
    path.join(webRoot, 'flutter_bootstrap.js'),
    'utf8',
  );
  if (!bootstrap.includes('"compileTarget":"dart2wasm"')) {
    failures.push('flutter_bootstrap.js does not advertise a dart2wasm build');
  }
  const usesLegacyLocalRendererFlag = bootstrap.includes(
    '"useLocalCanvasKit":true',
  );
  const usesExplicitLocalRendererUrl =
    bootstrap.includes('canvasKitBaseUrl: new URL(') &&
    bootstrap.includes(
      '`canvaskit/${_flutter.buildConfig.engineRevision}/`',
    );
  if (!usesLegacyLocalRendererFlag && !usesExplicitLocalRendererUrl) {
    failures.push('renderer binaries are not configured for self-hosting');
  }
  for (const artifact of ['main.dart.wasm', 'main.dart.mjs', 'main.dart.js']) {
    if (!bootstrap.includes(`${artifact}?v=`)) {
      failures.push(`${artifact} does not have a release-versioned URL`);
    }
  }
  const engineRevision = bootstrap.match(
    /"engineRevision":"([0-9a-f]{40})"/,
  )?.[1];
  if (!engineRevision) {
    failures.push('flutter_bootstrap.js does not expose an engine revision');
  } else {
    if (engineRevision !== expectedToolchain.flutterEngineRevision) {
      failures.push(
        `the release engine revision is ${engineRevision}; expected ${expectedToolchain.flutterEngineRevision}`,
      );
    }
    try {
      const renderer = await stat(
        path.join(webRoot, 'canvaskit', engineRevision, 'skwasm.wasm'),
      );
      if (!renderer.isFile() || renderer.size === 0) {
        failures.push('the versioned SkWasm renderer is empty');
      }
    } catch {
      failures.push('the versioned SkWasm renderer is missing');
    }
  }
  try {
    await stat(path.join(webRoot, 'canvaskit', 'skwasm.wasm'));
    failures.push('an unversioned SkWasm renderer is still publicly shippable');
  } catch {
    // Expected: renderer binaries live below the engine revision.
  }
  if (!bootstrap.includes("window.addEventListener('flutter-first-frame'")) {
    failures.push('custom first-frame bootstrap cleanup is missing');
  }
  if (
    !bootstrap.includes("markRuntime('flutter-run-app-fallback')") ||
    !bootstrap.includes("document.querySelector('flt-glass-pane')")
  ) {
    failures.push('the CanvasKit/WebKit first-frame fallback is missing');
  }
  if (
    !bootstrap.includes('window.requestAnimationFrame(() => {') ||
    !bootstrap.includes('window.requestAnimationFrame(removeBootstrapSurface)')
  ) {
    failures.push('the first-frame reveal is not compositor-safe');
  }
  for (const timelineEntry of [
    'flutter-bootstrap-start',
    'flutter-entrypoint-loaded',
    'flutter-engine-initialized',
    'flutter-first-frame-event',
    'flutter-first-frame-signal',
    'flutter-surface-reveal-start',
    'flutter-bootstrap-surface-removed',
    'flutter-bootstrap-to-first-frame',
    'flutter-bootstrap-to-reveal-signal',
    'flutter-first-frame-to-reveal',
  ]) {
    if (!bootstrap.includes(`'${timelineEntry}'`)) {
      failures.push(`the runtime timeline is missing ${timelineEntry}`);
    }
  }
  if (
    !bootstrap.includes('fontFallbackBaseUrl: new URL(') ||
    !bootstrap.includes("'assets/fallback_fonts/'") ||
    !bootstrap.includes('document.baseURI')
  ) {
    failures.push(
      'Flutter fallback fonts are not configured for same-origin loading',
    );
  }
  if (!bootstrap.includes('}).catch(showBootstrapFailure);')) {
    failures.push('the bootstrap failure recovery surface is missing');
  }
  if (!bootstrap.includes("splash.setAttribute('aria-busy', 'false')")) {
    failures.push('the bootstrap does not resolve its accessible busy state');
  }
  if (/\_flutter\.loader\.load\(\{\s*serviceWorkerSettings/.test(bootstrap)) {
    failures.push('the application bootstrap re-enabled the service worker');
  }
} catch {
  // The missing-file failure above is more actionable.
}

for (const { fileName, size, budget } of entries) {
  if (size === null) continue;
  const usage = ((size / budget) * 100).toFixed(1);
  console.log(
    `${fileName.padEnd(21)} ${formatBytes(size).padStart(9)} / ${formatBytes(budget)} (${usage}%)`,
  );
}

console.log(
  `${'public release'.padEnd(21)} ${formatBytes(releaseBytes).padStart(9)} / ${formatBytes(releaseBudget)}`,
);

if (failures.length > 0) {
  console.error('\nWeb build verification failed:');
  for (const failure of failures) console.error(`- ${failure}`);
  process.exitCode = 1;
} else {
  console.log('\nWeb build verification passed.');
}

function formatBytes(bytes) {
  return `${(bytes / 1024 / 1024).toFixed(2)} MiB`;
}

function escapeHtml(value) {
  return value.replace(/[&<>"']/g, (character) => {
    const entities = {
      '&': '&amp;',
      '<': '&lt;',
      '>': '&gt;',
      '"': '&quot;',
      "'": '&#39;',
    };
    return entities[character];
  });
}

async function collectFiles(directory) {
  const directoryEntries = await readdir(directory, { withFileTypes: true });
  const nested = await Promise.all(
    directoryEntries.map(async (entry) => {
      const entryPath = path.join(directory, entry.name);
      return entry.isDirectory() ? collectFiles(entryPath) : [entryPath];
    }),
  );
  return nested.flat();
}
