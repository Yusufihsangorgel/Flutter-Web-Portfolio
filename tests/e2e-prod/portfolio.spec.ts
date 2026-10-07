import { expect, test } from '../e2e/helpers/test_setup';
import type {
  APIRequestContext,
  CDPSession,
  Page,
  Response,
} from '@playwright/test';
import type { PortfolioTestData } from '../support/portfolio_test_data';
import {
  expectedArtifact,
  openChapterFromPalette,
  openPortfolio,
  packageMetadata,
  portfolio as basePortfolio,
  readAccessibilityTree,
  readRevealSourceCount,
  readRuntimeTimeline,
  required,
} from '../e2e/helpers/portfolio_test_helpers';
import {
  scrollToHeading,
  scrollToLocator,
  scrollToSemanticLink,
  scrollToText,
} from '../e2e/helpers/semantics_scroll';

type ProductionSystem = PortfolioTestData['systems'][number] & {
  year: string;
  technologies: string[];
};
type ProductionPortfolio = Omit<PortfolioTestData, 'systems'> & {
  systems: ProductionSystem[];
};
type ReleaseResponses = {
  document: Response | null;
  wasm: Response;
  runtime: Response;
  renderer: Response;
};

const portfolio = basePortfolio as ProductionPortfolio;

async function openProductionPortfolio(page: Page) {
  await openPortfolio(page, { timeout: 75000, requireOk: true });
}

function collectReleaseFailures(page: Page, origin: string) {
  const errors: string[] = [];
  const badResponses: string[] = [];
  page.on('pageerror', (error) => errors.push(error.message));
  page.on('console', (message) => {
    if (message.type() === 'error') errors.push(message.text());
  });
  page.on('response', (response) => {
    if (response.url().startsWith(origin) && response.status() >= 400) {
      badResponses.push(`${response.status()} ${response.url()}`);
    }
  });
  return { errors, badResponses };
}

async function captureReleaseResponses(page: Page): Promise<ReleaseResponses> {
  const wasm = page.waitForResponse((response) =>
    response.url().includes('/main.dart.wasm?v='),
  );
  const runtime = page.waitForResponse((response) =>
    response.url().includes('/main.dart.mjs?v='),
  );
  const renderer = page.waitForResponse((response) =>
    /\/canvaskit\/[0-9a-f]{40}\/skwasm\.wasm$/.test(response.url()),
  );
  const document = await page.goto('/', { waitUntil: 'domcontentloaded' });
  const [wasmResponse, runtimeResponse, rendererResponse] = await Promise.all([
    wasm,
    runtime,
    renderer,
  ]);
  return {
    document,
    wasm: wasmResponse,
    runtime: runtimeResponse,
    renderer: rendererResponse,
  };
}

async function expectProductionPreloads(page: Page) {
  const links = await page.locator('head link').evaluateAll((elements) =>
    elements.map((element) => ({
      rel: element.getAttribute('rel'),
      href: element.getAttribute('href'),
      as: element.getAttribute('as'),
      type: element.getAttribute('type'),
      fetchpriority: element.getAttribute('fetchpriority'),
    })),
  );
  expect(links).toEqual(
    expect.arrayContaining([
      expect.objectContaining({
        rel: 'preload',
        href: expect.stringMatching(/^main\.dart\.wasm\?v=[0-9a-f]{16}$/),
        as: 'fetch',
        type: 'application/wasm',
        fetchpriority: 'high',
      }),
      expect.objectContaining({
        rel: 'modulepreload',
        href: expect.stringMatching(/^main\.dart\.mjs\?v=[0-9a-f]{16}$/),
        fetchpriority: 'high',
      }),
      expect.objectContaining({
        rel: 'preload',
        href: expect.stringMatching(
          /^canvaskit\/[0-9a-f]{40}\/skwasm\.wasm$/,
        ),
        as: 'fetch',
        type: 'application/wasm',
        fetchpriority: 'high',
      }),
    ]),
  );
}

function expectIsolationHeaders(response: Response | null) {
  expect(response?.headers()['cross-origin-opener-policy']).toBe('same-origin');
  expect(response?.headers()['cross-origin-embedder-policy']).toBe(
    'credentialless',
  );
  expect(response?.headers()['content-security-policy']).toContain(
    "default-src 'self'",
  );
}

async function waitForReleasedApp(page: Page) {
  await page.waitForSelector('flt-semantics-host', {
    state: 'attached',
    timeout: 75000,
  });
  await expect(page.locator('#bootstrap-surface')).toHaveCount(0);
  await expect(page.getByRole('heading').first()).toBeAttached();
  await expect(page).toHaveTitle(portfolio.site.title);
}

async function assertAccessibleShell(
  page: Page,
  isMobile: boolean,
  accessibility: CDPSession,
) {
  await expect(page.locator('html')).toHaveAttribute(
    'data-render-quality',
    'essential',
  );
  await expect(page.locator('html')).toHaveAttribute(
    'data-render-quality-reason',
    'reducedMotion',
  );
  const tree = await accessibility.send('Accessibility.getFullAXTree');
  const nodes = tree.nodes.filter((node) => !node.ignored);
  const headings = nodes
    .filter((node) => node.role?.value === 'heading')
    .map((node) => ({
      name: node.name?.value ?? '',
      level: node.properties?.find((property) => property.name === 'level')
        ?.value?.value,
    }));
  const controls = nodes
    .filter((node) => ['button', 'link'].includes(node.role?.value ?? ''))
    .map((node) => node.name?.value ?? '');
  expect(headings).toContainEqual({
    name: `${portfolio.profile.display_name.accessible}, ${portfolio.profile.role}`,
    level: 1,
  });
  expect(controls).toEqual(
    expect.arrayContaining([
      'Skip to content',
      'Back to top',
      ...(isMobile
        ? ['Open navigation menu']
        : ['About', 'Experience', 'Open Source', 'Work']),
      'Language menu: English',
    ]),
  );
  expect(controls.every((name) => name.trim().length > 0)).toBe(true);
  expect(controls.join('\n')).not.toMatch(
    /Profile PROFILE|Show menu|Scroll to top|🇬🇧/,
  );
}

async function assertProductionContributionLinks(
  page: Page,
  accessibility: CDPSession,
) {
  await openChapterFromPalette(page, 'Go to Open Source', /#\/proof$/, 'Open Source');
  const contribution = required(
    portfolio.contributions.find((item) => item.featured) ??
      portfolio.contributions[0],
    'a visible contribution',
  );
  expect(contribution).toBeTruthy();
  await scrollToSemanticLink(page, contribution.title);
  const tree = await accessibility.send('Accessibility.getFullAXTree');
  const links = tree.nodes
    .filter((node) => !node.ignored && node.role?.value === 'link')
    .map((node) => node.name?.value ?? '');
  const status = contribution.status === 'merged' ? 'Merged' : 'Under review';
  expect(links).toEqual(
    expect.arrayContaining([
      expect.stringContaining(
        `View pull request. ${contribution.title}. ${contribution.project}. ${status}.`,
      ),
    ]),
  );
}

async function assertProductionProjectLinks(page: Page, accessibility: CDPSession) {
  await openChapterFromPalette(page, 'Go to Work', /#\/projects$/, 'Selected Work');
  const tree = await accessibility.send('Accessibility.getFullAXTree');
  const links = tree.nodes
    .filter((node) => !node.ignored && node.role?.value === 'link')
    .map((node) => node.name?.value ?? '');
  const featured = required(
    portfolio.systems.find((system) => system.featured),
    'a featured system',
  );
  const supporting = required(
    portfolio.systems.find((system) => !system.featured),
    'supporting work',
  );
  expect(featured).toBeTruthy();
  expect(supporting).toBeTruthy();
  const evidenceLabel = `Open evidence: ${featured.name}, ${featured.evidence[0].label}`;
  await scrollToSemanticLink(page, evidenceLabel);
  const visibleTree = await accessibility.send('Accessibility.getFullAXTree');
  const visibleLinks = visibleTree.nodes
    .filter((node) => !node.ignored && node.role?.value === 'link')
    .map((node) => node.name?.value ?? '');
  expect(visibleLinks).toEqual(expect.arrayContaining([evidenceLabel]));
  expect(links).not.toEqual(
    expect.arrayContaining([expect.stringContaining('Open project:')]),
  );
  expect(links).not.toContain('View source');
  expect(links).not.toContain('Website');
  return supporting;
}

async function assertSupportingAtlas(
  page: Page,
  accessibility: CDPSession,
  supporting: ProductionSystem,
) {
  await scrollToHeading(page, supporting.name);
  const headingTree = await accessibility.send('Accessibility.getFullAXTree');
  const headings = headingTree.nodes
    .filter((node) => !node.ignored && node.role?.value === 'heading')
    .map((node) => node.name?.value ?? '');
  const disclosures = headingTree.nodes.filter(
    (node) =>
      !node.ignored &&
      node.role?.value === 'button' &&
      node.properties?.some((property) => property.name === 'expanded'),
  );
  expect(headings).toContain(supporting.name);
  expect(disclosures.length).toBeGreaterThanOrEqual(1);
  const artifact = expectedArtifact(page, supporting);
  await scrollToLocator(page, page.getByRole('img', { name: artifact.alt }));
  const imageTree = await accessibility.send('Accessibility.getFullAXTree');
  const images = imageTree.nodes
    .filter((node) => !node.ignored && node.role?.value === 'image')
    .map((node) => node.name?.value ?? '');
  expect(images).toContain(artifact.alt);
  await scrollToText(page, supporting.evidence[0].label);
  const evidenceTree = await accessibility.send('Accessibility.getFullAXTree');
  const evidenceLinks = evidenceTree.nodes
    .filter((node) => !node.ignored && node.role?.value === 'link')
    .map((node) => node.name?.value ?? '');
  expect(evidenceLinks).toEqual(
    expect.arrayContaining([
      expect.stringContaining(
        `Open evidence: ${supporting.name}, ${supporting.evidence[0].label}`,
      ),
    ]),
  );
}

async function assertProductionDocument(request: APIRequestContext) {
  const response = await request.get('/');
  expect(response.status()).toBe(200);
  const html = await response.text();
  expect(html).not.toContain('bootstrap-progress');
  expect(html).toContain('aria-busy="true"');
  expect(html).toContain('class="bootstrap-shell" aria-hidden="true"');
  expect(html).toContain(`data-content-version="${portfolio.content_version}"`);
  expect(html).toContain(portfolio.profile.display_name.primary);
  expect(html).toContain(portfolio.profile.display_name.accent);
  expect(html).toContain(portfolio.profile.email);
  expect(html).toContain(portfolio.profile.headline);
  for (const fact of [
    portfolio.profile.location,
    portfolio.profile.since,
    portfolio.profile.focus[0],
  ]) {
    expect(html).toContain(fact);
  }
  expect(html).toContain(
    `content="${new URL(portfolio.site.social_image, portfolio.site.url)}"`,
  );
  expect(html).toContain('<meta property="og:image:width" content="1200">');
  expect(html).toContain('<meta property="og:image:height" content="630">');
}

async function assertProductionSocialImage(request: APIRequestContext) {
  const image = await request.get(portfolio.site.social_image);
  expect(image.status()).toBe(200);
  expect(image.headers()['content-type']).toContain('image/png');
  const png = await image.body();
  expect(png.subarray(1, 4).toString()).toBe('PNG');
  expect(png.readUInt32BE(16)).toBe(1200);
  expect(png.readUInt32BE(20)).toBe(630);
}

async function assertProductionFonts(request: APIRequestContext) {
  const fallback = await request.get(
    '/assets/fallback_fonts/roboto/v32/KFOmCnqEu92Fr1Me4GZLCzYlKw.woff2',
  );
  expect(fallback.status()).toBe(200);
  expect(fallback.headers()['content-type']).toContain('font/woff2');
  for (const path of [
    '/assets/assets/fonts/inter/Inter-Variable.ttf',
    '/assets/assets/fonts/noto_sans_arabic/NotoSansArabic-Variable.ttf',
    '/assets/assets/fonts/noto_sans_devanagari/NotoSansDevanagari-Variable.ttf',
  ]) {
    const font = await request.get(path);
    expect(font.status(), path).toBe(200);
    expect(font.headers()['content-type'], path).toContain('font/ttf');
    expect(font.headers()['content-encoding'], path).toBe('gzip');
  }
}

async function assertProductionMissingAssets(request: APIRequestContext) {
  const missingFont = await request.get('/assets/fallback_fonts/missing.woff2');
  expect(missingFont.status()).toBe(404);
  const symbols = await request.get('/canvaskit/skwasm.js.symbols');
  expect(symbols.status()).toBe(404);
  const version = await request.get('/version.json');
  expect(version.status()).toBe(200);
  expect(await version.json()).toMatchObject({ version: packageMetadata.version });
}

test('boots the production Wasm release with its security contract', async ({
  page,
}) => {
  const origin = new URL(test.info().project.use.baseURL as string).origin;
  const failures = collectReleaseFailures(page, origin);
  const release = await captureReleaseResponses(page);
  expect(release.document?.status()).toBe(200);
  expect(release.wasm.status()).toBe(200);
  expect(release.wasm.url()).toMatch(/main\.dart\.wasm\?v=[0-9a-f]{16}$/);
  expect(release.wasm.headers()['content-type']).toContain('application/wasm');
  expect(release.wasm.headers()['cache-control']).toContain('max-age=31536000');
  expect(release.runtime.status()).toBe(200);
  expect(release.runtime.headers()['content-type']).toContain('javascript');
  expect(release.renderer.status()).toBe(200);
  expect(release.renderer.headers()['cache-control']).toContain(
    'max-age=31536000',
  );
  await expectProductionPreloads(page);
  expectIsolationHeaders(release.document);
  await waitForReleasedApp(page);
  const timeline = await readRuntimeTimeline(page);
  expect(timeline.every((value) => Number.isFinite(value))).toBe(true);
  expect(timeline).toEqual([...timeline].sort((a, b) => a! - b!));
  expect(await readRevealSourceCount(page)).toBe(1);
  expect(await page.evaluate(() => window.crossOriginIsolated)).toBe(true);
  expect(failures.badResponses).toEqual([]);
  expect(failures.errors).toEqual([]);
});

test('serves the complete professional narrative in production', async ({
  page,
  isMobile,
}) => {
  await page.emulateMedia({ reducedMotion: 'reduce' });
  await openProductionPortfolio(page);
  await expect(page.getByRole('heading', { name: 'About' })).toBeAttached();

  await openChapterFromPalette(
    page,
    'Go to Experience',
    /#\/experience$/,
    'Experience',
  );
  await expect(
    page.getByText(portfolio.experience[0].company).first(),
  ).toBeAttached();

  await openChapterFromPalette(
    page,
    'Go to Open Source',
    /#\/proof$/,
    'Open Source',
  );
  await openChapterFromPalette(
    page,
    'Go to Work',
    /#\/projects$/,
    'Selected Work',
  );
  const supportingSystems = portfolio.systems.filter(
    (system) => !system.featured,
  );
  expect(supportingSystems.length).toBeGreaterThan(1);
  const supportingSystem = required(supportingSystems[0], 'supporting work');
  await scrollToHeading(page, supportingSystem.name);
  await expect(
    page.getByRole('img', { name: expectedArtifact(page, supportingSystem).alt }),
  ).toBeAttached();
  await scrollToText(page, supportingSystem.ownership);

  if (!isMobile) {
    const nextSystem = required(supportingSystems[1], 'a second work item');
    const selector = page.getByRole('button', {
      name: `Select evidence: ${nextSystem.name}`,
      exact: true,
    });
    await scrollToLocator(page, selector);
    await selector.click();
    await scrollToHeading(page, nextSystem.name);
    await scrollToLocator(
      page,
      page.getByRole('img', { name: expectedArtifact(page, nextSystem).alt }),
    );
  }
});

test('serves the production accessibility hierarchy', async ({
  page,
  isMobile,
}) => {
  await page.emulateMedia({ reducedMotion: 'reduce' });
  const accessibility = await readAccessibilityTree(page);
  await openProductionPortfolio(page);
  await assertAccessibleShell(page, isMobile, accessibility);
  await assertProductionContributionLinks(page, accessibility);
  const supporting = await assertProductionProjectLinks(page, accessibility);
  await assertSupportingAtlas(page, accessibility, supporting);
});

test('serves the localized Arabic command surface in production', async ({
  page,
  isMobile,
}) => {
  test.skip(isMobile, 'locale contract only needs one browser project');

  const runtimeErrors: string[] = [];
  page.on('pageerror', (error) => runtimeErrors.push(error.message));
  await page.emulateMedia({ reducedMotion: 'reduce' });
  await openProductionPortfolio(page);
  await openChapterFromPalette(
    page,
    'Go to Work',
    /#\/projects$/,
    'Selected Work',
  );
  await page.keyboard.press('Control+KeyK');
  await page.getByText('Switch to العربية', { exact: true }).click();

  await expect(page.locator('html')).toHaveAttribute('lang', 'ar');
  await expect(page.locator('html')).toHaveAttribute('dir', 'rtl');
  await expect(
    page.getByRole('heading', { name: 'أعمال مختارة' }),
  ).toBeAttached();
  await page.keyboard.press('Control+KeyK');
  await expect(
    page.getByText('الانتقال إلى الأعمال', { exact: true }),
  ).toBeVisible();
  expect(runtimeErrors).toEqual([]);
});

test('serves the declared production sharing and font assets', async ({
  request,
  isMobile,
}) => {
  test.skip(isMobile, 'static release contract only needs one browser project');
  await assertProductionDocument(request);
  await assertProductionSocialImage(request);
  await assertProductionFonts(request);
  await assertProductionMissingAssets(request);
});
