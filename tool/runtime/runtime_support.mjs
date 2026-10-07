import { spawn } from 'node:child_process';
import process from 'node:process';

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

export async function startLocalServer(url) {
  const child = spawn(process.execPath, ['tool/runtime/serve_web.mjs'], {
    cwd: process.cwd(),
    stdio: 'ignore',
  });
  child.unref();
  const deadline = Date.now() + 15000;
  while (Date.now() < deadline) {
    if (child.exitCode !== null) {
      throw new Error(`Local performance server exited with ${child.exitCode}.`);
    }
    try {
      const response = await fetch(url);
      if (response.ok) return child;
    } catch {
      // The local server is still starting.
    }
    await new Promise((resolve) => setTimeout(resolve, 100));
  }
  child.kill('SIGTERM');
  throw new Error(`Local performance server did not start at ${url}.`);
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
