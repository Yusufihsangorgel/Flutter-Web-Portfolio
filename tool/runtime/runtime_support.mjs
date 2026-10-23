import { execFileSync, spawn } from 'node:child_process';
import { createHash } from 'node:crypto';
import { readFileSync, realpathSync } from 'node:fs';
import { resolve } from 'node:path';
import process from 'node:process';
import { setTimeout as delay } from 'node:timers/promises';

import { stopOwnedServer } from './owned_server_cleanup.mjs';

const ownedServers = new WeakMap();
/** @type {import('node:child_process').ExecFileSyncOptionsWithStringEncoding} */
const inspectionOptions = { encoding: 'utf8', timeout: 2000, stdio: ['ignore', 'pipe', 'pipe'] };

export function validateJsonSchema(value, schema, path) {
  validateScalarRules(value, schema, path);
  if (schema.type === 'object') validateObject(value, schema, path);
  if (schema.type === 'array') validateArray(value, schema, path);
  if (schema.type === 'number' || schema.type === 'integer') {
    validateNumber(value, schema, path);
  }
}

function validateScalarRules(value, schema, path) {
  if ('const' in schema && !deepEqual(value, schema.const)) {
    throw new Error(`${path} must equal ${JSON.stringify(schema.const)}.`);
  }
  if (schema.enum && !schema.enum.some((candidate) => deepEqual(value, candidate))) {
    throw new Error(`${path} must be one of ${JSON.stringify(schema.enum)}.`);
  }
  if (schema.type && !matchesJsonType(value, schema.type)) {
    throw new Error(`${path} must be of type ${schema.type}.`);
  }
}

function validateObject(value, schema, path) {
  const properties = schema.properties ?? {};
  for (const required of schema.required ?? []) {
    if (!Object.hasOwn(value, required)) {
      throw new Error(`${path}.${required} is required.`);
    }
  }
  if (schema.additionalProperties === false) {
    for (const property of Object.keys(value)) {
      if (!Object.hasOwn(properties, property)) {
        throw new Error(`${path}.${property} is not allowed.`);
      }
    }
  }
  for (const [property, propertySchema] of Object.entries(properties)) {
    if (Object.hasOwn(value, property)) {
      validateJsonSchema(value[property], propertySchema, `${path}.${property}`);
    }
  }
}

function validateArray(value, schema, path) {
  if (schema.minItems !== undefined && value.length < schema.minItems) {
    throw new Error(`${path} must contain at least ${schema.minItems} item(s).`);
  }
  if (schema.uniqueItems) {
    const uniqueItems = new Set(value.map((item) => JSON.stringify(item)));
    if (uniqueItems.size !== value.length) {
      throw new Error(`${path} must not contain duplicate items.`);
    }
  }
  if (schema.items) {
    value.forEach((item, index) => validateJsonSchema(item, schema.items, `${path}[${index}]`));
  }
}

function validateNumber(value, schema, path) {
  if (schema.minimum !== undefined && value < schema.minimum) {
    throw new Error(`${path} must be at least ${schema.minimum}.`);
  }
  if (schema.maximum !== undefined && value > schema.maximum) {
    throw new Error(`${path} must be at most ${schema.maximum}.`);
  }
}

function matchesJsonType(value, type) {
  return switchJsonType(type, {
    array: () => Array.isArray(value),
    boolean: () => typeof value === 'boolean',
    integer: () => Number.isInteger(value),
    number: () => typeof value === 'number' && Number.isFinite(value),
    object: () => value !== null && typeof value === 'object' && !Array.isArray(value),
    string: () => typeof value === 'string',
  });
}

function switchJsonType(type, handlers) {
  const handler = handlers[type];
  if (!handler) throw new Error(`Unsupported JSON Schema type: ${type}.`);
  return handler();
}

function deepEqual(left, right) {
  return JSON.stringify(left) === JSON.stringify(right);
}

export function validateBudgetContract(value) {
  for (const metric of value.hardware_only_metrics) {
    if (!Object.hasOwn(value.maximum_median, metric)) {
      throw new Error(`Hardware-only metric ${metric} has no maximum_median threshold.`);
    }
  }
}

export function getEnforcementSkips(value, backend, measuredMedian) {
  // Skip hardware-specific metrics only when software rendering is confirmed.
  if (backend.software_rendering !== true) return [];
  return value.hardware_only_metrics.map((metric) => ({
    metric,
    measured_value: measuredMedian[metric],
    maximum_median: value.maximum_median[metric],
    reason: 'software_graphics_backend',
  }));
}

export function getBudgetFailures(thresholds, measured, skippedMetrics = new Set()) {
  return Object.entries(thresholds)
    .filter(([metric]) => !skippedMetrics.has(metric))
    .filter(([metric, maximum]) => measured[metric] > maximum)
    .map(([metric, maximum]) => `${metric}: ${measured[metric]} exceeds ${maximum}`);
}

export function parseChromiumArgs(value) {
  if (!value) return [];

  let parsed;
  try {
    parsed = JSON.parse(value);
  } catch (error) {
    throw new Error('PERF_CHROMIUM_ARGS must be a JSON array of Chromium arguments.', {
      cause: error,
    });
  }
  if (!Array.isArray(parsed) || parsed.some((argument) => typeof argument !== 'string')) {
    throw new Error('PERF_CHROMIUM_ARGS must be a JSON array containing only strings.');
  }
  return parsed;
}

export async function readGraphicsBackend(browserInstance) {
  let session;
  try {
    session = await browserInstance.newBrowserCDPSession();
    const { gpu } = await session.send('SystemInfo.getInfo');
    return describeGraphicsBackend(gpu);
  } catch (error) {
    return {
      renderer: 'unavailable',
      vendor: 'unavailable',
      display_type: 'unavailable',
      implementation: 'unavailable',
      software_rendering: null,
      diagnostic_error: error instanceof Error ? error.message : String(error),
    };
  } finally {
    try {
      await session?.detach();
    } catch {
      // Close may detach the diagnostics session first.
    }
  }
}

export async function startLocalServer(url, options = {}) {
  const target = new URL(url);
  if (target.protocol !== 'http:' || target.hostname !== '127.0.0.1') {
    throw new Error('Local performance server requires an HTTP loopback target.');
  }
  const port = Number(target.port || 80);
  const cwd = realpathSync(options.cwd ?? process.cwd());
  const timeoutMs = serverTimeout(options.timeoutMs, 15000);
  const requestTimeoutMs = serverTimeout(options.requestTimeoutMs, timeoutMs);
  const shutdownTimeoutMs = serverTimeout(options.shutdownTimeoutMs, 1000);
  const root = realpathSync(resolve(cwd, options.webRoot ?? process.env.WEB_ROOT ?? 'build/web'));
  const expectedHash = hashBytes(readFileSync(resolve(root, 'index.html')));
  options.signal?.throwIfAborted();
  if (!processIdentity(process.pid))
    throw new Error('Cannot verify the process inspector before spawn.');
  if (listenerPids(port).length > 0) {
    throw new Error(`Local performance server port ${port} is already occupied.`);
  }
  const child = spawn(process.execPath, ['tool/runtime/serve_web.mjs'], {
    cwd,
    env: { ...process.env, PORT: String(port), WEB_ROOT: root },
    stdio: ['ignore', 'pipe', 'pipe', 'ipc'],
  });
  const state = trackServer(child, { cwd, port, shutdownTimeoutMs });
  try {
    await new Promise((resolve, reject) => {
      child.once('spawn', resolve);
      child.once('error', reject);
    });
    state.identity = processIdentity(child.pid, { cwd, command: child.spawnargs.join(' ') });
    options.onSpawn?.(child, {
      pid: child.pid,
      commandAndStart: state.identity?.commandAndStart,
      cwd,
    });
    await waitForLocalServer(child, state, {
      url,
      timeoutMs,
      requestTimeoutMs,
      expectedHash,
      signal: options.signal,
    });
    return child;
  } catch (error) {
    try {
      await closeLocalServer(child);
    } catch (cleanupError) {
      throw new AggregateError([error, cleanupError], 'Local server startup and cleanup failed.', {
        cause: error,
      });
    }
    throw error;
  }
}

function serverTimeout(value, fallback) {
  const timeout = value ?? fallback;
  if (!Number.isInteger(timeout) || timeout < 1 || timeout > 2147483647) {
    throw new Error('Server deadlines must be positive finite timer durations.');
  }
  return timeout;
}

function listenerPids(port) {
  try {
    return execFileSync('lsof', ['-nP', `-iTCP:${port}`, '-sTCP:LISTEN', '-Fp'], inspectionOptions)
      .split('\n')
      .filter((line) => line.startsWith('p'))
      .map((line) => Number(line.slice(1)));
  } catch (error) {
    if (error.status === 1 && !error.stdout && !error.stderr) return [];
    throw new Error('Cannot verify the local server listener with lsof.', { cause: error });
  }
}

function processIdentity(pid, expected) {
  try {
    const commandAndStart = execFileSync(
      'ps',
      ['-ww', '-p', String(pid), '-o', 'lstart=', '-o', 'command='],
      inspectionOptions,
    ).trim();
    const cwd = execFileSync(
      'lsof',
      ['-a', '-p', String(pid), '-d', 'cwd', '-Fn'],
      inspectionOptions,
    )
      .split('\n')
      .find((line) => line.startsWith('n'))
      ?.slice(1);
    if (expected && (cwd !== expected.cwd || !commandAndStart.endsWith(expected.command))) {
      throw new Error('Spawned local server command or working directory did not match.');
    }
    return { commandAndStart, cwd };
  } catch (error) {
    if (error.status === 1 && !error.stderr) return null;
    throw error;
  }
}

function trackServer(child, options) {
  const state = {
    ...options,
    exited: false,
    output: '',
    abort: new AbortController(),
    identity: null,
    closing: null,
    controlReady: false,
    controlError: null,
  };
  child.on('message', (message) => {
    if (message?.type === 'runtime-server:control-ready' && message.pid === child.pid) {
      state.controlReady = true;
    }
  });
  state.exit = new Promise((resolve) => {
    const exited = () => {
      state.exited = true;
      state.abort.abort();
      resolve(undefined);
    };
    child.once('exit', exited);
    child.on('error', (error) => {
      if (!child.pid) exited();
      else state.controlError ??= error;
    });
  });
  child.stdout.on('data', (bytes) => {
    state.output = (state.output + bytes.toString()).slice(-8192);
  });
  child.stderr.on('data', () => {});
  ownedServers.set(child, state);
  return state;
}

async function waitForLocalServer(child, state, options) {
  const abort = options.signal
    ? AbortSignal.any([state.abort.signal, options.signal])
    : state.abort.signal;
  const deadline = Date.now() + options.timeoutMs;
  const marker = `Flutter web test server listening on http://127.0.0.1:${state.port}`;
  while (Date.now() < deadline) {
    abort.throwIfAborted();
    assertServerActive(child, state);
    if (state.output.includes(marker)) {
      const listeners = listenerPids(state.port);
      if (listeners.length !== 1 || listeners[0] !== child.pid) {
        throw new Error('Local performance listener does not belong to the spawned child.');
      }
      const signal = AbortSignal.any([
        abort,
        AbortSignal.timeout(Math.max(1, Math.min(options.requestTimeoutMs, deadline - Date.now()))),
      ]);
      await verifyLocalResponse(options.url, options.expectedHash, signal);
      assertServerActive(child, state);
      const remainingListeners = listenerPids(state.port);
      if (remainingListeners.length !== 1 || remainingListeners[0] !== child.pid) {
        throw new Error('Local performance listener ownership changed.');
      }
      return;
    }
    await delay(Math.min(50, Math.max(1, deadline - Date.now())), undefined, {
      signal: abort,
    });
  }
  throw new Error('Local performance server readiness deadline expired.');
}

function assertServerActive(child, state) {
  if (state.exited || child.exitCode !== null || child.signalCode !== null) {
    throw new Error(
      `Local performance server exited before readiness (${child.exitCode ?? child.signalCode}).`,
    );
  }
}

async function verifyLocalResponse(url, expectedHash, signal) {
  const response = await fetch(url, { signal, redirect: 'manual' });
  const body = await response.arrayBuffer();
  if (response.status !== 200 || hashBytes(Buffer.from(body)) !== expectedHash) {
    throw new Error('Local performance server did not serve the expected root artifact.');
  }
}

function hashBytes(bytes) {
  return createHash('sha256').update(bytes).digest('hex');
}

export async function closeLocalServer(child) {
  if (!child) return;
  const state = ownedServers.get(child);
  if (!state) throw new Error('Refusing to stop a server not started by this launcher.');
  state.closing ??= stopOwnedServer(child, state, signalLocalServer);
  await state.closing;
}

function signalLocalServer(child, state, signal) {
  if (!state.identity) return;
  try {
    const current = processIdentity(child.pid);
    if (
      current?.commandAndStart === state.identity.commandAndStart &&
      current?.cwd === state.identity.cwd &&
      child.exitCode === null &&
      child.signalCode === null &&
      !state.exited
    )
      child.kill(signal);
  } catch (error) {
    return error;
  }
}

export function summarize(samples, maximumMedian) {
  const metrics = [
    ...new Set([
      ...Object.keys(maximumMedian),
      'first_frame_to_reveal_ms',
      'scroll_frame_median_ms',
      'scroll_frame_p95_ms',
    ]),
  ];
  return Object.fromEntries(
    metrics.map((metric) => [
      metric,
      round(
        percentile(
          samples.map((sample) => sample[metric]).sort((a, b) => a - b),
          0.5,
        ),
        metric === 'cumulative_layout_shift' ? 4 : 2,
      ),
    ]),
  );
}

export function summarizeTransferredBytes(samples) {
  const resourceTypes = [
    ...new Set(samples.flatMap((sample) => Object.keys(sample.transferred_bytes_by_resource_type))),
  ].sort();
  return Object.fromEntries(
    resourceTypes.map((resourceType) => [
      resourceType,
      percentile(
        samples
          .map((sample) => sample.transferred_bytes_by_resource_type[resourceType] ?? 0)
          .sort((left, right) => left - right),
        0.5,
      ),
    ]),
  );
}

function percentile(sortedValues, percentileValue) {
  if (sortedValues.length === 0) return 0;
  const index = Math.min(
    sortedValues.length - 1,
    Math.ceil(sortedValues.length * percentileValue) - 1,
  );
  return sortedValues[index];
}

function round(value, digits = 2) {
  if (value === null || value === undefined || !Number.isFinite(value)) {
    return 0;
  }
  return Number(value.toFixed(digits));
}

function describeGraphicsBackend(gpu) {
  const device = gpu.devices?.[0] ?? {};
  const attributes = gpu.auxAttributes ?? {};
  const renderer = attributes.glRenderer ?? device.deviceString ?? 'unavailable';
  const backendSignals = [
    attributes.glRenderer,
    device.deviceString,
    attributes.displayType,
    attributes.glImplementationParts,
    gpu.featureStatus?.gpu_compositing,
    gpu.featureStatus?.webgl,
  ].filter(Boolean);
  const diagnostics = backendSignals.join(' ').toLowerCase();
  return {
    renderer,
    vendor: attributes.glVendor ?? device.vendorString ?? 'unavailable',
    display_type: attributes.displayType ?? 'unavailable',
    implementation: attributes.glImplementationParts ?? 'unavailable',
    software_rendering:
      backendSignals.length === 0 ? null : /swiftshader|llvmpipe|software/.test(diagnostics),
  };
}
