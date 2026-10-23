import assert from 'node:assert/strict';
import { execFileSync, spawnSync } from 'node:child_process';
import { createHash } from 'node:crypto';
import { constants } from 'node:fs';
import {
  access,
  chmod,
  mkdir,
  mkdtemp,
  readFile,
  realpath,
  rm,
  symlink,
  writeFile,
} from 'node:fs/promises';
import os from 'node:os';
import path from 'node:path';
import test from 'node:test';
import { fileURLToPath } from 'node:url';

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '../..');
const launcher = await readFile(path.join(root, 'tool/runtime/run_visual_in_docker.sh'));
const manifest = JSON.parse(await readFile(path.join(root, 'package.json'), 'utf8'));
const lock = JSON.parse(await readFile(path.join(root, 'package-lock.json'), 'utf8'));
const requested = manifest.devDependencies['@playwright/test'];
const lockedRequest = lock.packages[''].devDependencies['@playwright/test'];
const version = lock.packages['node_modules/@playwright/test'].version;
const otherVersion = manifest.devDependencies.eslint;
const commands = Object.fromEntries(
  await Promise.all(
    ['dirname', 'python3', 'realpath', 'id'].map(async (name) => [name, await executable(name)]),
  ),
);
const user = `${execFileSync(commands.id, ['-u'], { encoding: 'utf8', env: {} }).trim()}:${execFileSync(commands.id, ['-g'], { encoding: 'utf8', env: {} }).trim()}`;
const shells = [...new Set([await realpath('/bin/bash'), await executable('bash')])];
const runtimes = await Promise.all(
  shells.map(async (shell) => ({
    executable: shell,
    version: execFileSync(shell, ['--version'], { encoding: 'utf8', env: {} }).split('\n')[0],
    sha256: createHash('sha256')
      .update(await readFile(shell))
      .digest('hex'),
  })),
);
const artifact = 'checkout release artifact';

/** @typedef {{ requested?: string, lockedRequest?: string, lockedVersion?: string, installedVersion?: string, missingInstall?: boolean, missingBuild?: boolean }} FixtureOptions */
/** @typedef {{ args?: string[], cwd?: string, label?: string, dockerExit?: number, moduleMount?: string }} LaunchOptions */

async function executable(name) {
  for (const directory of (process.env.PATH ?? '').split(path.delimiter).filter(Boolean)) {
    const candidate = path.join(directory, name);
    try {
      await access(candidate, constants.X_OK);
      return await realpath(candidate);
    } catch (error) {
      if (!['ENOENT', 'EACCES', 'ENOTDIR'].includes(error.code)) throw error;
    }
  }
  throw new Error(`Required fixture command is unavailable: ${name}`);
}

async function writeJson(target, value) {
  await mkdir(path.dirname(target), { recursive: true });
  await writeFile(target, JSON.stringify(value));
}

/** @param {FixtureOptions} [options] */
async function writePackages(directory, options = {}) {
  await writeJson(path.join(directory, 'package.json'), {
    devDependencies: { '@playwright/test': options.requested ?? requested },
  });
  await writeJson(path.join(directory, 'package-lock.json'), {
    packages: {
      '': { devDependencies: { '@playwright/test': options.lockedRequest ?? lockedRequest } },
      'node_modules/@playwright/test': { version: options.lockedVersion ?? version },
    },
  });
  if (options.missingInstall) return;
  await writeJson(path.join(directory, 'node_modules/@playwright/test/package.json'), {
    version: options.installedVersion ?? version,
  });
}

async function writeArtifact(directory, content) {
  await mkdir(path.join(directory, 'build/web'), { recursive: true });
  await writeFile(path.join(directory, 'build/web/index.html'), content);
}

/** @param {FixtureOptions} [options] */
async function fixture(t, runtime, options = {}) {
  const base = await realpath(await mkdtemp(path.join(os.tmpdir(), 'visual launcher ')));
  t.after(() => rm(base, { recursive: true }));
  const checkout = path.join(base, 'checkout with spaces');
  const unrelated = path.join(base, 'unrelated cwd');
  const bin = path.join(base, 'fake commands');
  const script = path.join(checkout, 'tool/runtime/run_visual_in_docker.sh');
  await mkdir(path.dirname(script), { recursive: true });
  await mkdir(bin);
  await writeFile(script, launcher);
  await writePackages(checkout, options);
  if (!options.missingBuild) await writeArtifact(checkout, artifact);
  await writeArtifact(unrelated, 'unrelated artifact');
  // Valid decoys let a wrong repository root reach behavioral assertions.
  await writePackages(path.join(checkout, 'tool'));
  await writeArtifact(path.join(checkout, 'tool'), 'neighbor tool artifact');
  const docker = path.join(bin, 'docker');
  await writeFile(
    docker,
    '#!/bin/bash\nset -euo pipefail\nprintf \'%s\\0\' "$PWD" "$(<build/web/index.html)" "$@" >> "$VISUAL_DOCKER_TRACE"\nexit "${VISUAL_DOCKER_EXIT:-0}"\n',
  );
  await chmod(docker, 0o755);
  for (const [name, source] of Object.entries(commands)) {
    await symlink(source, path.join(bin, name));
  }
  return { base, checkout, unrelated, bin, script, runtime };
}

/** @param {LaunchOptions} [options] */
async function invoke(f, options = {}) {
  const trace = path.join(f.base, `${options.label ?? 'docker'}.argv`);
  const result = spawnSync(f.runtime.executable, [f.script, ...(options.args ?? [])], {
    cwd: options.cwd ?? f.checkout,
    env: {
      PATH: f.bin,
      VISUAL_DOCKER_TRACE: trace,
      VISUAL_DOCKER_EXIT: String(options.dockerExit ?? 0),
    },
    encoding: 'utf8',
    timeout: 10000,
  });
  assert.ifError(result.error);
  const calls = await readFile(trace, 'utf8').catch((error) => {
    if (error.code !== 'ENOENT') throw error;
    return null;
  });
  return { ...result, call: calls === null ? null : calls.split('\0').slice(0, -1) };
}

/** @param {LaunchOptions} [options] */
function dockerArgs(f, options = {}) {
  const mounts = ['--mount', `type=bind,source=${f.checkout},target=/workspace`];
  if (options.moduleMount) mounts.push('--mount', options.moduleMount);
  return [
    'run',
    '--rm',
    '--init',
    '--ipc=host',
    '--network',
    'none',
    '--cpus=2',
    '--user',
    user,
    '-e',
    'HOME=/tmp',
    ...mounts,
    '--workdir',
    '/workspace',
    `mcr.microsoft.com/playwright:v${version}-noble`,
    'node',
    'node_modules/@playwright/test/cli.js',
    'test',
    'tests/e2e/visual.spec.ts',
    ...(options.args ?? []),
  ];
}

/** @param {LaunchOptions} [options] */
function assertLaunch(result, f, options = {}) {
  assert.equal(result.status, options.dockerExit ?? 0, result.stderr);
  assert.ok(result.call, 'the fake Docker executable must be reached');
  assert.equal(result.call[0], f.checkout, 'launcher must select its checkout root');
  assert.equal(result.call[1], artifact, 'launcher must select its checkout artifact');
  assert.deepEqual(result.call.slice(2), dockerArgs(f, options));
}

function assertRejected(result, status, message) {
  assert.equal(result.status, status, result.stderr);
  assert.match(result.stderr, message);
  assert.equal(result.call, null, 'invalid input must not reach Docker');
}

for (const runtime of runtimes) {
  console.log(`Launcher runtime: ${JSON.stringify(runtime)}`);
  test(`${runtime.executable}: root and unrelated working directories select the same checkout, artifact and mounts`, async (t) => {
    const f = await fixture(t, runtime);
    const fromRoot = await invoke(f, { label: 'root' });
    const fromElsewhere = await invoke(f, { cwd: f.unrelated, label: 'elsewhere' });
    assertLaunch(fromRoot, f);
    assertLaunch(fromElsewhere, f);
    assert.deepEqual(fromElsewhere.call, fromRoot.call);
  });

  test(`${runtime.executable}: Docker is CPU-capped and retains the single-worker Playwright configuration`, async (t) => {
    const config = await readFile(path.join(root, 'playwright.config.ts'), 'utf8');
    assert.match(config, /^\s*workers:\s*1,/m);
    const result = await invoke(await fixture(t, runtime));
    assert.equal(result.status, 0, result.stderr);
    assert.ok(result.call, 'the fake Docker executable must be reached');
    assert.equal(result.call.filter((arg) => arg === '--cpus=2').length, 1);
    assert.equal(
      result.call.some((arg) => arg.startsWith('--workers')),
      false,
    );
  });

  test(`${runtime.executable}: update-snapshots is forwarded exactly once with the normal Docker contract`, async (t) => {
    const f = await fixture(t, runtime);
    const args = ['--update-snapshots'];
    const result = await invoke(f, { args });
    assertLaunch(result, f, { args });
    assert.equal(result.call.filter((arg) => arg === '--update-snapshots').length, 1);
  });

  test(`${runtime.executable}: a missing checkout build rejects valid neighboring and unrelated builds before Docker`, async (t) => {
    const f = await fixture(t, runtime, { missingBuild: true });
    const result = await invoke(f, { cwd: f.unrelated });
    assertRejected(result, 1, /build\/web is missing/);
  });

  test(`${runtime.executable}: a missing checkout installation rejects a valid neighboring installation before Docker`, async (t) => {
    const result = await invoke(await fixture(t, runtime, { missingInstall: true }));
    assertRejected(result, 1, /node_modules\/@playwright\/test is missing/);
  });

  /** @type {[string, FixtureOptions][]} */
  const mismatches = [
    ['manifest request', { requested: version }],
    ['lockfile request', { lockedRequest: version }],
    ['lockfile version', { lockedVersion: otherVersion }],
    ['installed version', { installedVersion: otherVersion }],
  ];
  for (const [label, options] of mismatches) {
    test(`${runtime.executable}: a mismatched ${label} rejects before Docker`, async (t) => {
      const result = await invoke(await fixture(t, runtime, options));
      assertRejected(result, 1, /Playwright package, lockfile, and installation disagree/);
    });
  }

  for (const args of [
    ['--unknown'],
    ['--workers=2'],
    ['--update-snapshots', '--unknown'],
    ['--update-snapshots', '--update-snapshots'],
    ['tests/e2e/visual.spec.ts'],
  ]) {
    test(`${runtime.executable}: invalid arguments ${JSON.stringify(args)} reject before Docker`, async (t) => {
      const result = await invoke(await fixture(t, runtime), { args });
      assertRejected(result, 2, /Usage: bash tool\/runtime\/run_visual_in_docker\.sh/);
    });
  }

  for (const kind of ['relative', 'absolute']) {
    test(`${runtime.executable}: ${kind} node_modules symlinks retain the resolved readonly mount`, async (t) => {
      const f = await fixture(t, runtime, { missingInstall: true });
      const modules = path.join(f.base, 'shared modules');
      await writeJson(path.join(modules, '@playwright/test/package.json'), { version });
      const link = kind === 'relative' ? path.relative(f.checkout, modules) : modules;
      await symlink(link, path.join(f.checkout, 'node_modules'), 'dir');
      const target = path.resolve('/workspace', link);
      const moduleMount = `type=bind,source=${await realpath(modules)},target=${target},readonly`;
      assertLaunch(await invoke(f), f, { moduleMount });
    });
  }

  test(`${runtime.executable}: a Docker command failure is preserved without a retry`, async (t) => {
    const f = await fixture(t, runtime);
    assertLaunch(await invoke(f, { dockerExit: 23 }), f, { dockerExit: 23 });
  });
}
