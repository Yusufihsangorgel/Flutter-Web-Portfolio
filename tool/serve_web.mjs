import { createReadStream, existsSync, readFileSync } from 'node:fs';
import { createServer } from 'node:http';
import { extname, join } from 'node:path';

import {
  canonicalStaticRoot,
  resolveStaticFile,
  StaticPathViolation,
} from './safe_static_path.mjs';
import { parseGlobalStaticHeaders } from './static_header_policy.mjs';

const configuredRoot = process.env.WEB_ROOT ?? 'build/web';
const port = Number(process.env.PORT ?? 4173);
const wasmDelayMs = Number(process.env.WASM_DELAY_MS ?? 0);

if (!Number.isFinite(wasmDelayMs) || wasmDelayMs < 0) {
  throw new Error('WASM_DELAY_MS must be a non-negative number.');
}

const contentTypes = new Map([
  ['.css', 'text/css; charset=utf-8'],
  ['.html', 'text/html; charset=utf-8'],
  ['.ico', 'image/x-icon'],
  ['.jpeg', 'image/jpeg'],
  ['.jpg', 'image/jpeg'],
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

if (!existsSync(join(configuredRoot, 'index.html'))) {
  throw new Error(
    'build/web is missing. Run npm run build:release first.',
  );
}
const root = canonicalStaticRoot(configuredRoot);

const globalHeaders = parseGlobalStaticHeaders(
  readFileSync(join(root, '_headers'), 'utf8'),
);

const server = createServer((request, response) => {
  for (const { name, value } of globalHeaders) response.setHeader(name, value);
  // Preview responses must never be confused with a provider's immutable
  // production cache policy.
  response.setHeader('Cache-Control', 'no-store');

  let decodedPath;
  try {
    const requestUrl = new URL(request.url ?? '/', 'http://127.0.0.1');
    decodedPath = decodeURIComponent(requestUrl.pathname);
  } catch {
    response.writeHead(400, { 'Content-Type': 'text/plain; charset=utf-8' });
    response.end('Bad Request');
    return;
  }
  if (decodedPath.includes('\0')) {
    response.writeHead(400, { 'Content-Type': 'text/plain; charset=utf-8' });
    response.end('Bad Request');
    return;
  }
  let filePath;
  try {
    filePath = resolveStaticFile(root, decodedPath);
  } catch (error) {
    if (!(error instanceof StaticPathViolation)) throw error;
    response.writeHead(403).end('Forbidden');
    return;
  }
  if (!filePath) {
    response.writeHead(404, { 'Content-Type': 'text/plain; charset=utf-8' });
    response.end('Not Found');
    return;
  }

  response.setHeader(
    'Content-Type',
    contentTypes.get(extname(filePath)) ?? 'application/octet-stream',
  );
  const sendFile = () => createReadStream(filePath).pipe(response);
  if (wasmDelayMs > 0 && extname(filePath) === '.wasm') {
    setTimeout(sendFile, wasmDelayMs);
    return;
  }
  sendFile();
});

server.listen(port, '127.0.0.1', () => {
  const delay = wasmDelayMs > 0 ? ` (Wasm delay: ${wasmDelayMs} ms)` : '';
  console.log(`Flutter web test server listening on http://127.0.0.1:${port}${delay}`);
});

for (const signal of ['SIGINT', 'SIGTERM']) {
  process.on(signal, () => server.close(() => process.exit(0)));
}
