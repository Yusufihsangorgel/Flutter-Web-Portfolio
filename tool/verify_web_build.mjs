import { readFile, readdir, stat } from 'node:fs/promises';
import path from 'node:path';
import process from 'node:process';

const webRoot = path.resolve(process.env.WEB_ROOT ?? 'build/web');
const budgets = {
  'main.dart.wasm': 3 * 1024 * 1024,
  'main.dart.js': 4 * 1024 * 1024,
  'flutter_bootstrap.js': 64 * 1024,
};

const failures = [];
const releaseBudget = 36 * 1024 * 1024;

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

const releaseFiles = await collectFiles(webRoot);
const symbolFiles = releaseFiles.filter((file) => file.endsWith('.symbols'));
if (symbolFiles.length > 0) {
  failures.push(
    `${symbolFiles.length} renderer symbol files are still publicly shippable; run npm run prepare:bundle`,
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
  if (!index.includes('class="bootstrap-progress"')) {
    failures.push('the neutral first-frame progress cue is missing');
  }
  if (!index.includes('aria-busy="true"')) {
    failures.push('the neutral first-frame bed does not expose loading state');
  }
  if (/bootstrap-(?:title|nav|brand|intro)/.test(index)) {
    failures.push('the HTML bootstrap duplicated meaningful portfolio content');
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
  if (!bootstrap.includes('"useLocalCanvasKit":true')) {
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
    'flutter-surface-reveal-start',
    'flutter-bootstrap-surface-removed',
    'flutter-bootstrap-to-first-frame',
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
