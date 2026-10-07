import assert from 'node:assert/strict';
import { spawn } from 'node:child_process';
import { mkdir, mkdtemp, rm, writeFile } from 'node:fs/promises';
import { createServer } from 'node:net';
import os from 'node:os';
import path from 'node:path';

const fixture = await mkdtemp(path.join(os.tmpdir(), 'portfolio-preview-security-'));
try {
  await mkdir(path.join(fixture, '.well-known'), { recursive: true });
  await writeFile(path.join(fixture, 'index.html'), 'safe');
  await writeFile(path.join(fixture, '404.html'), 'missing page');
  await writeFile(path.join(fixture, '_headers'), '/*\n  X-Content-Type-Options: nosniff\n');
  await writeFile(
    path.join(fixture, '.well-known', 'security.txt'),
    'Contact: mailto:security@example.com\n',
  );
  await assertPreviewStaticContract(fixture);
} finally {
  await rm(fixture, { recursive: true, force: true });
}

async function assertPreviewStaticContract(webRoot) {
  const probe = createServer();
  await new Promise((resolve) => probe.listen(0, '127.0.0.1', () => resolve(undefined)));
  const { port } = /** @type {import('node:net').AddressInfo} */ (probe.address());
  await new Promise((resolve) => probe.close(resolve));

  const preview = spawn(process.execPath, ['tool/runtime/serve_web.mjs'], {
    env: { ...process.env, WEB_ROOT: webRoot, PORT: String(port) },
    stdio: ['ignore', 'pipe', 'inherit'],
  });
  try {
    await new Promise((resolve, reject) => {
      preview.once('error', reject);
      preview.once('exit', (code) => reject(new Error(`preview exited with ${code}`)));
      preview.stdout.on('data', (chunk) => {
        if (String(chunk).includes('listening')) resolve(undefined);
      });
    });
    const origin = `http://127.0.0.1:${port}`;

    const home = await fetch(`${origin}/`);
    assert.equal(home.status, 200);
    assert.equal(await home.text(), 'safe');

    const missing = await fetch(`${origin}/missing-route`);
    assert.equal(missing.status, 404);
    assert.match(missing.headers.get('content-type'), /^text\/html/);
    assert.equal(missing.headers.get('x-content-type-options'), 'nosniff');
    assert.equal(await missing.text(), 'missing page');

    const security = await fetch(`${origin}/.well-known/security.txt`);
    assert.equal(security.status, 200);
    assert.match(security.headers.get('content-type'), /^text\/plain; charset=utf-8$/);
    assert.match(await security.text(), /^Contact: /m);
  } finally {
    preview.removeAllListeners('exit');
    preview.kill();
  }
}
