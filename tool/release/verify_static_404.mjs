import { readFile } from 'node:fs/promises';
import path from 'node:path';

import { releaseBaseHref, renderNotFoundPage } from './not_found_page.mjs';

const releaseFiles = ['404.html', '.well-known/security.txt'];
const nginxFailure =
  'Nginx must return 404 for unknown paths using /404.html without an index fallback';
const nginxPackaging = /^COPY\s+nginx\/default\.conf\s+\/etc\/nginx\/conf\.d\/default\.conf\s*$/m;
const releasePackaging = /^COPY\s+build\/web\s+\/usr\/share\/nginx\/html\s*$/m;
const indexFallbackRule = /^\s*\/\*\s+\/(?:index\.html)?(?=\s|$)/m;

export async function verifyStatic404Release({ sourceRoot, webRoot }) {
  const [nginx, dockerfile, redirects] = await Promise.all([
    readText(path.join(sourceRoot, 'nginx', 'default.conf')),
    readText(path.join(sourceRoot, 'Dockerfile')),
    readText(path.join(sourceRoot, 'web', '_redirects')),
  ]);
  return [
    ...(await releaseFileIssues(sourceRoot, webRoot)),
    ...nginxIssues(nginx ?? ''),
    ...dockerfileIssues(dockerfile ?? ''),
    ...(indexFallbackRule.test(redirects ?? '') ? ['_redirects contains an index fallback'] : []),
  ];
}

async function releaseFileIssues(sourceRoot, webRoot) {
  const issues = [];
  for (const relative of releaseFiles) {
    const source = await readText(path.join(sourceRoot, 'web', relative));
    const release = await readText(path.join(webRoot, relative));
    if (!source?.trim()) issues.push(`source ${relative} is missing or empty`);
    if (!release?.trim()) issues.push(`${relative} is missing or empty in the release`);
    else if (source) {
      const expected = await expectedReleaseFile(relative, source, webRoot);
      if (expected.issue) issues.push(expected.issue);
      else if (release !== expected.text) issues.push(`${relative} is stale in the release`);
    }
  }
  return issues;
}

async function expectedReleaseFile(relative, source, webRoot) {
  if (relative !== '404.html') return { text: source };
  try {
    const index = await readText(path.join(webRoot, 'index.html'));
    return { text: renderNotFoundPage(source, releaseBaseHref(index ?? '')) };
  } catch (error) {
    return { issue: `404.html cannot be checked: ${error.message}` };
  }
}

// Locations other than `location /` may keep narrow rewrites; only the root
// location and the server scope decide what an unknown path returns.
function nginxIssues(source) {
  const nginx = source.replace(/#.*$/gm, '');
  const rootLocation = nginx.match(/\blocation\s+\/\s*\{([^}]*)\}/)?.[1] ?? '';
  // Quoted and unquoted runs cannot overlap, so the match stays linear.
  const serverScope = nginx.replace(/\blocation(?=\s)[^{};"]*(?:"[^"]*"[^{};"]*)*\{[^}]*\}/g, '');
  const unknownPathScope = `${rootLocation}\n${serverScope}`;
  const returns404 =
    /\btry_files\s+\$uri\s+\$uri\/\s+=404\s*;/.test(rootLocation) &&
    /\berror_page\s+404\s+\/404\.html\s*;/.test(unknownPathScope);
  const fallsBack =
    /\b(?:try_files|rewrite)\s+[^;]*\s+\/(?:index\.html)?(?=\s|;)/.test(rootLocation) ||
    hasServerFallback(serverScope) ||
    /\breturn\s+200\b/.test(rootLocation) ||
    /\breturn\s+200\b/.test(serverScope) ||
    /\berror_page\s+404\s+(?:=\d{3}|=)?\s*\/index\.html\s*;/.test(unknownPathScope);
  return returns404 && !fallsBack ? [] : [nginxFailure];
}

function hasServerFallback(serverScope) {
  if (/\btry_files\s+[^;]*\s+\/(?:index\.html)?(?=\s|;)/.test(serverScope)) return true;
  const catchAll = new Set(['', '.*', '(.*)']);
  return [...serverScope.matchAll(/\brewrite\s+(\S+)\s+\/(?:index\.html)?(?=\s|;)/g)].some(
    ([, pattern]) => catchAll.has(pattern.replace(/^\^\/?/, '').replace(/\$$/, '')),
  );
}

function dockerfileIssues(dockerfile) {
  const issues = [];
  if (!nginxPackaging.test(dockerfile)) {
    issues.push('Dockerfile does not package the verified Nginx configuration');
  }
  if (!releasePackaging.test(dockerfile)) {
    issues.push('Dockerfile does not package the verified release files');
  }
  return issues;
}

async function readText(file) {
  try {
    return await readFile(file, 'utf8');
  } catch {
    return null;
  }
}
