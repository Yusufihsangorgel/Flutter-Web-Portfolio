import assert from 'node:assert/strict';
import { chmod, mkdir, mkdtemp, readFile, rm, writeFile } from 'node:fs/promises';
import os from 'node:os';
import path from 'node:path';
import process from 'node:process';
import { spawnSync } from 'node:child_process';
import { fileURLToPath } from 'node:url';

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '../..');
const auditFile = path.join(root, 'tool', 'audit', 'audit_repository_history.mjs');
const source = await readFile(auditFile, 'utf8');
assert.doesNotMatch(
  source,
  /\[[^\]]*['"][^'"]+['"]\]\.join\(/,
  'the audit must not build its patterns from joined string fragments',
);

const tempRoot = await mkdtemp(path.join(os.tmpdir(), 'audit-history-test-'));
const binDirectory = path.join(tempRoot, 'bin');
await mkdir(binDirectory);
const fakeGit = String.raw`#!/bin/sh
scenario="$AUDIT_SCENARIO"
case "$1" in
  rev-list|rev-parse) printf 'head\n' ;;
  show)
    case "$3" in
      --format=%s) printf 'subject\n' ;;
      "--format=%an <%ae>%n%cn <%ce>%n%B")
        if [ "$scenario" = metadata ]; then printf 'Co-Authored-By\n'; fi
        ;;
      *) exit 2 ;;
    esac
    ;;
  ls-tree)
    if [ "$scenario" = restricted-path ]; then printf '.config/settings.json\n'; fi
    if [ "$scenario" = instruction-path ]; then printf 'AGENTS.md\n'; fi
    if [ "$scenario" = clean ]; then printf '.github/workflows/ci.yml\npackages/a/.hidden/data.txt\n'; fi
    ;;
  ls-files)
    if [ "$scenario" = restricted-path ]; then printf '.config/settings.json\n'; fi
    if [ "$scenario" = instruction-path ]; then printf 'AGENTS.md\n'; fi
    if [ "$scenario" = clean ]; then printf '.github/workflows/ci.yml\npackages/a/.hidden/data.txt\n'; fi
    printf 'README.md\n'
    ;;
  grep)
    case "$*" in
      *"Co-Authored-By|Generated with"*)
        if [ "$scenario" = attribution ]; then printf 'README.md:1:Co-Authored-By\n'; exit 0; fi
        ;;
      *"TODO|FIXME|HACK|XXX"*)
        if [ "$scenario" = development ]; then printf 'tool/source.mjs:1:TODO\n'; exit 0; fi
        ;;
    esac
    exit 1
    ;;
  for-each-ref)
    if [ "$scenario" = tag ]; then printf 'tag\0v1\0Release\n\nCo-Authored-By: someone\n\036\n'; fi
    if [ "$scenario" = clean ]; then printf 'tag\0v1\0Release\n\nNotes\n\036\n'; fi
    exit 0
    ;;
  *) exit 2 ;;
esac
`;

try {
  const gitShim = path.join(binDirectory, 'git');
  await writeFile(gitShim, fakeGit);
  await chmod(gitShim, 0o755);
  /** @type {Array<[string, number, RegExp]>} */
  const cases = [
    ['clean', 0, /History audit passed: 1 commits/],
    ['metadata', 1, /metadata contains an attribution marker/],
    ['attribution', 1, /HEAD tracked source contains an attribution marker/],
    ['restricted-path', 1, /restricted path \.config\/settings\.json/],
    ['instruction-path', 1, /restricted path AGENTS\.md/],
    ['development', 1, /worktree contains unresolved development markers/],
    ['tag', 1, /annotated tag v1 contains an attribution marker/],
  ];

  for (const [scenario, expectedStatus, expectedOutput] of cases) {
    const result = spawnSync(process.execPath, [auditFile], {
      cwd: root,
      encoding: 'utf8',
      env: {
        ...process.env,
        PATH: `${binDirectory}${path.delimiter}${process.env.PATH}`,
        AUDIT_SCENARIO: scenario,
      },
    });
    const output = `${result.stdout}\n${result.stderr}`;
    assert.equal(result.status, expectedStatus, `${scenario}: ${output}`);
    assert.match(output, expectedOutput, scenario);
  }
  console.log('Repository history audit tests passed.');
} finally {
  await rm(tempRoot, { recursive: true, force: true });
}
