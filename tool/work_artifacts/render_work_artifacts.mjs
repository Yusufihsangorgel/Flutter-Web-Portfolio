import { chromium } from '@playwright/test';
import { mkdir } from 'node:fs/promises';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

import { renderArtifacts } from './artifact_plan.mjs';
import {
  renderInputDigest,
  verifyArtifacts,
  workArtifactPaths,
  writeArtifacts,
} from './manifest.mjs';
import { boardFrame } from './page.mjs';
import { createArtifactRenderer } from './renderer.mjs';

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '../..');
const paths = workArtifactPaths(root);

if (process.argv.includes('--check')) {
  const failures = await verifyArtifacts(paths);
  if (failures.length > 0) {
    process.stderr.write(
      `${failures.map((failure) => `- ${failure}`).join('\n')}\n` +
        'Work artifacts are stale. Run `node tool/work_artifacts/render_work_artifacts.mjs` ' +
        'and commit assets/work plus tool/work_sources/artifact-manifest.json.\n',
    );
    process.exit(1);
  }
  process.stdout.write('Work artifacts match their renderer inputs.\n');
  process.exit(0);
}

await mkdir(paths.output, { recursive: true });
const browser = await chromium.launch({ headless: true });

try {
  const page = await browser.newPage({
    viewport: { width: boardFrame.width, height: boardFrame.height },
    deviceScaleFactor: 1,
  });
  const renderer = createArtifactRenderer(page, paths);
  await renderArtifacts(renderer);
  await writeArtifacts(paths, {
    outputs: renderer.outputs,
    inputDigest: await renderInputDigest(paths),
    renderer: `Chromium ${browser.version()}`,
  });
} finally {
  await browser.close();
}
