import assert from 'node:assert/strict';
import fs from 'node:fs/promises';
import { syncBuiltinESMExports } from 'node:module';
import os from 'node:os';
import path from 'node:path';
import test from 'node:test';

import * as repository from './portfolio_init_repository.mjs';

const originals = new Map([
  ['README.md', Buffer.from([0, 17, 34, 51, 68, 85, 102, 119, 136, 153, 255])],
  ['CHANGELOG.md', Buffer.from([0, 16, 32, 48, 64, 80, 96, 112, 128])],
  ['packages/cell/block.bin', Buffer.from([0, 15, 30, 45, 60, 75, 90, 105, 120])],
  ['assets/content/locales/block.bin', Buffer.from([0, 14, 28, 42, 56, 70])],
]);
const changed = Buffer.from([255, 254, 0, 253]);
const sentinel = Buffer.from([0, 127, 128, 255]);

async function exists(file) {
  try {
    await fs.lstat(file);
    return true;
  } catch (error) {
    if (error.code === 'ENOENT') return false;
    throw error;
  }
}

function assertWithin(directory, file) {
  assert.equal(typeof file, 'string');
  const relative = path.relative(directory, file);
  assert(!path.isAbsolute(relative) && relative !== '..' && !relative.startsWith(`..${path.sep}`));
}

function controlFilesystem(t, fixture) {
  const nativeTemporary = fs.mkdtemp;
  t.mock.method(fs, 'mkdtemp', async (prefix) => {
    assert.equal(prefix, path.join(os.tmpdir(), 'portfolio-init-transaction-'));
    const backup = await nativeTemporary(path.join(fixture.temporary, path.basename(prefix)));
    fixture.backups.push(backup);
    return backup;
  });
  for (const operation of ['mkdir', 'rm', 'writeFile', 'rename', 'cp']) {
    const native = fs[operation];
    t.mock.method(fs, operation, async (...args) => {
      assertWithin(fixture.directory, args[0]);
      if (operation === 'cp' || operation === 'rename') assertWithin(fixture.directory, args[1]);
      if (
        operation === 'cp' &&
        fixture.remainingFaults > 0 &&
        args[0] === path.join(fixture.backups[0], fixture.faultRelative) &&
        args[1] === path.join(fixture.root, fixture.faultRelative)
      ) {
        assert.equal(await exists(args[1]), false, 'the real rollback removed the target');
        const readme = path.join(fixture.root, 'README.md');
        fixture.readmeAtFault = (await exists(readme)) ? await fs.readFile(readme) : null;
        fixture.remainingFaults -= 1;
        fixture.faults += 1;
        throw fixture.copyError;
      }
      return Reflect.apply(native, fs, args);
    });
  }
  syncBuiltinESMExports();
}

async function withFixture(t, runCase) {
  const directory = await fs.mkdtemp(path.join(os.tmpdir(), 'portfolio-recovery-test-'));
  const fixture = {
    directory,
    root: path.join(directory, 'repo'),
    temporary: path.join(directory, 'temporary'),
    backups: [],
    remainingFaults: 0,
    faultRelative: 'README.md',
    readmeAtFault: null,
    faults: 0,
    copyError: Object.assign(new Error('Injected restoration-copy failure'), { code: 'EIO' }),
  };
  await fs.mkdir(fixture.root);
  await fs.mkdir(fixture.temporary);
  for (const [relative, bytes] of originals) {
    const file = path.join(fixture.root, relative);
    await fs.mkdir(path.dirname(file), { recursive: true });
    await fs.writeFile(file, bytes);
  }
  await fs.writeFile(path.join(fixture.root, 'untouched.bin'), sentinel);
  await fs.writeFile(path.join(directory, 'outside.bin'), sentinel);
  // Load cp's lazy internal helpers before mocking the public filesystem bindings.
  const copyControl = path.join(directory, 'copy-control');
  await fs.cp(fixture.root, copyControl, { recursive: true });
  await fs.rm(copyControl, { recursive: true, force: true });
  controlFilesystem(t, fixture);
  try {
    await runCase(fixture);
    assert.deepEqual(await fs.readFile(path.join(fixture.root, 'untouched.bin')), sentinel);
    assert.deepEqual(await fs.readFile(path.join(directory, 'outside.bin')), sentinel);
  } finally {
    t.mock.restoreAll();
    syncBuiltinESMExports();
    await fs.rm(directory, { recursive: true, force: true });
  }
}

async function mutate(fixture) {
  for (const relative of originals.keys()) {
    await fs.writeFile(path.join(fixture.root, relative), changed);
  }
  await fs.writeFile(path.join(fixture.root, 'SECURITY.md'), changed);
  await fs.mkdir(path.join(fixture.root, 'build/web'), { recursive: true });
  await fs.writeFile(path.join(fixture.root, 'build/web/new.bin'), changed);
}

async function assertOriginalBytes(directory) {
  for (const [relative, bytes] of originals) {
    assert.deepEqual(await fs.readFile(path.join(directory, relative)), bytes, relative);
  }
}

async function assertRestored(fixture) {
  await assertOriginalBytes(fixture.root);
  assert.equal(await exists(path.join(fixture.root, 'SECURITY.md')), false);
  assert.equal(await exists(path.join(fixture.root, 'build/web')), false);
}

async function captureRollbackFailure(transaction) {
  let failure;
  await assert.rejects(transaction.rollback(), (error) => {
    failure = error;
    return true;
  });
  return failure;
}

test('failed rollback survives finally disposal and can later restore every original byte', async (t) => {
  await withFixture(t, async (fixture) => {
    const transaction = await repository.createRepositoryTransaction(fixture.root);
    const backup = fixture.backups[0];
    await mutate(fixture);
    fixture.remainingFaults = 1;
    const failure = await captureRollbackFailure(transaction);
    assert.equal(fixture.faults, 1);
    assert.equal(await exists(path.join(fixture.root, 'README.md')), false);
    await transaction.dispose();
    await transaction.dispose();
    assert.equal(await exists(backup), true, 'failed rollback must retain its recovery directory');
    await assertOriginalBytes(backup);
    assert.equal(failure.cause, fixture.copyError);
    assert(
      failure.message.includes(backup),
      'the error identifies the retained recovery directory',
    );
    assert(
      failure.message.includes(fixture.root),
      'the error identifies the restoration destination',
    );
    assert.match(failure.message, /restore|copy/i);
    await transaction.rollback();
    await assertRestored(fixture);
    await transaction.dispose();
    assert.equal(await exists(backup), false);
    assert.deepEqual(await fs.readdir(fixture.temporary), []);
  });
});

test('another failed recovery attempt does not make the backup disposable', async (t) => {
  await withFixture(t, async (fixture) => {
    const transaction = await repository.createRepositoryTransaction(fixture.root);
    await mutate(fixture);
    fixture.remainingFaults = 2;
    for (let attempt = 0; attempt < 2; attempt += 1) {
      await captureRollbackFailure(transaction);
      await transaction.dispose();
      await assertOriginalBytes(fixture.backups[0]);
    }
    assert.equal(fixture.faults, 2);
    await transaction.rollback();
    await assertRestored(fixture);
    await transaction.dispose();
    assert.deepEqual(await fs.readdir(fixture.temporary), []);
  });
});

test('the caller failure handler keeps both causes and an actionable recovery path', async (t) => {
  await withFixture(t, async (fixture) => {
    const transaction = await repository.createRepositoryTransaction(fixture.root);
    await mutate(fixture);
    fixture.remainingFaults = 1;
    const original = new Error('Injected initialization failure');
    const messages = [];
    t.mock.method(console, 'error', (message) => messages.push(message));
    let failure;
    try {
      await repository.rollbackInitialization(transaction, original);
    } catch (error) {
      failure = error;
    } finally {
      await transaction.dispose();
    }
    assert(failure instanceof AggregateError);
    assert.equal(failure.cause, original);
    assert.equal(failure.errors.length, 2);
    assert.equal(failure.errors[0], original);
    assert.equal(failure.errors[1].cause, fixture.copyError);
    assert(failure.message.includes(fixture.backups[0]));
    assert(failure.message.includes(fixture.root));
    assert.deepEqual(messages, [], 'partial restoration must not claim complete restoration');
    await assertOriginalBytes(fixture.backups[0]);
    await transaction.rollback();
    await assertRestored(fixture);
    await transaction.dispose();
    assert.deepEqual(await fs.readdir(fixture.temporary), []);
  });
});

test('complete rollback rethrows the same original error and cleans only its backup', async (t) => {
  await withFixture(t, async (fixture) => {
    const transaction = await repository.createRepositoryTransaction(fixture.root);
    await mutate(fixture);
    const original = new Error('Injected initialization failure');
    const messages = [];
    t.mock.method(console, 'error', (message) => messages.push(message));
    try {
      await assert.rejects(repository.rollbackInitialization(transaction, original), (error) => {
        assert.equal(error, original);
        return true;
      });
    } finally {
      await transaction.dispose();
    }
    await assertRestored(fixture);
    assert.deepEqual(messages, [
      'Initialization failed; restored every repository file changed by the initializer.',
    ]);
    assert.deepEqual(await fs.readdir(fixture.temporary), []);
  });
});

test('ordinary success disposal preserves current bytes and another transaction backup', async (t) => {
  await withFixture(t, async (fixture) => {
    const first = await repository.createRepositoryTransaction(fixture.root);
    const second = await repository.createRepositoryTransaction(fixture.root);
    await mutate(fixture);
    await first.dispose();
    assert.equal(await exists(fixture.backups[0]), false);
    await assertOriginalBytes(fixture.backups[1]);
    for (const relative of originals.keys()) {
      assert.deepEqual(await fs.readFile(path.join(fixture.root, relative)), changed);
    }
    assert.deepEqual(await fs.readFile(path.join(fixture.root, 'SECURITY.md')), changed);
    assert.deepEqual(await fs.readFile(path.join(fixture.root, 'build/web/new.bin')), changed);
    await second.dispose();
    assert.deepEqual(await fs.readdir(fixture.temporary), []);
  });
});

test('direct complete rollback restores bytes and initially absent targets without retaining a backup', async (t) => {
  await withFixture(t, async (fixture) => {
    const transaction = await repository.createRepositoryTransaction(fixture.root);
    await mutate(fixture);
    await transaction.rollback();
    await assertRestored(fixture);
    await transaction.dispose();
    assert.deepEqual(await fs.readdir(fixture.temporary), []);
  });
});

test('atomic custom output stays confined without creating a repository transaction', async (t) => {
  await withFixture(t, async (fixture) => {
    const output = path.join(fixture.root, 'custom/content.bin');
    await repository.writeAtomically(output, changed);
    assert.deepEqual(await fs.readFile(output), changed);
    assert.deepEqual(await fs.readdir(path.dirname(output)), ['content.bin']);
    await assertRestored(fixture);
    assert.deepEqual(fixture.backups, []);
    assert.deepEqual(await fs.readdir(fixture.temporary), []);
  });
});

test('initializer source wires the tested failure handler and keeps the custom-output early return', async () => {
  const source = await fs.readFile(new URL('./init_portfolio.mjs', import.meta.url), 'utf8');
  assert.match(source, /^ {2}rollbackInitialization,$/m);
  assert.match(
    source,
    /} catch \(error\) {\s+await rollbackInitialization\(transaction, error\);\s+} finally {\s+await transaction\.dispose\(\);\s+}/,
  );
  assert.match(
    source,
    /if \(output !== defaultOutput\) {\s+await writePortfolioDocument\(document, output\);[^}]+return;\s+}\s+const repositories/,
  );
});

test('partial rollback retains its backup after restoring README before a CHANGELOG copy fault', async (t) => {
  await withFixture(t, async (fixture) => {
    const transaction = await repository.createRepositoryTransaction(fixture.root);
    const backup = fixture.backups[0];
    await mutate(fixture);
    fixture.faultRelative = 'CHANGELOG.md';
    fixture.remainingFaults = 1;
    let failure;
    try {
      failure = await captureRollbackFailure(transaction);
    } finally {
      await transaction.dispose();
    }
    assert.equal(fixture.faults, 1);
    assert.equal(failure.cause, fixture.copyError);
    assert.deepEqual(
      fixture.readmeAtFault,
      originals.get('README.md'),
      'README was restored before the injected failure',
    );
    assert.deepEqual(
      await fs.readFile(path.join(fixture.root, 'README.md')),
      originals.get('README.md'),
    );
    assert.equal(await exists(path.join(fixture.root, 'CHANGELOG.md')), false);
    assert.deepEqual(
      await fs.readFile(path.join(fixture.root, 'packages/cell/block.bin')),
      changed,
    );
    assert.equal(
      await exists(backup),
      true,
      'finally disposal must preserve a partial rollback backup',
    );
    await assertOriginalBytes(backup);
    await transaction.rollback();
    await assertRestored(fixture);
    assert.equal(fixture.faults, 1, 'the retry must not inject another failure');
    await transaction.dispose();
    assert.equal(await exists(backup), false);
    assert.deepEqual(await fs.readdir(fixture.temporary), []);
  });
});
