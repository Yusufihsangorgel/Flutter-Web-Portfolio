import assert from 'node:assert/strict';
import childProcess from 'node:child_process';
import { randomInt } from 'node:crypto';
import { mkdir, mkdtemp, realpath, rm, writeFile } from 'node:fs/promises';
import { syncBuiltinESMExports } from 'node:module';
import os from 'node:os';
import path from 'node:path';
import test from 'node:test';
import { setTimeout as delay } from 'node:timers/promises';

import { closeLocalServer, startLocalServer } from './runtime_support.mjs';

const nativeExec = childProcess.execFileSync;
const nativeSpawn = childProcess.spawn;
const nativeTimeout = globalThis.setTimeout;
/** @type {import('node:child_process').ExecFileSyncOptionsWithStringEncoding} */
const inspectOptions = { encoding: 'utf8', timeout: 2000, stdio: ['ignore', 'pipe', 'pipe'] };

function identity(pid) {
  try {
    const commandAndStart = nativeExec(
      'ps',
      ['-ww', '-p', String(pid), '-o', 'lstart=', '-o', 'command='],
      inspectOptions,
    ).trim();
    const cwd = nativeExec('lsof', ['-a', '-p', String(pid), '-d', 'cwd', '-Fn'], inspectOptions)
      .split('\n')
      .find((line) => line.startsWith('n'))
      ?.slice(1);
    return { pid, commandAndStart, cwd };
  } catch (error) {
    if (error.status === 1) return null;
    throw error;
  }
}

function listeners(port) {
  try {
    return nativeExec('lsof', ['-nP', `-iTCP:${port}`, '-sTCP:LISTEN', '-Fp'], inspectOptions)
      .split('\n')
      .filter((line) => line.startsWith('p'))
      .map((line) => Number(line.slice(1)));
  } catch (error) {
    if (error.status === 1 && !error.stdout && !error.stderr) return [];
    throw error;
  }
}

async function waitFor(check, timeoutMs = 4000) {
  const deadline = performance.now() + timeoutMs;
  while (performance.now() < deadline) {
    if (await check()) return;
    await delay(10);
  }
  throw new Error('Owned cleanup fixture event deadline expired.');
}

async function exitedWithin(h, timeoutMs = 1500) {
  const abort = new AbortController();
  try {
    return await Promise.race([
      h.exit.then(() => true),
      delay(timeoutMs, undefined, { signal: abort.signal }).then(() => false),
    ]);
  } finally {
    abort.abort();
  }
}

async function fixture(context) {
  const port = randomInt(45000, 60000);
  assert.deepEqual(listeners(port), [], 'lsof must prove the new fixture port empty');
  const cwd = await realpath(await mkdtemp(path.join(os.tmpdir(), 'owned-cleanup-')));
  const webRoot = path.join(cwd, 'build/web');
  await mkdir(webRoot, { recursive: true });
  await mkdir(path.join(cwd, 'tool/runtime'), { recursive: true });
  await writeFile(
    path.join(webRoot, 'index.html'),
    '<!doctype html><title>cleanup fixture</title>\n',
  );
  await writeFile(path.join(webRoot, '_headers'), '/*\n  X-Content-Type-Options: nosniff\n');
  const source = `setTimeout(() => process.exit(86), 10000).unref();
let release;
const barrier = new Promise(resolve => { release = resolve; });
process.on('message', message => {
  if (message.type === 'fixture:import') release();
  if (message.type === 'fixture:exit') process.exit(0);
  if (message.type === 'fixture:duplicates') {
    for (let index = 0; index < 3; index += 1) {
      process.send({ type: 'runtime-server:control-ready', pid: process.pid });
    }
    process.send({ type: 'fixture:duplicated' });
  }
});
process.send({ type: 'fixture:booted' });
await barrier;
await import(${JSON.stringify(new URL('./serve_web.mjs', import.meta.url).href)});
process.send({ type: 'fixture:imported' });
`;
  await writeFile(path.join(cwd, 'tool/runtime/serve_web.mjs'), source);
  context.after(async () => {
    assert.deepEqual(listeners(port), [], 'only a released owned fixture may be removed');
    await rm(cwd, { recursive: true });
  });
  return { cwd, webRoot, port, target: `http://127.0.0.1:${port}` };
}

function sendFixture(h, type) {
  if (h.child?.connected) h.send({ type });
}

function shutdown(h, message, callback) {
  h.shutdowns.push(performance.now());
  if (h.scenario.transport === 'throw') throw h.transportError;
  if (h.scenario.transport === 'callback') {
    h.callback = callback;
    callback(h.transportError);
    callback(null);
    return true;
  }
  if (h.scenario.transport === 'child-error') {
    h.child.emit('error', h.transportError);
    callback(null);
    return true;
  }
  if (h.scenario.transport === 'disconnect') {
    h.child.disconnect();
    callback(h.transportError);
    return true;
  }
  if (h.scenario.transport === 'duplicates') {
    h.queued = { message, callback };
    sendFixture(h, 'fixture:duplicates');
    return true;
  }
  if (h.scenario.transport === 'exit') {
    sendFixture(h, 'fixture:exit');
    callback(null);
    return true;
  }
  return h.send(message, callback);
}

function attachChild(h, child) {
  h.child = child;
  h.send = child.send.bind(child);
  h.kill = child.kill.bind(child);
  h.emit = child.emit.bind(child);
  h.exit = new Promise((resolve) => child.once('exit', resolve));
  child.once('spawn', () => {
    h.owner = identity(child.pid);
  });
  child.emit = (event, ...args) => {
    if (event === 'message' && args[0]?.type === 'runtime-server:control-ready') {
      h.readyAt ??= performance.now();
      if (h.scenario.holdReady) {
        h.held.push(args[0]);
        return false;
      }
    }
    return h.emit(event, ...args);
  };
  child.on('message', (message) => {
    if (message.type === 'fixture:booted') {
      h.booted = true;
      if (h.scenario.earlyExit) sendFixture(h, 'fixture:exit');
      else if (!h.scenario.late) sendFixture(h, 'fixture:import');
    }
    if (message.type === 'fixture:imported') h.imported = true;
    if (message.type === 'fixture:duplicated') {
      h.send(h.queued.message, h.queued.callback);
      h.queued = null;
    }
  });
  child.send = (message, callback) =>
    message?.type === 'runtime-server:shutdown'
      ? shutdown(h, message, callback)
      : h.send(message, callback);
  child.kill = (signal) => {
    h.signalRequests.push(signal);
    assert.deepEqual(
      identity(child.pid),
      h.owner,
      'OS signals require fresh owned command/start/cwd',
    );
    h.osSignals.push(signal);
    return h.kill(signal);
  };
}

function patchInspector(h) {
  childProcess.spawn = (...args) => {
    const child = Reflect.apply(nativeSpawn, childProcess, args);
    attachChild(h, child);
    return child;
  };
  childProcess.execFileSync = (command, ...args) => {
    if (
      command === 'ps' &&
      h.child &&
      Array.isArray(args[0]) &&
      args[0].includes(String(h.child.pid))
    ) {
      h.inspections += 1;
      if (h.scenario.authority === 'missing' && h.inspections === 1) {
        h.closing = true;
        h.beforeListeners = h.child.listenerCount('message');
        h.failedAt = performance.now();
        throw h.primary;
      }
      if (h.closing) {
        h.guardInspections += 1;
        if (h.scenario.authority === 'recover' && h.guardInspections === 1) throw h.inspectorError;
        if (h.scenario.authority === 'mismatch') return 'nonmatching owned fixture command';
      }
    }
    return Reflect.apply(nativeExec, childProcess, [command, ...args]);
  };
  syncBuiltinESMExports();
}

function patchTimers(h) {
  globalThis.setTimeout = Object.assign((...args) => {
    if (h.closing && args[1] === h.S) {
      h.phases.push({ at: performance.now(), delay: args[1] });
      if (h.scenario.late && h.phases.length === 1) sendFixture(h, 'fixture:import');
    }
    return Reflect.apply(nativeTimeout, globalThis, args);
  }, nativeTimeout);
}

function harness(f, scenario) {
  const h = {
    f,
    scenario,
    S: scenario.S ?? 200,
    child: null,
    exit: null,
    owner: null,
    send: null,
    kill: null,
    emit: null,
    held: [],
    phases: [],
    shutdowns: [],
    signalRequests: [],
    osSignals: [],
    safetyActions: [],
    inspections: 0,
    guardInspections: 0,
    closing: false,
    beforeListeners: null,
    booted: false,
    imported: false,
    readyAt: null,
    callback: null,
    queued: null,
    primary: Object.assign(new Error('owned inspector fixture failure'), { code: 'ENOENT' }),
    transportError: new Error('owned shutdown transport fixture failure'),
    inspectorError: Object.assign(new Error('owned guard inspector fixture failure'), {
      code: 'ENOENT',
    }),
  };
  patchInspector(h);
  patchTimers(h);
  return h;
}

function restore() {
  childProcess.spawn = nativeSpawn;
  childProcess.execFileSync = nativeExec;
  globalThis.setTimeout = nativeTimeout;
  syncBuiltinESMExports();
}

function errorContains(error, expected) {
  return (
    error === expected || (error?.errors ?? []).some((entry) => errorContains(entry, expected))
  );
}

function snapshot(h, failure) {
  return {
    pid: h.child?.pid,
    exitCode: h.child?.exitCode,
    signalCode: h.child?.signalCode,
    port: h.f.port,
    listeners: listeners(h.f.port),
    shutdowns: h.shutdowns.length,
    osSignals: [...h.osSignals],
    signalRequests: [...h.signalRequests],
    phases: h.phases.map((phase) => phase.delay),
    inspections: h.inspections,
    readyAfterFirstWindow:
      h.readyAt !== null && h.failedAt !== undefined && h.readyAt - h.failedAt > h.S,
    originalError: failure === h.primary,
    primaryCause: failure?.cause === h.primary,
    transportRetained: errorContains(failure, h.transportError),
    messageListeners: h.child?.listenerCount('message'),
    namedListeners: h.child
      ?.listeners('message')
      .filter((listener) => listener.name === 'onControlReady').length,
  };
}

async function cleanup(h) {
  restore();
  if (!h.child || h.child.exitCode !== null || h.child.signalCode !== null) return;
  assert.deepEqual(
    identity(h.child.pid),
    h.owner,
    'manual cleanup must still identify the own child',
  );
  await waitFor(() => h.booted);
  if (h.child.connected) {
    h.safetyActions.push(h.imported ? 'owned-ipc-shutdown' : 'owned-fixture-exit');
    h.send({ type: h.imported ? 'runtime-server:shutdown' : 'fixture:exit' });
    if (await exitedWithin(h)) return;
  }
  for (const signal of ['SIGTERM', 'SIGKILL']) {
    assert.deepEqual(
      identity(h.child.pid),
      h.owner,
      'verify command/start/cwd immediately before signal',
    );
    h.safetyActions.push(signal);
    h.kill(signal);
    if (await exitedWithin(h)) return;
  }
  throw new Error('Verified owned fixture failed to exit.');
}

async function runOperation(h) {
  const options = { cwd: h.f.cwd, webRoot: h.f.webRoot, shutdownTimeoutMs: h.S };
  if (h.scenario.S === 1000) delete options.shutdownTimeoutMs;
  if (h.scenario.authority === 'missing') {
    try {
      await startLocalServer(h.f.target, options);
    } catch (error) {
      return error;
    }
  } else {
    const child = await startLocalServer(h.f.target, options);
    h.closing = true;
    h.beforeListeners = child.listenerCount('message');
    const results = await Promise.allSettled([closeLocalServer(child), closeLocalServer(child)]);
    assert.equal(results[0].status, results[1].status, 'concurrent close shares the same outcome');
    if (results[0].status === 'rejected') return results[0].reason;
  }
  return null;
}

function assertOutcome(h, failure, before) {
  assert.equal(before.namedListeners, 0, 'closing listener must be removed');
  assert.equal(
    before.messageListeners,
    h.beforeListeners,
    'unrelated message listeners must remain',
  );
  assert.ok(
    before.phases.every((value) => value === h.S),
    'phase budgets must stay unchanged',
  );
  if (h.scenario.authority === 'missing')
    assert.equal(h.inspections, 1, 'no initial authority is ever promoted');
  if (h.scenario.success) {
    assert.equal(before.exitCode, 0);
    assert.deepEqual(before.listeners, []);
    assert.equal(before.shutdowns, h.scenario.earlyExit ? 0 : 1);
    assert.deepEqual(before.osSignals, []);
    assert.equal(failure, h.scenario.authority === 'missing' ? h.primary : null);
    if (h.scenario.late) {
      assert.equal(before.readyAfterFirstWindow, true);
      assert.equal(before.phases.length, 1, 'late control must reuse the existing fallback wait');
    }
  } else if (h.scenario.authority === 'recover') {
    assert.equal(failure, null);
    assert.equal(before.signalCode, 'SIGKILL');
    assert.deepEqual(before.osSignals, ['SIGKILL']);
    assert.deepEqual(before.listeners, []);
  } else {
    assert.ok(failure instanceof AggregateError);
    if (h.scenario.authority === 'missing') assert.equal(failure.cause, h.primary);
    assert.equal(before.exitCode, null, 'a callback/error is not proof of exit');
    assert.deepEqual(before.osSignals, []);
    assert.deepEqual(before.listeners, [h.child.pid]);
    if (h.scenario.holdReady) {
      assert.equal(before.shutdowns, 0);
      assert.equal(before.phases.length, 2, 'never-ready cleanup keeps only S+S+S');
    } else {
      assert.equal(before.shutdowns, 1);
      assert.equal(before.phases.length, 3, 'first-window control keeps its extra IPC wait');
      assert.equal(before.transportRetained, true);
    }
  }
}

async function staleActions(h, failure, before) {
  for (const message of h.held) h.emit('message', message);
  h.callback?.(null);
  h.callback?.(new Error('after-deadline fixture callback'));
  const result = await Promise.allSettled([closeLocalServer(h.child)]);
  const succeeded = h.scenario.success || h.scenario.authority === 'recover';
  assert.equal(result[0].status, succeeded ? 'fulfilled' : 'rejected');
  if (!succeeded && result[0].status === 'rejected') {
    assert.equal(result[0].reason, failure.cause === h.primary ? failure.errors[1] : failure);
  }
  assert.equal(h.shutdowns.length, before.shutdowns, 'no post-close shutdown attempt');
  assert.equal(h.phases.length, before.phases.length, 'no post-close phase or timer');
}

async function runCase(context, scenario) {
  const f = await fixture(context);
  const h = harness(f, scenario);
  let before;
  try {
    const failure = await runOperation(h);
    before = snapshot(h, failure);
    assertOutcome(h, failure, before);
    await staleActions(h, failure, before);
  } finally {
    await cleanup(h);
    assert.deepEqual(listeners(f.port), []);
    context.diagnostic(
      JSON.stringify({
        scenario: context.name,
        S: h.S,
        owner: h.owner,
        beforeSafetyCleanup: before,
        safetyActions: h.safetyActions,
        afterSafetyCleanup: {
          exitCode: h.child?.exitCode,
          signalCode: h.child?.signalCode,
          port: f.port,
          listenerAfter: 'empty',
        },
      }),
    );
  }
}

for (const [name, scenario] of /** @type {const} */ ([
  [
    'late control after first default window',
    { S: 1000, authority: 'missing', late: true, success: true },
  ],
  [
    'already-ready duplicate frames and concurrent close',
    { authority: 'known', transport: 'duplicates', success: true },
  ],
  ['early ready with no initial inspection authority', { authority: 'missing', success: true }],
  [
    'actual exit before control readiness',
    { authority: 'missing', earlyExit: true, success: true },
  ],
  [
    'never delivered control then after-deadline readiness',
    { authority: 'missing', holdReady: true },
  ],
  [
    'send failure preserves the existing first-window budget',
    { authority: 'missing', transport: 'throw' },
  ],
  [
    'callback failure cannot be erased by callback success',
    { authority: 'missing', transport: 'callback' },
  ],
  [
    'child error and callback success never stand in for exit',
    { authority: 'missing', transport: 'child-error' },
  ],
  [
    'send disconnect records failure without new authority',
    { authority: 'missing', transport: 'disconnect' },
  ],
  [
    'known identity permits only freshly recovered inspection',
    { authority: 'recover', transport: 'throw' },
  ],
  [
    'known identity rejects mismatched fresh inspection',
    { authority: 'mismatch', transport: 'throw' },
  ],
  [
    'actual exit during an IPC attempt suppresses later signals',
    { authority: 'known', transport: 'exit', success: true },
  ],
])) {
  test(name, { timeout: 10000 }, (context) => runCase(context, scenario));
}
