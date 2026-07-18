import { existsSync, realpathSync, statSync } from 'node:fs';
import { extname, isAbsolute, join, normalize, relative, resolve, sep } from 'node:path';

export class StaticPathViolation extends Error {}

export function canonicalStaticRoot(value) {
  return realpathSync(resolve(value));
}

export function resolveStaticFile(root, requestPath, fallback = 'index.html') {
  const relativePath = normalize(requestPath).replace(/^[/\\]+/, '');
  const candidate = resolve(root, relativePath || fallback);
  assertContained(root, candidate);

  let filePath = resolveExistingPath(root, candidate);
  if (filePath && statSync(filePath).isDirectory()) {
    filePath = resolveExistingPath(root, join(filePath, 'index.html'));
  }
  if (filePath && statSync(filePath).isFile()) return filePath;
  if (extname(relativePath)) return null;

  const fallbackPath = resolveExistingPath(root, resolve(root, fallback));
  if (!fallbackPath || !statSync(fallbackPath).isFile()) return null;
  return fallbackPath;
}

function resolveExistingPath(root, candidate) {
  if (!existsSync(candidate)) return null;
  let canonical;
  try {
    canonical = realpathSync(candidate);
  } catch (error) {
    if (error?.code === 'ENOENT') return null;
    throw error;
  }
  assertContained(root, canonical);
  return canonical;
}

function assertContained(root, candidate) {
  const rootRelativePath = relative(root, candidate);
  if (
    rootRelativePath === '..' ||
    rootRelativePath.startsWith(`..${sep}`) ||
    isAbsolute(rootRelativePath)
  ) {
    throw new StaticPathViolation('Static path escapes the configured web root.');
  }
}
