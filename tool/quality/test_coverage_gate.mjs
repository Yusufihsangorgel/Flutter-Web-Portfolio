import assert from 'node:assert/strict';
import { spawnSync } from 'node:child_process';
import { mkdtemp, readFile, rm, writeFile } from 'node:fs/promises';
import os from 'node:os';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import test from 'node:test';

const toolRoot = path.dirname(fileURLToPath(import.meta.url));
const gate = path.join(toolRoot, 'coverage_gate.mjs');
const fixtures = path.join(toolRoot, '..', 'fixtures', 'lcov');

async function withThresholds(values, check) {
  const directory = await mkdtemp(path.join(os.tmpdir(), 'coverage-gate-'));
  const thresholds = path.join(directory, 'thresholds.json');
  const summary = path.join(directory, 'summary.md');
  try {
    await writeFile(thresholds, `${JSON.stringify(values)}\n`);
    await check({ thresholds, summary });
  } finally {
    await rm(directory, { recursive: true, force: true });
  }
}

function runGate(fixture, thresholds, options = {}) {
  return spawnSync(
    process.execPath,
    [
      gate,
      '--coverage',
      path.join(fixtures, fixture),
      '--thresholds',
      thresholds,
      ...(options.update ? ['--update'] : []),
    ],
    {
      encoding: 'utf8',
      env: { ...process.env, GITHUB_STEP_SUMMARY: options.summary ?? '' },
    },
  );
}

test('coverage below a threshold fails', async () => {
  await withThresholds({ domain: 75, application: 50 }, async ({ thresholds }) => {
    const result = runGate('below.lcov', thresholds);
    assert.equal(result.status, 1, result.stderr);
    assert.match(result.stdout, /\| domain \| 2\/4 \| 50\.0% \| 75\.0% \| FAIL \|/);
    assert.match(result.stdout, /\| application \| 0\/2 \| 0\.0% \| 50\.0% \| FAIL \|/);
  });
});

test('coverage equal to thresholds passes and writes the summary', async () => {
  await withThresholds({ domain: 75, application: 50 }, async ({ thresholds, summary }) => {
    const result = runGate('equal.lcov', thresholds, { summary });
    assert.equal(result.status, 0, result.stderr);
    assert.match(result.stdout, /\| domain \| 3\/4 \| 75\.0% \| 75\.0% \| PASS \|/);
    assert.match(result.stdout, /\| application \| 3\/6 \| 50\.0% \| 50\.0% \| PASS \|/);
    assert.equal(await readFile(summary, 'utf8'), result.stdout);
  });
});

test('--update floors percentages to one decimal', async () => {
  await withThresholds({ domain: 0, application: 0 }, async ({ thresholds }) => {
    const result = runGate('thirds.lcov', thresholds, { update: true });
    assert.equal(result.status, 0, result.stderr);
    assert.deepEqual(JSON.parse(await readFile(thresholds, 'utf8')), {
      domain: 66.6,
      application: 33.3,
    });
  });
});

test('--update refuses to lower either threshold', async () => {
  const initial = { domain: 70, application: 30 };
  await withThresholds(initial, async ({ thresholds }) => {
    const result = runGate('thirds.lcov', thresholds, { update: true });
    assert.equal(result.status, 1, result.stderr);
    assert.match(result.stderr, /would lower domain/);
    assert.deepEqual(JSON.parse(await readFile(thresholds, 'utf8')), initial);
  });
});
