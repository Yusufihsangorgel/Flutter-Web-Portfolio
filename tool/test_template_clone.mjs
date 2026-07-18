import { spawnSync } from 'node:child_process';
import {
  mkdtemp,
  readFile,
  readdir,
  rm,
  symlink,
} from 'node:fs/promises';
import os from 'node:os';
import path from 'node:path';
import process from 'node:process';
import { fileURLToPath } from 'node:url';

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const temporaryDirectory = await mkdtemp(
  path.join(os.tmpdir(), 'portfolio-template-clone-'),
);
const clone = path.join(temporaryDirectory, 'portfolio');

try {
  run('git', ['clone', '--quiet', '--no-local', '--depth', '1', root, clone], root);
  await symlink(path.join(root, 'node_modules'), path.join(clone, 'node_modules'), 'junction');

  run(process.execPath, [
    'tool/init_portfolio.mjs',
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
    '--force',
  ], clone);

  await assertGuideOnly(path.join(clone, 'assets', 'work'));
  await assertGuideOnly(path.join(clone, 'tool', 'work_sources'));

  run('flutter', ['pub', 'get'], clone);
  run('npm', ['run', 'build:release'], clone);

  const generated = JSON.parse(
    await readFile(path.join(clone, 'assets', 'content', 'portfolio.json'), 'utf8'),
  );
  assert(generated.profile.name === 'Ada Lovelace', 'custom identity');
  assert(generated.experience.length === 0, 'empty experience');
  assert(generated.contributions.length === 0, 'empty contributions');
  assert(generated.systems.length === 0, 'empty selected work');

  const publicText = await collectPublicText(path.join(clone, 'build', 'web'));
  const forbidden = [
    /yusuf/i,
    /görgel/i,
    /gorgel/i,
    /developeryusuf/i,
    /fugasoft/i,
    /juniustech/i,
    /promob\s*tr/i,
    /\bdorse\b/i,
  ];
  for (const pattern of forbidden) {
    assert(!pattern.test(publicText), `public identity residue: ${pattern}`);
  }

  console.log('Clean-clone initializer and release build passed.');
} finally {
  await rm(temporaryDirectory, { recursive: true, force: true });
}

async function assertGuideOnly(directory) {
  const entries = (await readdir(directory)).sort();
  assert(
    entries.length === 1 && entries[0] === 'README.md',
    `${path.relative(clone, directory)} contains only its guide`,
  );
}

async function collectPublicText(directory) {
  const textExtensions = new Set([
    '.css',
    '.html',
    '.js',
    '.json',
    '.mjs',
    '.sha256',
    '.txt',
    '.xml',
  ]);
  const entries = await readdir(directory, { withFileTypes: true });
  const chunks = [];
  for (const entry of entries) {
    const absolute = path.join(directory, entry.name);
    if (entry.isDirectory()) {
      chunks.push(await collectPublicText(absolute));
    } else if (textExtensions.has(path.extname(entry.name))) {
      chunks.push(await readFile(absolute, 'utf8'));
    }
  }
  return chunks.join('\n');
}

function run(command, args, cwd) {
  const result = spawnSync(command, args, {
    cwd,
    stdio: 'inherit',
    shell: process.platform === 'win32',
  });
  if (result.error) throw result.error;
  if (result.status !== 0) {
    throw new Error(`${command} ${args.join(' ')} exited with ${result.status}.`);
  }
}

function assert(condition, label) {
  if (!condition) throw new Error(`Clean-clone assertion failed: ${label}`);
}
