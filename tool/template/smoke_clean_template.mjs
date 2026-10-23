import { chromium } from '@playwright/test';
import { createReadStream } from 'node:fs';
import { createServer } from 'node:http';
import path from 'node:path';
import process from 'node:process';
import { pathToFileURL } from 'node:url';

import {
  canonicalStaticRoot,
  resolveStaticFile,
  StaticPathViolation,
} from '../shared/safe_static_path.mjs';

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

function createSmokeServer(root, basePath) {
  return createServer((request, response) => {
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
}

export async function smokeCleanTemplate(options = {}, dependencies = {}) {
  const root = canonicalStaticRoot(options.root ?? 'build/web');
  const basePath = normalizeBasePath(options.basePath ?? '/');
  const server = createSmokeServer(root, basePath);
  const handles = { launch: null, signal: new AbortController() };
  const removeSignals = smokeSignalHandlers(handles.signal);
  const interrupted = new Promise((_, reject) => {
    handles.signal.signal.addEventListener('abort', () => reject(handles.signal.signal.reason), {
      once: true,
    });
  });
  let failure;
  try {
    await Promise.race([
      runSmokeBrowser(server, { ...options, basePath }, dependencies, handles),
      interrupted,
    ]);
  } catch (error) {
    failure = error;
  }
  try {
    const settled = await Promise.allSettled([
      closeSmokeServer(server),
      handles.launch?.then(
        (browser) => browser.close(),
        (error) => {
          if (error !== failure) throw error;
        },
      ),
    ]);
    const errors = settled.flatMap((result) =>
      result.status === 'rejected' ? [result.reason] : [],
    );
    if (errors.length > 0) {
      const cleanupFailure =
        errors.length === 1
          ? errors[0]
          : new AggregateError(errors, 'Owned smoke handles did not close.');
      failure = failure
        ? new AggregateError([failure, cleanupFailure], 'Smoke operation and cleanup failed.', {
            cause: failure,
          })
        : cleanupFailure;
    }
  } finally {
    removeSignals();
  }
  if (handles.signal.signal.aborted && failure !== handles.signal.signal.reason) {
    failure = new AggregateError(
      [handles.signal.signal.reason, failure].filter(Boolean),
      'Smoke interrupted during cleanup.',
      { cause: handles.signal.signal.reason },
    );
  }
  if (failure) throw failure;
}

function smokeSignalHandlers(abort) {
  const handlers = ['SIGINT', 'SIGTERM'].map((signal) => ({
    signal,
    handler: () => {
      if (abort.signal.aborted) return;
      process.exitCode = signal === 'SIGINT' ? 130 : 143;
      abort.abort(
        Object.assign(new Error(`Template smoke interrupted by ${signal}.`), {
          runtimeSignal: signal,
        }),
      );
    },
  }));
  for (const { signal, handler } of handlers) process.on(signal, handler);
  return () => {
    for (const { signal, handler } of handlers) process.removeListener(signal, handler);
  };
}

async function runSmokeBrowser(server, options, dependencies, handles) {
  const { launchBrowser = (settings) => chromium.launch(settings), checkBrowser = smokePages } =
    dependencies;
  await new Promise((resolve, reject) => {
    server.once('error', reject);
    server.listen(options.port ?? 0, '127.0.0.1', () => resolve(undefined));
  });
  handles.signal.signal.throwIfAborted();
  const address = server.address();
  if (!address || typeof address === 'string') throw new Error('Smoke server did not bind.');
  const origin = `http://127.0.0.1:${address.port}`;
  handles.launch = launchBrowser({ headless: true });
  const browser = await handles.launch;
  handles.signal.signal.throwIfAborted();
  await checkBrowser(browser, { origin, basePath: options.basePath });
}

async function closeSmokeServer(server) {
  await new Promise((resolve, reject) => {
    server.close((error) => {
      if (error && !('code' in error && error.code === 'ERR_SERVER_NOT_RUNNING')) reject(error);
      else resolve(undefined);
    });
    server.closeAllConnections();
  });
}

async function smokePages(browser, { origin, basePath }) {
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
    if (documentState.overflow > 1)
      failures.push(`horizontal overflow: ${documentState.overflow}px`);
    await page.close();
    if (failures.length > 0) {
      throw new Error(`${viewport.name} clean-template smoke failed:\n- ${failures.join('\n- ')}`);
    }
  }
}

if (process.argv[1] && import.meta.url === pathToFileURL(process.argv[1]).href) {
  try {
    await smokeCleanTemplate({ basePath: readOption('--base-path') ?? '/' });
    process.stdout.write('Clean-template desktop and mobile browser smoke passed.\n');
  } catch (error) {
    if (!error.runtimeSignal && !error.cause?.runtimeSignal) throw error;
    console.error(error.message);
  }
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
