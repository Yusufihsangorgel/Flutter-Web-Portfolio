import { readFile } from 'node:fs/promises';
import { execFileSync } from 'node:child_process';

const portfolio = JSON.parse(
  await readFile(new URL('../assets/content/portfolio.json', import.meta.url)),
);
const profileGitHubUrl = new URL(
  portfolio.profile.links.find((link) => link.id === 'github')?.url ?? '',
);
const profileGitHubPath = profileGitHubUrl.pathname
  .split('/')
  .filter(Boolean);
if (profileGitHubUrl.hostname !== 'github.com' || profileGitHubPath.length !== 1) {
  throw new Error('profile.links must contain one canonical GitHub profile URL');
}
const expectedAuthor = profileGitHubPath[0];
const token = resolveGitHubToken();
const headers = {
  Accept: 'application/vnd.github+json',
  'User-Agent': 'flutter-web-portfolio-source-audit',
  'X-GitHub-Api-Version': '2022-11-28',
  ...(token ? { Authorization: `Bearer ${token}` } : {}),
};

const records = portfolio.contributions.map((contribution, index) => {
  const url = new URL(contribution.url);
  const match = url.pathname.match(/^\/([^/]+)\/([^/]+)\/pull\/(\d+)\/?$/);
  if (url.hostname !== 'github.com' || !match) {
    throw new Error(
      `contributions[${index}].url must be a GitHub pull-request URL`,
    );
  }
  return {
    contribution,
    endpoint: `https://api.github.com/repos/${match[1]}/${match[2]}/pulls/${match[3]}`,
  };
});

const results = await Promise.all(
  records.map(async ({ contribution, endpoint }) => {
    const response = await fetch(endpoint, { headers });
    if (!response.ok) {
      throw new Error(
        `${contribution.url}: GitHub returned ${response.status} ${response.statusText}`,
      );
    }
    const pullRequest = await response.json();
    const mergedDate = pullRequest.merged_at?.slice(0, 10) ?? null;
    const expectedMerged = contribution.status === 'merged';
    const actualAuthor = pullRequest.user?.login;

    if (actualAuthor?.toLowerCase() !== expectedAuthor.toLowerCase()) {
      throw new Error(
        `${contribution.url}: authored by ${actualAuthor ?? 'unknown'}, expected ${expectedAuthor}`,
      );
    }

    if (expectedMerged && mergedDate === null) {
      throw new Error(`${contribution.url}: marked merged but is not merged`);
    }
    if (expectedMerged && mergedDate !== contribution.date) {
      throw new Error(
        `${contribution.url}: merged ${mergedDate}, canonical date is ${contribution.date}`,
      );
    }
    if (!expectedMerged && (pullRequest.state !== 'open' || mergedDate !== null)) {
      throw new Error(
        `${contribution.url}: marked under_review but GitHub state is ${pullRequest.state}`,
      );
    }
    if (!expectedMerged && pullRequest.draft !== false) {
      throw new Error(
        `${contribution.url}: marked under_review but GitHub draft is ${pullRequest.draft}`,
      );
    }

    return `${contribution.project}: ${contribution.status} (${pullRequest.html_url})`;
  }),
);

console.log(
  `Verified ${results.length} contribution records against the GitHub API:\n${results
    .map((result) => `- ${result}`)
    .join('\n')}`,
);

function resolveGitHubToken() {
  const environmentToken = process.env.GITHUB_TOKEN?.trim();
  if (environmentToken) return environmentToken;
  try {
    return execFileSync('gh', ['auth', 'token'], {
      encoding: 'utf8',
      stdio: ['ignore', 'pipe', 'ignore'],
    }).trim();
  } catch {
    return null;
  }
}
