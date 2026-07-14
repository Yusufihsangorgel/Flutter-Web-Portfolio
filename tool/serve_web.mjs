import { createReadStream, existsSync, statSync } from 'node:fs';
import { createServer } from 'node:http';
import { extname, join, normalize, resolve } from 'node:path';

const root = resolve(process.env.WEB_ROOT ?? 'build/web');
const port = Number(process.env.PORT ?? 4173);
const wasmDelayMs = Number(process.env.WASM_DELAY_MS ?? 0);

if (!Number.isFinite(wasmDelayMs) || wasmDelayMs < 0) {
  throw new Error('WASM_DELAY_MS must be a non-negative number.');
}

const contentTypes = new Map([
  ['.css', 'text/css; charset=utf-8'],
  ['.html', 'text/html; charset=utf-8'],
  ['.ico', 'image/x-icon'],
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

if (!existsSync(join(root, 'index.html'))) {
  throw new Error(
    'build/web is missing. Run flutter build web --release --wasm --no-web-resources-cdn first.',
  );
}

const server = createServer((request, response) => {
  const requestUrl = new URL(request.url ?? '/', `http://${request.headers.host}`);
  const decodedPath = decodeURIComponent(requestUrl.pathname);
  const relativePath = normalize(decodedPath).replace(/^[/\\]+/, '');
  let filePath = resolve(root, relativePath);

  if (!filePath.startsWith(`${root}/`) && filePath !== root) {
    response.writeHead(403).end('Forbidden');
    return;
  }

  response.setHeader('Cache-Control', 'no-store');
  response.setHeader('Cross-Origin-Embedder-Policy', 'credentialless');
  response.setHeader('Cross-Origin-Opener-Policy', 'same-origin');
  response.setHeader(
    'Content-Security-Policy',
    "default-src 'self'; script-src 'self' 'unsafe-inline' 'unsafe-eval' https://analytics.developeryusuf.com; worker-src 'self' blob:; style-src 'self' 'unsafe-inline'; font-src 'self'; img-src 'self' data: https: blob:; connect-src 'self' https://api.rss2json.com https://api.github.com https://analytics.developeryusuf.com; frame-ancestors 'self';",
  );

  if (existsSync(filePath) && statSync(filePath).isDirectory()) {
    filePath = join(filePath, 'index.html');
  }
  if (!existsSync(filePath) || !statSync(filePath).isFile()) {
    if (extname(relativePath)) {
      response.writeHead(404, { 'Content-Type': 'text/plain; charset=utf-8' });
      response.end('Not Found');
      return;
    }
    filePath = join(root, 'index.html');
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
