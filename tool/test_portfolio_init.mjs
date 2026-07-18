import { spawnSync } from 'node:child_process';
import { mkdtemp, readFile, rm } from 'node:fs/promises';
import os from 'node:os';
import path from 'node:path';
import process from 'node:process';
import { fileURLToPath } from 'node:url';

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const temporaryDirectory = await mkdtemp(path.join(os.tmpdir(), 'portfolio-init-'));
const output = path.join(temporaryDirectory, 'portfolio.json');

try {
  run(process.execPath, [
    path.join(root, 'tool', 'init_portfolio.mjs'),
    '--name',
    'Ada Lovelace',
    '--role',
    'Computing Pioneer',
    '--email',
    'ada@example.com',
    '--site',
    'https://example.com',
    '--location',
    'London, UK',
    '--focus',
    'Analytical engines, Mathematical notation, Computing history',
    '--github',
    'https://github.com/example',
    '--output',
    output,
    '--force',
  ]);

  const generated = JSON.parse(await readFile(output, 'utf8'));
  assert(generated.schema_version === 8, 'schema version');
  assert(generated.profile.name === 'Ada Lovelace', 'profile name');
  assert(generated.site.title === 'Ada Lovelace — Computing Pioneer', 'site title');
  assert(generated.profile.focus.length === 3, 'focus list');
  assert(generated.experience.length === 0, 'empty optional experience');
  assert(generated.contributions.length === 0, 'empty optional contributions');
  assert(generated.systems.length === 0, 'empty optional work');

  const serialized = JSON.stringify(generated).toLowerCase();
  for (const forbidden of [
    'yusuf',
    'görgel',
    'gorgel',
    'developeryusuf',
    'fugasoft',
    'dorse',
  ]) {
    assert(!serialized.includes(forbidden), `identity residue: ${forbidden}`);
  }

  run(process.env.DART_BIN ?? 'dart', [
    'run',
    path.join(root, 'tool', 'validate_portfolio.dart'),
    output,
  ]);
  console.log('Portfolio initializer smoke test passed.');
} finally {
  await rm(temporaryDirectory, { recursive: true, force: true });
}

function run(command, args) {
  const result = spawnSync(command, args, {
    cwd: root,
    encoding: 'utf8',
    shell: process.platform === 'win32',
  });
  if (result.stdout) process.stdout.write(result.stdout);
  if (result.stderr) process.stderr.write(result.stderr);
  if (result.error) throw result.error;
  if (result.status !== 0) {
    throw new Error(`${command} ${args.join(' ')} exited with ${result.status}.`);
  }
}

function assert(condition, label) {
  if (!condition) throw new Error(`Initializer assertion failed: ${label}`);
}
