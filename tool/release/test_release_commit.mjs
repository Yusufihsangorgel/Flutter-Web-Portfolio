import assert from 'node:assert/strict';
import { spawnSync } from 'node:child_process';
import { chmod, mkdir, mkdtemp, readFile, realpath, rm, writeFile } from 'node:fs/promises';
import os from 'node:os';
import path from 'node:path';
import test from 'node:test';
import { fileURLToPath } from 'node:url';

import { resolveReleaseCommit } from './bundle_helpers.mjs';
import { checkMetadata, verifyReleaseDocument } from './verify_document.mjs';

const checkoutCommit = '6d027707aaa95b6dc57b6f89dcbd42eaca7f1995';
const otherCommit = 'f'.repeat(40);
const variables = ['GITHUB_SHA', 'VERCEL_GIT_COMMIT_SHA', 'COMMIT_REF', 'CF_PAGES_COMMIT_SHA'];
const portfolio = { content_version: 'technical-release' };
const version = {
  commit: checkoutCommit,
  content_version: portfolio.content_version,
  built_at: '2026-10-25T00:00:00.000Z',
};
const mismatchIssue = 'version.json commit does not match the expected release commit';
const verifierUrl = new URL('./verify_web_build.mjs', import.meta.url);
const noGit = () => {
  throw new Error('technical fixture has no checkout');
};

for (const name of variables) {
  test(`${name}: matching provider and checkout revisions agree`, () => {
    let reads = 0;
    assert.equal(
      resolveReleaseCommit({ [name]: checkoutCommit }, () => {
        reads += 1;
        return checkoutCommit;
      }),
      checkoutCommit,
    );
    assert.equal(reads, 1, 'provider builds must check an available checkout');
  });

  test(`${name}: a different valid provider revision must not bypass the checkout`, () => {
    assert.throws(
      () => resolveReleaseCommit({ [name]: otherCommit }, () => checkoutCommit),
      /release commit does not match the checkout commit/,
    );
  });

  test(`${name}: Gitless hosted builds retain their provider revision`, () => {
    assert.equal(resolveReleaseCommit({ [name]: checkoutCommit }, noGit), checkoutCommit);
  });
}

for (let index = 0; index < variables.length; index += 1) {
  test(`${variables[index]} retains priority over later provider variables without Git`, () => {
    const env = Object.fromEntries(
      variables
        .slice(index)
        .map((name, position) => [name, position === 0 ? checkoutCommit : otherCommit]),
    );
    assert.equal(resolveReleaseCommit(env, noGit), checkoutCommit);
  });
}

test('only the selected provider revision is compared with Git', () => {
  assert.equal(
    resolveReleaseCommit(
      { GITHUB_SHA: checkoutCommit, COMMIT_REF: otherCommit },
      () => checkoutCommit,
    ),
    checkoutCommit,
  );
});

test('an empty higher-priority variable does not hide a selected mismatch', () => {
  assert.throws(
    () =>
      resolveReleaseCommit(
        { GITHUB_SHA: '', VERCEL_GIT_COMMIT_SHA: otherCommit },
        () => checkoutCommit,
      ),
    /release commit does not match the checkout commit/,
  );
});

test('no provider revision falls back to the checkout exactly once', () => {
  let reads = 0;
  assert.equal(
    resolveReleaseCommit({}, () => {
      reads += 1;
      return checkoutCommit;
    }),
    checkoutCommit,
  );
  assert.equal(reads, 1);
});

test('empty provider variables fall back to Git', () => {
  assert.equal(
    resolveReleaseCommit(
      Object.fromEntries(variables.map((name) => [name, ''])),
      () => checkoutCommit,
    ),
    checkoutCommit,
  );
});

for (const env of [{}, Object.fromEntries(variables.map((name) => [name, '']))]) {
  test(`no checkout and ${Object.keys(env).length ? 'empty' : 'absent'} provider revisions fail explicitly`, () => {
    assert.throws(() => resolveReleaseCommit(env, noGit), /needs the built commit/);
  });
}

test('the resolver preserves raw values; metadata retains its lowercase 40-hex format contract', () => {
  assert.deepEqual(checkMetadata(version, portfolio), []);
  for (const commit of ['', 'a'.repeat(39), 'a'.repeat(41), 'A'.repeat(40), 'g'.repeat(40)]) {
    assert.equal(
      resolveReleaseCommit({ GITHUB_SHA: commit || undefined }, commit ? noGit : () => ''),
      commit,
    );
    assert.ok(
      checkMetadata({ ...version, commit }, portfolio).includes('version.json commit is invalid'),
    );
  }
});

test('metadata compares a well-formed artifact revision with its expected release revision', () => {
  assert.deepEqual(checkMetadata(version, portfolio, checkoutCommit), []);
  assert.deepEqual(checkMetadata(version, portfolio, otherCommit), [mismatchIssue]);
  assert.deepEqual(checkMetadata({ ...version, content_version: 'stale' }, portfolio), [
    'version.json content_version is stale',
  ]);
  assert.deepEqual(checkMetadata({ ...version, built_at: 'invalid' }, portfolio), [
    'version.json built_at is invalid',
  ]);
});

async function writeTree(root, files) {
  for (const [relative, bytes] of Object.entries(files)) {
    const target = path.join(root, relative);
    await mkdir(path.dirname(target), { recursive: true });
    await writeFile(target, bytes);
  }
}

async function fixture(t, output = 'build/web') {
  const root = await realpath(await mkdtemp(path.join(os.tmpdir(), 'release-commit-')));
  await writeFile(path.join(root, '.owned'), 'neutral revision fixture');
  t.after(async () => {
    assert.equal(await realpath(root), root);
    assert.equal(path.dirname(root), await realpath(os.tmpdir()));
    assert.ok(path.basename(root).startsWith('release-commit-'));
    assert.equal(await readFile(path.join(root, '.owned'), 'utf8'), 'neutral revision fixture');
    await rm(root, { recursive: true });
  });
  await writeTree(root, {
    'assets/content/portfolio.json': JSON.stringify({
      ...portfolio,
      site: { social_image: '/card.png', locales: [], resume_enabled: false },
    }),
    'tool/quality/toolchain.json': JSON.stringify({ flutterEngineRevision: checkoutCommit }),
    [`${output}/version.json`]: JSON.stringify(version),
    'owned-bin/git': `#!${process.execPath}
import { appendFileSync } from 'node:fs';
appendFileSync(process.env.GIT_TRACE_FILE, JSON.stringify({ cwd: process.cwd(), argv: process.argv.slice(2) }) + '\\n');
if (process.env.FIXTURE_GIT_EXIT === '1') process.exit(1);
console.log(process.env.FIXTURE_GIT_COMMIT);
`,
  });
  await chmod(path.join(root, 'owned-bin/git'), 0o755);
  return { root, output };
}

/** @param {{root: string, output: string}} f @param {{ providerCommit?: string, checkout?: string, noGit?: boolean, deploy?: boolean }} [options] */
async function invokeVerifier(f, options = {}) {
  const trace = path.join(f.root, 'git.jsonl');
  /** @type {NodeJS.ProcessEnv} */
  const env = {
    PATH: path.join(f.root, 'owned-bin'),
    WEB_ROOT: f.output,
    GIT_TRACE_FILE: trace,
    FIXTURE_GIT_COMMIT: options.checkout ?? checkoutCommit,
    FIXTURE_GIT_EXIT: options.noGit ? '1' : '0',
    PROVIDER_TRACE: path.join(f.root, 'provider.jsonl'),
  };
  if (options.providerCommit !== undefined) env.GITHUB_SHA = options.providerCommit;
  const args = options.deploy
    ? [path.join(f.root, 'tool/release/deploy_portfolio.mjs'), 'netlify', '--skip-build']
    : [fileURLToPath(verifierUrl)];
  const result = spawnSync(process.execPath, args, {
    cwd: f.root,
    env,
    encoding: 'utf8',
    shell: false,
    timeout: 10000,
  });
  assert.ifError(result.error);
  return {
    ...result,
    gitCalls: await readFile(trace, 'utf8').catch((error) => {
      if (error.code !== 'ENOENT') throw error;
      return '';
    }),
  };
}

function assertVerifierReached(result) {
  assert.equal(result.status, 1, result.stderr);
  assert.match(result.stderr, /Web build verification failed:/);
  assert.match(result.stderr, /index.html is missing/);
  assert.doesNotMatch(result.stderr, /ERR_MODULE_NOT_FOUND|SyntaxError|ReferenceError/);
}

function assertGitCall(result, f) {
  assert.deepEqual(result.gitCalls.trim().split('\n').map((line) => JSON.parse(line)), [{ cwd: f.root, argv: ['rev-parse', 'HEAD'] }]);
}

test('the release-document verifier checks the expected commit without changing unpinned callers', async (t) => {
  const f = await fixture(t);
  const releaseRoot = path.join(f.root, f.output);
  assert.deepEqual(await verifyReleaseDocument(releaseRoot, portfolio, []), ['index.html is missing']);
  assert.deepEqual(await verifyReleaseDocument(releaseRoot, portfolio, [], checkoutCommit), ['index.html is missing']);
  assert.deepEqual(await verifyReleaseDocument(releaseRoot, portfolio, [], otherCommit), ['index.html is missing', mismatchIssue]);
});

for (const output of ['build/web', 'custom-output']) {
  test(`the actual bundle verifier rejects a wrong version commit in ${output}`, async (t) => {
    const f = await fixture(t, output);
    await writeFile(path.join(f.root, output, 'version.json'), JSON.stringify({ ...version, commit: otherCommit }));
    const result = await invokeVerifier(f, { providerCommit: checkoutCommit });
    assertVerifierReached(result);
    assert.ok(result.stderr.includes(mismatchIssue), 'the production verifier must compare version.json, not just its format');
    assertGitCall(result, f);
  });
}

test('the actual bundle verifier derives its expected commit from Git without provider variables', async (t) => {
  const f = await fixture(t);
  const result = await invokeVerifier(f);
  assertVerifierReached(result);
  assert.ok(!result.stderr.includes(mismatchIssue));
  assertGitCall(result, f);
});

test('the actual bundle verifier reports a Git-only artifact commit mismatch', async (t) => {
  const f = await fixture(t);
  await writeFile(
    path.join(f.root, f.output, 'version.json'),
    JSON.stringify({ ...version, commit: otherCommit }),
  );
  const result = await invokeVerifier(f);
  assertVerifierReached(result);
  assert.ok(
    result.stderr.includes(mismatchIssue),
    'the production verifier must compare version.json with the Git-derived commit',
  );
  assertGitCall(result, f);
});

test('standalone custom WEB_ROOT verification retains Gitless provider support', async (t) => {
  const f = await fixture(t, 'custom-output');
  const result = await invokeVerifier(f, { providerCommit: checkoutCommit, noGit: true });
  assertVerifierReached(result);
  assert.ok(!result.stderr.includes(mismatchIssue));
  assertGitCall(result, f);
});

test('skip-build deployment exercises the actual verifier commit comparison before a provider can run', async (t) => {
  const f = await fixture(t);
  await writeTree(f.root, {
    'tool/release/deploy_portfolio.mjs': await readFile(new URL('./deploy_portfolio.mjs', import.meta.url)),
    'tool/shared/cli_safety.mjs': await readFile(new URL('../shared/cli_safety.mjs', import.meta.url)),
    'tool/release/verify_web_build.mjs': `import ${JSON.stringify(verifierUrl.href)};\n`,
    'build/web/index.html': 'neutral incomplete release document',
    'build/web/version.json': JSON.stringify({ ...version, commit: otherCommit }),
    'owned-bin/netlify': `#!${process.execPath}\nimport { appendFileSync } from 'node:fs';\nappendFileSync(process.env.PROVIDER_TRACE, 'provider reached');\n`,
  });
  await chmod(path.join(f.root, 'owned-bin/netlify'), 0o755);
  const result = await invokeVerifier(f, { providerCommit: checkoutCommit, deploy: true });
  assert.equal(result.status, 1, result.stderr);
  assert.match(result.stderr, /Web build verification failed:/);
  assert.ok(result.stderr.includes(mismatchIssue), 'skip-build must check the artifact revision through the real verifier');
  assertGitCall(result, f);
  await assert.rejects(readFile(path.join(f.root, 'provider.jsonl')), { code: 'ENOENT' });
});
