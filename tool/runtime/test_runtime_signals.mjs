import assert from 'node:assert/strict';
import childProcess from 'node:child_process';
import { randomInt } from 'node:crypto';
import { mkdir, mkdtemp, readFile, realpath, rm, writeFile } from 'node:fs/promises';
import { createServer } from 'node:http';
import { syncBuiltinESMExports } from 'node:module';
import os from 'node:os';
import path from 'node:path';
import process from 'node:process';
import test from 'node:test';
import { setTimeout as delay } from 'node:timers/promises';
import { fileURLToPath } from 'node:url';

import { startLocalServer } from './runtime_support.mjs';
import { collectRuntimeRuns } from './measure_web_runtime.mjs';
import { smokeCleanTemplate } from '../template/smoke_clean_template.mjs';

const nativeExec = childProcess.execFileSync;
const nativeSpawn = childProcess.spawn;
/** @type {import('node:child_process').ExecFileSyncOptionsWithStringEncoding} */
const inspectOptions = { encoding: 'utf8', timeout: 2000, stdio: ['ignore', 'pipe', 'pipe'] };
const artifact = '<!doctype html><title>signal fixture</title>\n';

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
    const result = await check();
    if (result) return result;
    await delay(15);
  }
  throw new Error('Owned fixture event deadline expired.');
}

function signalOwned(child, expected, signal) {
  assert.equal(child.exitCode, null);
  assert.equal(child.signalCode, null);
  assert.deepEqual(
    identity(child.pid),
    expected,
    'fresh command/start/cwd must identify the owned child',
  );
  child.kill(signal);
}

async function stopCaptured(child, exited, expected) {
  if (!child || child.exitCode !== null || child.signalCode !== null) return;
  assert.ok(expected, 'a recorded owned process identity is required before cleanup signals');
  for (const signal of ['SIGTERM', 'SIGKILL']) {
    signalOwned(child, expected, signal);
    if (await Promise.race([exited.then(() => true), delay(1200).then(() => false)])) return;
  }
  throw new Error('Verified owned fixture child did not exit.');
}

async function fixture(context, mode = 'real') {
  const port = randomInt(45000, 60000);
  assert.deepEqual(listeners(port), [], 'lsof must prove the chosen port empty before bind');
  const cwd = await realpath(await mkdtemp(path.join(os.tmpdir(), 'runtime-signal-')));
  const webRoot = path.join(cwd, 'build/web');
  await mkdir(webRoot, { recursive: true });
  await mkdir(path.join(cwd, 'tool/runtime'), { recursive: true });
  await writeFile(path.join(webRoot, 'index.html'), artifact);
  await writeFile(path.join(webRoot, '_headers'), '/*\n  X-Content-Type-Options: nosniff\n');
  const script = `import { writeFileSync } from 'node:fs';
process.on('exit', code => writeFileSync('server-exit', JSON.stringify({ pid: process.pid, code })));
setTimeout(() => process.exit(82), 6000).unref();
${mode === 'delayed' ? 'await new Promise(resolve => setTimeout(resolve, 140));' : ''}
${
  mode === 'no-control'
    ? `import { createServer } from 'node:http';
const server = createServer((_request, response) => response.end(${JSON.stringify(artifact)}));
server.listen(Number(process.env.PORT), '127.0.0.1');
setTimeout(() => server.close(() => process.exit(0)), 1600);`
    : `await import(${JSON.stringify(new URL('./serve_web.mjs', import.meta.url).href)});`
}
`;
  await writeFile(path.join(cwd, 'tool/runtime/serve_web.mjs'), script);
  context.after(async () => {
    assert.deepEqual(listeners(port), [], 'fixture must release its port before removal');
    await rm(cwd, { recursive: true });
  });
  return { cwd, webRoot, port, target: `http://127.0.0.1:${port}` };
}

function inspectionFault(phase) {
  const state = {
    fault: Object.assign(new Error('controlled inspector unavailable'), { code: 'ENOENT' }),
    child: null,
    exited: null,
    expected: null,
    failure: null,
    signals: [],
  };
  childProcess.spawn = (...args) => {
    state.child = Reflect.apply(nativeSpawn, childProcess, args);
    state.exited = new Promise((resolve) => state.child.once('exit', resolve));
    state.child.once('spawn', () => {
      state.expected = identity(state.child.pid);
    });
    const kill = state.child.kill.bind(state.child);
    state.child.kill = (signal) => {
      state.signals.push(signal);
      return kill(signal);
    };
    return state.child;
  };
  childProcess.execFileSync = (command, ...args) => {
    if (
      command === 'ps' &&
      (phase === 'preflight' ||
        (Array.isArray(args[0]) && args[0].includes(String(state.child?.pid))))
    ) {
      throw state.fault;
    }
    return Reflect.apply(nativeExec, childProcess, [command, ...args]);
  };
  syncBuiltinESMExports();
  return state;
}

async function assertInspectionResult(f, state, phase, mode) {
  if (phase === 'preflight') {
    assert.equal(state.child, null, 'inspection dependency must be checked before spawn');
    assert.equal(state.failure, state.fault);
  } else {
    assert.ok(state.child);
    if (mode === 'no-control') {
      assert.equal(state.failure.cause, state.fault);
      assert.ok(state.failure instanceof AggregateError);
      assert.ok(state.failure.errors.some((error) => /did not exit/.test(error.message)));
      await waitFor(() => state.child.exitCode !== null);
    } else
      assert.equal(state.failure, state.fault, 'owned IPC cleanup must retain the primary error');
    assert.ok(
      state.child.exitCode !== null || state.child.signalCode !== null,
      'failed start must await owned exit',
    );
    assert.deepEqual(state.signals, [], 'an unavailable inspector must never cause a PID signal');
  }
  assert.deepEqual(listeners(f.port), []);
}

async function inspectionCase(context, phase, mode = 'real') {
  const f = await fixture(context, mode);
  const state = inspectionFault(phase);
  try {
    try {
      await startLocalServer(f.target, {
        cwd: f.cwd,
        webRoot: f.webRoot,
        timeoutMs: 1500,
        shutdownTimeoutMs: mode === 'no-control' ? 100 : 500,
      });
    } catch (error) {
      state.failure = error;
    }
  } finally {
    childProcess.spawn = nativeSpawn;
    childProcess.execFileSync = nativeExec;
    syncBuiltinESMExports();
  }
  try {
    await assertInspectionResult(f, state, phase, mode);
  } finally {
    await stopCaptured(state.child, state.exited, state.expected);
    assert.deepEqual(listeners(f.port), []);
    context.diagnostic(
      JSON.stringify({
        inspectionCleanup: phase,
        mode,
        port: f.port,
        identity: state.expected,
        exitCode: state.child?.exitCode,
        signalCode: state.child?.signalCode,
        primaryMessage: state.failure?.message,
        signals: state.signals,
        listenerAfter: 'empty',
      }),
    );
  }
}

function ownerDependencies(state) {
  return {
    async launchBrowser() {
      return {
        async close() {
          state.closes += 1;
          process.send({ type: 'browser-close-started' });
          if (state.behavior === 'repeat')
            await new Promise((resolve) => {
              state.close = resolve;
            });
          if (state.behavior === 'close-error')
            throw new Error('owned browser close fixture failure');
        },
      };
    },
    async measure() {
      state.measures += 1;
      if (state.measures > 1) return { run: 1 };
      if (state.mode === 'external') {
        const response = await fetch(state.target, { signal: AbortSignal.timeout(1000) });
        assert.equal(await response.text(), artifact);
      }
      process.send({ type: 'pending' });
      await new Promise((resolve, reject) => {
        state.resume = { resolve, reject };
      });
      return { run: 1 };
    },
  };
}

function runtimeOwnerOptions(cwd, target, mode) {
  return {
    target,
    externalTarget: mode === 'external',
    budget: {},
    runCount: 1,
    startupTimeoutMs: 1000,
    chromiumArgs: [],
    serverOptions: {
      cwd,
      webRoot: path.join(cwd, 'build/web'),
      timeoutMs: 2500,
      onSpawn(child, record) {
        process.send({ type: 'owned-server', record });
        child.once('exit', (code, signal) => process.send({ type: 'server-exit', code, signal }));
      },
    },
  };
}

async function runOwner() {
  const [mode, behavior, cwd, target] = process.argv.slice(3);
  const state = { mode, behavior, target, measures: 0, closes: 0, close: null, resume: null };
  const before = ['SIGINT', 'SIGTERM'].map((signal) => process.listenerCount(signal));
  const release = (message) => {
    if (message.type === 'release-close') state.close?.();
    if (message.type === 'resume') state.resume?.resolve();
    if (message.type === 'reject')
      state.resume?.reject(new Error('owned measurement fixture failure'));
  };
  process.on('message', release);
  const dependencies = ownerDependencies(state);
  let failure;
  try {
    if (mode === 'smoke') {
      await smokeCleanTemplate(
        { root: path.join(cwd, 'build/web'), port: Number(new URL(target).port) },
        { launchBrowser: dependencies.launchBrowser, checkBrowser: dependencies.measure },
      );
    } else {
      await collectRuntimeRuns(runtimeOwnerOptions(cwd, target, mode), dependencies);
    }
  } catch (error) {
    failure = {
      message: error.message,
      signal: error.runtimeSignal ?? error.cause?.runtimeSignal,
      errors: error.errors?.flatMap((entry) => [
        entry.message,
        ...(entry.errors ?? []).map((nested) => nested.message),
      ]),
    };
    if (!failure.signal) process.exitCode = 1;
  } finally {
    process.removeListener('message', release);
    process.send(
      {
        type: 'settled',
        before,
        after: ['SIGINT', 'SIGTERM'].map((signal) => process.listenerCount(signal)),
        closes: state.closes,
        measures: state.measures,
        failure,
      },
      () => process.disconnect(),
    );
  }
}

async function startOwner(f, mode, behavior) {
  const child = nativeSpawn(
    process.execPath,
    [fileURLToPath(import.meta.url), '--runtime-owner', mode, behavior, f.cwd, f.target],
    { cwd: f.cwd, stdio: ['ignore', 'ignore', 'pipe', 'ipc'] },
  );
  const messages = [];
  let stderr = '';
  child.stderr.on('data', (bytes) => {
    stderr += bytes;
  });
  child.on('message', (message) => {
    messages.push(message);
  });
  const exited = new Promise((resolve) =>
    child.once('exit', (code, signal) => resolve({ code, signal })),
  );
  await new Promise((resolve, reject) => {
    child.once('spawn', resolve);
    child.once('error', reject);
  });
  const expected = identity(child.pid);
  assert.equal(expected.cwd, f.cwd);
  assert.ok(expected.commandAndStart.endsWith(child.spawnargs.join(' ')));
  return { child, expected, messages, exited, stderr: () => stderr };
}

async function finishServerRecord(f, record) {
  if (!record || !listeners(f.port).includes(record.pid)) return;
  const expected = { ...record, cwd: f.cwd };
  const active = identity(record.pid);
  assert.deepEqual(active, expected);
  assert.deepEqual(identity(record.pid), expected, 'verify owned orphan immediately before signal');
  process.kill(record.pid, 'SIGTERM');
  await waitFor(async () => {
    try {
      return JSON.parse(await readFile(path.join(f.cwd, 'server-exit'), 'utf8')).pid === record.pid;
    } catch (error) {
      if (error.code === 'ENOENT') return false;
      throw error;
    }
  });
  await waitFor(() => {
    const current = identity(record.pid);
    return !current || current.commandAndStart !== record.commandAndStart;
  });
  assert.deepEqual(listeners(f.port), []);
}

async function exerciseOwner(owner, signal, behavior) {
  await waitFor(() => owner.messages.find((message) => message.type === 'pending'));
  if (signal) {
    signalOwned(owner.child, owner.expected, signal);
    if (behavior === 'repeat') {
      await waitFor(() =>
        owner.messages.find((message) => message.type === 'browser-close-started'),
      );
      signalOwned(owner.child, owner.expected, signal);
      owner.child.send({ type: 'release-close' });
    }
  } else owner.child.send({ type: behavior === 'measure-error' ? 'reject' : 'resume' });
  const deadline = new AbortController();
  try {
    return await Promise.race([
      owner.exited,
      delay(5000, undefined, { signal: deadline.signal }).then(() => {
        throw new Error('Owned measurement process did not exit before its deadline.');
      }),
    ]);
  } finally {
    deadline.abort();
  }
}

function assertOwnerResult(owner, mode, signal, behavior) {
  const settled = owner.messages.find((message) => message.type === 'settled');
  assert.ok(settled, `collector must settle after awaited cleanup; stderr=${owner.stderr()}`);
  assert.equal(settled.closes, 1);
  if (behavior === 'complete') assert.equal(settled.measures, 2);
  if (mode === 'runtime')
    assert.ok(owner.messages.some((message) => message.type === 'server-exit'));
  assert.deepEqual(settled.after, settled.before, 'owned signal handlers must be removed');
  if (signal) assert.equal(settled.failure.signal, signal);
  if (behavior === 'close-error') {
    assert.ok(
      settled.failure.errors.some((message) => /owned browser close fixture failure/.test(message)),
    );
  }
  return settled;
}

async function ownerCase(context, mode, signal, behavior = 'pending') {
  const f = await fixture(context);
  let external;
  if (mode === 'external') {
    assert.deepEqual(listeners(f.port), []);
    external = createServer((_request, response) => response.end(artifact));
    await new Promise((resolve) => external.listen(f.port, '127.0.0.1', () => resolve(undefined)));
  }
  const owner = await startOwner(f, mode, behavior);
  try {
    const exit = await exerciseOwner(owner, signal, behavior);
    const settled = assertOwnerResult(owner, mode, signal, behavior);
    if (mode === 'external') assert.equal(external.listening, true);
    else assert.deepEqual(listeners(f.port), [], 'owner signal must leave its port free');
    context.diagnostic(
      JSON.stringify({
        mode,
        signal,
        behavior,
        port: f.port,
        owner: owner.expected,
        exit,
        settled,
        ownedServer: owner.messages.find((message) => message.type === 'owned-server')?.record,
        listenerAfter: mode === 'external' ? 'caller-owned' : 'empty',
      }),
    );
  } finally {
    await stopCaptured(owner.child, owner.exited, owner.expected);
    await finishServerRecord(
      f,
      owner.messages.find((message) => message.type === 'owned-server')?.record,
    );
    if (external)
      await new Promise((resolve) => {
        external.close(resolve);
        external.closeAllConnections();
      });
    assert.deepEqual(listeners(f.port), []);
    context.diagnostic(
      JSON.stringify({
        ownerCleanup: mode,
        behavior,
        port: f.port,
        owner: owner.expected,
        parentExit: { code: owner.child.exitCode, signal: owner.child.signalCode },
        ownedServer: owner.messages.find((message) => message.type === 'owned-server')?.record,
        listenerAfter: 'empty',
      }),
    );
  }
}

if (process.argv[2] === '--runtime-owner') {
  await runOwner();
} else {
  test('F1 inspector preflight fails before spawning', (t) => inspectionCase(t, 'preflight'));
  test('F1 post-spawn inspector failure awaits delayed owned IPC registration and exit', (t) =>
    inspectionCase(t, 'post-spawn', 'delayed'));
  test('F1 unavailable control preserves primary and cleanup errors without an unverified signal', (t) =>
    inspectionCase(t, 'post-spawn', 'no-control'));
  for (const signal of ['SIGINT', 'SIGTERM']) {
    test(`runtime owner ${signal} pending measurement cleans only owned handles`, (t) =>
      ownerCase(t, 'runtime', signal));
  }
  test('runtime repeated owner signal closes once and removes handlers', (t) =>
    ownerCase(t, 'runtime', 'SIGTERM', 'repeat'));
  test('runtime signal retains a browser-close failure and still awaits owned server exit', (t) =>
    ownerCase(t, 'runtime', 'SIGTERM', 'close-error'));
  test('explicit external target survives owner SIGTERM and remains caller-owned', (t) =>
    ownerCase(t, 'external', 'SIGTERM'));
  test('smoke owner SIGTERM closes its browser and server while checks are pending', (t) =>
    ownerCase(t, 'smoke', 'SIGTERM'));
  test('normal runtime completion removes signal handlers and awaits cleanup', (t) =>
    ownerCase(t, 'runtime', null, 'complete'));
  test('runtime measurement error removes signal handlers and awaits cleanup', (t) =>
    ownerCase(t, 'runtime', null, 'measure-error'));
}
