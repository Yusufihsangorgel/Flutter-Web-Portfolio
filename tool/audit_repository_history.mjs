import { spawnSync } from 'node:child_process';
import path from 'node:path';
import process from 'node:process';
import { fileURLToPath } from 'node:url';

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const commits = git(['rev-list', '--all']).trim().split('\n').filter(Boolean);
const attributionPattern = String.raw`Co-Authored-By|Generated with`;
const instructionFilePattern = /(^|\/)(agents|[^/]+-instructions)\.md$/i;
const allowedRootDirectories = new Set(['.github']);
const restrictedPathRule =
  'instruction files and hidden root directories other than .github are not allowed';
const excluded = [
  ':(exclude)build/**',
  ':(exclude).dart_tool/**',
  ':(exclude)node_modules/**',
  ':(exclude)package-lock.json',
];
const attributionExclusions = [
  ...excluded,
  ':(exclude)tool/audit_repository_history.mjs',
  ':(exclude)tool/test_audit_repository_history.mjs',
];
const failures = [];
const evolutionSignals = new Map();
const historicalAttributionResidues = new Map();
const historicalAttributionPaths = new Set();
const head = git(['rev-parse', 'HEAD']).trim();
const evolutionPattern =
  String.raw`TODO|FIXME|HACK|XXX|debugPrint[[:space:]]*\(|(^|[^[:alnum:]_])print[[:space:]]*\(|//[[:space:]]*ignore:|ignore_for_file`;
const evolutionExclusions = [
  ':(exclude)tool/audit_repository_history.mjs',
  ':(exclude)tool/test_audit_repository_history.mjs',
];

for (const commit of commits) {
  const subject = git(['show', '-s', '--format=%s', commit]).trim();
  const metadata = git([
    'show',
    '-s',
    '--format=%an <%ae>%n%cn <%ce>%n%B',
    commit,
  ]);
  if (new RegExp(attributionPattern, 'i').test(metadata)) {
    failures.push(`${commit.slice(0, 8)} metadata contains an attribution marker`);
  }

  const paths = git(['ls-tree', '-r', '--name-only', commit])
    .trim()
    .split('\n')
    .filter(Boolean);
  const forbiddenPath = paths.find(isRestrictedPath);
  if (forbiddenPath) {
    failures.push(
      `${commit.slice(0, 8)} contains restricted path ${forbiddenPath} (${restrictedPathRule})`,
    );
  }

  const attributionHits = grepCommit(
    commit,
    attributionPattern,
    ['.'],
    attributionExclusions,
    true,
  );
  if (attributionHits.length > 0) {
    if (commit === head) {
      failures.push('HEAD tracked source contains an attribution marker');
    } else {
      historicalAttributionResidues.set(commit, {
        subject,
        count: attributionHits.length,
      });
      for (const hit of attributionHits) {
        const match = hit.match(/^[^:]+:([^:]+):/);
        if (match) historicalAttributionPaths.add(match[1]);
      }
    }
  }

  const signalHits = grepCommit(
    commit,
    evolutionPattern,
    ['lib', 'test', 'tool'],
    evolutionExclusions,
    false,
  );
  if (signalHits.length > 0) {
    evolutionSignals.set(commit, { subject, count: signalHits.length });
  }
}

for (const target of ['worktree', 'index']) {
  const currentAttributionHits = grepCurrent(
    target,
    attributionPattern,
    ['.'],
    attributionExclusions,
    true,
  );
  if (currentAttributionHits.length > 0) {
    failures.push(
      `${target} source contains an attribution marker:\n${currentAttributionHits
        .slice(0, 20)
        .map((line) => `  ${line}`)
        .join('\n')}`,
    );
  }
}

const currentPaths = git([
  'ls-files',
  '--cached',
  '--others',
  '--exclude-standard',
]);
const forbiddenCurrentPath = currentPaths
  .trim()
  .split('\n')
  .filter(Boolean)
  .find(isRestrictedPath);
if (forbiddenCurrentPath) {
  failures.push(
    `current repository contains restricted path ${forbiddenCurrentPath} (${restrictedPathRule})`,
  );
}

const currentSignals = grepCurrent(
  'worktree',
  evolutionPattern,
  ['lib', 'test', 'tool'],
  evolutionExclusions,
  false,
);
if (currentSignals.length > 0) {
  failures.push(
    `worktree contains unresolved development markers:\n${currentSignals
      .slice(0, 20)
      .map((line) => `  ${line}`)
      .join('\n')}`,
  );
}

// Tag messages span several lines, so records end with a record separator.
const annotatedTags = git([
  'for-each-ref',
  '--format=%(objecttype)%00%(refname:short)%00%(contents)%1e',
  'refs/tags',
]);
for (const record of annotatedTags.split('\x1e')) {
  const [type, name, ...contents] = record.replace(/^\n/, '').split('\0');
  if (type === 'tag' && new RegExp(attributionPattern, 'i').test(contents.join('\0'))) {
    failures.push(`annotated tag ${name} contains an attribution marker`);
  }
}

if (failures.length > 0) {
  for (const failure of failures) console.error(`- ${failure}`);
  process.exit(1);
}

console.log(
  `History audit passed: ${commits.length} commits, zero attribution markers, zero restricted configuration paths, and a clean candidate worktree/index.`,
);
if (evolutionSignals.size > 0) {
  console.log(
    `${evolutionSignals.size} historical snapshots contained ordinary development markers; all are resolved at HEAD.`,
  );
}
if (historicalAttributionResidues.size > 0) {
  console.log(
    `${historicalAttributionResidues.size} historical snapshots matched attribution markers in tracked text; no match remains in the candidate source.`,
  );
  console.log(
    `Historical reference paths: ${[...historicalAttributionPaths].sort().join(', ')}.`,
  );
}

function grepCommit(commit, pattern, paths, exclusions, ignoreCase) {
  const flags = ['grep', '-I', '-n'];
  if (ignoreCase) flags.push('-i');
  const result = spawnSync(
    'git',
    [...flags, '-E', pattern, commit, '--', ...paths, ...exclusions],
    { cwd: root, encoding: 'utf8' },
  );
  if (result.status === 1) return [];
  if (result.status !== 0) {
    throw result.error ?? new Error(result.stderr || 'git grep failed');
  }
  return result.stdout.trim().split('\n').filter(Boolean);
}

function isRestrictedPath(file) {
  if (instructionFilePattern.test(file)) return true;
  const separator = file.indexOf('/');
  if (separator < 0) return false;
  const rootDirectory = file.slice(0, separator);
  return rootDirectory.startsWith('.') && !allowedRootDirectories.has(rootDirectory);
}

function grepCurrent(target, pattern, paths, exclusions, ignoreCase) {
  const flags = ['grep', '-I', '-n'];
  flags.push(target === 'index' ? '--cached' : '--untracked');
  if (ignoreCase) flags.push('-i');
  const result = spawnSync(
    'git',
    [...flags, '-E', pattern, '--', ...paths, ...exclusions],
    { cwd: root, encoding: 'utf8' },
  );
  if (result.status === 1) return [];
  if (result.status !== 0) {
    throw result.error ?? new Error(result.stderr || 'git grep failed');
  }
  return result.stdout.trim().split('\n').filter(Boolean);
}

function git(args) {
  const result = spawnSync('git', args, { cwd: root, encoding: 'utf8' });
  if (result.status !== 0) {
    throw result.error ?? new Error(result.stderr || `git ${args.join(' ')} failed`);
  }
  return result.stdout;
}
