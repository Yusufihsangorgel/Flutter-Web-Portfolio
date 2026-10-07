import { existsSync, realpathSync, statSync } from 'node:fs';
import { isAbsolute, join, normalize, relative, resolve, sep } from 'node:path';

export class StaticPathViolation extends Error {}

export function canonicalStaticRoot(value) {
  return realpathSync(resolve(value));
}

// Mirrors `try_files $uri $uri/ =404`: unknown paths never fall back to the shell.
export function resolveStaticFile(root, requestPath, indexFile = 'index.html') {
  const relativePath = normalize(requestPath).replace(/^[/\\]+/, '');
  const candidate = resolve(root, relativePath || indexFile);
  assertContained(root, candidate);

  let filePath = resolveExistingPath(root, candidate);
  if (filePath && statSync(filePath).isDirectory()) {
    filePath = resolveExistingPath(root, join(filePath, 'index.html'));
  }
  return filePath && statSync(filePath).isFile() ? filePath : null;
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
