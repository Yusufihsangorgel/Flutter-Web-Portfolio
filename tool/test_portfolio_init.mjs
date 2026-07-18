import { spawnSync } from 'node:child_process';
import { mkdtemp, readFile, rm } from 'node:fs/promises';
import os from 'node:os';
import path from 'node:path';
import process from 'node:process';
import { fileURLToPath } from 'node:url';

import { resolveSafePublicPngPath } from './safe_public_asset_path.mjs';
import { resolveExecutable } from './cli_safety.mjs';
import {
  collectTemplateIdentityMarkers,
  findTemplateIdentityResidue,
} from './template_identity_markers.mjs';

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const temporaryDirectory = await mkdtemp(path.join(os.tmpdir(), 'portfolio-init-'));
const output = path.join(temporaryDirectory, 'portfolio.json');
const templateDocument = JSON.parse(
  await readFile(path.join(root, 'assets', 'content', 'portfolio.json'), 'utf8'),
);
const templateIdentityMarkers = collectTemplateIdentityMarkers(templateDocument);

try {
  for (const unsafe of [
    '/assets/og/%2e%2e/private.png',
    '/assets/og/%5c..%5cprivate.png',
    '../private.png',
  ]) {
    assertThrows(
      () => resolveSafePublicPngPath(unsafe),
      `unsafe social image path: ${unsafe}`,
    );
  }

  runExpectFailure(process.execPath, [
    path.join(root, 'tool', 'init_portfolio.mjs'),
    '--keep-demo-assets',
  ], 'initialized repositories must not retain demo-owner artifacts');

  runExpectFailure(process.execPath, [
    path.join(root, 'tool', 'init_portfolio.mjs'),
    '--skip-sync',
  ], 'the canonical portfolio must update every public surface transactionally');

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
  assert(
    generated.site.template_repository === false,
    'initialized portfolio is not advertised as a GitHub template',
  );
  assert(generated.profile.name === 'Ada Lovelace', 'profile name');
  assert(generated.site.title === 'Ada Lovelace — Computing Pioneer', 'site title');
  assert(generated.profile.focus.length === 3, 'focus list');
  assert(
    JSON.stringify(generated.site.locales) === JSON.stringify(['en']),
    'clean clones advertise only fully authored locales',
  );
  assert(generated.experience.length === 0, 'empty optional experience');
  assert(generated.contributions.length === 0, 'empty optional contributions');
  assert(generated.systems.length === 0, 'empty optional work');

  const serialized = JSON.stringify(generated).toLowerCase();
  const residue = findTemplateIdentityResidue(
    serialized,
    templateIdentityMarkers,
  );
  assert(
    residue.length === 0,
    `identity residue: ${residue.map((item) => item.marker).join(', ')}`,
  );

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
  const result = spawnSync(resolveExecutable(command), args, {
    cwd: root,
    encoding: 'utf8',
    shell: false,
  });
  if (result.stdout) process.stdout.write(result.stdout);
  if (result.stderr) process.stderr.write(result.stderr);
  if (result.error) throw result.error;
  if (result.status !== 0) {
    throw new Error(`${command} ${args.join(' ')} exited with ${result.status}.`);
  }
}

function runExpectFailure(command, args, expectedMessage) {
  const result = spawnSync(resolveExecutable(command), args, {
    cwd: root,
    encoding: 'utf8',
    shell: false,
  });
  if (result.error) throw result.error;
  assert(result.status !== 0, `${command} ${args.join(' ')} should fail`);
  assert(
    `${result.stdout}\n${result.stderr}`.includes(expectedMessage),
    `deprecated unsafe flag reports its contract: ${expectedMessage}`,
  );
}

function assert(condition, label) {
  if (!condition) throw new Error(`Initializer assertion failed: ${label}`);
}

function assertThrows(operation, label) {
  try {
    operation();
  } catch {
    return;
  }
  throw new Error(`Initializer assertion failed: ${label}`);
}
