import assert from 'node:assert/strict';
import { spawnSync } from 'node:child_process';
import { mkdir, mkdtemp, readFile, rm, symlink, writeFile } from 'node:fs/promises';
import os from 'node:os';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import test from 'node:test';

const toolRoot = path.dirname(fileURLToPath(import.meta.url));
const gate = path.join(toolRoot, 'coverage_gate.mjs');
const fixtures = path.join(toolRoot, '..', 'fixtures', 'lcov');
const contracts = [
  'lib/app/domain/providers/asset_loader.dart',
  'lib/app/domain/providers/key_value_store.dart',
  'lib/app/domain/repositories/language_repository.dart',
];
const additionalDomains = [
  'lib/app/narrative/domain/chapter.dart',
  'lib/app/features/render_quality/domain/profile.dart',
];
async function withThresholds(values, check, fixture = 'equal.lcov') {
  const directory = await mkdtemp(path.join(os.tmpdir(), 'coverage-gate-'));
  const thresholds = path.join(directory, 'thresholds.json');
  const summary = path.join(directory, 'summary.md');
  try {
    await writeFile(thresholds, `${JSON.stringify(values)}\n`);
    const sourcePaths = [
      ...(await readFile(path.join(fixtures, fixture), 'utf8')).matchAll(/^SF:(.+)$/gm),
    ]
      .map((match) => match[1])
      .filter((file) => file.startsWith('lib/app/'));
    for (const file of [...sourcePaths, ...contracts]) {
      const destination = path.join(directory, file);
      await mkdir(path.dirname(destination), { recursive: true });
      const content = contracts.includes(file)
        ? await readFile(path.join(toolRoot, '../..', file), 'utf8')
        : 'int fixture() => 1;\n';
      await writeFile(destination, content);
    }
    await check({ thresholds, summary, directory });
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
      options.coverage ?? path.join(fixtures, fixture),
      '--thresholds',
      thresholds,
      ...(options.update ? ['--update'] : []),
    ],
    {
      encoding: 'utf8',
      cwd: path.dirname(thresholds),
      env: { ...process.env, GITHUB_STEP_SUMMARY: options.summary ?? '' },
    },
  );
}

test('coverage below a threshold fails', async () => {
  await withThresholds(
    { domain: 75, application: 50 },
    async ({ thresholds }) => {
      const result = runGate('below.lcov', thresholds);
      assert.equal(result.status, 1, result.stderr);
      assert.match(result.stdout, /\| domain \| 2\/4 \| 50\.0% \| 75\.0% \| FAIL \|/);
      assert.match(result.stdout, /\| application \| 0\/2 \| 0\.0% \| 50\.0% \| FAIL \|/);
    },
    'below.lcov',
  );
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
  await withThresholds(
    { domain: 0, application: 0 },
    async ({ thresholds }) => {
      const result = runGate('thirds.lcov', thresholds, { update: true });
      assert.equal(result.status, 0, result.stderr);
      assert.deepEqual(JSON.parse(await readFile(thresholds, 'utf8')), {
        domain: 66.6,
        application: 33.3,
      });
    },
    'thirds.lcov',
  );
});

test('--update refuses to lower either threshold', async () => {
  const initial = { domain: 70, application: 30 };
  await withThresholds(
    initial,
    async ({ thresholds }) => {
      const result = runGate('thirds.lcov', thresholds, { update: true });
      assert.equal(result.status, 1, result.stderr);
      assert.match(result.stderr, /would lower domain/);
      assert.deepEqual(JSON.parse(await readFile(thresholds, 'utf8')), initial);
    },
    'thirds.lcov',
  );
});

test('omitted executable source is rejected even when untracked', async () => {
  await withThresholds({ domain: 75, application: 50 }, async ({ thresholds, directory }) => {
    const missing = 'lib/app/domain/new_logic.dart';
    await writeFile(path.join(directory, missing), 'int answer() => 42;\n');
    const result = runGate('equal.lcov', thresholds);
    assert.equal(result.status, 1, result.stdout);
    assert.match(result.stderr, /Missing LCOV source: lib\/app\/domain\/new_logic\.dart/);
  });
});

test('audited abstract-only contracts are absent without lowering coverage', async () => {
  await withThresholds({ domain: 75, application: 50 }, async ({ thresholds }) => {
    const result = runGate('equal.lcov', thresholds);
    assert.equal(result.status, 0, result.stderr);
    assert.match(result.stdout, /\| domain \| 3\/4 \| 75\.0%/);
  });
});

test('an audited contract changing to executable code requires coverage', async () => {
  await withThresholds({ domain: 75, application: 50 }, async ({ thresholds, directory }) => {
    const contract = contracts[0];
    await writeFile(path.join(directory, contract), 'int executable() => 1;\n');
    const result = runGate('equal.lcov', thresholds);
    assert.equal(result.status, 1, result.stdout);
    assert.match(
      result.stderr,
      /Missing LCOV source: lib\/app\/domain\/providers\/asset_loader\.dart/,
    );
  });
});

test('empty LCOV record does not hide an executable source', async () => {
  await withThresholds({ domain: 75, application: 50 }, async ({ thresholds, directory }) => {
    const missing = 'lib/app/controllers/new_controller.dart';
    await writeFile(path.join(directory, missing), 'int answer() => 42;\n');
    const coverage = path.join(directory, 'empty-source.lcov');
    await writeFile(
      coverage,
      `${await readFile(path.join(fixtures, 'equal.lcov'), 'utf8')}SF:${missing}\nend_of_record\n`,
    );
    const result = runGate('equal.lcov', thresholds, { coverage });
    assert.equal(result.status, 1, result.stdout);
    assert.match(result.stderr, /Missing LCOV source: lib\/app\/controllers\/new_controller\.dart/);
  });
});

test('symlinked eligible source cannot evade the inventory', async () => {
  await withThresholds({ domain: 75, application: 50 }, async ({ thresholds, directory }) => {
    await symlink('document.dart', path.join(directory, 'lib/app/domain/linked.dart'));
    const result = runGate('equal.lcov', thresholds);
    assert.equal(result.status, 1, result.stdout);
    assert.match(result.stderr, /Missing LCOV source: lib\/app\/domain\/linked\.dart/);
  });
});

test('equivalent LCOV paths match the source inventory', async () => {
  await withThresholds({ domain: 75, application: 50 }, async ({ thresholds, directory }) => {
    const coverage = path.join(directory, 'normalized.lcov');
    const original = await readFile(path.join(fixtures, 'equal.lcov'), 'utf8');
    await writeFile(
      coverage,
      original.replace('SF:lib/app/domain/document.dart', 'SF:lib/app/domain/./document.dart'),
    );
    const result = runGate('equal.lcov', thresholds, { coverage });
    assert.equal(result.status, 0, result.stderr);
  });
});

async function addDomainSources(directory) {
  for (const file of additionalDomains) {
    const destination = path.join(directory, file);
    await mkdir(path.dirname(destination), { recursive: true });
    await writeFile(destination, 'int fixture() => 1;\n');
  }
}

test('narrative and feature domain lines count without changing application', async () => {
  await withThresholds({ domain: 75, application: 50 }, async ({ thresholds, directory }) => {
    await addDomainSources(directory);
    const coverage = path.join(directory, 'expanded.lcov');
    const original = await readFile(path.join(fixtures, 'equal.lcov'), 'utf8');
    const extra = additionalDomains.map((file) => `SF:${file}\nDA:1,1\nDA:2,0\nend_of_record\n`);
    await writeFile(coverage, original + extra.join(''));
    const result = runGate('equal.lcov', thresholds, { coverage });
    assert.equal(result.status, 1, result.stderr);
    assert.match(result.stdout, /\| domain \| 5\/8 \| 62\.5% \| 75\.0% \| FAIL \|/);
    assert.match(result.stdout, /\| application \| 3\/6 \| 50\.0% \| 50\.0% \| PASS \|/);
  });
});

for (const file of additionalDomains) {
  test(`omitted ${file} fails the source inventory`, async () => {
    await withThresholds({ domain: 75, application: 50 }, async ({ thresholds, directory }) => {
      await addDomainSources(directory);
      const result = runGate('equal.lcov', thresholds);
      assert.equal(result.status, 1, result.stdout);
      assert.match(result.stderr, /Missing LCOV source:/);
      assert.ok(result.stderr.includes(file), result.stderr);
    });
  });

  test(`empty ${file} record fails the source inventory`, async () => {
    await withThresholds({ domain: 75, application: 50 }, async ({ thresholds, directory }) => {
      await addDomainSources(directory);
      const coverage = path.join(directory, 'empty-domain.lcov');
      const original = await readFile(path.join(fixtures, 'equal.lcov'), 'utf8');
      const other = additionalDomains.find((candidate) => candidate !== file);
      await writeFile(
        coverage,
        `${original}SF:${other}\nDA:1,1\nend_of_record\nSF:${file}\nend_of_record\n`,
      );
      const result = runGate('equal.lcov', thresholds, { coverage });
      assert.equal(result.status, 1, result.stdout);
      assert.match(result.stderr, /Missing LCOV source:/);
      assert.ok(result.stderr.includes(file), result.stderr);
    });
  });
}
