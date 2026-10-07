import {
  cp,
  lstat,
  mkdir,
  mkdtemp,
  readFile,
  readdir,
  rename,
  rm,
  writeFile,
} from 'node:fs/promises';
import os from 'node:os';
import path from 'node:path';
import process from 'node:process';

import { rewritePackageLinks } from './package_links.mjs';
import { renderStarterReadme } from './starter_readme.mjs';

const transactionTargets = [
  'README.md',
  'CHANGELOG.md',
  'CODE_OF_CONDUCT.md',
  'SECURITY.md',
  'package.json',
  'nginx/default.conf',
  'firebase.json',
  'vercel.json',
  'netlify.toml',
  'web/_headers',
  'web/index.html',
  'web/.well-known/security.txt',
  'web/manifest.json',
  'web/robots.txt',
  'web/sitemap.xml',
  'web/llms.txt',
  'assets/content/portfolio.json',
  'assets/content/locales',
  'assets/work',
  'tool/work_sources',
  'web/assets/og/engineering-showcase.png',
  'web/assets/og/engineering-showcase.png.sha256',
  'assets/build/source_manifest.sha256',
  'build/web',
  'packages',
  'docs/readme/home-desktop.jpg',
  'tool/work_artifacts',
];

export async function initializeCanonicalRepository(context) {
  await resetLocales(context.root);
  console.log('Removed the demo owner’s translated professional copy.');
  await pruneDemoAssets(context.root);
  console.log('Removed the demo owner’s work artifacts and source captures.');
  await removeDemoArtifactRenderer(context.root);
  console.log('Removed the demo owner’s artifact renderer and package command.');
  await writeStarterChangelog(context.root);
  await writeAtomically(
    path.join(context.root, 'README.md'),
    renderStarterReadme({
      name: context.answers.name,
      site: context.answers.site,
      repository: context.initializationRepository,
    }),
  );
  await rm(path.join(context.root, 'docs', 'readme', 'home-desktop.jpg'), {
    force: true,
  });
  await rewritePackageLinks(
    context.root,
    context.originalRepository,
    context.initializationRepository,
  );
  console.log('Replaced the demo history with an identity-neutral changelog.');
  await rm(path.join(context.root, 'build', 'web'), {
    recursive: true,
    force: true,
  });
  console.log('Removed the inherited public release; a clean build is required.');
  synchronizePublicSurfaces(context);
}

async function resetLocales(root) {
  const directory = path.join(root, 'assets', 'content', 'locales');
  await rm(directory, { recursive: true, force: true });
  await mkdir(directory, { recursive: true });
  await writeFile(path.join(directory, '.gitkeep'), '');
}

async function pruneDemoAssets(root) {
  await pruneDirectory(path.join(root, 'assets', 'work'), new Set(['README.md']));
  await pruneDirectory(path.join(root, 'tool', 'work_sources'), new Set(['README.md']));
  await writeFile(
    path.join(root, 'tool', 'work_sources', 'README.md'),
    `# Work artifact sources\n\nKeep a source ledger for every project image you add to \`assets/work/\`. Record\nthe original URL or local capture, capture date, permitted use, and any crop or\ncomposition applied. Do not add evidence you cannot publicly substantiate.\n`,
  );
}

async function removeDemoArtifactRenderer(root) {
  await rm(path.join(root, 'tool', 'work_artifacts'), {
    recursive: true,
    force: true,
  });
  const packagePath = path.join(root, 'package.json');
  const packageDocument = JSON.parse(await readFile(packagePath, 'utf8'));
  for (const script of ['render:work-artifacts', 'verify:work-artifacts', 'test:work-artifacts']) {
    delete packageDocument.scripts?.[script];
  }
  await writeAtomically(packagePath, `${JSON.stringify(packageDocument, null, 2)}\n`);
}

async function writeStarterChangelog(root) {
  await writeAtomically(
    path.join(root, 'CHANGELOG.md'),
    `# Changelog

This project follows [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Changed

- Initialized a clean portfolio record and regenerated every public surface.
- Removed the template demo's professional history, artifacts, and localized claims.
`,
  );
}

async function pruneDirectory(directory, keep) {
  for (const entry of await readdir(directory, { withFileTypes: true })) {
    if (keep.has(entry.name)) continue;
    await rm(path.join(directory, entry.name), {
      recursive: entry.isDirectory(),
      force: true,
    });
  }
}

function synchronizePublicSurfaces(context) {
  const environment = {
    ...process.env,
    PORTFOLIO_GITHUB_REPOSITORY: context.initializationRepository,
  };
  for (const script of [
    ['tool', 'content', 'sync_public_content.mjs'],
    ['tool', 'assets', 'render_social_card.mjs'],
    ['tool', 'release', 'write_source_manifest.mjs'],
  ]) {
    context.run(process.execPath, [path.join(context.root, ...script)], environment);
  }
  console.log('Synchronized metadata, README record, manifest, and hosting files.');
}

export async function writeAtomically(output, contents) {
  await mkdir(path.dirname(output), { recursive: true });
  const temporary = path.join(
    path.dirname(output),
    `.${path.basename(output)}.${process.pid}.${Date.now()}.tmp`,
  );
  try {
    await writeFile(temporary, contents);
    await rename(temporary, output);
  } finally {
    await rm(temporary, { force: true });
  }
}

export async function createRepositoryTransaction(root) {
  const temporary = await mkdtemp(path.join(os.tmpdir(), 'portfolio-init-transaction-'));
  const snapshots = [];
  for (const relative of transactionTargets) {
    snapshots.push(await snapshotTarget(root, temporary, relative));
  }
  return {
    rollback: () => restoreSnapshots(snapshots),
    dispose: () => rm(temporary, { recursive: true, force: true }),
  };
}

async function snapshotTarget(root, temporary, relative) {
  const target = path.join(root, relative);
  const backup = path.join(temporary, relative);
  const existed = await pathExists(target);
  if (existed) {
    await mkdir(path.dirname(backup), { recursive: true });
    await cp(target, backup, { recursive: true, force: true });
  }
  return { target, backup, existed };
}

async function restoreSnapshots(snapshots) {
  for (const snapshot of snapshots) {
    await rm(snapshot.target, { recursive: true, force: true });
    if (!snapshot.existed) continue;
    await mkdir(path.dirname(snapshot.target), { recursive: true });
    await cp(snapshot.backup, snapshot.target, {
      recursive: true,
      force: true,
    });
  }
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
