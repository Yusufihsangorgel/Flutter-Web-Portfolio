import assert from 'node:assert/strict';

import {
  applyContentVersionBump,
  applyContributionFacts,
  applyPackageFacts,
  bumpContentVersion,
  buildCandidateSearchUrl,
  buildReport,
  decideWrite,
  extractCandidateRecord,
  extractGithubLogin,
  extractPackageFacts,
  filterNewCandidates,
  groupCandidatesByRepo,
  parseArgs,
  parseGithubPullUrl,
  UsageError,
} from './refresh_portfolio_data.mjs';

let failures = 0;

function test(label, fn) {
  try {
    fn();
    console.log(`ok - ${label}`);
  } catch (error) {
    failures += 1;
    console.error(`not ok - ${label}`);
    console.error(error);
  }
}

function samplePackage(overrides = {}) {
  return {
    id: 'redis_task_queue',
    name: 'redis_task_queue',
    description: 'Old description.',
    url: 'https://pub.dev/packages/redis_task_queue',
    repository: 'https://github.com/example/redis_task_queue',
    version: '1.1.4',
    likes: 1,
    pub_points: 160,
    downloads: 546,
    category: 'server',
    topics: [],
    maturity: 'L3',
    proof: 'A measured claim that must never be touched.',
    roadmap: [{ title: 'Untouched roadmap entry', status: 'done' }],
    ...overrides,
  };
}

// ---------------------------------------------------------------------------
// Score-lag guard
// ---------------------------------------------------------------------------

test('score-lag guard keeps the previous pub_points when grantedPoints is null', () => {
  const pkg = samplePackage({ pub_points: 160 });
  const facts = extractPackageFacts(
    { latest: { version: '1.2.0', pubspec: { description: 'New', topics: [] } } },
    { grantedPoints: null, maxPoints: 160, likeCount: 2, downloadCount30Days: 600 },
  );
  assert.equal(facts.scorePending, true);
  const outcome = applyPackageFacts(pkg, facts);
  assert.equal(pkg.pub_points, 160, 'pub_points must stay at the previous value');
  assert.equal(outcome.pendingScore, true);
  assert.equal(
    outcome.changedFields.includes('pub_points'),
    false,
    'pub_points must not be reported as a changed field while pending',
  );
  // The version bump itself is still a visible change, independent of score lag.
  assert.equal(outcome.visibleChanged, true);
});

test('score-lag guard also fires when grantedPoints is entirely absent', () => {
  const facts = extractPackageFacts(
    { latest: { version: '1.0.0', pubspec: {} } },
    { maxPoints: 160, likeCount: 0, downloadCount30Days: 0 },
  );
  assert.equal(facts.scorePending, true);
  assert.equal(facts.pubPoints, null);
});

test('a real grantedPoints value is applied and never treated as pending', () => {
  const pkg = samplePackage({ pub_points: 150 });
  const facts = extractPackageFacts(
    { latest: { version: '1.1.4', pubspec: { description: pkg.description, topics: [] } } },
    { grantedPoints: 160, maxPoints: 160, likeCount: 1, downloadCount30Days: 546 },
  );
  const outcome = applyPackageFacts(pkg, facts);
  assert.equal(pkg.pub_points, 160);
  assert.equal(outcome.pendingScore, false);
  assert.equal(outcome.changedFields.includes('pub_points'), true);
});

// ---------------------------------------------------------------------------
// Counters-only vs visible change, and the --counters flag
// ---------------------------------------------------------------------------

test('a counters-only package change is classified as counters, not visible', () => {
  const pkg = samplePackage();
  const facts = extractPackageFacts(
    { latest: { version: pkg.version, pubspec: { description: pkg.description, topics: [] } } },
    { grantedPoints: pkg.pub_points, maxPoints: 160, likeCount: 4, downloadCount30Days: 999 },
  );
  const outcome = applyPackageFacts(pkg, facts);
  assert.equal(outcome.visibleChanged, false);
  assert.equal(outcome.counterChanged, true);
  assert.equal(pkg.likes, 4);
  assert.equal(pkg.downloads, 999);
});

test('the authored description is never replaced by the pubspec description', () => {
  const pkg = samplePackage({ description: 'Authored site copy.' });
  const facts = extractPackageFacts(
    { latest: { version: pkg.version, pubspec: { description: 'Plain pubspec text.', topics: [] } } },
    { grantedPoints: pkg.pub_points, maxPoints: 160, likeCount: pkg.likes, downloadCount30Days: pkg.downloads },
  );
  const outcome = applyPackageFacts(pkg, facts);
  assert.equal(pkg.description, 'Authored site copy.');
  assert.equal(outcome.visibleChanged, false);
  assert.equal(outcome.changedFields.includes('description'), false);
});

test('a topics-only change refreshes the field but is not a visible change', () => {
  const pkg = samplePackage({ topics: [] });
  const facts = extractPackageFacts(
    { latest: { version: pkg.version, pubspec: { topics: ['redis', 'queue'] } } },
    { grantedPoints: pkg.pub_points, maxPoints: 160, likeCount: pkg.likes, downloadCount30Days: pkg.downloads },
  );
  const outcome = applyPackageFacts(pkg, facts);
  assert.deepEqual(pkg.topics, ['redis', 'queue']);
  assert.equal(outcome.visibleChanged, false);
  assert.equal(outcome.counterChanged, true);
});

test('counters-only change produces no write by default, and writes with --counters', () => {
  const counterOnly = { anyFailure: false, check: false, hasVisible: false, hasCounters: true };
  assert.equal(decideWrite({ ...counterOnly, includeCounters: false }), false);
  assert.equal(decideWrite({ ...counterOnly, includeCounters: true }), true);
});

test('a visible change always writes regardless of the --counters flag', () => {
  assert.equal(
    decideWrite({ anyFailure: false, check: false, hasVisible: true, hasCounters: false, includeCounters: false }),
    true,
  );
});

test('--check never writes, and a fetch failure never writes', () => {
  assert.equal(
    decideWrite({ anyFailure: false, check: true, hasVisible: true, hasCounters: false, includeCounters: false }),
    false,
  );
  assert.equal(
    decideWrite({ anyFailure: true, check: false, hasVisible: true, hasCounters: false, includeCounters: true }),
    false,
  );
});

// ---------------------------------------------------------------------------
// content_version bump
// ---------------------------------------------------------------------------

test('content_version bumps N within the same UTC day', () => {
  assert.equal(bumpContentVersion('2026.08.30.1', '2026-08-30'), '2026.08.30.2');
  assert.equal(bumpContentVersion('2026.08.30.4', '2026-08-30'), '2026.08.30.5');
});

test('content_version resets to N=1 on a new UTC day', () => {
  assert.equal(bumpContentVersion('2026.08.30.3', '2026-08-31'), '2026.08.31.1');
});

test('a visible write bumps content_version and never touches verified_at', () => {
  const document = { content_version: '2026.08.30.1', verified_at: '2026-08-29' };
  applyContentVersionBump(document, { shouldWrite: true, hasVisible: true }, '2026-09-22');
  assert.equal(document.content_version, '2026.09.22.1');
  assert.equal(document.verified_at, '2026-08-29');
});

test('a counters-only write or no write leaves content_version alone', () => {
  const countersOnly = { content_version: '2026.08.30.1' };
  applyContentVersionBump(countersOnly, { shouldWrite: true, hasVisible: false }, '2026-09-22');
  assert.equal(countersOnly.content_version, '2026.08.30.1');
  const checkOnly = { content_version: '2026.08.30.1' };
  applyContentVersionBump(checkOnly, { shouldWrite: false, hasVisible: true }, '2026-09-22');
  assert.equal(checkOnly.content_version, '2026.08.30.1');
});

test('a missing counter in the score response keeps the stored value', () => {
  const pkg = samplePackage({ likes: 3, downloads: 500 });
  const facts = extractPackageFacts(
    { latest: { version: pkg.version, pubspec: { topics: pkg.topics } } },
    { grantedPoints: pkg.pub_points, maxPoints: 160 },
  );
  const outcome = applyPackageFacts(pkg, facts);
  assert.equal(pkg.likes, 3);
  assert.equal(pkg.downloads, 500);
  assert.equal(outcome.counterChanged, false);
});

test('content_version falls back to N=1 for a missing or malformed value', () => {
  assert.equal(bumpContentVersion(undefined, '2026-09-01'), '2026.09.01.1');
  assert.equal(bumpContentVersion('not-a-version', '2026-09-01'), '2026.09.01.1');
});

// ---------------------------------------------------------------------------
// Unknown fields and key order survive a round trip
// ---------------------------------------------------------------------------

test('unknown fields and key order survive applying a package update', () => {
  const pkg = samplePackage();
  pkg.future_field_the_tool_does_not_know_about = { keep: 'me' };
  const before = Object.keys(pkg);

  const facts = extractPackageFacts(
    { latest: { version: '2.0.0', pubspec: { description: 'Refreshed.', topics: ['a', 'b'] } } },
    { grantedPoints: 140, maxPoints: 160, likeCount: 5, downloadCount30Days: 700 },
  );
  applyPackageFacts(pkg, facts);

  assert.deepEqual(Object.keys(pkg), before, 'no key was added, removed, or reordered');
  assert.deepEqual(pkg.future_field_the_tool_does_not_know_about, { keep: 'me' });
  assert.equal(pkg.proof, 'A measured claim that must never be touched.');
  assert.deepEqual(pkg.roadmap, [{ title: 'Untouched roadmap entry', status: 'done' }]);

  const serialized = JSON.stringify(pkg, null, 2);
  const reparsed = JSON.parse(serialized);
  assert.deepEqual(Object.keys(reparsed), before);
});

test('a full document round trip keeps top-level key order and untouched sections', () => {
  const document = {
    schema_version: 9,
    content_version: '2026.08.30.1',
    verified_at: '2026-08-29',
    site: { title: 'Example' },
    packages: [samplePackage()],
    an_unknown_top_level_field: 'preserved',
  };
  const originalKeys = Object.keys(document);
  const facts = extractPackageFacts(
    { latest: { version: '9.9.9', pubspec: { description: 'x', topics: [] } } },
    { grantedPoints: 100, maxPoints: 160, likeCount: 0, downloadCount30Days: 0 },
  );
  applyPackageFacts(document.packages[0], facts);
  document.verified_at = '2026-09-22';
  document.content_version = bumpContentVersion(document.content_version, '2026-09-22');

  assert.deepEqual(Object.keys(document), originalKeys);
  assert.equal(document.an_unknown_top_level_field, 'preserved');
  const roundTripped = JSON.parse(JSON.stringify(document, null, 2));
  assert.deepEqual(Object.keys(roundTripped), originalKeys);
});

// ---------------------------------------------------------------------------
// Contribution status/date flips
// ---------------------------------------------------------------------------

function sampleContribution(overrides = {}) {
  return {
    id: 'example-contribution',
    project: 'Example',
    status: 'under_review',
    date: '2026-09-01',
    title: 'Untouched title',
    problem: 'Untouched problem',
    change: 'Untouched change',
    url: 'https://github.com/example/example/pull/1',
    featured: false,
    ...overrides,
  };
}

test('under_review flips to merged and sets the merge date', () => {
  const contribution = sampleContribution();
  const outcome = applyContributionFacts(contribution, {
    state: 'closed',
    merged_at: '2026-09-15T10:00:00Z',
  });
  assert.equal(outcome.changed, true);
  assert.equal(outcome.outcome, 'merged');
  assert.equal(contribution.status, 'merged');
  assert.equal(contribution.date, '2026-09-15');
  // Hand-authored fields must never move.
  assert.equal(contribution.title, 'Untouched title');
  assert.equal(contribution.problem, 'Untouched problem');
  assert.equal(contribution.change, 'Untouched change');
  assert.equal(contribution.featured, false);
});

test('closed without merging is reported, not changed', () => {
  const contribution = sampleContribution();
  const outcome = applyContributionFacts(contribution, { state: 'closed', merged_at: null });
  assert.equal(outcome.changed, false);
  assert.equal(outcome.outcome, 'closed_unmerged');
  assert.equal(contribution.status, 'under_review');
  assert.equal(contribution.date, '2026-09-01');
});

test('an already-merged entry is never re-examined', () => {
  const contribution = sampleContribution({ status: 'merged', date: '2026-01-01' });
  const outcome = applyContributionFacts(contribution, {
    state: 'closed',
    merged_at: '2026-09-15T10:00:00Z',
  });
  assert.equal(outcome.changed, false);
  assert.equal(outcome.outcome, 'not_applicable');
  assert.equal(contribution.date, '2026-01-01');
});

test('a still-open review is left alone and not reported as closed', () => {
  const contribution = sampleContribution();
  const outcome = applyContributionFacts(contribution, { state: 'open', merged_at: null });
  assert.equal(outcome.changed, false);
  assert.equal(outcome.outcome, 'still_open');
  assert.equal(contribution.status, 'under_review');
});

test('parseGithubPullUrl accepts a pull URL and rejects everything else', () => {
  assert.deepEqual(parseGithubPullUrl('https://github.com/dart-lang/ai/pull/570'), {
    owner: 'dart-lang',
    repo: 'ai',
    number: 570,
  });
  assert.equal(parseGithubPullUrl('https://github.com/dart-lang/ai/issues/570'), null);
  assert.equal(parseGithubPullUrl('not a url'), null);
  assert.equal(parseGithubPullUrl(null), null);
});

// ---------------------------------------------------------------------------
// Candidate discovery
// ---------------------------------------------------------------------------

test('candidates exclude URLs already present in contributions', () => {
  const records = [
    extractCandidateRecord({
      html_url: 'https://github.com/dart-lang/ai/pull/685',
      title: 'Already listed',
      repository_url: 'https://api.github.com/repos/dart-lang/ai',
      pull_request: { merged_at: '2026-09-21T16:01:43Z' },
    }),
    extractCandidateRecord({
      html_url: 'https://github.com/dart-lang/ai/pull/999',
      title: 'A new candidate',
      repository_url: 'https://api.github.com/repos/dart-lang/ai',
      pull_request: { merged_at: '2026-09-20T00:00:00Z' },
    }),
  ];
  const kept = filterNewCandidates(records, [
    'https://github.com/dart-lang/ai/pull/685',
    'https://github.com/other/repo/pull/1',
  ]);
  assert.equal(kept.length, 1);
  assert.equal(kept[0].url, 'https://github.com/dart-lang/ai/pull/999');
});

test('candidates de-duplicate a URL matched with a trailing slash or different case', () => {
  const records = [
    extractCandidateRecord({
      html_url: 'https://github.com/dart-lang/ai/pull/685/',
      title: 'Trailing slash',
      repository_url: 'https://api.github.com/repos/dart-lang/ai',
    }),
  ];
  const kept = filterNewCandidates(records, ['HTTPS://GITHUB.COM/dart-lang/ai/pull/685']);
  assert.equal(kept.length, 0);
});

test('groupCandidatesByRepo groups and sorts by owner/repo', () => {
  const groups = groupCandidatesByRepo([
    { owner: 'b', repo: 'two', url: 'u1', title: 't1' },
    { owner: 'a', repo: 'one', url: 'u2', title: 't2' },
    { owner: 'a', repo: 'one', url: 'u3', title: 't3' },
  ]);
  assert.deepEqual(
    groups.map((g) => g.repo),
    ['a/one', 'b/two'],
  );
  assert.equal(groups[0].items.length, 2);
});

test('the candidate search query is scoped to public results only', () => {
  const url = new URL(buildCandidateSearchUrl('example-user'));
  const query = url.searchParams.get('q');
  assert.ok(query.includes('is:public'), `query must contain is:public, got: ${query}`);
  assert.ok(query.includes('is:merged'));
  assert.ok(query.includes('author:example-user'));
  assert.ok(query.includes('-user:example-user'));
});

test('extractGithubLogin reads the profile.links github entry', () => {
  const document = {
    profile: {
      links: [
        { id: 'linkedin', url: 'https://www.linkedin.com/in/example/' },
        { id: 'github', url: 'https://github.com/example-user' },
      ],
    },
  };
  assert.equal(extractGithubLogin(document), 'example-user');
  assert.equal(extractGithubLogin({ profile: { links: [] } }), null);
  assert.equal(extractGithubLogin({}), null);
});

// ---------------------------------------------------------------------------
// CLI argument parsing
// ---------------------------------------------------------------------------

test('parseArgs accepts the documented flags', () => {
  const options = parseArgs(['--check', '--counters', '--report', '/tmp/r.md', '--file', '/tmp/p.json']);
  assert.deepEqual(options, {
    check: true,
    counters: true,
    report: '/tmp/r.md',
    file: '/tmp/p.json',
  });
});

test('parseArgs rejects an unknown flag and a flag missing its value', () => {
  assert.throws(() => parseArgs(['--nope']), UsageError);
  assert.throws(() => parseArgs(['--report']), UsageError);
  assert.throws(() => parseArgs(['--file']), UsageError);
});

// ---------------------------------------------------------------------------
// Report rendering (smoke coverage; the live run is eyeballed separately)
// ---------------------------------------------------------------------------

test('buildReport renders every section, including an empty one', () => {
  const report = buildReport({
    generatedAt: '2026-09-22T00:00:00.000Z',
    visibleChanges: ['redis_task_queue: version'],
    counterChanges: [],
    pendingScorePackages: ['re2'],
    closedUnmergedContributions: [],
    failures: [],
    candidateGroups: [{ repo: 'dart-lang/ai', items: [{ title: 'x', url: 'https://x', mergedDate: '2026-09-20' }] }],
    candidatesError: null,
  });
  assert.ok(report.includes('## Visible changes'));
  assert.ok(report.includes('redis_task_queue: version'));
  assert.ok(report.includes('## Counter-only changes'));
  assert.ok(report.includes('None.'));
  assert.ok(report.includes('`re2`'));
  assert.ok(report.includes('### dart-lang/ai'));
  assert.ok(report.endsWith('\n') && !report.endsWith('\n\n'));
});

if (failures > 0) {
  console.error(`\n${failures} test(s) failed.`);
  process.exitCode = 1;
} else {
  console.log('\nAll refresh_portfolio_data tests passed.');
}
