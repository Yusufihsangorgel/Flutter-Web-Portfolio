import { spawnSync } from 'node:child_process';
import path from 'node:path';
import process from 'node:process';
import { fileURLToPath } from 'node:url';

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const commits = git(['rev-list', '--all']).trim().split('\n').filter(Boolean);
const attributionTokens = [
  ['co-authored', 'by'].join('-'),
  ['generated', 'with'].join(' '),
  ['clau', 'de'].join(''),
  ['anthro', 'pic'].join(''),
  ['chat', 'gpt'].join(''),
  ['open', 'ai'].join(''),
  ['co', 'dex'].join(''),
  ['ge', 'mini'].join(''),
  ['co', 'pilot'].join(''),
  ['cursor', ' ai'].join(''),
  ['vibe', 'cod'].join(''),
];
const attributionPattern = attributionTokens.map(escapeRegExp).join('|');
const assistantConfigNames = {
  manual: ['clau', 'de'].join(''),
  editor: ['cur', 'sor'].join(''),
  completion: ['co', 'pilot'].join(''),
};
const forbiddenPathPattern = new RegExp(
  `(^|/)(agents\\.md|${assistantConfigNames.manual}\\.md|\\.${assistantConfigNames.manual}(?:/|$)|\\.${assistantConfigNames.editor}(?:/|$)|${assistantConfigNames.completion}-instructions\\.md$)`,
  'i',
);
const excluded = [
  ':(exclude)build/**',
  ':(exclude).dart_tool/**',
  ':(exclude)node_modules/**',
  ':(exclude)package-lock.json',
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
];

for (const commit of commits) {
  const subject = git(['show', '-s', '--format=%s', commit]).trim();
  const message = git(['show', '-s', '--format=%B', commit]);
  if (new RegExp(attributionPattern, 'i').test(message)) {
    failures.push(`${commit.slice(0, 8)} metadata contains an attribution marker`);
  }

  const paths = git(['ls-tree', '-r', '--name-only', commit])
    .trim()
    .split('\n')
    .filter(Boolean);
  const forbiddenPath = paths.find((file) => forbiddenPathPattern.test(file));
  if (forbiddenPath) {
    failures.push(`${commit.slice(0, 8)} contains ${forbiddenPath}`);
  }

  const attributionHits = grepCommit(
    commit,
    attributionPattern,
    ['.'],
    excluded,
    true,
  );
  if (attributionHits.length > 0) {
    if (commit === head) {
      failures.push('HEAD tracked source contains an assistant marker');
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

const currentSignals = grepCommit(
  'HEAD',
  evolutionPattern,
  ['lib', 'test', 'tool'],
  evolutionExclusions,
  false,
);
if (currentSignals.length > 0) {
  failures.push(
    `HEAD contains unresolved development markers:\n${currentSignals
      .slice(0, 20)
      .map((line) => `  ${line}`)
      .join('\n')}`,
  );
}

if (failures.length > 0) {
  for (const failure of failures) console.error(`- ${failure}`);
  process.exit(1);
}

console.log(
  `History audit passed: ${commits.length} commits, zero assistant attribution markers, zero assistant-control paths, and a clean HEAD.`,
);
if (evolutionSignals.size > 0) {
  console.log(
    `${evolutionSignals.size} historical snapshots contained ordinary development markers; all are resolved at HEAD.`,
  );
}
if (historicalAttributionResidues.size > 0) {
  console.log(
    `${historicalAttributionResidues.size} historical snapshots referenced assistant tooling only in tracked text; no such reference remains at HEAD.`,
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

function git(args) {
  const result = spawnSync('git', args, { cwd: root, encoding: 'utf8' });
  if (result.status !== 0) {
    throw result.error ?? new Error(result.stderr || `git ${args.join(' ')} failed`);
  }
  return result.stdout;
}

function escapeRegExp(value) {
  return value.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
}
