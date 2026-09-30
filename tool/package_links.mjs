import { readFile, readdir, writeFile } from 'node:fs/promises';
import path from 'node:path';

// Reads the package.json repository, which sync rewrites for every clone, so a repeated init still resolves it.
export function findTemplateRepository(manifest) {
  const raw = typeof manifest.repository === 'string' ? manifest.repository : manifest.repository?.url;
  const url = URL.parse(String(raw ?? '').replace(/^git\+/, '').replace(/\.git$/, ''));
  if (url?.protocol !== 'https:' || url.hostname !== 'github.com' ||
      url.pathname.split('/').filter(Boolean).length !== 2) {
    throw new Error('package.json must name the GitHub source repository.');
  }
  return url.href.replace(/\/$/, '');
}

export function rewritePubspecLinks(source, original, replacement) {
  const field = /^((?:homepage|repository|issue_tracker|documentation):[ \t]*)(['"]?)(https?:\/\/[^\s'"]+)\2(?=[ \t]*(?:#.*)?$)/gm;
  return source.replace(field, (match, prefix, quote, value) => {
    if (!value.startsWith(original)) return match;
    const suffix = value.slice(original.length);
    if (suffix && !/^(?:[/?#]|\.git(?:$|[/?#]))/.test(suffix)) return match;
    return `${prefix}${quote}${replacement}${suffix}${quote}`;
  });
}

export async function rewritePackageLinks(root, original, repository) {
  const directory = path.join(root, 'packages');
  const entries = await readdir(directory, { withFileTypes: true });
  const replacement = `https://github.com/${repository}`;
  for (const entry of entries) {
    if (!entry.isDirectory()) continue;
    const file = path.join(directory, entry.name, 'pubspec.yaml');
    let source;
    try {
      source = await readFile(file, 'utf8');
    } catch (error) {
      if (error.code === 'ENOENT') continue;
      throw error;
    }
    const next = rewritePubspecLinks(source, original, replacement);
    if (next !== source) await writeFile(file, next);
  }
}
