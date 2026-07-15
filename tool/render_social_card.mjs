import { chromium } from '@playwright/test';
import { access, copyFile, mkdir, readFile } from 'node:fs/promises';
import { fileURLToPath } from 'node:url';
import path from 'node:path';

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const source = path.join(root, 'tool', 'social_card.html');
const portfolio = JSON.parse(
  await readFile(path.join(root, 'assets', 'content', 'portfolio.json'), 'utf8'),
);
const displayName = portfolio.profile?.display_name;
for (const field of ['primary', 'accent', 'navigation', 'accessible']) {
  requiredString(displayName?.[field], `profile.display_name.${field}`);
}
const socialImagePath = resolveSocialImagePath(portfolio.site.social_image);
const output = path.join(root, 'web', ...socialImagePath.split('/'));
const buildRoot = path.join(root, 'build', 'web');
const buildOutput = path.join(buildRoot, ...socialImagePath.split('/'));

await mkdir(path.dirname(output), { recursive: true });
const browser = await chromium.launch({ headless: true });

try {
  const page = await browser.newPage({ viewport: { width: 1200, height: 630 } });
  await page.goto(`file://${source}`, { waitUntil: 'load' });
  await page.evaluate(async (document) => {
    const displayName = document.profile.display_name;
    const title = window.document.querySelector('.title');
    const primary = window.document.querySelector('[data-name-primary]');
    const accentElement = window.document.querySelector('[data-name-accent]');
    primary.textContent = displayName.primary;
    accentElement.textContent = displayName.accent;
    window.document.querySelector('[data-role]').textContent =
      document.profile.role;
    window.document.querySelector('[data-focus]').textContent =
      document.profile.focus.slice(0, 3).join(' · ');
    window.document.querySelector('[data-headline]').textContent =
      document.profile.headline;
    window.document.querySelector('[data-domain]').textContent =
      document.site.domain_label;
    window.document.title = `${displayName.accessible} social card`;
    await window.document.fonts.ready;
    let titleSize = 108;
    title.style.fontSize = `${titleSize}px`;
    while (
      Math.max(primary.scrollWidth, accentElement.scrollWidth) >
        title.clientWidth &&
      titleSize > 64
    ) {
      titleSize -= 2;
      title.style.fontSize = `${titleSize}px`;
    }
  }, portfolio);
  await page.screenshot({ path: output, type: 'png' });
  if (await exists(buildRoot)) {
    await mkdir(path.dirname(buildOutput), { recursive: true });
    await copyFile(output, buildOutput);
  }
  process.stdout.write(`Rendered ${path.relative(root, output)} at 1200x630.\n`);
} finally {
  await browser.close();
}

async function exists(target) {
  try {
    await access(target);
    return true;
  } catch {
    return false;
  }
}

function requiredString(value, field) {
  if (typeof value !== 'string' || value.trim().length === 0) {
    throw new Error(`${field} must be a non-empty string`);
  }
  return value.trim();
}

function resolveSocialImagePath(value) {
  const url = new URL(value, 'https://portfolio.invalid');
  const relative = decodeURIComponent(url.pathname).replace(/^\/+/, '');
  const normalized = path.posix.normalize(relative);
  if (
    !relative ||
    normalized.startsWith('../') ||
    path.posix.isAbsolute(normalized) ||
    path.posix.extname(normalized).toLowerCase() !== '.png'
  ) {
    throw new Error('site.social_image must resolve to a safe PNG asset path');
  }
  return normalized;
}
