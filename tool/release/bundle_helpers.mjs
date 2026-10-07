import { execFileSync } from 'node:child_process';
import { createHash } from 'node:crypto';
import { readFile, readdir, rm, utimes, writeFile } from 'node:fs/promises';
import path from 'node:path';
import { gzipSync } from 'node:zlib';

const compressible = new Set([
  '.js',
  '.mjs',
  '.wasm',
  '.json',
  '.html',
  '.txt',
  '.xml',
  '.svg',
  '.ttf',
  '.otf',
]);
// Hosted build sandboxes may ship no .git directory but export the built commit.
const commitVariables = [
  'GITHUB_SHA',
  'VERCEL_GIT_COMMIT_SHA',
  'COMMIT_REF',
  'CF_PAGES_COMMIT_SHA',
];

export function resolveReleaseCommit(env = process.env, readGitCommit = readCheckoutCommit) {
  const provided = commitVariables.map((name) => env[name]).find(Boolean);
  if (provided) return provided;
  try {
    return readGitCommit();
  } catch {
    throw new Error(
      `version.json needs the built commit: set ${commitVariables.join(', ')} or build in a git checkout`,
    );
  }
}

function readCheckoutCommit() {
  return execFileSync('git', ['rev-parse', 'HEAD'], {
    encoding: 'utf8',
    stdio: ['ignore', 'pipe', 'ignore'],
  }).trim();
}

export async function precompressAssets(root) {
  let count = 0;
  for (const file of await collectFiles(root)) {
    if (!compressible.has(path.extname(file).toLowerCase())) continue;
    const bytes = await readFile(file);
    if (bytes.length <= 1024) continue;
    await writeFile(`${file}.gz`, gzipSync(bytes, { level: 9 }));
    count += 1;
  }
  return count;
}

export async function normalizeReleaseTimestamps(directory) {
  for (const entry of await readdir(directory, { withFileTypes: true })) {
    const file = path.join(directory, entry.name);
    if (entry.isDirectory()) {
      await normalizeReleaseTimestamps(file);
      continue;
    }
    if (!entry.isFile()) throw new Error(`Release entry is not a regular file: ${file}`);
    const digest = createHash('sha256')
      .update(await readFile(file))
      .digest();
    // Keep HTTP dates in the past and within signed 32-bit epoch seconds.
    const timestamp = 1 + (digest.readUInt32BE(0) >>> 2);
    await utimes(file, timestamp, timestamp);
  }
  await utimes(directory, 946684800, 946684800);
}

export async function normalizeNoticeWhitespace(root) {
  const file = path.join(root, 'assets', 'NOTICES');
  const notices = await readFile(file, 'utf8');
  const normalized = notices.replace(/[\t ]+$/gm, '');
  if (normalized !== notices) await writeFile(file, normalized);
}

export async function writeLegacyServiceWorkerKillSwitch(root) {
  const source = `'use strict';

self.addEventListener('install', () => self.skipWaiting());
self.addEventListener('activate', (event) => {
  event.waitUntil((async () => {
    const scope = self.registration.scope;
    const names = await caches.keys();
    await Promise.all(names.map(async (name) => {
      const cache = await caches.open(name);
      const requests = await cache.keys();
      if (requests.length > 0 && requests.every((request) => request.url.startsWith(scope))) {
        await caches.delete(name);
      }
    }));
    await self.registration.unregister();
  })());
});
`;
  await writeFile(path.join(root, 'flutter_service_worker.js'), source);
}

export async function collectFiles(directory) {
  const entries = await readdir(directory, { withFileTypes: true });
  const nested = await Promise.all(
    entries.map(async (entry) => {
      const entryPath = path.join(directory, entry.name);
      return entry.isDirectory() ? collectFiles(entryPath) : [entryPath];
    }),
  );
  return nested.flat();
}

export async function removeEmptyDirectories(directory) {
  const entries = await readdir(directory, { withFileTypes: true });
  await Promise.all(
    entries
      .filter((entry) => entry.isDirectory())
      .map((entry) => removeEmptyDirectories(path.join(directory, entry.name))),
  );
  if ((await readdir(directory)).length === 0) {
    await rm(directory, { recursive: true, force: true });
  }
}

export function formatBytes(bytes) {
  return `${(bytes / 1024 / 1024).toFixed(2)} MiB`;
}
