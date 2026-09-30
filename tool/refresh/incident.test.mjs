import assert from 'node:assert/strict';
import { spawnSync } from 'node:child_process';
import { readFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { applyPackageFacts, buildReport, extractPackageFacts, mergeWritingEntries } from '../refresh_portfolio_data.mjs';

export function runIncidentTests(test, samplePackage) {
  scoreValidityTests(test, samplePackage);
  metricsReportTests(test);
  taskStatusTests(test);
  scoreFailureTests(test, samplePackage);
  cliTests(test);
  writingTests(test);
}

function scoreValidityTests(test, samplePackage) {
  test('a settled score drop is accepted when report sections total the score', () => {
    const pkg = samplePackage();
    const score = { grantedPoints: 140, maxPoints: 160 };
    const confirmed = extractPackageFacts(
      { latest: { version: pkg.version } },
      score,
      refreshFixture('pub-metrics-confirmed'),
      pkg.pub_points,
    );
    assert.equal(confirmed.scorePending, false);
    applyPackageFacts(pkg, confirmed);
    assert.equal(pkg.pub_points, 140);

    const pendingAnalysis = extractPackageFacts(
      { latest: { version: pkg.version } },
      score,
      refreshFixture('pub-metrics-pending'),
      160,
    );
    assert.equal(pendingAnalysis.scorePending, true);
  });

  test('a missing or zero maxPoints makes the score unavailable', () => {
    for (const score of [
      { grantedPoints: 0 },
      { grantedPoints: 0, maxPoints: null },
      { grantedPoints: 0, maxPoints: 0 },
    ]) {
      const facts = extractPackageFacts({ latest: { version: '1.1.4' } }, score);
      assert.equal(facts.scorePending, true);
    }
  });
}

function metricsReportTests(test) {
  test('a missing Pana report does not confirm a score drop', () => {
    const facts = extractPackageFacts(
      { latest: { version: '1.1.4' } },
      { grantedPoints: 140, maxPoints: 160 },
      refreshFixture('pub-metrics-missing-report'),
      160,
    );
    assert.equal(facts.scorePending, true);
  });

  test('section totals that disagree with the score do not confirm a drop', () => {
    const facts = extractPackageFacts(
      { latest: { version: '1.1.4' } },
      { grantedPoints: 140, maxPoints: 160 },
      refreshFixture('pub-metrics-sums-disagree'),
      160,
    );
    assert.equal(facts.scorePending, true);
  });

  test('a non-success reportStatus does not confirm a matching score', () => {
    const metrics = refreshFixture('pub-metrics-confirmed');
    metrics.scorecard.panaReport.reportStatus = 'pending';
    const facts = extractPackageFacts(
      { latest: { version: '1.1.4' } },
      { grantedPoints: 140, maxPoints: 160 },
      metrics,
      160,
    );
    assert.equal(facts.scorePending, true);
  });
}

function taskStatusTests(test) {
  test('a running taskStatus does not confirm a matching report', () => {
    const metrics = refreshFixture('pub-metrics-confirmed');
    metrics.scorecard.taskStatus = 'running';
    const facts = extractPackageFacts(
      { latest: { version: '1.1.4' } },
      { grantedPoints: 140, maxPoints: 160 },
      metrics,
      160,
    );
    assert.equal(facts.scorePending, true);
  });

  test('a success taskStatus confirms a matching report', () => {
    const metrics = refreshFixture('pub-metrics-confirmed');
    metrics.scorecard.taskStatus = 'success';
    const facts = extractPackageFacts(
      { latest: { version: '1.1.4' } },
      { grantedPoints: 140, maxPoints: 160 },
      metrics,
      160,
    );
    assert.equal(facts.scorePending, false);
  });

  test('an unknown taskStatus remains unsettled', () => {
    const metrics = refreshFixture('pub-metrics-confirmed');
    metrics.scorecard.taskStatus = 'queued';
    const facts = extractPackageFacts(
      { latest: { version: '1.1.4' } },
      { grantedPoints: 140, maxPoints: 160 },
      metrics,
      160,
    );
    assert.equal(facts.scorePending, true);
  });
}

function refreshFixture(name) {
  return JSON.parse(readFileSync(new URL(`../fixtures/refresh/${name}.json`, import.meta.url), 'utf8'));
}

function scoreFailureTests(test, samplePackage) {
  test('a failed score request keeps stored points and renders the required report line', () => {
    const pkg = samplePackage({ featured: true, maturity_level: 'L3' });
    const facts = extractPackageFacts({ latest: { version: pkg.version } }, null, null, pkg.pub_points);
    const outcome = applyPackageFacts(pkg, facts);
    assert.equal(outcome.pendingScore, true);
    assert.equal(pkg.pub_points, 160);
    assert.equal(pkg.featured, true);
    assert.equal(pkg.maturity_level, 'L3');
    const report = buildReport({
      generatedAt: '2026-09-29T00:00:00Z', visibleChanges: [], counterChanges: [],
      pendingScorePackages: [pkg.name], scoreUnavailable: [`${pkg.name}: score unavailable, kept 160/160`],
      closedUnmergedContributions: [], failures: [], candidateGroups: [], candidatesError: null,
    });
    assert.ok(report.includes(`${pkg.name}: score unavailable, kept 160/160`));
  });
}

function cliTests(test) {
  test('the CLI keeps a transient score and prints the unavailable line', () => {
    const script = fileURLToPath(new URL('../refresh_portfolio_data.mjs', import.meta.url));
    const mock = fileURLToPath(new URL('../fixtures/refresh/mock-fetch.mjs', import.meta.url));
    const document = fileURLToPath(new URL('../fixtures/refresh/cli-document.json', import.meta.url));
    const run = spawnSync(process.execPath, ['--import', mock, script, '--check', '--file', document], {
      encoding: 'utf8',
    });
    assert.equal(run.status, 0, run.stderr);
    assert.ok(run.stdout.includes('re2: score unavailable, kept 160/160'));
    assert.equal(JSON.parse(readFileSync(document, 'utf8')).packages[0].pub_points, 160);
  });

  test('the CLI keeps stored points when the score request fails', () => {
    const script = fileURLToPath(new URL('../refresh_portfolio_data.mjs', import.meta.url));
    const mock = fileURLToPath(new URL('../fixtures/refresh/mock-fetch.mjs', import.meta.url));
    const document = fileURLToPath(new URL('../fixtures/refresh/cli-document.json', import.meta.url));
    const run = spawnSync(process.execPath, ['--import', mock, script, '--check', '--file', document], {
      encoding: 'utf8', env: { ...process.env, REFRESH_TEST_SCORE_FAILURE: '1' },
    });
    assert.equal(run.status, 0, run.stderr);
    assert.ok(run.stdout.includes('re2: score unavailable, kept 160/160'));
    assert.equal(JSON.parse(readFileSync(document, 'utf8')).packages[0].pub_points, 160);
  });

  test('the CLI recognizes a score drop confirmed by metrics sections', () => {
    const script = fileURLToPath(new URL('../refresh_portfolio_data.mjs', import.meta.url));
    const mock = fileURLToPath(new URL('../fixtures/refresh/mock-fetch.mjs', import.meta.url));
    const document = fileURLToPath(new URL('../fixtures/refresh/cli-document.json', import.meta.url));
    const run = spawnSync(process.execPath, ['--import', mock, script, '--check', '--file', document], {
      encoding: 'utf8', env: { ...process.env, REFRESH_TEST_CONFIRMED_DROP: '1' },
    });
    assert.equal(run.status, 1, run.stderr);
    assert.ok(run.stdout.includes('Visible changes: 1'));
    assert.ok(!run.stdout.includes('score unavailable'));
    assert.equal(JSON.parse(readFileSync(document, 'utf8')).packages[0].pub_points, 160);
  });
}

function writingTests(test) {
  test('writing merge retains unmanaged fields on an existing entry', () => {
    const previous = [{
      title: 'Dated', url: 'https://example.com/dated', source: 'feed', date: '2026-07-28',
      featured: true, maturity_level: 'L3', future_field: { keep: true },
    }];
    const merged = mergeWritingEntries(
      { feed: [{ title: 'Dated', url: previous[0].url, publishedAt: '2026-07-29T06:41:58.000Z' }] },
      ['feed'],
      { previous },
    );
    assert.equal(merged[0].date, '2026-07-29');
    assert.equal(merged[0].featured, true);
    assert.equal(merged[0].maturity_level, 'L3');
    assert.deepEqual(merged[0].future_field, { keep: true });
  });

  test('writing merge retains unmanaged fields when a source changes its article URL', () => {
    const previous = [{
      title: 'Dated', url: 'https://example.com/old', source: 'feed', date: '2026-07-28',
      featured: true,
    }];
    const merged = mergeWritingEntries(
      { feed: [{ title: 'Dated', url: 'https://example.com/new', publishedAt: '2026-07-29T06:41:58.000Z' }] },
      ['feed'], { previous },
    );
    assert.equal(merged[0].url, 'https://example.com/new');
    assert.equal(merged[0].featured, true);
  });

  test('writing merge retains unmanaged fields when a preferred source changes', () => {
    const previous = [{
      title: 'Dated', url: 'https://example.com/old', source: 'old', date: '2026-07-28',
      featured: true,
    }];
    const merged = mergeWritingEntries(
      { new: [{ title: 'Dated', url: 'https://example.com/new', publishedAt: '2026-07-29T06:41:58.000Z' }] },
      ['new'], { previous },
    );
    assert.equal(merged[0].source, 'new');
    assert.equal(merged[0].featured, true);
  });
}
