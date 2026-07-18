import { createHash } from 'node:crypto';
import { readFile, readdir } from 'node:fs/promises';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

export const portfolioRoot = path.resolve(
  path.dirname(fileURLToPath(import.meta.url)),
  '..',
);

// Local path packages are part of the executable source graph just as much as
// lib/. Omitting them would let a tracked release pass provenance verification
// after its runtime dependency had changed.
const sourceDirectories = ['assets', 'lib', 'packages', 'tool', 'web'];
const sourceFiles = [
  'analysis_options.yaml',
  'package.json',
  'package-lock.json',
  'pubspec.yaml',
  'pubspec.lock',
];
const generatedManifest = 'assets/build/source_manifest.sha256';

export async function renderSourceManifest(root = portfolioRoot) {
  const files = [
    ...sourceFiles,
    ...(
      await Promise.all(
        sourceDirectories.map((directory) =>
          collectFiles(path.join(root, directory), root),
        ),
      )
    ).flat(),
  ]
    .filter((file) => file !== generatedManifest)
    .sort((left, right) => left.localeCompare(right));

  const lines = await Promise.all(
    files.map(async (file) => {
      const content = await readFile(path.join(root, file));
      const digest = createHash('sha256').update(content).digest('hex');
      return `${digest}  ${file}`;
    }),
  );
  return `${lines.join('\n')}\n`;
}

async function collectFiles(directory, root) {
  const entries = await readdir(directory, { withFileTypes: true });
  const nested = await Promise.all(
    entries.map(async (entry) => {
      const absolute = path.join(directory, entry.name);
      if (entry.isDirectory()) return collectFiles(absolute, root);
      return [path.relative(root, absolute).split(path.sep).join('/')];
    }),
  );
  return nested.flat();
}
