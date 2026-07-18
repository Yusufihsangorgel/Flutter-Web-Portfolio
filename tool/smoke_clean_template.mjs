import { chromium } from '@playwright/test';
import { createReadStream } from 'node:fs';
import { createServer } from 'node:http';
import path from 'node:path';
import process from 'node:process';

import {
  canonicalStaticRoot,
  resolveStaticFile,
  StaticPathViolation,
} from './safe_static_path.mjs';

const root = canonicalStaticRoot('build/web');
const basePath = normalizeBasePath(readOption('--base-path') ?? '/');
const contentTypes = new Map([
  ['.css', 'text/css; charset=utf-8'],
  ['.html', 'text/html; charset=utf-8'],
  ['.js', 'text/javascript; charset=utf-8'],
  ['.json', 'application/json; charset=utf-8'],
  ['.mjs', 'text/javascript; charset=utf-8'],
  ['.otf', 'font/otf'],
  ['.png', 'image/png'],
  ['.svg', 'image/svg+xml'],
  ['.ttf', 'font/ttf'],
  ['.wasm', 'application/wasm'],
  ['.woff', 'font/woff'],
  ['.woff2', 'font/woff2'],
]);

const server = createServer((request, response) => {
  const url = new URL(request.url ?? '/', `http://${request.headers.host}`);
  if (!url.pathname.startsWith(basePath)) {
    response.writeHead(404).end('Not Found');
    return;
  }
  let relative;
  try {
    relative = decodeURIComponent(url.pathname.slice(basePath.length));
  } catch {
    response.writeHead(400).end('Bad Request');
    return;
  }
  if (relative.includes('\0')) {
    response.writeHead(400).end('Bad Request');
    return;
  }
  let file;
  try {
    file = resolveStaticFile(root, relative);
  } catch (error) {
    if (!(error instanceof StaticPathViolation)) throw error;
    response.writeHead(403).end('Forbidden');
    return;
  }
  if (!file) {
    response.writeHead(404).end('Not Found');
    return;
  }
  response.setHeader('Cross-Origin-Opener-Policy', 'same-origin');
  response.setHeader('Cross-Origin-Embedder-Policy', 'credentialless');
  response.setHeader(
    'Content-Type',
    contentTypes.get(path.extname(file)) ?? 'application/octet-stream',
  );
  createReadStream(file).pipe(response);
});

await new Promise((resolve, reject) => {
  server.once('error', reject);
  server.listen(0, '127.0.0.1', resolve);
});

const address = server.address();
if (!address || typeof address === 'string') throw new Error('Smoke server did not bind.');
const origin = `http://127.0.0.1:${address.port}`;
const browser = await chromium.launch({ headless: true });
try {
  for (const viewport of [
    { name: 'desktop', width: 1440, height: 900 },
    { name: 'mobile', width: 412, height: 915 },
  ]) {
    const page = await browser.newPage({
      viewport: { width: viewport.width, height: viewport.height },
      locale: 'en-US',
      timezoneId: 'UTC',
      reducedMotion: 'reduce',
    });
    const failures = [];
    page.on('pageerror', (error) => failures.push(error.message));
    page.on('response', (response) => {
      if (response.status() >= 400) failures.push(`${response.status()} ${response.url()}`);
    });
    await page.goto(`${origin}${basePath}`, { waitUntil: 'domcontentloaded' });
    await page.waitForSelector('flt-semantics-host', {
      state: 'attached',
      timeout: 20000,
    });
    await page.locator('#bootstrap-surface').waitFor({ state: 'detached' });
    if ((await page.title()) !== 'Ada Lovelace — Computing Pioneer') {
      failures.push(`unexpected title: ${await page.title()}`);
    }
    for (const absent of ['Experience', 'Open Source', 'Selected Work']) {
      if ((await page.getByRole('heading', { name: absent, exact: true }).count()) !== 0) {
        failures.push(`empty chapter remained visible: ${absent}`);
      }
    }
    if ((await page.getByRole('heading', { name: /^About(?:\s|$)/ }).count()) !== 1) {
      failures.push('About chapter is missing');
    }
    const documentState = await page.evaluate(() => ({
      lang: document.documentElement.lang,
      overflow: document.documentElement.scrollWidth - window.innerWidth,
    }));
    if (documentState.lang !== 'en') failures.push(`unexpected lang: ${documentState.lang}`);
    if (documentState.overflow > 1) failures.push(`horizontal overflow: ${documentState.overflow}px`);
    await page.close();
    if (failures.length > 0) {
      throw new Error(`${viewport.name} clean-template smoke failed:\n- ${failures.join('\n- ')}`);
    }
  }
  process.stdout.write('Clean-template desktop and mobile browser smoke passed.\n');
} finally {
  await browser.close();
  await new Promise((resolve) => server.close(resolve));
}

function readOption(name) {
  const index = process.argv.indexOf(name);
  if (index < 0) return null;
  const value = process.argv[index + 1];
  if (!value || value.startsWith('--')) throw new Error(`${name} requires a value.`);
  return value;
}

function normalizeBasePath(value) {
  const normalized = path.posix.normalize(`/${value.replaceAll('\\', '/').replace(/^\/+/, '')}`);
  if (normalized.includes('..')) throw new Error('Base path must not traverse directories.');
  return normalized.endsWith('/') ? normalized : `${normalized}/`;
}
