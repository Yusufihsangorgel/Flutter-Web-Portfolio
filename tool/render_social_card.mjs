import { chromium } from '@playwright/test';
import { mkdir, readFile } from 'node:fs/promises';
import { fileURLToPath } from 'node:url';
import path from 'node:path';

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const source = path.join(root, 'tool', 'social_card.html');
const output = path.join(root, 'web', 'assets', 'og', 'engineering-showcase.png');
const portfolio = JSON.parse(
  await readFile(path.join(root, 'assets', 'content', 'portfolio.json'), 'utf8'),
);

await mkdir(path.dirname(output), { recursive: true });
const browser = await chromium.launch({ headless: true });

try {
  const page = await browser.newPage({ viewport: { width: 1200, height: 630 } });
  await page.goto(`file://${source}`, { waitUntil: 'load' });
  await page.evaluate((document) => {
    const words = document.profile.role.toUpperCase().split(/\s+/);
    const accent = words.pop();
    window.document.querySelector('[data-role-primary]').textContent =
      words.join(' ');
    window.document.querySelector('[data-role-accent]').textContent =
      `${accent}.`;
    window.document.querySelector('[data-focus]').textContent =
      document.profile.focus.slice(0, 3).join(' / ').toUpperCase();
    window.document.querySelector('[data-headline]').textContent =
      document.profile.headline;
    window.document.querySelector('[data-domain]').textContent =
      document.site.domain_label;
    window.document.title = `${document.profile.role} social card`;
  }, portfolio);
  await page.screenshot({ path: output, type: 'png' });
  process.stdout.write(`Rendered ${path.relative(root, output)} at 1200x630.\n`);
} finally {
  await browser.close();
}
