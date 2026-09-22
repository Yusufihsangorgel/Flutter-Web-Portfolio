// Refreshes the package and contribution records in
// assets/content/portfolio.json from pub.dev and the GitHub API, without
// touching any hand-authored copy (roadmap, maturity, proof, contribution
// prose). See docs/AUTOMATION.md for what this does and does not cover.
import { readFile, writeFile } from 'node:fs/promises';
import path from 'node:path';
import process from 'node:process';
import { fileURLToPath } from 'node:url';

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const DEFAULT_FILE = path.join(root, 'assets', 'content', 'portfolio.json');
const USER_AGENT = 'flutter-web-portfolio-refresh';
const GITHUB_PULL_PATTERN =
  /^https:\/\/github\.com\/([A-Za-z0-9_.-]+)\/([A-Za-z0-9_.-]+)\/pull\/(\d+)\/?$/;

export class UsageError extends Error {}

// ---------------------------------------------------------------------------
// Pure logic: no network, no filesystem. Every function here is exported so
// tool/test_refresh_portfolio_data.mjs can exercise it against fixtures.
// ---------------------------------------------------------------------------

export function parseArgs(argv) {
  const options = { check: false, counters: false, report: null, file: null };
  for (let index = 0; index < argv.length; index += 1) {
    const arg = argv[index];
    switch (arg) {
      case '--check':
        options.check = true;
        break;
      case '--counters':
        options.counters = true;
        break;
      case '--report': {
        const value = argv[index + 1];
        if (!value) throw new UsageError('--report requires a path');
        options.report = value;
        index += 1;
        break;
      }
      case '--file': {
        const value = argv[index + 1];
        if (!value) throw new UsageError('--file requires a path');
        options.file = value;
        index += 1;
        break;
      }
      default:
        throw new UsageError(`Unknown argument: ${arg}`);
    }
  }
  return options;
}

export function parseGithubPullUrl(url) {
  const match = typeof url === 'string' ? GITHUB_PULL_PATTERN.exec(url) : null;
  if (!match) return null;
  return { owner: match[1], repo: match[2], number: Number(match[3]) };
}

export function extractGithubLogin(document) {
  const links = document?.profile?.links;
  const link = Array.isArray(links) ? links.find((entry) => entry?.id === 'github') : null;
  if (!link || typeof link.url !== 'string') return null;
  let url;
  try {
    url = new URL(link.url);
  } catch {
    return null;
  }
  if (url.hostname !== 'github.com') return null;
  const segments = url.pathname.split('/').filter(Boolean);
  return segments.length === 1 ? segments[0] : null;
}

/**
 * pub.dev's public score response (`VersionScore` in pub-dev's own
 * pkg/_pub_shared/lib/data/package_api.dart) carries only grantedPoints,
 * maxPoints, likeCount, downloadCount30Days, and tags. It names neither the
 * analysed version nor a lastUpdated timestamp, so grantedPoints being
 * null/absent is the only signal the public API exposes for "the pana run
 * for the latest version has not landed yet" — verified against a live
 * response and against that source file before writing this guard.
 */
export function extractPackageFacts(packageResponse, scoreResponse) {
  const latest = packageResponse?.latest;
  if (!latest || typeof latest.version !== 'string' || latest.version.length === 0) {
    throw new Error('pub.dev package response is missing latest.version');
  }
  const pubspec = latest.pubspec && typeof latest.pubspec === 'object' ? latest.pubspec : {};
  const topics = Array.isArray(pubspec.topics)
    ? pubspec.topics.filter((topic) => typeof topic === 'string')
    : [];
  if (!scoreResponse || typeof scoreResponse !== 'object') {
    throw new Error('pub.dev score response is not an object');
  }
  const grantedPoints = scoreResponse.grantedPoints;
  const scorePending = grantedPoints === null || grantedPoints === undefined;
  if (!scorePending && typeof grantedPoints !== 'number') {
    throw new Error('pub.dev score response has a non-numeric grantedPoints');
  }
  return {
    version: latest.version,
    topics,
    // Counters are not rendered, so a missing one keeps the stored value
    // instead of blocking the whole refresh.
    likes: typeof scoreResponse.likeCount === 'number' ? scoreResponse.likeCount : null,
    downloads:
      typeof scoreResponse.downloadCount30Days === 'number'
        ? scoreResponse.downloadCount30Days
        : null,
    pubPoints: scorePending ? null : grantedPoints,
    scorePending,
  };
}

function sameStringArray(a, b) {
  return (
    Array.isArray(a) &&
    Array.isArray(b) &&
    a.length === b.length &&
    a.every((value, index) => value === b[index])
  );
}

export const COUNTER_FIELDS = new Set(['topics', 'likes', 'downloads']);

/**
 * Mutates `pkg` in place — never rebuilds the object from a field list — so
 * any field the schema does not know about survives untouched, and the key
 * order emitted by JSON.stringify is exactly the order the file already had.
 *
 * `description` is authored site copy that intentionally differs from the
 * pubspec description, so it is never overwritten. `topics` is stored but not
 * rendered, so it refreshes as a counter.
 */
export function applyPackageFacts(pkg, facts) {
  const changedFields = [];
  let visibleChanged = false;
  let counterChanged = false;

  if (facts.version !== pkg.version) {
    pkg.version = facts.version;
    visibleChanged = true;
    changedFields.push('version');
  }
  if (!sameStringArray(facts.topics, pkg.topics)) {
    pkg.topics = facts.topics;
    counterChanged = true;
    changedFields.push('topics');
  }

  let pendingScore = false;
  if (facts.scorePending) {
    pendingScore = true;
  } else if (facts.pubPoints !== pkg.pub_points) {
    pkg.pub_points = facts.pubPoints;
    visibleChanged = true;
    changedFields.push('pub_points');
  }

  if (facts.likes !== null && facts.likes !== pkg.likes) {
    pkg.likes = facts.likes;
    counterChanged = true;
    changedFields.push('likes');
  }
  if (facts.downloads !== null && facts.downloads !== pkg.downloads) {
    pkg.downloads = facts.downloads;
    counterChanged = true;
    changedFields.push('downloads');
  }

  return { visibleChanged, counterChanged, pendingScore, changedFields };
}

/** Only entries already marked `under_review` can change: a `merged` entry
 * has nothing left to learn from this check, and the schema gives closed
 * work no third status to move to. */
export function applyContributionFacts(contribution, pullRequest) {
  if (contribution.status !== 'under_review') {
    return { changed: false, outcome: 'not_applicable' };
  }
  if (pullRequest.merged_at) {
    const mergedDate = String(pullRequest.merged_at).slice(0, 10);
    contribution.status = 'merged';
    contribution.date = mergedDate;
    return { changed: true, outcome: 'merged', mergedDate };
  }
  if (pullRequest.state === 'closed') {
    return { changed: false, outcome: 'closed_unmerged' };
  }
  return { changed: false, outcome: 'still_open' };
}

export function bumpContentVersion(current, todayIso) {
  const todayKey = todayIso.replaceAll('-', '.');
  const match = /^(\d{4}\.\d{2}\.\d{2})\.(\d+)$/.exec(typeof current === 'string' ? current : '');
  if (match && match[1] === todayKey) {
    return `${todayKey}.${Number(match[2]) + 1}`;
  }
  return `${todayKey}.1`;
}

/**
 * `verified_at` is published as the date every listed source was checked by
 * hand; this tool checks only pub.dev and GitHub, so it never touches it.
 */
export function applyContentVersionBump(document, { shouldWrite, hasVisible }, todayIso) {
  if (shouldWrite && hasVisible) {
    document.content_version = bumpContentVersion(document.content_version, todayIso);
  }
}

export function buildCandidateSearchUrl(login, page = 1) {
  const query = `author:${login} is:pr is:merged is:public -user:${login}`;
  const params = new URLSearchParams({ q: query, per_page: '100', page: String(page) });
  return `https://api.github.com/search/issues?${params.toString()}`;
}

export function extractCandidateRecord(item) {
  const match = /^https:\/\/api\.github\.com\/repos\/([^/]+)\/([^/]+)$/.exec(
    item?.repository_url ?? '',
  );
  const mergedAt = item?.pull_request?.merged_at ?? item?.closed_at ?? null;
  return {
    url: item?.html_url ?? null,
    title: item?.title ?? null,
    owner: match ? match[1] : null,
    repo: match ? match[2] : null,
    mergedDate: mergedAt ? String(mergedAt).slice(0, 10) : null,
  };
}

function normalizeUrl(url) {
  return typeof url === 'string' ? url.replace(/\/+$/, '').toLowerCase() : null;
}

export function filterNewCandidates(records, existingUrls) {
  const existing = new Set(existingUrls.map(normalizeUrl).filter(Boolean));
  const seen = new Set();
  const result = [];
  for (const record of records) {
    const key = normalizeUrl(record.url);
    if (!key || existing.has(key) || seen.has(key)) continue;
    seen.add(key);
    result.push(record);
  }
  return result;
}

export function groupCandidatesByRepo(records) {
  const groups = new Map();
  for (const record of records) {
    const key = record.owner && record.repo ? `${record.owner}/${record.repo}` : 'unknown';
    if (!groups.has(key)) groups.set(key, []);
    groups.get(key).push(record);
  }
  return [...groups.entries()]
    .sort((a, b) => a[0].localeCompare(b[0]))
    .map(([repo, items]) => ({ repo, items }));
}

export function decideWrite({ anyFailure, check, hasVisible, hasCounters, includeCounters }) {
  return !anyFailure && !check && (hasVisible || (hasCounters && includeCounters));
}

export function buildReport(summary) {
  const lines = [`# Portfolio data refresh — ${summary.generatedAt}`, ''];

  lines.push('## Visible changes', '');
  if (summary.visibleChanges.length === 0) {
    lines.push('None.');
  } else {
    for (const change of summary.visibleChanges) lines.push(`- ${change}`);
  }
  lines.push('');

  lines.push('## Counter-only changes', '');
  if (summary.counterChanges.length === 0) {
    lines.push('None.');
  } else {
    for (const change of summary.counterChanges) lines.push(`- ${change}`);
  }
  lines.push('');

  lines.push('## Pending pub.dev score', '');
  if (summary.pendingScorePackages.length === 0) {
    lines.push('None.');
  } else {
    for (const name of summary.pendingScorePackages) {
      lines.push(`- \`${name}\`: pub.dev has not published a score for the latest version yet.`);
    }
  }
  lines.push('');

  lines.push('## Closed without merging', '');
  if (summary.closedUnmergedContributions.length === 0) {
    lines.push('None.');
  } else {
    for (const item of summary.closedUnmergedContributions) {
      lines.push(`- \`${item.id}\`: ${item.url} closed without merging; entry left unchanged.`);
    }
  }
  lines.push('');

  lines.push('## Fetch failures', '');
  if (summary.failures.length === 0) {
    lines.push('None.');
  } else {
    for (const failure of summary.failures) lines.push(`- ${failure}`);
  }
  lines.push('');

  lines.push('## Candidate pull requests not yet in contributions', '');
  if (summary.candidatesError) {
    lines.push(`Could not be determined: ${summary.candidatesError}`);
  } else if (summary.candidateGroups.length === 0) {
    lines.push('None.');
  } else {
    for (const group of summary.candidateGroups) {
      lines.push(`### ${group.repo}`, '');
      for (const item of group.items) {
        lines.push(`- [${item.title}](${item.url})${item.mergedDate ? ` — merged ${item.mergedDate}` : ''}`);
      }
      lines.push('');
    }
  }

  return `${lines.join('\n').trimEnd()}\n`;
}

// ---------------------------------------------------------------------------
// Thin I/O layer.
// ---------------------------------------------------------------------------

function delay(ms) {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

function createLimiter(limit) {
  let active = 0;
  const queue = [];
  const runNext = () => {
    if (active >= limit || queue.length === 0) return;
    active += 1;
    const { fn, resolve, reject } = queue.shift();
    fn().then(
      (value) => {
        active -= 1;
        resolve(value);
        runNext();
      },
      (error) => {
        active -= 1;
        reject(error);
        runNext();
      },
    );
  };
  return function run(fn) {
    return new Promise((resolve, reject) => {
      queue.push({ fn, resolve, reject });
      runNext();
    });
  };
}

async function fetchJson(url, { headers, attempts = 3 } = {}) {
  let lastError = null;
  for (let attempt = 1; attempt <= attempts; attempt += 1) {
    try {
      const response = await fetch(url, { headers });
      if (response.ok) {
        return { ok: true, status: response.status, body: await response.json() };
      }
      if (response.status >= 500 || response.status === 429) {
        lastError = new Error(`${url} responded ${response.status}`);
      } else {
        let body = null;
        try {
          body = await response.json();
        } catch {
          // Non-JSON error body; keep body null.
        }
        return { ok: false, status: response.status, body, error: null };
      }
    } catch (error) {
      lastError = error;
    }
    if (attempt < attempts) await delay(attempt * 500);
  }
  return { ok: false, status: null, body: null, error: lastError };
}

function describeFetchFailure(result, label) {
  if (result.error) return `${label}: ${result.error.message}`;
  return `${label}: HTTP ${result.status}`;
}

async function main() {
  const options = parseArgs(process.argv.slice(2));
  const filePath = options.file ? path.resolve(options.file) : DEFAULT_FILE;
  const raw = await readFile(filePath, 'utf8');
  const document = JSON.parse(raw);

  const token = process.env.GITHUB_TOKEN?.trim() || null;
  const githubHeaders = {
    Accept: 'application/vnd.github+json',
    'User-Agent': USER_AGENT,
    'X-GitHub-Api-Version': '2022-11-28',
    ...(token ? { Authorization: `Bearer ${token}` } : {}),
  };
  const pubHeaders = { 'User-Agent': USER_AGENT };

  const limiter = createLimiter(6);
  const failures = [];

  const packages = Array.isArray(document.packages) ? document.packages : [];
  const packageFetches = packages.map((pkg) => ({
    pkg,
    infoPromise: limiter(() =>
      fetchJson(`https://pub.dev/api/packages/${encodeURIComponent(pkg.name)}`, {
        headers: pubHeaders,
      }),
    ),
    scorePromise: limiter(() =>
      fetchJson(`https://pub.dev/api/packages/${encodeURIComponent(pkg.name)}/score`, {
        headers: pubHeaders,
      }),
    ),
  }));

  const contributions = Array.isArray(document.contributions) ? document.contributions : [];
  const contributionFetches = contributions
    .filter((contribution) => contribution.status === 'under_review')
    .map((contribution) => {
      const parsed = parseGithubPullUrl(contribution.url);
      if (!parsed) return null;
      return {
        contribution,
        promise: limiter(() =>
          fetchJson(
            `https://api.github.com/repos/${parsed.owner}/${parsed.repo}/pulls/${parsed.number}`,
            { headers: githubHeaders },
          ),
        ),
      };
    })
    .filter(Boolean);

  const visibleChanges = [];
  const counterChanges = [];
  const pendingScorePackages = [];
  let anyFailure = false;

  for (const { pkg, infoPromise, scorePromise } of packageFetches) {
    const [infoResult, scoreResult] = await Promise.all([infoPromise, scorePromise]);
    if (!infoResult.ok) {
      failures.push(describeFetchFailure(infoResult, `${pkg.name}: pub.dev package lookup`));
      anyFailure = true;
      continue;
    }
    if (!scoreResult.ok) {
      failures.push(describeFetchFailure(scoreResult, `${pkg.name}: pub.dev score lookup`));
      anyFailure = true;
      continue;
    }
    let facts;
    try {
      facts = extractPackageFacts(infoResult.body, scoreResult.body);
    } catch (error) {
      failures.push(`${pkg.name}: ${error.message}`);
      anyFailure = true;
      continue;
    }
    const outcome = applyPackageFacts(pkg, facts);
    if (outcome.pendingScore) pendingScorePackages.push(pkg.name);
    if (outcome.visibleChanged) {
      visibleChanges.push(`${pkg.name}: ${outcome.changedFields.filter((f) => !COUNTER_FIELDS.has(f)).join(', ')}`);
    }
    if (outcome.counterChanged) {
      counterChanges.push(`${pkg.name}: ${outcome.changedFields.filter((f) => COUNTER_FIELDS.has(f)).join(', ')}`);
    }
  }

  const closedUnmergedContributions = [];
  for (const { contribution, promise } of contributionFetches) {
    const result = await promise;
    if (!result.ok) {
      failures.push(describeFetchFailure(result, `${contribution.id}: GitHub pull request lookup`));
      anyFailure = true;
      continue;
    }
    const outcome = applyContributionFacts(contribution, result.body);
    if (outcome.changed) {
      visibleChanges.push(`${contribution.id}: status -> merged (${outcome.mergedDate})`);
    } else if (outcome.outcome === 'closed_unmerged') {
      closedUnmergedContributions.push({ id: contribution.id, url: contribution.url });
    }
  }

  // Candidate discovery only runs when portfolio.json itself names the
  // GitHub account (via profile.links); it is report-only and never blocks
  // the write, since a search-quota hiccup here should not stop a real,
  // successfully fetched package/contribution refresh from being written.
  let candidateGroups = [];
  let candidatesError = null;
  const login = extractGithubLogin(document);
  if (login) {
    try {
      const existingUrls = contributions.map((c) => c.url).filter((u) => typeof u === 'string');
      const records = [];
      let page = 1;
      let total = Infinity;
      while ((page - 1) * 100 < total) {
        const result = await limiter(() =>
          fetchJson(buildCandidateSearchUrl(login, page), { headers: githubHeaders }),
        );
        if (!result.ok) {
          candidatesError = describeFetchFailure(result, 'GitHub search');
          break;
        }
        total = typeof result.body.total_count === 'number' ? result.body.total_count : 0;
        const items = Array.isArray(result.body.items) ? result.body.items : [];
        for (const item of items) records.push(extractCandidateRecord(item));
        if (items.length === 0) break;
        page += 1;
      }
      if (!candidatesError) {
        candidateGroups = groupCandidatesByRepo(filterNewCandidates(records, existingUrls));
      }
    } catch (error) {
      candidatesError = error.message;
    }
  } else {
    candidatesError = 'portfolio.json has no profile.links entry with id "github"';
  }

  const todayIso = new Date().toISOString().slice(0, 10);
  const hasVisible = visibleChanges.length > 0;
  const hasCounters = counterChanges.length > 0;
  const shouldWrite = decideWrite({
    anyFailure,
    check: options.check,
    hasVisible,
    hasCounters,
    includeCounters: options.counters,
  });

  applyContentVersionBump(document, { shouldWrite, hasVisible }, todayIso);
  if (shouldWrite) {
    await writeFile(filePath, `${JSON.stringify(document, null, 2)}\n`);
  }

  const summaryLines = [
    `Packages checked: ${packages.length}`,
    `Contributions checked: ${contributionFetches.length} (of ${contributions.length} total, only under_review entries)`,
    `Visible changes: ${visibleChanges.length}`,
    `Counter-only changes: ${counterChanges.length}`,
    `Pending pub.dev score: ${pendingScorePackages.length}`,
    `Closed without merging: ${closedUnmergedContributions.length}`,
    `Fetch failures: ${failures.length}`,
    `Candidates: ${candidatesError ? `unavailable (${candidatesError})` : candidateGroups.reduce((total, group) => total + group.items.length, 0)}`,
    shouldWrite
      ? `Wrote ${path.relative(root, filePath)}.`
      : anyFailure
        ? 'Did not write: a fetch failed (all-or-nothing).'
        : options.check
          ? 'Did not write: --check.'
          : 'Did not write: no visible change (counter-only changes need --counters).',
  ];
  console.log(summaryLines.join('\n'));

  if (options.report) {
    const report = buildReport({
      generatedAt: new Date().toISOString(),
      visibleChanges,
      counterChanges,
      pendingScorePackages,
      closedUnmergedContributions,
      failures,
      candidateGroups,
      candidatesError,
    });
    await writeFile(path.resolve(options.report), report);
  }

  if (anyFailure) {
    process.exitCode = 2;
  } else if (options.check) {
    process.exitCode = hasVisible ? 1 : 0;
  } else {
    process.exitCode = 0;
  }
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
