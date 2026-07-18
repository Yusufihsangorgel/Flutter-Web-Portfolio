import path from 'node:path';

const baseSegment = /^[A-Za-z0-9._~-]+$/;
const providerId = /^[A-Za-z0-9][A-Za-z0-9._-]{0,127}$/;
const cloudflareProject = /^[a-z0-9](?:[a-z0-9_-]{0,56}[a-z0-9])?$/;
const firebaseProject = /^[a-z][a-z0-9-]{4,28}[a-z0-9]$/;
const dockerReference = /^(?:[A-Za-z0-9.-]+(?::[0-9]{1,5})\/)?[a-z0-9]+(?:[._-][a-z0-9]+)*(?:\/[a-z0-9]+(?:[._-][a-z0-9]+)*)*(?::[A-Za-z0-9_][A-Za-z0-9_.-]{0,127})?(?:@sha256:[0-9a-f]{64})?$/;

export function normalizeBaseHref(value) {
  const raw = requiredText(value, '--base-href');
  if (
    raw.includes('\\') ||
    raw.includes('\0') ||
    raw.includes('?') ||
    raw.includes('#') ||
    raw.includes('%') ||
    raw.startsWith('//') ||
    raw.includes('//') ||
    raw.includes('://')
  ) {
    throw new Error('--base-href must be a local absolute URL path');
  }

  let decoded;
  try {
    decoded = decodeURIComponent(raw);
  } catch {
    throw new Error('--base-href contains invalid percent encoding');
  }
  if (
    decoded.includes('\\') ||
    decoded.includes('?') ||
    decoded.includes('#') ||
    decoded.includes('%')
  ) {
    throw new Error('--base-href must not contain encoded path separators or URL metadata');
  }

  const withLeadingSlash = decoded.startsWith('/') ? decoded : `/${decoded}`;
  const segments = withLeadingSlash.split('/');
  if (
    segments.some(
      (segment, index) =>
        (index > 0 && (segment === '.' || segment === '..')) ||
        (segment.length > 0 && !baseSegment.test(segment)),
    )
  ) {
    throw new Error('--base-href contains an unsafe path segment');
  }
  const normalized = path.posix.normalize(withLeadingSlash);
  if (!normalized.startsWith('/') || normalized.startsWith('//')) {
    throw new Error('--base-href must remain within the hosting origin');
  }
  return normalized.endsWith('/') ? normalized : `${normalized}/`;
}

export function validateDeploymentValue(kind, value) {
  const candidate = requiredText(value, kind);
  switch (kind) {
    case 'firebase-project':
      if (!firebaseProject.test(candidate)) invalid(kind);
      break;
    case 'cloudflare-project':
      if (!cloudflareProject.test(candidate)) invalid(kind);
      break;
    case 'netlify-site':
      if (!providerId.test(candidate)) invalid(kind);
      break;
    case 'docker-image':
      if (!dockerReference.test(candidate)) invalid(kind);
      break;
    default:
      throw new Error(`Unknown deployment value kind: ${kind}`);
  }
  return candidate;
}

// Node does not resolve npm-style Windows shims without a shell. Resolve only
// the known executable suffixes and keep shell:false so user data is never
// reparsed as command text.
export function resolveExecutable(command, platform = process.platform) {
  if (platform !== 'win32' || path.extname(command)) return command;
  if (command === 'flutter' || command === 'dart') return `${command}.bat`;
  if (
    ['npm', 'npx', 'firebase', 'netlify', 'wrangler', 'vercel'].includes(command)
  ) {
    return `${command}.cmd`;
  }
  return command;
}

function requiredText(value, label) {
  if (typeof value !== 'string' || value.length === 0 || value.trim() !== value) {
    throw new Error(`${label} must be a non-empty value without surrounding whitespace`);
  }
  if (/[^\x21-\x7e]/.test(value)) {
    throw new Error(`${label} contains unsupported control or non-ASCII characters`);
  }
  return value;
}

function invalid(kind) {
  throw new Error(`Invalid ${kind} value`);
}
