import assert from 'node:assert/strict';
import { spawnSync } from 'node:child_process';
import { chmod, mkdir, mkdtemp, readFile, realpath, rm, writeFile } from 'node:fs/promises';
import os from 'node:os';
import path from 'node:path';
import test from 'node:test';

const deploySource = await readFile(new URL('./deploy_portfolio.mjs', import.meta.url));
const safetySource = await readFile(new URL('../shared/cli_safety.mjs', import.meta.url));
const artifact = 'neutral packaged release';
const providers = [
  {
    name: 'firebase',
    options: ['--project', 'release-fixture'],
    command: 'firebase',
    args: ['deploy', '--only', 'hosting', '--project', 'release-fixture'],
  },
  {
    name: 'netlify',
    options: [],
    command: 'netlify',
    args: ['deploy', '--prod', '--dir', 'build/web'],
  },
  {
    name: 'cloudflare',
    options: ['--project', 'release-fixture'],
    command: 'wrangler',
    args: ['pages', 'deploy', 'build/web', '--project-name', 'release-fixture'],
  },
  {
    name: 'docker',
    options: ['--image', 'release-fixture:test'],
    command: 'docker',
    args: ['build', '--tag', 'release-fixture:test', '.'],
  },
  { name: 'vercel', options: [], command: 'vercel', args: ['deploy', '--prod'] },
];
const stub = `#!${process.execPath}
import { appendFileSync, readFileSync } from 'node:fs';
import path from 'node:path';
const command = path.basename(process.argv[1], '.mjs');
const stage = ({ build_portfolio: 'build', verify_web_build: 'verify' })[command] ?? command;
const webRoot = path.resolve(process.env.WEB_ROOT ?? 'build/web');
appendFileSync(process.env.RELEASE_TRACE, JSON.stringify({
  stage, cwd: process.cwd(), script: process.argv[1], argv: process.argv.slice(2),
  resolvedWebRoot: webRoot,
  artifact: stage === 'vercel' ? null : readFileSync('build/web/index.html', 'utf8'),
  verifiedArtifact: stage === 'verify' ? readFileSync(path.join(webRoot, 'index.html'), 'utf8') : null,
}) + '\\n');
process.exit(Number(process.env[stage === 'build' ? 'BUILD_EXIT' : stage === 'verify' ? 'VERIFY_EXIT' : 'PROVIDER_EXIT'] ?? 0));
`;

async function writeTree(root, files) {
  for (const [relative, bytes] of Object.entries(files)) {
    const target = path.join(root, relative);
    await mkdir(path.dirname(target), { recursive: true });
    await writeFile(target, bytes);
  }
}

async function fixture(t, { localBuild = true } = {}) {
  const base = await realpath(await mkdtemp(path.join(os.tmpdir(), 'deploy-release-root-')));
  await writeFile(path.join(base, '.owned'), 'neutral deployment fixture');
  t.after(async () => {
    assert.equal(await realpath(base), base);
    assert.equal(path.dirname(base), await realpath(os.tmpdir()));
    assert.ok(path.basename(base).startsWith('deploy-release-root-'));
    assert.equal(await readFile(path.join(base, '.owned'), 'utf8'), 'neutral deployment fixture');
    await rm(base, { recursive: true });
  });
  const checkout = path.join(base, 'checkout with spaces');
  const elsewhere = path.join(base, 'caller cwd');
  const bin = path.join(base, 'owned commands');
  await mkdir(bin);
  await writeTree(checkout, {
    'tool/release/deploy_portfolio.mjs': deploySource,
    'tool/shared/cli_safety.mjs': safetySource,
    'tool/release/build_portfolio.mjs': stub,
    'tool/release/verify_web_build.mjs': stub,
    ...(localBuild ? { 'build/web/index.html': artifact } : {}),
    'index.html': 'neutral checkout-root decoy',
    'alternate-output/index.html': 'neutral alternate release',
  });
  await writeTree(elsewhere, { 'build/web/index.html': 'neutral caller decoy' });
  for (const { command } of providers) {
    const target = path.join(bin, command);
    await writeFile(target, stub);
    await chmod(target, 0o755);
  }
  return { base, checkout, elsewhere, bin };
}

/** @param {any} f @param {typeof providers[number]} provider @param {{ webRoot?: string, skipBuild?: boolean, buildExit?: number, verifyExit?: number, providerExit?: number, options?: string[] }} [options] */
async function invoke(f, provider, options = {}) {
  const trace = path.join(f.base, 'events.jsonl');
  /** @type {NodeJS.ProcessEnv} */
  const env = {
    PATH: f.bin,
    RELEASE_TRACE: trace,
    BUILD_EXIT: String(options.buildExit ?? 0),
    VERIFY_EXIT: String(options.verifyExit ?? 0),
    PROVIDER_EXIT: String(options.providerExit ?? 0),
  };
  if (options.webRoot !== undefined) env.WEB_ROOT = options.webRoot;
  const result = spawnSync(
    process.execPath,
    [
      path.join(f.checkout, 'tool/release/deploy_portfolio.mjs'),
      provider.name,
      ...provider.options,
      ...(options.options ?? []),
      ...(options.skipBuild ? ['--skip-build'] : []),
    ],
    { cwd: f.elsewhere, env, encoding: 'utf8', shell: false, timeout: 10000 },
  );
  assert.ifError(result.error);
  const recorded = await readFile(trace, 'utf8').catch((error) => {
    if (error.code !== 'ENOENT') throw error;
    return '';
  });
  return {
    ...result,
    events: recorded
      .trim()
      .split('\n')
      .filter(Boolean)
      .map((line) => JSON.parse(line)),
  };
}

function assertEvents(result, f, stages, providerArgs) {
  assert.deepEqual(
    result.events.map((event) => event.stage),
    stages,
  );
  for (const event of result.events) {
    assert.equal(event.cwd, f.checkout);
    if (event.stage !== 'vercel') {
      assert.equal(event.resolvedWebRoot, path.join(f.checkout, 'build/web'));
      assert.equal(event.artifact, artifact);
      if (event.stage === 'verify') assert.equal(event.verifiedArtifact, artifact);
    }
    if (['build', 'verify'].includes(event.stage)) {
      assert.deepEqual(event.argv, []);
      assert.equal(path.dirname(event.script), path.join(f.checkout, 'tool/release'));
    } else {
      const provider = providers.find(({ command }) => command === event.stage);
      assert.equal(event.script, path.join(f.bin, provider.command));
      assert.deepEqual(event.argv, providerArgs ?? provider.args);
    }
  }
}

function assertFailure(result, message) {
  assert.equal(result.status, 1, result.stderr);
  assert.match(result.stderr, message);
  assert.doesNotMatch(result.stdout, /Run with: docker run/);
}

for (const provider of providers) {
  for (const rootKind of ['default', 'relative', 'absolute']) {
    test(`${provider.name}: ${rootKind} WEB_ROOT keeps checkout cwd and the provider build contract`, async (t) => {
      const f = await fixture(t);
      const webRoot =
        rootKind === 'default'
          ? undefined
          : rootKind === 'relative'
            ? 'build/web'
            : path.join(f.checkout, 'build/web');
      const result = await invoke(f, provider, { webRoot });
      assert.equal(result.status, 0, result.stderr);
      const stages =
        provider.name === 'vercel' ? [provider.command] : ['build', 'verify', provider.command];
      assertEvents(result, f, stages);
      assert.deepEqual(result.events.at(-1).argv, provider.args);
    });
  }

  test(`${provider.name}: provider errors do not report deployment success`, async (t) => {
    const f = await fixture(t);
    const result = await invoke(f, provider, { providerExit: 23 });
    assertFailure(result, /exited with 23/);
    assertEvents(
      result,
      f,
      provider.name === 'vercel' ? [provider.command] : ['build', 'verify', provider.command],
    );
  });

  if (provider.name === 'vercel') continue;
  for (const rootKind of ['relative alternate', 'absolute caller', 'empty']) {
    test(`${provider.name}: ${rootKind} WEB_ROOT rejects before every child side effect`, async (t) => {
      const f = await fixture(t);
      const webRoot =
        rootKind === 'relative alternate'
          ? 'alternate-output'
          : rootKind === 'absolute caller'
            ? path.join(f.elsewhere, 'build/web')
            : '';
      const result = await invoke(f, provider, { webRoot });
      assertFailure(result, /WEB_ROOT.*build\/web/);
      assert.deepEqual(result.events, [], 'conflicting roots must not build, verify or deploy');
    });
  }

  test(`${provider.name}: skip-build still verifies the packaged release`, async (t) => {
    const f = await fixture(t);
    const result = await invoke(f, provider, { skipBuild: true });
    assert.equal(result.status, 0, result.stderr);
    assertEvents(result, f, ['verify', provider.command]);
    assert.deepEqual(result.events.at(-1).argv, provider.args);
  });

  test(`${provider.name}: skip-build cannot bypass the WEB_ROOT policy`, async (t) => {
    const result = await invoke(await fixture(t), provider, {
      skipBuild: true,
      webRoot: 'alternate-output',
    });
    assertFailure(result, /WEB_ROOT.*build\/web/);
    assert.deepEqual(result.events, []);
  });

  test(`${provider.name}: a failed build prevents verification and deployment`, async (t) => {
    const f = await fixture(t);
    const result = await invoke(f, provider, { buildExit: 19 });
    assertFailure(result, /exited with 19/);
    assertEvents(result, f, ['build']);
  });

  for (const skipBuild of [false, true]) {
    test(`${provider.name}: verification failure prevents deployment (skip-build=${skipBuild})`, async (t) => {
      const f = await fixture(t);
      const result = await invoke(f, provider, { skipBuild, verifyExit: 17 });
      assertFailure(result, /exited with 17/);
      assertEvents(result, f, skipBuild ? ['verify'] : ['build', 'verify']);
    });
  }
}

test('Vercel custom WEB_ROOT reaches only its owned command without a local build', async (t) => {
  const f = await fixture(t, { localBuild: false });
  const provider = providers.find((provider) => provider.name === 'vercel');
  const result = await invoke(f, provider, { webRoot: 'alternate-output' });
  assert.equal(result.status, 0, result.stderr);
  assertEvents(result, f, ['vercel']);
  assert.equal(
    result.events[0].resolvedWebRoot,
    path.join(f.checkout, 'alternate-output'),
  );
});

test('Vercel retains its repository-owned build and rejects skip-build before any child', async (t) => {
  const result = await invoke(
    await fixture(t),
    providers.find((provider) => provider.name === 'vercel'),
    { skipBuild: true },
  );
  assertFailure(result, /Vercel owns its build.*--skip-build is not supported/);
  assert.deepEqual(result.events, []);
});

test('normalized relative WEB_ROOT and an explicit Netlify site keep their original contracts', async (t) => {
  const f = await fixture(t);
  const provider = providers.find((provider) => provider.name === 'netlify');
  const webRoot = './build/../build/web';
  const result = await invoke(f, provider, { webRoot, options: ['--site', 'release-fixture'] });
  assert.equal(result.status, 0, result.stderr);
  assertEvents(result, f, ['build', 'verify', 'netlify'], [
    ...provider.args,
    '--site',
    'release-fixture',
  ]);
  assert.deepEqual(result.events.at(-1).argv, [...provider.args, '--site', 'release-fixture']);
});
