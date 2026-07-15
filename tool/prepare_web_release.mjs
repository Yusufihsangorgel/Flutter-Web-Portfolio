import { createHash } from 'node:crypto';
import {
  mkdir,
  readFile,
  readdir,
  rename,
  rm,
  stat,
  unlink,
  writeFile,
} from 'node:fs/promises';
import path from 'node:path';
import process from 'node:process';

const webRoot = path.resolve(process.env.WEB_ROOT ?? 'build/web');
const files = await collectFiles(webRoot);
const symbolFiles = files.filter((file) => file.endsWith('.symbols'));

const removedBytes = (
  await Promise.all(
    symbolFiles.map(async (file) => {
      const metadata = await stat(file);
      await unlink(file);
      return metadata.size;
    }),
  )
).reduce((total, size) => total + size, 0);

const releaseId = await createReleaseId();
const bootstrapPath = path.join(webRoot, 'flutter_bootstrap.js');
const bootstrap = await readFile(bootstrapPath, 'utf8');
const engineRevision = extractEngineRevision(bootstrap);
const versionedBootstrap = versionEntrypoints(bootstrap, releaseId);
await writeFile(bootstrapPath, versionedBootstrap);
await versionRendererDirectory(engineRevision);
await injectReleasePreloads(releaseId, engineRevision);
await injectBootstrapShell();
await writeLegacyServiceWorkerKillSwitch();
await normalizeNoticeWhitespace();

console.log(
  `Removed ${symbolFiles.length} renderer symbol files (${formatBytes(removedBytes)}) from the public release.`,
);
console.log(
  `Versioned entrypoints as ${releaseId} and renderer assets as ${engineRevision}.`,
);

async function createReleaseId() {
  const hash = createHash('sha256');
  for (const file of ['main.dart.wasm', 'main.dart.mjs', 'main.dart.js']) {
    hash.update(await readFile(path.join(webRoot, file)));
  }
  return hash.digest('hex').slice(0, 16);
}

function extractEngineRevision(bootstrap) {
  const match = bootstrap.match(/"engineRevision":"([0-9a-f]{40})"/);
  if (!match) {
    throw new Error('flutter_bootstrap.js does not contain an engine revision');
  }
  return match[1];
}

function versionEntrypoints(bootstrap, releaseId) {
  const entrypoints = {
    mainWasmPath: 'main.dart.wasm',
    jsSupportRuntimePath: 'main.dart.mjs',
    mainJsPath: 'main.dart.js',
  };
  let output = bootstrap;
  for (const [key, file] of Object.entries(entrypoints)) {
    const pattern = new RegExp(
      `"${key}":"${file.replaceAll('.', '\\.')}(?:\\?v=[0-9a-f]+)?"`,
    );
    if (!pattern.test(output)) {
      throw new Error(`flutter_bootstrap.js does not contain ${key}`);
    }
    output = output.replace(pattern, `"${key}":"${file}?v=${releaseId}"`);
  }
  return output;
}

async function versionRendererDirectory(engineRevision) {
  const rendererRoot = path.join(webRoot, 'canvaskit');
  const entries = await readdir(rendererRoot, { withFileTypes: true });
  const versionPattern = /^[0-9a-f]{40}$/;
  const looseEntries = entries.filter(
    (entry) => !(entry.isDirectory() && versionPattern.test(entry.name)),
  );
  const versionDirectory = path.join(rendererRoot, engineRevision);

  if (looseEntries.length === 0) {
    await stat(versionDirectory);
    return;
  }

  await Promise.all(
    entries
      .filter(
        (entry) => entry.isDirectory() && versionPattern.test(entry.name),
      )
      .map((entry) =>
        rm(path.join(rendererRoot, entry.name), {
          recursive: true,
          force: true,
        }),
      ),
  );
  await mkdir(versionDirectory, { recursive: true });
  await Promise.all(
    looseEntries.map((entry) =>
      rename(
        path.join(rendererRoot, entry.name),
        path.join(versionDirectory, entry.name),
      ),
    ),
  );
}

async function injectReleasePreloads(releaseId, engineRevision) {
  const indexPath = path.join(webRoot, 'index.html');
  const index = await readFile(indexPath, 'utf8');
  const withoutPreviousHints = index.replace(
    /\n?\s*<!-- release-preloads:start -->[\s\S]*?<!-- release-preloads:end -->\n?/,
    '\n',
  );
  const preloadBlock = `  <!-- release-preloads:start -->
  <link rel="preload" href="main.dart.wasm?v=${releaseId}" as="fetch" type="application/wasm" crossorigin fetchpriority="high">
  <link rel="modulepreload" href="main.dart.mjs?v=${releaseId}" crossorigin fetchpriority="high">
  <link rel="preload" href="canvaskit/${engineRevision}/skwasm.wasm" as="fetch" type="application/wasm" crossorigin fetchpriority="high">
  <!-- release-preloads:end -->`;

  if (!withoutPreviousHints.includes('</head>')) {
    throw new Error('index.html does not contain a closing head tag');
  }
  await writeFile(
    indexPath,
    withoutPreviousHints.replace('</head>', `${preloadBlock}\n</head>`),
  );
}

async function injectBootstrapShell() {
  const contentPath = path.join(
    webRoot,
    'assets',
    'assets',
    'content',
    'portfolio.json',
  );
  const portfolio = JSON.parse(await readFile(contentPath, 'utf8'));
  const contentVersion = requiredString(
    portfolio.content_version,
    'content_version',
  );
  const role = requiredString(portfolio.profile?.role, 'profile.role');
  const location = requiredString(
    portfolio.profile?.location,
    'profile.location',
  );
  const since = requiredString(portfolio.profile?.since, 'profile.since');
  const headline = requiredString(
    portfolio.profile?.headline,
    'profile.headline',
  );
  const focus = portfolio.profile?.focus;
  if (!Array.isArray(focus) || focus.length < 3) {
    throw new Error('profile.focus must contain at least three values');
  }
  const capabilities = focus
    .slice(0, 3)
    .map((value, index) => requiredString(value, `profile.focus[${index}]`));
  const frame = requiredString(
    portfolio.story?.[0]?.eyebrow,
    'story[0].eyebrow',
  );

  const roleWords = role.trim().toUpperCase().split(/\s+/);
  const roleAccent = roleWords.pop();
  const rolePrefix = roleWords.join(' ');
  const capabilityMarkup = capabilities
    .map(
      (value, index) => `      <li class="bootstrap-capability">
        <span class="bootstrap-capability-index">${String(index + 1).padStart(2, '0')}</span>
        ${escapeHtml(value)}
      </li>`,
    )
    .join('\n');
  const prefixMarkup = rolePrefix
    ? `        <span>${escapeHtml(rolePrefix)}</span>\n`
    : '';
  const shell = `    <!-- bootstrap-content:start -->
    <div class="bootstrap-shell" aria-hidden="true" data-content-version="${escapeHtml(contentVersion)}">
      <div class="bootstrap-rail">
        <span>${escapeHtml(frame)} / FRAME LIFECYCLE</span>
        <span class="bootstrap-rail-end">
          <span class="bootstrap-rail-focus">${escapeHtml(capabilities.slice(0, 2).join(' / '))}</span>
          <span>${escapeHtml(location)}</span>
          <span class="bootstrap-live-dot"></span>
        </span>
      </div>
      <div class="bootstrap-stage">
        <p class="bootstrap-kicker">${escapeHtml(role)} / ${escapeHtml(location)} / SINCE ${escapeHtml(since)}</p>
        <p class="bootstrap-title">
${prefixMarkup}        <span class="bootstrap-title-accent">${escapeHtml(roleAccent)}.</span>
        </p>
      </div>
      <div class="bootstrap-footer">
        <p class="bootstrap-statement">${escapeHtml(headline)}</p>
        <ol class="bootstrap-capabilities">
${capabilityMarkup}
        </ol>
      </div>
    </div>
    <!-- bootstrap-content:end -->`;

  const indexPath = path.join(webRoot, 'index.html');
  const index = await readFile(indexPath, 'utf8');
  const marker = /\s*<!-- bootstrap-content:start -->[\s\S]*?<!-- bootstrap-content:end -->/;
  if (!marker.test(index)) {
    throw new Error('index.html does not contain the bootstrap content markers');
  }
  await writeFile(indexPath, index.replace(marker, `\n${shell}`));
}

function requiredString(value, path) {
  if (typeof value !== 'string' || value.trim().length === 0) {
    throw new Error(`${path} must be a non-empty string`);
  }
  return value.trim();
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

async function normalizeNoticeWhitespace() {
  const noticesPath = path.join(webRoot, 'assets', 'NOTICES');
  const notices = await readFile(noticesPath, 'utf8');
  const normalized = notices.replace(/[\t ]+$/gm, '');
  if (normalized !== notices) await writeFile(noticesPath, normalized);
}

async function writeLegacyServiceWorkerKillSwitch() {
  const source = `'use strict';

self.addEventListener('install', (event) => {
  self.skipWaiting();
});

self.addEventListener('activate', (event) => {
  event.waitUntil((async () => {
    await self.registration.unregister();
    const names = await caches.keys();
    await Promise.all(names.map((name) => caches.delete(name)));
  })());
});
`;
  await writeFile(path.join(webRoot, 'flutter_service_worker.js'), source);
}

async function collectFiles(directory) {
  const entries = await readdir(directory, { withFileTypes: true });
  const nested = await Promise.all(
    entries.map(async (entry) => {
      const entryPath = path.join(directory, entry.name);
      return entry.isDirectory() ? collectFiles(entryPath) : [entryPath];
    }),
  );
  return nested.flat();
}

function formatBytes(bytes) {
  return `${(bytes / 1024 / 1024).toFixed(2)} MiB`;
}
