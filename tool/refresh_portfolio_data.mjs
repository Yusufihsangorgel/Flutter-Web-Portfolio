import { readFile, writeFile } from 'node:fs/promises';
import path from 'node:path';
import process from 'node:process';
import { fileURLToPath } from 'node:url';
import { parseArgs, UsageError } from './refresh/args.mjs';
import { extractGithubLogin, parseGithubPullUrl, applyContributionFacts, buildCandidateSearchUrl, extractCandidateRecord, filterNewCandidates, groupCandidatesByRepo } from './refresh/github.mjs';
import { extractPackageFacts, applyPackageFacts, COUNTER_FIELDS } from './refresh/pub.mjs';
import { mergeWritingEntries, isWritingListChanged, decideWrite, applyContentVersionBump } from './refresh/merge.mjs';
import { fetchWritingSourceEntries } from './refresh/feeds.mjs';
import { buildReport } from './refresh/report.mjs';
import { createLimiter, fetchJson, describeFetchFailure } from './refresh/http.mjs';

export * from './refresh/args.mjs';
export * from './refresh/github.mjs';
export * from './refresh/pub.mjs';
export * from './refresh/feeds.mjs';
export * from './refresh/merge.mjs';
export * from './refresh/report.mjs';

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const DEFAULT_FILE = path.join(root, 'assets', 'content', 'portfolio.json');
const USER_AGENT = 'flutter-web-portfolio-refresh';

function createHeaders() {
  const token = process.env.GITHUB_TOKEN?.trim() || null;
  const github = {
    Accept: 'application/vnd.github+json',
    'User-Agent': USER_AGENT,
    'X-GitHub-Api-Version': '2022-11-28',
    ...(token ? { Authorization: `Bearer ${token}` } : {}),
  };
  const pub = { 'User-Agent': USER_AGENT };
  const feed = {
    'User-Agent': USER_AGENT,
    Accept: 'application/rss+xml, application/atom+xml, application/xml;q=0.9, text/xml;q=0.8, */*;q=0.5',
  };
  return { github, pub, feed };
}

async function refreshPackages(ctx) {
  const fetches = ctx.packages.map((pkg) => {
    const base = `https://pub.dev/api/packages/${encodeURIComponent(pkg.name)}`;
    return {
      pkg,
      base,
      info: ctx.limiter(() => fetchJson(base, { headers: ctx.headers.pub })),
      score: ctx.limiter(() => fetchJson(`${base}/score`, { headers: ctx.headers.pub })),
    };
  });
  for (const { pkg, base, info, score } of fetches) {
    const [infoResult, scoreResult] = await Promise.all([info, score]);
    if (!infoResult.ok) {
      ctx.failures.push(describeFetchFailure(infoResult, `${pkg.name}: pub.dev package lookup`));
      ctx.anyFailure = true;
      continue;
    }
    const scoreBody = scoreResult.ok ? scoreResult.body : null;
    let metricsBody = null;
    if (Number.isFinite(scoreBody?.grantedPoints) && scoreBody.grantedPoints < pkg.pub_points) {
      const metricsResult = await ctx.limiter(() => fetchJson(`${base}/metrics`, { headers: ctx.headers.pub }));
      if (metricsResult.ok) metricsBody = metricsResult.body;
    }
    let facts;
    try {
      facts = extractPackageFacts(infoResult.body, scoreBody, metricsBody, pkg.pub_points);
    } catch (error) {
      ctx.failures.push(`${pkg.name}: ${error.message}`);
      ctx.anyFailure = true;
      continue;
    }
    const outcome = applyPackageFacts(pkg, facts);
    if (outcome.pendingScore) {
      ctx.pendingScorePackages.push(pkg.name);
      const max = Number.isFinite(facts.maxPoints) && facts.maxPoints > 0 ? facts.maxPoints : 160;
      ctx.scoreUnavailable.push(`${pkg.name}: score unavailable, kept ${pkg.pub_points}/${max}`);
    }
    if (outcome.visibleChanged) {
      ctx.visibleChanges.push(`${pkg.name}: ${outcome.changedFields.filter((f) => !COUNTER_FIELDS.has(f)).join(', ')}`);
    }
    if (outcome.counterChanged) {
      ctx.counterChanges.push(`${pkg.name}: ${outcome.changedFields.filter((f) => COUNTER_FIELDS.has(f)).join(', ')}`);
    }
  }
}

async function refreshContributions(ctx) {
  const fetches = ctx.contributions
    .filter((contribution) => contribution.status === 'under_review')
    .map((contribution) => {
      const parsed = parseGithubPullUrl(contribution.url);
      if (!parsed) return null;
      const url = `https://api.github.com/repos/${parsed.owner}/${parsed.repo}/pulls/${parsed.number}`;
      return { contribution, promise: ctx.limiter(() => fetchJson(url, { headers: ctx.headers.github })) };
    }).filter(Boolean);
  ctx.contributionsChecked = fetches.length;
  for (const { contribution, promise } of fetches) {
    const result = await promise;
    if (!result.ok) {
      ctx.failures.push(describeFetchFailure(result, `${contribution.id}: GitHub pull request lookup`));
      ctx.anyFailure = true;
      continue;
    }
    const outcome = applyContributionFacts(contribution, result.body);
    if (outcome.changed) {
      ctx.visibleChanges.push(`${contribution.id}: status -> merged (${outcome.mergedDate})`);
    } else if (outcome.outcome === 'closed_unmerged') {
      ctx.closedUnmergedContributions.push({ id: contribution.id, url: contribution.url });
    }
  }
}

async function refreshWriting(ctx) {
  const sources = Array.isArray(ctx.document.writing_sources) ? ctx.document.writing_sources : [];
  const previous = Array.isArray(ctx.document.writing) ? ctx.document.writing : [];
  const entriesBySource = {};
  const fetches = sources.map((source) => ({
    source,
    promise: ctx.limiter(() => fetchWritingSourceEntries(source, {
      feedHeaders: ctx.headers.feed, jsonHeaders: ctx.headers.pub,
    })),
  }));
  for (const { source, promise } of fetches) {
    const result = await promise;
    if (result.ok) {
      entriesBySource[source.id] = result.entries;
      continue;
    }
    ctx.writingFailures.push(result.failure);
    entriesBySource[source.id] = previous.filter((entry) => entry.source === source.id)
      .map((entry) => ({ ...entry, publishedAt: `${entry.date}T00:00:00.000Z` }));
  }
  const merged = mergeWritingEntries(entriesBySource, sources.map((source) => source.id), { previous });
  ctx.writingChanged = isWritingListChanged(previous, merged);
  ctx.writingEntryCount = merged.length;
  ctx.previousWritingEntryCount = previous.length;
  ctx.writingSourceCount = sources.length;
  if (ctx.writingChanged) {
    ctx.document.writing = merged;
    ctx.visibleChanges.push(`writing: ${merged.length} entries (was ${previous.length})`);
  }
}

async function discoverCandidates(ctx) {
  const login = extractGithubLogin(ctx.document);
  if (!login) {
    ctx.candidatesError = 'portfolio.json has no profile.links entry with id "github"';
    return;
  }
  try {
    const existingUrls = ctx.contributions.map((c) => c.url).filter((u) => typeof u === 'string');
    const records = [];
    let page = 1;
    let total = Infinity;
    while ((page - 1) * 100 < total) {
      const url = buildCandidateSearchUrl(login, page);
      const result = await ctx.limiter(() => fetchJson(url, { headers: ctx.headers.github }));
      if (!result.ok) {
        ctx.candidatesError = describeFetchFailure(result, 'GitHub search');
        break;
      }
      total = typeof result.body.total_count === 'number' ? result.body.total_count : 0;
      const items = Array.isArray(result.body.items) ? result.body.items : [];
      for (const item of items) records.push(extractCandidateRecord(item));
      if (items.length === 0) break;
      page += 1;
    }
    if (!ctx.candidatesError) {
      ctx.candidateGroups = groupCandidatesByRepo(filterNewCandidates(records, existingUrls));
    }
  } catch (error) {
    ctx.candidatesError = error.message;
  }
}

function buildConsoleSummary(ctx, shouldWrite) {
  const candidateCount = ctx.candidateGroups.reduce((total, group) => total + group.items.length, 0);
  return [
    `Packages checked: ${ctx.packages.length}`,
    `Contributions checked: ${ctx.contributionsChecked} (of ${ctx.contributions.length} total, only under_review entries)`,
    `Visible changes: ${ctx.visibleChanges.length}`,
    `Counter-only changes: ${ctx.counterChanges.length}`,
    `Pending pub.dev score: ${ctx.pendingScorePackages.length}`,
    `Closed without merging: ${ctx.closedUnmergedContributions.length}`,
    `Fetch failures: ${ctx.failures.length}`,
    `Writing sources checked: ${ctx.writingSourceCount}`,
    `Writing entries: ${ctx.writingEntryCount}${ctx.writingChanged ? ' (updated)' : ''}`,
    `Writing source failures: ${ctx.writingFailures.length}`,
    `Candidates: ${ctx.candidatesError ? `unavailable (${ctx.candidatesError})` : candidateCount}`,
    shouldWrite ? `Wrote ${path.relative(root, ctx.filePath)}.` :
      ctx.anyFailure ? 'Did not write: a fetch failed (all-or-nothing).' :
        ctx.options.check ? 'Did not write: --check.' :
          'Did not write: no visible change (counter-only changes need --counters).',
  ].join('\n');
}

async function finishRefresh(ctx) {
  const hasVisible = ctx.visibleChanges.length > 0;
  const shouldWrite = decideWrite({
    anyFailure: ctx.anyFailure, check: ctx.options.check, hasVisible,
    hasCounters: ctx.counterChanges.length > 0, includeCounters: ctx.options.counters,
  });
  applyContentVersionBump(ctx.document, { shouldWrite, hasVisible }, new Date().toISOString().slice(0, 10));
  if (shouldWrite) await writeFile(ctx.filePath, `${JSON.stringify(ctx.document, null, 2)}\n`);
  console.log(buildConsoleSummary(ctx, shouldWrite));
  for (const line of ctx.scoreUnavailable) console.log(line);
  if (ctx.options.report) {
    const report = buildReport({ ...ctx, generatedAt: new Date().toISOString() });
    await writeFile(path.resolve(ctx.options.report), report);
  }
  process.exitCode = ctx.anyFailure ? 2 : ctx.options.check && hasVisible ? 1 : 0;
}

async function main() {
  const options = parseArgs(process.argv.slice(2));
  const filePath = options.file ? path.resolve(options.file) : DEFAULT_FILE;
  const document = JSON.parse(await readFile(filePath, 'utf8'));
  const ctx = {
    options, filePath, document, headers: createHeaders(), limiter: createLimiter(6),
    packages: Array.isArray(document.packages) ? document.packages : [],
    contributions: Array.isArray(document.contributions) ? document.contributions : [],
    failures: [], visibleChanges: [], counterChanges: [], pendingScorePackages: [],
    scoreUnavailable: [], closedUnmergedContributions: [], writingFailures: [],
    candidateGroups: [], candidatesError: null, anyFailure: false,
  };
  await refreshPackages(ctx);
  await refreshContributions(ctx);
  await refreshWriting(ctx);
  await discoverCandidates(ctx);
  await finishRefresh(ctx);
}

const isMain = (() => {
  if (!process.argv[1]) return false;
  return fileURLToPath(import.meta.url) === path.resolve(process.argv[1]);
})();

if (isMain) {
  main().catch((error) => {
    if (error instanceof UsageError) {
      console.error(`Usage error: ${error.message}`);
      process.exitCode = 64;
      return;
    }
    console.error(error?.stack || String(error));
    process.exitCode = 2;
  });
}
