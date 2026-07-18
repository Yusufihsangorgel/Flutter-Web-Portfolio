import { spawnSync } from 'node:child_process';
import { createHash } from 'node:crypto';
import {
  cp,
  lstat,
  mkdtemp,
  readFile,
  readdir,
  rm,
  symlink,
  writeFile,
} from 'node:fs/promises';
import os from 'node:os';
import path from 'node:path';
import process from 'node:process';
import { fileURLToPath } from 'node:url';

import {
  collectTemplateIdentityMarkers,
  findTemplateIdentityResidue,
} from './template_identity_markers.mjs';
import { resolveExecutable } from './cli_safety.mjs';

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const temporaryDirectory = await mkdtemp(
  path.join(os.tmpdir(), 'portfolio-template-clone-'),
);
const clone = path.join(temporaryDirectory, 'portfolio');

try {
  await cp(root, clone, {
    recursive: true,
    filter: (source) => {
      const relative = path.relative(root, source);
      const top = relative.split(path.sep)[0];
      return !new Set([
        ['.clau', 'de'].join(''),
        '.dart_tool',
        '.flutter-plugins',
        '.flutter-plugins-dependencies',
        '.git',
        '.hosted-cache',
        '.idea',
        '.metadata',
        '.vscode',
        'build',
        'coverage',
        'node_modules',
        'playwright-report',
        'test-results',
      ]).has(top);
    },
  });
  await materializeTrackedBuild(clone, temporaryDirectory);
  await symlink(path.join(root, 'node_modules'), path.join(clone, 'node_modules'), 'junction');
  const templateDocument = JSON.parse(
    await readFile(path.join(clone, 'assets', 'content', 'portfolio.json'), 'utf8'),
  );
  const templateIdentityMarkers = collectTemplateIdentityMarkers(templateDocument);

  const initializerArguments = [
    'tool/init_portfolio.mjs',
    '--name',
    'Ada Lovelace',
    '--role',
    'Computing Pioneer',
    '--email',
    'ada@example.com',
    '--site',
    'https://ada.github.io/portfolio',
    '--location',
    'London, UK',
    '--focus',
    'Analytical engines, Mathematical notation, Computing history',
    '--github',
    'https://github.com/example',
    '--repository',
    'ada/portfolio',
    '--force',
  ];

  const repositoryOption = initializerArguments.indexOf('--repository');
  const archiveArguments = initializerArguments.toSpliced(repositoryOption, 2);
  runExpectMessageFailure(
    process.execPath,
    archiveArguments,
    clone,
    'Pass --repository owner/repository',
  );

  const beforeFailure = await snapshotTree(clone);
  runExpectFailure(process.execPath, initializerArguments, clone, {
    ...process.env,
    NODE_ENV: 'test',
    PORTFOLIO_TEST_RENDER_FAILURE: 'true',
  });
  assert(
    (await snapshotTree(clone)) === beforeFailure,
    'failed initialization restores the complete repository',
  );

  run(process.execPath, initializerArguments, clone);

  assert(
    !(await pathExists(path.join(clone, 'build', 'web'))),
    'successful initialization removes the inherited public release',
  );

  await assertGuideOnly(path.join(clone, 'assets', 'work'));
  await assertGuideOnly(path.join(clone, 'tool', 'work_sources'));
  await assertCleanLocaleDirectory(
    path.join(clone, 'assets', 'content', 'locales'),
  );

  const generated = JSON.parse(
    await readFile(path.join(clone, 'assets', 'content', 'portfolio.json'), 'utf8'),
  );
  assert(generated.profile.name === 'Ada Lovelace', 'custom identity');
  assert(generated.experience.length === 0, 'empty experience');
  assert(generated.contributions.length === 0, 'empty contributions');
  assert(generated.systems.length === 0, 'empty selected work');
  const robots = await readFile(path.join(clone, 'web', 'robots.txt'), 'utf8');
  const index = await readFile(path.join(clone, 'web', 'index.html'), 'utf8');
  const readme = await readFile(path.join(clone, 'README.md'), 'utf8');
  const changelog = await readFile(path.join(clone, 'CHANGELOG.md'), 'utf8');
  const packageDocument = JSON.parse(
    await readFile(path.join(clone, 'package.json'), 'utf8'),
  );
  assert(
    robots.includes('Sitemap: https://ada.github.io/portfolio/sitemap.xml'),
    'project Pages sitemap stays below the repository path',
  );
  assert(
    index.includes('https://ada.github.io/portfolio/assets/og/engineering-showcase.png'),
    'project Pages social card stays below the repository path',
  );
  assert(
    readme.includes('github.com/ada/portfolio/actions/workflows/ci.yml/badge.svg'),
    'README CI badge follows the generated repository',
  );
  assert(
    readme.includes('alt="View repository"') &&
      !readme.includes('github.com/ada/portfolio/generate'),
    'initialized repositories never advertise an unverified template action',
  );
  assert(
    readme.includes('already contains an initialized portfolio') &&
      !readme.includes('Choose **Use this template** above'),
    'initialized onboarding never points to a missing template action',
  );
  assert(
    readme.includes("repository owner's canonical content document") &&
      !readme.includes('evidence for the demo'),
    'initialized record copy describes the current owner instead of the demo',
  );
  assert(
    packageDocument.repository?.url === 'https://github.com/ada/portfolio.git',
    'generated repository identity persists outside the source checkout',
  );
  assert(
    changelog.includes('Initialized a clean portfolio record') &&
      !changelog.includes('## [1.'),
    'initialized repositories receive an identity-neutral starter changelog',
  );
  assert(
    !packageDocument.scripts?.['render:work-artifacts'],
    'demo-owner artifact renderer command is absent',
  );
  assert(
    !(await pathExists(path.join(clone, 'tool', 'render_work_artifacts.mjs'))),
    'demo-owner artifact renderer source is absent',
  );
  const repositoryText = await collectRepositoryText(clone);
  const repositoryResidue = findTemplateIdentityResidue(
    repositoryText,
    templateIdentityMarkers,
  );
  assert(
    repositoryResidue.length === 0,
    `repository identity residue: ${repositoryResidue
      .map(({ marker, line }) => `${marker} (${line})`)
      .join(' | ')}`,
  );

  const canonicalPath = path.join(clone, 'assets', 'content', 'portfolio.json');
  const canonical = await readFile(canonicalPath, 'utf8');
  const hostile = JSON.parse(canonical);
  hostile.site.social_description =
    'Safe </script><script>alert(1)</script> boundary';
  await writeFile(canonicalPath, `${JSON.stringify(hostile, null, 2)}\n`);
  run(process.execPath, ['tool/sync_public_content.mjs'], clone, {
    ...process.env,
    PORTFOLIO_GITHUB_REPOSITORY: 'ada/portfolio',
  });
  const hostileIndex = await readFile(path.join(clone, 'web', 'index.html'), 'utf8');
  assert(
    !hostileIndex.includes('</script><script>alert(1)</script>'),
    'JSON-LD cannot close its script element',
  );
  assert(hostileIndex.includes('\\u003c/script\\u003e'), 'JSON-LD escapes HTML boundaries');
  await writeFile(canonicalPath, canonical);
  run(process.execPath, ['tool/sync_public_content.mjs'], clone, {
    ...process.env,
    PORTFOLIO_GITHUB_REPOSITORY: 'ada/portfolio',
  });

  run('flutter', ['pub', 'get'], clone);
  run('flutter', ['test'], clone);
  run('npx', ['playwright', 'test', '--list'], clone);
  run('npm', ['run', 'build:release'], clone);
  run('npm', ['test', '--', '--project=desktop'], clone);
  run('npm', ['run', 'build:release', '--', '--base-href', '/portfolio/'], clone);
  run(process.execPath, ['tool/smoke_clean_template.mjs', '--base-path', '/portfolio/'], clone);
  await assertGuideOnly(
    path.join(clone, 'build', 'web', 'assets', 'assets', 'work'),
  );

  const publicText = await collectPublicText(path.join(clone, 'build', 'web'));
  const publicResidue = findTemplateIdentityResidue(
    publicText,
    templateIdentityMarkers,
  );
  assert(
    publicResidue.length === 0,
    `public identity residue: ${publicResidue
      .map(({ marker }) => marker)
      .join(', ')}`,
  );

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

async function assertCleanLocaleDirectory(directory) {
  const entries = (await readdir(directory)).sort();
  assert(
    entries.length === 1 && entries[0] === '.gitkeep',
    'demo owner portfolio localizations were removed',
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

async function collectRepositoryText(directory) {
  const excluded = new Set(['.git', 'build', 'node_modules']);
  const chunks = [];
  await collect(directory);
  return chunks.join('\n');

  async function collect(target) {
    const entries = await readdir(target, { withFileTypes: true });
    for (const entry of entries) {
      if (excluded.has(entry.name)) continue;
      const absolute = path.join(target, entry.name);
      const relative = path.relative(directory, absolute).split(path.sep).join('/');
      chunks.push(relative);
      if (entry.isDirectory()) {
        await collect(absolute);
        continue;
      }
      if (!entry.isFile()) continue;
      const bytes = await readFile(absolute);
      if (bytes.includes(0)) continue;
      try {
        const decoded = new TextDecoder('utf-8', { fatal: true }).decode(bytes);
        chunks.push(
          ...decoded.split('\n').map((line) => `${relative}:${line}`),
        );
      } catch {
        // Binary assets are covered by their path; only valid UTF-8 is scanned.
      }
    }
  }
}

function run(command, args, cwd, environment = process.env) {
  const result = spawnSync(resolveExecutable(command), args, {
    cwd,
    stdio: 'inherit',
    shell: false,
    env: environment,
  });
  if (result.error) throw result.error;
  if (result.status !== 0) {
    throw new Error(`${command} ${args.join(' ')} exited with ${result.status}.`);
  }
}

function runExpectFailure(command, args, cwd, environment) {
  const result = spawnSync(resolveExecutable(command), args, {
    cwd,
    encoding: 'utf8',
    shell: false,
    env: environment,
  });
  if (result.error) throw result.error;
  assert(result.status !== 0, `${command} ${args.join(' ')} should fail`);
  assert(
    `${result.stdout}\n${result.stderr}`.includes('restored every repository file'),
    'failure reports transactional restoration',
  );
}

function runExpectMessageFailure(command, args, cwd, expectedMessage) {
  const result = spawnSync(resolveExecutable(command), args, {
    cwd,
    encoding: 'utf8',
    shell: false,
  });
  if (result.error) throw result.error;
  assert(result.status !== 0, `${command} ${args.join(' ')} should fail`);
  assert(
    `${result.stdout}\n${result.stderr}`.includes(expectedMessage),
    `failure reports its safe repository contract: ${expectedMessage}`,
  );
}

async function snapshotTree(directory) {
  const hash = createHash('sha256');
  await visit(directory);
  return hash.digest('hex');

  async function visit(current) {
    const entries = (await readdir(current, { withFileTypes: true })).sort((a, b) =>
      a.name.localeCompare(b.name),
    );
    for (const entry of entries) {
      if (entry.name === 'node_modules') continue;
      const absolute = path.join(current, entry.name);
      const relative = path.relative(directory, absolute);
      hash.update(`${entry.isDirectory() ? 'd' : 'f'}:${relative}\0`);
      if (entry.isDirectory()) await visit(absolute);
      else hash.update(await readFile(absolute));
    }
  }
}

async function materializeTrackedBuild(directory, temporaryRoot) {
  const tracked = spawnSync(
    'git',
    ['ls-tree', '-d', '--name-only', 'HEAD', 'build'],
    { cwd: root, encoding: 'utf8' },
  );
  if (tracked.error) throw tracked.error;
  if (tracked.status !== 0) {
    throw new Error(`git ls-tree exited with ${tracked.status}.`);
  }
  if (tracked.stdout.trim() !== 'build') return;
  const archive = path.join(temporaryRoot, 'tracked-build.tar');
  run('git', ['archive', '--format=tar', '--output', archive, 'HEAD', 'build'], root);
  run('tar', ['-xf', archive, '-C', directory], root);
  await rm(archive, { force: true });
}

async function pathExists(target) {
  try {
    await lstat(target);
    return true;
  } catch (error) {
    if (error?.code === 'ENOENT') return false;
    throw error;
  }
}

function assert(condition, label) {
  if (!condition) throw new Error(`Clean-clone assertion failed: ${label}`);
}
