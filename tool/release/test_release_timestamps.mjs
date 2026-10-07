import assert from 'node:assert/strict';
import { execFileSync } from 'node:child_process';
import { mkdir, mkdtemp, readFile, rm, stat, utimes, writeFile } from 'node:fs/promises';
import path from 'node:path';
import test from 'node:test';
import { gzipSync } from 'node:zlib';

import { collectFiles } from './bundle_helpers.mjs';

const fixtureParent = path.resolve('.dart_tool');
const engineRevision = 'b'.repeat(40);
const epoch = 946684800;
const portfolio = {
  content_version: '1.0.0',
  site: { title: 'Example portfolio', locales: ['en'] },
  profile: {
    name: 'Example',
    role: 'Engineer',
    display_name: {
      primary: 'Example',
      accent: 'Portfolio',
      navigation: 'Example',
      accessible: 'Example portfolio',
    },
    email: 'contact@example.com',
    since: '2020',
    location: 'Remote',
    headline: 'Building software',
    focus: ['Testing', 'Shipping', 'Maintaining'],
  },
};
const translations = {
  home_section: {
    based_in: 'Based in',
    working_since: 'Working since',
    focus: 'Focus',
    email: 'Email',
    view_work: 'View work',
  },
  accessibility: { loading_portfolio: 'Loading', load_failure: 'Failed', retry: 'Retry' },
};

async function fixture(context, content = 'AAAA') {
  await mkdir(fixtureParent, { recursive: true });
  const root = await mkdtemp(path.join(fixtureParent, 'cache-validators-'));
  context.after(() => rm(root, { recursive: true, force: true }));
  const web = path.join(root, 'web');
  const files = {
    'index.html':
      '<html><head><base href="/"></head><body><!-- bootstrap-content:start --><!-- bootstrap-content:end --><!-- static-document:start --><!-- static-document:end --></body></html>',
    'flutter_bootstrap.js': JSON.stringify({
      engineRevision,
      mainWasmPath: 'main.dart.wasm',
      jsSupportRuntimePath: 'main.dart.mjs',
      mainJsPath: 'main.dart.js',
    }),
    'main.dart.wasm': content,
    'main.dart.mjs': 'runtime',
    'main.dart.js': 'fallback',
    'version.json': '{}',
    'assets/NOTICES': 'License notice\n',
    'assets/assets/content/portfolio.json': JSON.stringify(portfolio),
    'assets/assets/content/data.json': JSON.stringify({ text: content.repeat(400) }),
    'assets/assets/i18n/en.json': JSON.stringify(translations),
    'assets/assets/fonts/example.ttf': content,
    'assets/assets/images/example.png': content,
    'canvaskit/skwasm.wasm': 'renderer',
  };
  for (const [relative, bytes] of Object.entries(files)) {
    const file = path.join(web, relative);
    await mkdir(path.dirname(file), { recursive: true });
    await writeFile(file, bytes);
    await utimes(file, epoch, epoch);
  }
  return web;
}

function prepare(web, commit = 'a'.repeat(40)) {
  execFileSync(process.execPath, ['tool/release/prepare_web_release.mjs'], {
    env: { ...process.env, WEB_ROOT: web, GITHUB_SHA: commit, SOURCE_DATE_EPOCH: String(epoch) },
    stdio: ['ignore', 'pipe', 'pipe'],
  });
}

async function timestamps(web) {
  const result = {};
  for (const file of (await collectFiles(web)).sort()) {
    result[path.relative(web, file)] = (await stat(file)).mtimeMs;
  }
  return result;
}

function archive(web) {
  const version = execFileSync('tar', ['--version'], { encoding: 'utf8' });
  const metadata = version.includes('GNU tar')
    ? ['--sort=name', '--format=gnu', '--owner=0', '--group=0', '--numeric-owner']
    : [
        '--format=ustar',
        '--uid=0',
        '--gid=0',
        '--uname=',
        '--gname=',
        '--no-xattrs',
        '--no-acls',
        '--no-fflags',
      ];
  const bytes = execFileSync('tar', [...metadata, '-C', path.dirname(web), '-cf', '-', 'web']);
  return gzipSync(bytes, { level: 9 });
}

test('same-length release edits change validators for stable paths and compressed assets', async (context) => {
  const first = await fixture(context);
  const second = await fixture(context, 'BBBB');
  prepare(first);
  prepare(second, 'c'.repeat(40));
  for (const relative of [
    'index.html',
    'flutter_bootstrap.js',
    'version.json',
    'assets/assets/content/data.json',
    'assets/assets/content/data.json.gz',
    'assets/assets/fonts/example.ttf',
    'assets/assets/images/example.png',
  ]) {
    const before = await stat(path.join(first, relative));
    const after = await stat(path.join(second, relative));
    assert.equal(before.size, after.size, `${relative} fixture must retain its byte length`);
    assert.notEqual(
      before.mtimeMs,
      after.mtimeMs,
      `${relative} must change Last-Modified and ETag`,
    );
  }
});

test('repeated preparation and packaging preserve bytes and content timestamps', async (context) => {
  const web = await fixture(context);
  prepare(web);
  const before = await timestamps(web);
  const bytes = archive(web);
  for (const file of await collectFiles(web)) await utimes(file, epoch + 100, epoch + 100);
  await utimes(path.join(web, 'assets'), epoch + 200, epoch + 200);
  prepare(web);
  assert.deepEqual(await timestamps(web), before);
  assert.deepEqual(archive(web), bytes);
  const rebuilt = await fixture(context);
  prepare(rebuilt);
  assert.deepEqual(await timestamps(rebuilt), before);
  assert.deepEqual(archive(rebuilt), bytes);
  for (const directory of ['', 'assets', 'assets/assets/content']) {
    assert.equal((await stat(path.join(web, directory))).mtimeMs, epoch * 1000);
  }
  for (const mtime of Object.values(before)) {
    assert.equal(mtime % 1000, 0);
    assert.ok(mtime > 0 && mtime <= 1073741824000, 'Last-Modified must stay in the past');
  }
});

test('release archive retains file timestamps and CI preserves the Docker copy path', async (context) => {
  const web = await fixture(context);
  prepare(web);
  const tarball = path.join(path.dirname(web), 'web-release.tar.gz');
  await writeFile(tarball, archive(web));
  const extracted = path.join(path.dirname(web), 'extracted');
  await mkdir(extracted);
  execFileSync('tar', ['-xzf', tarball, '-C', extracted]);
  assert.deepEqual(await timestamps(path.join(extracted, 'web')), await timestamps(web));
  for (const directory of ['', 'assets', 'assets/assets/content']) {
    assert.equal((await stat(path.join(extracted, 'web', directory))).mtimeMs, epoch * 1000);
  }
  const workflow = await readFile('.github/workflows/ci.yml', 'utf8');
  const command = workflow.split('\n').find((line) => line.includes('tar --sort=name'));
  assert.ok(command, 'CI must package the prepared release');
  assert.doesNotMatch(command, /--mtime|--clamp-mtime/);
  assert.match(command, /--format=gnu --owner=0 --group=0 --numeric-owner/);
  assert.match(command, /gzip -n -9/);
  assert.match(
    await readFile('Dockerfile', 'utf8'),
    /^COPY build\/web \/usr\/share\/nginx\/html$/m,
  );
});
