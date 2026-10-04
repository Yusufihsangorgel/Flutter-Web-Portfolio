import { spawnSync } from 'node:child_process';
import { cp, lstat, mkdir, mkdtemp, readFile, rm, symlink, writeFile } from 'node:fs/promises';
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
import { findTemplateRepository } from './package_links.mjs';

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
  assert(generated.schema_version === 10, 'schema version');
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
  assert(generated.writing_sources.length === 0, 'empty optional writing sources');
  assert(generated.writing.length === 0, 'empty optional writing');

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
  await testRepositoryInitialization();
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

async function testRepositoryInitialization() {
  const clone = path.join(temporaryDirectory, 'clone');
  await cp(root, clone, {
    recursive: true,
    filter: (source) => !new Set([
      '.git', '.dart_tool', 'build', 'node_modules', 'coverage',
    ]).has(path.relative(root, source).split(path.sep)[0]),
  });
  await writeFile(path.join(clone, 'tool/render_social_card.mjs'),
    `if (process.env.PORTFOLIO_TEST_RENDER_FAILURE === 'true' && !process.argv.includes('--check-browser')) {
  console.error('Simulated social-card failure for the initializer transaction test.');
  process.exit(1);
}
`);
  await symlink(path.resolve(root, 'node_modules'), path.join(clone, 'node_modules'));
  const readmeFile = path.join(clone, 'README.md');
  const screenshotFile = path.join(clone, 'docs/readme/home-desktop.jpg');
  const pubspecFile = path.join(clone, 'packages/adaptive_render_budget/pubspec.yaml');
  await mkdir(path.dirname(screenshotFile), { recursive: true });
  await writeFile(screenshotFile, Buffer.from([1, 2, 3, 4]));
  const original = findTemplateRepository(JSON.parse(await readFile(path.join(root, 'package.json'), 'utf8')));
  const pubspec = await readFile(pubspecFile, 'utf8');
  if (!/^repository:/m.test(pubspec)) {
    await writeFile(pubspecFile, `${pubspec}\nrepository: ${original}/tree/main/packages/adaptive_render_budget\n`);
  }
  const before = await Promise.all([readFile(readmeFile), readFile(screenshotFile), readFile(pubspecFile)]);
  const args = [
    'tool/init_portfolio.mjs', '--name', 'Ada Lovelace', '--role', 'Computing Pioneer',
    '--email', 'ada@example.com', '--site', 'https://example.com',
    '--location', 'London, UK', '--focus', 'Computing, Mathematics, Engineering',
    '--repository', 'example/portfolio', '--force',
  ];
  const failed = spawnSync(process.execPath, args, {
    cwd: clone, encoding: 'utf8',
    env: { ...process.env, NODE_ENV: 'test', PORTFOLIO_TEST_RENDER_FAILURE: 'true' },
  });
  if (failed.error) throw failed.error;
  assert(failed.status !== 0 && failed.stderr.includes('Simulated social-card failure'),
    `forced render failure reaches rollback: ${failed.stderr.slice(0, 800)}`);
  const after = await Promise.all([readFile(readmeFile), readFile(screenshotFile), readFile(pubspecFile)]);
  after.forEach((value, index) => assert(value.equals(before[index]), `rollback restores file ${index}`));
  await rm(screenshotFile);
  const absentFailure = spawnSync(process.execPath, args, {
    cwd: clone, encoding: 'utf8',
    env: { ...process.env, NODE_ENV: 'test', PORTFOLIO_TEST_RENDER_FAILURE: 'true' },
  });
  if (absentFailure.error) throw absentFailure.error;
  assert(absentFailure.status !== 0 && absentFailure.stderr.includes('Simulated social-card failure'),
    'missing screenshot failure reaches rollback');
  assert(!(await exists(screenshotFile)), 'rollback preserves absent screenshot');
  runInClone(args, clone);
  const readme = await readFile(readmeFile, 'utf8');
  assert(findTemplateIdentityResidue(readme, templateIdentityMarkers).length === 0, 'README identity residue');
  assert(!(await exists(screenshotFile)), 'initialized clone omits screenshot');
  for (const marker of ['portfolio-ci', 'portfolio-template', 'portfolio-demo',
    'portfolio-onboarding', 'portfolio-record-intro', 'portfolio-record']) {
    const body = readme.match(new RegExp(`<!-- ${marker}:start -->\\n([\\s\\S]*?)\\n<!-- ${marker}:end -->`))?.[1];
    assert(body?.trim(), `${marker} is filled`);
  }
  assert((await readFile(pubspecFile, 'utf8')).includes(
    'repository: https://github.com/example/portfolio/tree/main/packages/adaptive_render_budget'),
  'package repository follows the clone');
}

function runInClone(args, cwd) {
  const result = spawnSync(process.execPath, args, { cwd, encoding: 'utf8' });
  if (result.error) throw result.error;
  if (result.status !== 0) throw new Error(result.stderr || result.stdout);
}

async function exists(file) {
  try {
    await lstat(file);
    return true;
  } catch (error) {
    if (error.code === 'ENOENT') return false;
    throw error;
  }
}
