import { chromium } from '@playwright/test';
import { mkdir } from 'node:fs/promises';
import { fileURLToPath } from 'node:url';
import path from 'node:path';

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const source = path.join(root, 'tool', 'social_card.html');
const output = path.join(root, 'web', 'assets', 'og', 'engineering-showcase.png');

await mkdir(path.dirname(output), { recursive: true });
const browser = await chromium.launch({ headless: true });

try {
  const page = await browser.newPage({ viewport: { width: 1200, height: 630 } });
  await page.goto(`file://${source}`, { waitUntil: 'load' });
  await page.screenshot({ path: output, type: 'png' });
  process.stdout.write(`Rendered ${path.relative(root, output)} at 1200x630.\n`);
} finally {
  await browser.close();
}
