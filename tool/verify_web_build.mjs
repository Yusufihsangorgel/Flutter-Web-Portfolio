import { readFile, stat } from 'node:fs/promises';
import path from 'node:path';
import process from 'node:process';

const webRoot = path.resolve(process.env.WEB_ROOT ?? 'build/web');
const budgets = {
  'main.dart.wasm': 3 * 1024 * 1024,
  'main.dart.js': 4 * 1024 * 1024,
  'flutter_bootstrap.js': 64 * 1024,
};

const failures = [];

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
  if (!killSwitch.includes('client.navigate(client.url)')) {
    failures.push('the legacy service-worker does not return clients to the network');
  }
  if (/addEventListener\(['"]fetch['"]/.test(killSwitch)) {
    failures.push('the legacy service-worker must not intercept fetches');
  }
} catch {
  failures.push('flutter_service_worker.js kill switch is missing');
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
  if (!bootstrap.includes("window.addEventListener('flutter-first-frame'")) {
    failures.push('custom first-frame bootstrap cleanup is missing');
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
