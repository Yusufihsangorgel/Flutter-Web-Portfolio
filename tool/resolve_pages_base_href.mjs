import path from 'node:path';
import process from 'node:process';
import { fileURLToPath } from 'node:url';

export function resolvePagesBaseHref({ repository, owner, cname, override }) {
  const explicit = override?.trim();
  if (explicit) return normalizeBaseHref(explicit);

  const repositoryName = requiredSegment(repository, 'repository');
  const ownerName = requiredSegment(owner, 'owner');
  if (cname?.trim()) return '/';
  if (repositoryName.toLowerCase() === `${ownerName.toLowerCase()}.github.io`) {
    return '/';
  }
  return `/${repositoryName}/`;
}

function normalizeBaseHref(value) {
  const comparable = decodeURIComponent(value.replaceAll('\\', '/'));
  if (
    /%2e/i.test(value) ||
    /(^|\/)\.{1,2}($|\/)/.test(comparable)
  ) {
    throw new Error('Pages base href must not traverse directories.');
  }
  const url = new URL(value, 'https://portfolio.invalid');
  if (url.origin !== 'https://portfolio.invalid' || url.search || url.hash) {
    throw new Error('Pages base href must be a root-relative path.');
  }
  const normalized = path.posix.normalize(url.pathname);
  const withLeadingSlash = normalized.startsWith('/')
    ? normalized
    : `/${normalized}`;
  return withLeadingSlash.endsWith('/')
    ? withLeadingSlash
    : `${withLeadingSlash}/`;
}

function requiredSegment(value, label) {
  const normalized = value?.trim();
  if (!normalized || normalized.includes('/') || normalized.includes('..')) {
    throw new Error(`${label} must be one repository path segment.`);
  }
  return normalized;
}

if (
  process.argv[1] &&
  path.resolve(process.argv[1]) === fileURLToPath(import.meta.url)
) {
  const options = parseArguments(process.argv.slice(2));
  process.stdout.write(`${resolvePagesBaseHref(options)}\n`);
}

function parseArguments(values) {
  const parsed = {};
  for (let index = 0; index < values.length; index += 2) {
    const option = values[index];
    const value = values[index + 1];
    if (!option?.startsWith('--') || value === undefined) {
      throw new Error('Expected --repository, --owner, --cname, and --override values.');
    }
    const key = option.slice(2);
    if (!['repository', 'owner', 'cname', 'override'].includes(key)) {
      throw new Error(`Unsupported option: ${option}`);
    }
    parsed[key] = value;
  }
  return parsed;
}
