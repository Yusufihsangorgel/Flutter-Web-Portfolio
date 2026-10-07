import path from 'node:path';

export function resolveSafePublicPngPath(value, field = 'site.social_image') {
  let decodedInput;
  try {
    decodedInput = decodeURIComponent(String(value));
  } catch {
    throw new Error(`${field} contains invalid percent encoding`);
  }
  if (
    decodedInput.includes('\\') ||
    decodedInput.split(/[/?#]/).some((segment) => segment === '..')
  ) {
    throw new Error(`${field} must not traverse public asset directories`);
  }
  let pathname;
  try {
    pathname = new URL(value, 'https://portfolio.invalid').pathname;
  } catch {
    throw new Error(`${field} must be a valid public PNG asset path`);
  }
  let decoded;
  try {
    decoded = decodeURIComponent(pathname).replace(/^\/+/, '');
  } catch {
    throw new Error(`${field} contains invalid percent encoding`);
  }
  const segments = decoded.split('/');
  if (
    !decoded ||
    decoded.includes('\\') ||
    decoded.includes('\0') ||
    segments.some((segment) => segment === '..')
  ) {
    throw new Error(`${field} must not traverse public asset directories`);
  }
  const normalized = path.posix.normalize(decoded);
  if (
    normalized.startsWith('../') ||
    path.posix.isAbsolute(normalized) ||
    path.posix.extname(normalized).toLowerCase() !== '.png'
  ) {
    throw new Error(`${field} must resolve to a safe PNG asset path`);
  }
  return normalized;
}

export function resolveContainedPublicPath(root, relative, field = 'asset') {
  const absoluteRoot = path.resolve(root);
  const resolved = path.resolve(absoluteRoot, ...relative.split('/'));
  const containment = path.relative(absoluteRoot, resolved);
  if (
    containment === '..' ||
    containment.startsWith(`..${path.sep}`) ||
    path.isAbsolute(containment)
  ) {
    throw new Error(`${field} escapes its public root`);
  }
  return resolved;
}
