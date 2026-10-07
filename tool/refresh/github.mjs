const GITHUB_PULL_PATTERN =
  /^https:\/\/github\.com\/([A-Za-z0-9_.-]+)\/([A-Za-z0-9_.-]+)\/pull\/(\d+)\/?$/;

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
