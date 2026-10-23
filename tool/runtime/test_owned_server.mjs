import assert from 'node:assert/strict';
import { execFileSync } from 'node:child_process';
import { randomInt } from 'node:crypto';
import { mkdir, mkdtemp, readFile, rm, symlink, writeFile } from 'node:fs/promises';
import { createServer } from 'node:http';
import os from 'node:os';
import path from 'node:path';
import process from 'node:process';
import test from 'node:test';
import { fileURLToPath } from 'node:url';

import { closeLocalServer, startLocalServer } from './runtime_support.mjs';
import { collectRuntimeRuns } from './measure_web_runtime.mjs';
import { smokeCleanTemplate } from '../template/smoke_clean_template.mjs';

const artifact = '<!doctype html><title>runtime fixture</title>\n';
const headers = '/*\n  X-Content-Type-Options: nosniff\n';
const fixtureOwner = {
  pid: process.pid,
  argv: process.argv,
  commandAndStart: execFileSync(
    'ps',
    ['-ww', '-p', String(process.pid), '-o', 'lstart=', '-o', 'command='],
    { encoding: 'utf8', timeout: 2000 },
  ).trim(),
  cwd: process.cwd(),
};

function listeners(port) {
  try {
    return execFileSync('lsof', ['-nP', `-iTCP:${port}`, '-sTCP:LISTEN', '-Fp'], {
      encoding: 'utf8',
      timeout: 2000,
      stdio: ['ignore', 'pipe', 'pipe'],
    });
  } catch (error) {
    if (error.status === 1 && !error.stdout && !error.stderr) return '';
    throw error;
  }
}

function emptyPort() {
  const port = randomInt(45000, 60000);
  assert.equal(listeners(port), '', 'chosen fixture port must already be empty');
  return port;
}

async function fixture(context, mode = 'real') {
  const cwd = await mkdtemp(path.join(os.tmpdir(), 'runtime-owned-'));
  const port = emptyPort();
  const webRoot = path.join(cwd, 'build/web');
  await mkdir(webRoot, { recursive: true });
  await mkdir(path.join(cwd, 'tool/runtime'), { recursive: true });
  await writeFile(path.join(webRoot, 'index.html'), artifact);
  await writeFile(path.join(webRoot, '_headers'), headers);
  await writeFile(path.join(webRoot, 'version.json'), '{"commit":"fixture"}\n');
  const script = path.join(cwd, 'tool/runtime/serve_web.mjs');
  if (mode === 'real')
    await symlink(fileURLToPath(new URL('./serve_web.mjs', import.meta.url)), script);
  else await writeFile(script, fixtureScript(mode));
  const state = {
    cwd,
    webRoot,
    port,
    url: `http://127.0.0.1:${port}`,
    child: null,
    identity: null,
    options: null,
  };
  state.options = {
    cwd,
    webRoot,
    timeoutMs: 1800,
    requestTimeoutMs: 300,
    shutdownTimeoutMs: 200,
    onSpawn(child, identity) {
      state.child = child;
      state.identity = identity;
      if (identity.commandAndStart) {
        assert.ok(
          identity.commandAndStart.includes(`${child.spawnfile} tool/runtime/serve_web.mjs`),
        );
      }
    },
  };
  context.after(async () => {
    await closeLocalServer(state.child);
    assert.equal(listeners(port), '', 'fixture cleanup must leave the port free');
    await rm(cwd, { recursive: true });
  });
  return state;
}

function fixtureScript(mode) {
  return `import { createServer } from 'node:http';
import { appendFileSync, readFileSync } from 'node:fs';
const mode = ${JSON.stringify(mode)};
if (mode === 'exit') process.exit(7);
const body = readFileSync(process.env.WEB_ROOT + '/index.html');
const server = createServer((_request, response) => {
  appendFileSync('requests', 'GET\\n');
  if (mode === 'headers') return;
  if (mode === 'body-exit') {
    response.writeHead(200); response.write('partial');
    setTimeout(() => process.exit(9), 100); return;
  }
  if (mode === 'body') { response.writeHead(200); response.write('partial'); return; }
  if (mode === 'redirect') {
    response.writeHead(302, { Location: readFileSync('redirect', 'utf8') }); response.end(); return;
  }
  if (mode === 'wrong-root') { response.end('unrelated 200'); return; }
  if (mode === 'slow') { setTimeout(() => response.end(body), 180); return; }
  response.end(body);
});
server.listen(Number(process.env.PORT), '127.0.0.1', () => {
  if (mode !== 'no-marker') console.log('Flutter web test server listening on http://127.0.0.1:' + process.env.PORT);
});
process.on('SIGTERM', () => {
  appendFileSync('signals', 'SIGTERM\\n');
  if (mode === 'ignore-term') return;
  server.closeAllConnections(); server.close(() => process.exit(0));
});
setTimeout(() => { server.closeAllConnections(); server.close(() => process.exit(8)); }, 6000).unref();
`;
}

function assertStopped(context, state) {
  assert.ok(state.child, 'actual child must have been spawned');
  assert.ok(
    state.child.exitCode !== null || state.child.signalCode !== null,
    'API must await child exit before settling',
  );
  assert.equal(listeners(state.port), '', 'API must release its port before settling');
  context.diagnostic(
    JSON.stringify({
      port: state.port,
      identity: state.identity,
      execPath: state.child.spawnfile,
      argv: state.child.spawnargs,
      exitCode: state.child.exitCode,
      signalCode: state.child.signalCode,
      listenerAfter: 'empty',
    }),
  );
}

async function ownListener(context, handler) {
  const port = emptyPort();
  const server = createServer(handler);
  let requests = 0;
  let connections = 0;
  server.on('request', () => {
    requests += 1;
  });
  server.on('connection', () => {
    connections += 1;
  });
  await new Promise((resolve, reject) => {
    server.once('error', reject);
    server.listen(port, '127.0.0.1', () => resolve(undefined));
  });
  context.after(async () => {
    const closed = new Promise((resolve) => server.close(resolve));
    server.closeAllConnections();
    await closed;
    assert.equal(listeners(port), '');
    context.diagnostic(
      JSON.stringify({ externalPort: port, fixtureOwner, listenerAfter: 'empty' }),
    );
  });
  return {
    port,
    server,
    url: `http://127.0.0.1:${port}`,
    counts: () => ({ requests, connections }),
  };
}

test('occupied port refuses an unrelated 200 fixture without a connection, child or signal', async (t) => {
  const f = await fixture(t);
  // Only this newly registered fixture may occupy the previously verified empty port.
  const foreign = createServer((_request, response) => response.end('unrelated 200'));
  let requests = 0;
  let signals = 0;
  let connections = 0;
  const signal = () => {
    signals += 1;
  };
  process.on('SIGTERM', signal);
  foreign.on('request', () => {
    requests += 1;
  });
  foreign.on('connection', () => {
    connections += 1;
  });
  assert.equal(listeners(f.port), '');
  await new Promise((resolve) => foreign.listen(f.port, '127.0.0.1', () => resolve(undefined)));
  try {
    await assert.rejects(startLocalServer(f.url, f.options), /already occupied/);
    assert.equal(f.child, null);
    assert.deepEqual(
      { requests, signals, connections },
      { requests: 0, signals: 0, connections: 0 },
    );
    assert.equal(foreign.listening, true);
    t.diagnostic(
      JSON.stringify({ port: f.port, owner: fixtureOwner, requests, signals, connections }),
    );
  } finally {
    process.removeListener('SIGTERM', signal);
    await new Promise((resolve) => foreign.close(resolve));
  }
});

for (const mode of ['exit', 'no-marker', 'headers', 'body', 'body-exit', 'wrong-root']) {
  test(
    `readiness rejects ${mode} and awaits only its child's cleanup`,
    { timeout: 8000 },
    async (t) => {
      const f = await fixture(t, mode);
      if (mode === 'no-marker') f.options.timeoutMs = 250;
      const started = performance.now();
      await assert.rejects(startLocalServer(f.url, f.options));
      assert.ok(performance.now() - started < 5000, 'startup and cleanup are bounded');
      assertStopped(t, f);
      if (mode === 'no-marker')
        await assert.rejects(readFile(path.join(f.cwd, 'requests')), /ENOENT/);
      if (mode === 'headers' || mode === 'body') {
        assert.equal(await readFile(path.join(f.cwd, 'requests'), 'utf8'), 'GET\n');
      }
    },
  );
}

for (const mode of ['headers', 'body']) {
  test(`overall deadline also bounds ${mode} when the request timeout is longer`, async (t) => {
    const f = await fixture(t, mode);
    f.options.timeoutMs = 350;
    f.options.requestTimeoutMs = 4000;
    const started = performance.now();
    await assert.rejects(startLocalServer(f.url, f.options));
    assert.ok(performance.now() - started < 2500);
    assertStopped(t, f);
  });
}

test('readiness never follows a redirect to another controlled listener', async (t) => {
  const destination = await ownListener(t, (_request, response) => response.end('unrelated 200'));
  const f = await fixture(t, 'redirect');
  await writeFile(path.join(f.cwd, 'redirect'), destination.url);
  await assert.rejects(startLocalServer(f.url, f.options), /expected root artifact/);
  assert.deepEqual(destination.counts(), { requests: 0, connections: 0 });
  assertStopped(t, f);
});

test('finite slow response remains valid, including body readback', async (t) => {
  const f = await fixture(t, 'slow');
  f.options.requestTimeoutMs = 900;
  const child = await startLocalServer(f.url, f.options);
  assert.equal(child, f.child);
  await closeLocalServer(child);
  assertStopped(t, f);
});

test('real preview serves the intended root, headers, version, MIME and missing-path status', async (t) => {
  const f = await fixture(t);
  const child = await startLocalServer(f.url, f.options);
  const response = await fetch(f.url, { signal: AbortSignal.timeout(1000) });
  assert.equal(await response.text(), artifact);
  assert.equal(response.headers.get('cache-control'), 'no-store');
  assert.equal(response.headers.get('x-content-type-options'), 'nosniff');
  assert.match(response.headers.get('content-type'), /^text\/html/);
  const version = await fetch(`${f.url}/version.json`, { signal: AbortSignal.timeout(1000) });
  assert.deepEqual(await version.json(), { commit: 'fixture' });
  const missing = await fetch(`${f.url}/missing`, { signal: AbortSignal.timeout(1000) });
  assert.equal(missing.status, 404);
  await missing.text();
  assert.equal(child.exitCode, null);
  await closeLocalServer(child);
  const kill = child.kill;
  child.kill = () => {
    assert.fail('an exited child must never be signalled again');
  };
  await closeLocalServer(child);
  child.kill = kill;
  assertStopped(t, f);
});

test('one-argument API preserves cwd/root and derives the port from its target', async (t) => {
  const f = await fixture(t);
  const prior = { cwd: process.cwd(), PORT: process.env.PORT, WEB_ROOT: process.env.WEB_ROOT };
  const neighbor = emptyPort();
  assert.notEqual(neighbor, f.port);
  process.chdir(f.cwd);
  process.env.WEB_ROOT = f.webRoot;
  process.env.PORT = String(neighbor);
  try {
    f.child = await startLocalServer(f.url);
    f.identity = {
      pid: f.child.pid,
      cwd: process.cwd(),
      commandAndStart: execFileSync(
        'ps',
        ['-ww', '-p', String(f.child.pid), '-o', 'lstart=', '-o', 'command='],
        { encoding: 'utf8', timeout: 2000 },
      ).trim(),
    };
    assert.equal(f.child.spawnfile, process.execPath);
    assert.deepEqual(f.child.spawnargs, [process.execPath, 'tool/runtime/serve_web.mjs']);
    assert.equal(listeners(neighbor), '');
    await closeLocalServer(f.child);
    assertStopped(t, f);
  } finally {
    process.chdir(prior.cwd);
    for (const key of ['PORT', 'WEB_ROOT']) {
      if (prior[key] === undefined) delete process.env[key];
      else process.env[key] = prior[key];
    }
  }
});

test('cleanup escalates only its verified active child and awaits exit', async (t) => {
  const f = await fixture(t, 'ignore-term');
  const child = await startLocalServer(f.url, f.options);
  await closeLocalServer(child);
  assert.equal(await readFile(path.join(f.cwd, 'signals'), 'utf8'), 'SIGTERM\n');
  assert.equal(child.signalCode, 'SIGKILL');
  assertStopped(t, f);
});

test('a child error notification alone is not proof that the owned process exited', async (t) => {
  const f = await fixture(t);
  const child = await startLocalServer(f.url, f.options);
  child.emit('error', new Error('non-exit fixture notification'));
  assert.equal(child.exitCode, null);
  await closeLocalServer(child);
  assertStopped(t, f);
});

for (const phase of ['launch', 'measure', 'close', 'success']) {
  test(`runtime ${phase} boundary awaits owned-server cleanup`, async (t) => {
    const f = await fixture(t);
    const calls = [];
    let closes = 0;
    const operation = collectRuntimeRuns(
      {
        target: f.url,
        budget: {},
        runCount: 2,
        startupTimeoutMs: 1000,
        chromiumArgs: ['--disable-gpu'],
        serverOptions: f.options,
      },
      {
        async launchBrowser(settings) {
          assert.deepEqual(settings, { headless: true, args: ['--disable-gpu'] });
          if (phase === 'launch') throw new Error('launch fixture failure');
          return {
            async close() {
              closes += 1;
              if (phase === 'close') throw new Error('close fixture failure');
            },
          };
        },
        async measure(_browser, run, options) {
          calls.push({ run, options });
          if (phase === 'measure') throw new Error('measure fixture failure');
          return { run };
        },
      },
    );
    if (phase === 'success') {
      const result = await operation;
      assert.equal(result.runs.length, 2);
      assert.equal(result.throttledRuns.length, 2);
      assert.deepEqual(
        calls.map(({ run }) => run),
        [1, 1, 2, 2],
      );
      assert.equal(calls[0].options.profile, undefined);
      assert.deepEqual(calls[1].options.profile, {
        download_mbps: 9,
        upload_mbps: 1.5,
        latency_ms: 60,
        cpu_throttling_rate: 4,
      });
      assert.ok(calls.every(({ options }) => options.target === f.url));
    } else await assert.rejects(operation, new RegExp(`${phase} fixture failure`));
    assert.equal(closes, phase === 'launch' ? 0 : 1);
    assertStopped(t, f);
  });
}

test('explicit external target remains usable and is never launcher-owned or closed', async (t) => {
  const f = await ownListener(t, (_request, response) => response.end('explicit target fixture'));
  const target = `${f.url}/portfolio/`;
  const result = await collectRuntimeRuns(
    {
      target,
      externalTarget: true,
      budget: {},
      runCount: 1,
      startupTimeoutMs: 1000,
      chromiumArgs: [],
    },
    {
      async launchBrowser() {
        return { async close() {} };
      },
      async measure(_browser, run, options) {
        assert.equal(options.target, target);
        const response = await fetch(options.target, { signal: AbortSignal.timeout(1000) });
        assert.equal(await response.text(), 'explicit target fixture');
        return { run };
      },
    },
  );
  assert.equal(result.runs.length, 1);
  assert.equal(result.throttledRuns.length, 1);
  assert.equal(f.server.listening, true);
  assert.equal(f.counts().requests, 2);
  await assert.rejects(closeLocalServer(f.server), /not started by this launcher/);
  assert.equal(f.server.listening, true);
});

for (const phase of ['launch', 'check', 'close', 'success']) {
  test(`smoke ${phase} boundary closes its server without a real browser`, async (t) => {
    const f = await fixture(t);
    const operation = smokeCleanTemplate(
      { root: f.webRoot, basePath: '/portfolio/', port: f.port },
      {
        async launchBrowser() {
          if (phase === 'launch') throw new Error('launch fixture failure');
          return {
            async close() {
              if (phase === 'close') throw new Error('close fixture failure');
            },
          };
        },
        async checkBrowser(_browser, { origin, basePath }) {
          assert.equal(basePath, '/portfolio/');
          assert.equal(origin, f.url);
          const response = await fetch(`${origin}${basePath}`, {
            signal: AbortSignal.timeout(1000),
          });
          assert.equal(await response.text(), artifact);
          assert.equal(response.headers.get('cross-origin-opener-policy'), 'same-origin');
          assert.equal(response.headers.get('cross-origin-embedder-policy'), 'credentialless');
          const outside = await fetch(`${origin}/outside`, { signal: AbortSignal.timeout(1000) });
          assert.equal(outside.status, 404);
          await outside.text();
          if (phase === 'check') throw new Error('check fixture failure');
        },
      },
    );
    if (phase === 'success') await operation;
    else await assert.rejects(operation, new RegExp(`${phase} fixture failure`));
    assert.equal(listeners(f.port), '', 'smoke API must await server close even on browser errors');
    t.diagnostic(
      JSON.stringify({ smoke: phase, port: f.port, owner: fixtureOwner, listenerAfter: 'empty' }),
    );
  });
}
