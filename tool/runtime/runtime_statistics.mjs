const derivedMetrics = [
  'first_frame_to_reveal_ms',
  'scroll_frame_median_ms',
  'scroll_frame_p95_ms',
];

export function getBudgetFailures(thresholds, measured, skippedMetrics = new Set()) {
  requireRecord(thresholds, 'Runtime budget thresholds');
  requireRecord(measured, 'Runtime budget measurements');
  const entries = Object.entries(thresholds);
  for (const [metric, maximum] of entries) {
    requireMeasurement(maximum, `${metric} threshold`);
    requireOwnMeasurement(measured, metric, `${metric} measurement`);
  }
  return entries
    .filter(([metric]) => !skippedMetrics.has(metric))
    .filter(([metric, maximum]) => measured[metric] > maximum)
    .map(([metric, maximum]) => `${metric}: ${measured[metric]} exceeds ${maximum}`);
}

export function summarize(samples, maximumMedian) {
  requireSamples(samples, 'Runtime samples');
  requireRecord(maximumMedian, 'Runtime budget thresholds');
  samples.forEach((sample, index) => requireRecord(sample, `Runtime sample ${index}`));
  const metrics = [...new Set([...Object.keys(maximumMedian), ...derivedMetrics])];
  return Object.fromEntries(
    metrics.map((metric) => {
      const values = samples
        .map((sample, index) =>
          requireOwnMeasurement(sample, metric, `Runtime sample ${index} ${metric}`),
        )
        .sort((left, right) => left - right);
      const digits = metric === 'cumulative_layout_shift' ? 4 : 2;
      return [metric, round(percentile(values, 0.5), digits)];
    }),
  );
}

export function summarizeTransferredBytes(samples) {
  requireSamples(samples, 'Transferred-byte samples');
  const maps = samples.map((sample, index) => {
    requireRecord(sample, `Transferred-byte sample ${index}`);
    if (!Object.hasOwn(sample, 'transferred_bytes_by_resource_type')) {
      throw new Error(`Runtime sample ${index} is missing transferred_bytes_by_resource_type.`);
    }
    const totals = sample.transferred_bytes_by_resource_type;
    requireRecord(totals, `Runtime sample ${index} transferred_bytes_by_resource_type`);
    for (const [resourceType, bytes] of Object.entries(totals)) {
      requireMeasurement(bytes, `Runtime sample ${index} ${resourceType} bytes`);
    }
    return totals;
  });
  const resourceTypes = [...new Set(maps.flatMap((totals) => Object.keys(totals)))].sort();
  return Object.fromEntries(
    resourceTypes.map((resourceType) => {
      const values = maps
        .map((totals, index) =>
          Object.hasOwn(totals, resourceType)
            ? requireMeasurement(
                totals[resourceType],
                `Runtime sample ${index} ${resourceType} bytes`,
              )
            : 0,
        )
        .sort((left, right) => left - right);
      return [resourceType, percentile(values, 0.5)];
    }),
  );
}

function requireSamples(samples, name) {
  if (!Array.isArray(samples) || samples.length === 0) {
    throw new Error(`${name} must contain at least one actual sample.`);
  }
  for (let index = 0; index < samples.length; index += 1) {
    if (!Object.hasOwn(samples, index)) {
      throw new Error(`${name} is missing sample ${index}.`);
    }
  }
}

function requireRecord(value, name) {
  if (value === null || typeof value !== 'object' || Array.isArray(value)) {
    throw new Error(`${name} must be an object.`);
  }
}

function requireOwnMeasurement(record, metric, name) {
  if (!Object.hasOwn(record, metric)) throw new Error(`${name} is missing.`);
  return requireMeasurement(record[metric], name);
}

function requireMeasurement(value, name) {
  if (typeof value !== 'number' || !Number.isFinite(value) || value < 0) {
    throw new Error(`${name} must be a finite, non-negative number.`);
  }
  return value;
}

function percentile(sortedValues, percentileValue) {
  if (sortedValues.length === 0) throw new Error('A percentile requires at least one sample.');
  const index = Math.min(
    sortedValues.length - 1,
    Math.ceil(sortedValues.length * percentileValue) - 1,
  );
  return sortedValues[index];
}

function round(value, digits = 2) {
  return Number(requireMeasurement(value, 'Runtime summary value').toFixed(digits));
}
