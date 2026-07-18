import { chromium } from '@playwright/test';
import { createHash } from 'node:crypto';
import { access, copyFile, mkdir, readFile, stat, writeFile } from 'node:fs/promises';
import { fileURLToPath } from 'node:url';
import path from 'node:path';
import process from 'node:process';

import {
  resolveContainedPublicPath,
  resolveSafePublicPngPath,
} from './safe_public_asset_path.mjs';
import { assertRasterDimensions, inspectRaster } from './raster_inspector.mjs';
import {
  serializeSocialCardFingerprint,
  verifySocialCardFingerprint,
} from './social_card_fingerprint.mjs';

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
if (process.argv.includes('--check-browser')) {
  const browser = await launchChromium();
  await browser.close();
  process.stdout.write('Chromium is ready for deterministic social-card rendering.\n');
  process.exit(0);
}

const source = path.join(root, 'tool', 'social_card.html');
const portfolioPath = path.join(root, 'assets', 'content', 'portfolio.json');
const portfolio = JSON.parse(
  await readFile(portfolioPath, 'utf8'),
);
const displayName = portfolio.profile?.display_name;
for (const field of ['primary', 'accent', 'navigation', 'accessible']) {
  requiredString(displayName?.[field], `profile.display_name.${field}`);
}
const socialImagePath = resolveSafePublicPngPath(portfolio.site.social_image);
const output = resolveContainedPublicPath(
  path.join(root, 'web'),
  socialImagePath,
  'site.social_image',
);
const fingerprintOutput = `${output}.sha256`;
const buildRoot = path.join(root, 'build', 'web');
const buildOutput = resolveContainedPublicPath(
  buildRoot,
  socialImagePath,
  'site.social_image',
);
const buildFingerprintOutput = `${buildOutput}.sha256`;
const inputDigest = await renderInputDigest();

if (
  process.argv.includes('--verify') ||
  process.env.PORTFOLIO_VERIFY_SOCIAL_CARD === 'true'
) {
  await verifyCommittedCard();
  process.stdout.write('Committed social card matches its source fingerprint.\n');
  process.exit(0);
}

await mkdir(path.dirname(output), { recursive: true });
const browser = await launchChromium();

try {
  if (
    process.env.NODE_ENV === 'test' &&
    process.env.PORTFOLIO_TEST_RENDER_FAILURE === 'true'
  ) {
    throw new Error('Simulated social-card failure for the initializer transaction test.');
  }
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
  const pngBytes = await readFile(output);
  assertRasterDimensions(
    inspectRaster(pngBytes, 'rendered social card'),
    1200,
    630,
    'rendered social card',
  );
  await writeFile(
    fingerprintOutput,
    serializeSocialCardFingerprint({ inputDigest, pngBytes }),
  );
  if (await exists(buildRoot)) {
    await mkdir(path.dirname(buildOutput), { recursive: true });
    await copyFile(output, buildOutput);
    await copyFile(fingerprintOutput, buildFingerprintOutput);
  }
  process.stdout.write(`Rendered ${path.relative(root, output)} at 1200x630.\n`);
} finally {
  await browser.close();
}

async function launchChromium() {
  try {
    return await chromium.launch({ headless: true });
  } catch (error) {
    throw new Error(
      'Chromium is required to render the social card. Run `npm run setup:browsers` once, then retry.',
      { cause: error },
    );
  }
}

async function exists(target) {
  try {
    await access(target);
    return true;
  } catch {
    return false;
  }
}

async function renderInputDigest() {
  const hash = createHash('sha256');
  for (const file of [
    portfolioPath,
    source,
    fileURLToPath(import.meta.url),
    path.join(root, 'tool', 'raster_inspector.mjs'),
    path.join(root, 'tool', 'safe_public_asset_path.mjs'),
    path.join(root, 'tool', 'social_card_fingerprint.mjs'),
    path.join(root, 'package-lock.json'),
    path.join(root, 'assets', 'fonts', 'space_grotesk', 'SpaceGrotesk-Variable.ttf'),
    path.join(root, 'assets', 'fonts', 'jetbrains_mono', 'JetBrainsMono-Variable.ttf'),
  ]) {
    hash.update(path.relative(root, file));
    hash.update('\0');
    hash.update(await readFile(file));
    hash.update('\0');
  }
  return hash.digest('hex');
}

async function verifyCommittedCard() {
  try {
    const [metadata, committedFingerprint, pngBytes] = await Promise.all([
      stat(output),
      readFile(fingerprintOutput, 'utf8'),
      readFile(output),
    ]);
    if (
      !metadata.isFile() ||
      metadata.size === 0 ||
      !hasExpectedDimensions(pngBytes) ||
      !verifySocialCardFingerprint({
        fingerprintText: committedFingerprint,
        expectedInputDigest: inputDigest,
        pngBytes,
      })
    ) {
      throw new Error('stale');
    }
  } catch {
    throw new Error(
      'The committed social card is missing or stale. Run `npm run render:social-card` locally and commit the PNG plus its .sha256 sidecar.',
    );
  }
}

function hasExpectedDimensions(bytes) {
  try {
    assertRasterDimensions(
      inspectRaster(bytes, 'committed social card'),
      1200,
      630,
      'committed social card',
    );
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
