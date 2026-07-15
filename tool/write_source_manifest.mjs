import { mkdir, writeFile } from 'node:fs/promises';
import path from 'node:path';

import { portfolioRoot, renderSourceManifest } from './source_manifest.mjs';

const output = path.join(
  portfolioRoot,
  'assets',
  'build',
  'source_manifest.sha256',
);

await mkdir(path.dirname(output), { recursive: true });
await writeFile(output, await renderSourceManifest(portfolioRoot));
process.stdout.write('Wrote assets/build/source_manifest.sha256.\n');
