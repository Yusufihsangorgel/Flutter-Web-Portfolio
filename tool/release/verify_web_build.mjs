import { readFile, stat } from 'node:fs/promises';
import path from 'node:path';
import process from 'node:process';

import { renderSourceManifest } from './source_manifest.mjs';
import {
  resolveContainedPublicPath,
  resolveSafePublicPngPath,
} from '../shared/safe_public_asset_path.mjs';
import { assertRasterDimensions, inspectRaster } from '../assets/raster_inspector.mjs';
import { verifyRuntimeAssets } from '../verify_web_runtime_assets.mjs';
import { verifyResumeRelease } from '../resume/verify_resume_release.mjs';
import { collectFiles } from './bundle_helpers.mjs';
import { verifyStatic404Release } from './verify_static_404.mjs';
import { verifyReleaseDocument } from './verify_document.mjs';

const webRoot = path.resolve(process.env.WEB_ROOT ?? 'build/web');
const budgets = {
  'main.dart.wasm': 3 * 1024 * 1024,
  'main.dart.js': 4 * 1024 * 1024,
  'flutter_bootstrap.js': 64 * 1024,
};

const failures = [];
const releaseBudget = 52 * 1024 * 1024;
const sourcePortfolio = JSON.parse(
  await readFile(path.resolve('assets', 'content', 'portfolio.json'), 'utf8'),
);
const expectedToolchain = JSON.parse(
  await readFile(path.resolve('tool', 'quality', 'toolchain.json'), 'utf8'),
);
const socialImagePath = resolveSafePublicPngPath(sourcePortfolio.site.social_image);

try {
  const [embeddedManifest, currentManifest] = await Promise.all([
    readFile(path.join(webRoot, 'assets', 'assets', 'build', 'source_manifest.sha256'), 'utf8'),
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
  } catch {
    failures.push(`${sidecar} is missing from the release; run npm run prepare:bundle`);
  }
}
failures.push(...(await verifyStatic404Release({ sourceRoot: path.resolve(), webRoot })));
const symbolFiles = releaseFiles.filter((file) => file.endsWith('.symbols'));
if (symbolFiles.length > 0) {
  failures.push(
    `${symbolFiles.length} renderer symbol files are still publicly shippable; run npm run prepare:bundle`,
  );
}

const unreachableRendererFiles = releaseFiles.filter((file) => {
  const segments = path.relative(webRoot, file).split(path.sep);
  if (segments[0] !== 'canvaskit') return false;
  return segments.includes('experimental_webparagraph') || segments.at(-1).startsWith('wimp.');
});
if (unreachableRendererFiles.length > 0) {
  failures.push(
    `${unreachableRendererFiles.length} unreachable renderer variant files are still publicly shippable; run npm run prepare:bundle`,
  );
}

// Precompressed siblings only duplicate counted files; verifyReleaseDocument checks their bytes.
const releaseBytes = (
  await Promise.all(
    releaseFiles
      .filter((file) => !file.endsWith('.gz'))
      .map(async (file) => (await stat(file)).size),
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
    await readFile(path.join(webRoot, 'assets', 'AssetManifest.bin.json'), 'utf8'),
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
      if (assetManifestBytes && !assetManifestBytes.includes(Buffer.from(asset, 'utf8'))) {
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
      const [metadata, bytes] = await Promise.all([stat(outputPath), readFile(outputPath)]);
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
    if (assetManifestBytes && !assetManifestBytes.includes(Buffer.from(asset, 'utf8'))) {
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
  const releaseRaster = inspectRaster(releaseSocialCard, 'release social preview');
  const sourceRaster = inspectRaster(sourceSocialCard, 'source social preview');
  assertRasterDimensions(releaseRaster, 1200, 630, 'release social preview');
  assertRasterDimensions(sourceRaster, 1200, 630, 'source social preview');
} catch (error) {
  failures.push(`the generated social preview is missing or corrupt: ${error.message}`);
}

failures.push(
  ...(await verifyRuntimeAssets({
    webRoot,
    expectedEngine: expectedToolchain.flutterEngineRevision,
  })),
);
failures.push(...(await verifyResumeRelease({ webRoot, record: sourcePortfolio })));

try {
  const killSwitch = await readFile(path.join(webRoot, 'flutter_service_worker.js'), 'utf8');
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

failures.push(...(await verifyReleaseDocument(webRoot, sourcePortfolio, releaseFiles)));

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
