import { expect, Locator, Page, test } from '@playwright/test';
import { readFileSync } from 'node:fs';

const portfolio = JSON.parse(
  readFileSync('assets/content/portfolio.json', 'utf8'),
);
const packageMetadata = JSON.parse(readFileSync('package.json', 'utf8'));
const localReleasePreview = (() => {
  const value = process.env.PLAYWRIGHT_BASE_URL;
  if (!value) return false;
  return ['127.0.0.1', 'localhost'].includes(new URL(value).hostname);
})();

async function openPortfolio(page: Page) {
  const response = await page.goto('/', { waitUntil: 'domcontentloaded' });
  expect(response?.status()).toBe(200);
  await page.waitForSelector('flt-semantics-host', {
    state: 'attached',
    timeout: 75000,
  });
  await expect(page.locator('#bootstrap-surface')).toHaveCount(0);
  await expect(page.getByRole('heading').first()).toBeAttached();
  await expect(page).toHaveTitle(portfolio.site.title);
  await expect(page.locator('html')).toHaveAttribute(
    'data-render-quality',
    /^(essential|balanced|cinematic)$/,
  );
}

async function openChapterFromPalette(
  page: Page,
  command: string,
  hash: RegExp,
  heading: string,
) {
  await page.keyboard.press('Control+KeyK');
  const commandItem = page.getByText(command, { exact: true });
  await expect(commandItem).toBeVisible();
  await commandItem.click();
  await expect(page).toHaveURL(hash);
  await expect(
    page.getByRole('heading', { name: heading, exact: true }),
  ).toBeAttached();
}

async function scrollToHeading(page: Page, name: string) {
  const heading = page.getByRole('heading', { name, exact: true });
  for (let attempt = 0; attempt < 80; attempt += 1) {
    if ((await heading.count()) > 0) {
      const [box, viewportHeight] = await Promise.all([
        heading.boundingBox(),
        page.evaluate(() => window.innerHeight),
      ]);
      if (box && box.y < viewportHeight && box.y + box.height > 0) return;
    }
    await page.mouse.wheel(0, 500);
  }
  await expect(heading).toBeVisible();
}

async function scrollToLocator(page: Page, locator: Locator) {
  for (let attempt = 0; attempt < 80; attempt += 1) {
    if ((await locator.count()) > 0) {
      const [box, viewportHeight] = await Promise.all([
        locator.first().boundingBox(),
        page.evaluate(() => window.innerHeight),
      ]);
      if (box && box.y < viewportHeight && box.y + box.height > 0) {
        return locator.first();
      }
    }
    await page.mouse.wheel(0, 420);
    await page.waitForTimeout(60);
  }
  await expect(locator.first()).toBeVisible();
  return locator.first();
}

async function scrollToText(page: Page, text: string) {
  return scrollToLocator(page, page.getByText(text).first());
}

async function scrollToSemanticLink(page: Page, title: string) {
  // Flutter exposes this tappable Semantics node to Chromium's AX tree as a
  // link, but its generated <a> intentionally has no href. Playwright's DOM
  // role selector therefore cannot see it; the CDP AX assertion below still
  // verifies the real link role and accessible name.
  const link = page
    .locator('flt-semantics-host a')
    .filter({ hasText: title });
  // Route navigation animates the Flutter scroll position. Give the target
  // semantics node a chance to enter the viewport before sending wheel input,
  // otherwise mobile emulation can race past the short link target.
  await link
    .first()
    .waitFor({ state: 'attached', timeout: 1200 })
    .catch(() => undefined);
  for (let attempt = 0; attempt < 80; attempt += 1) {
    if ((await link.count()) > 0) {
      const [box, viewportHeight] = await Promise.all([
        link.first().boundingBox(),
        page.evaluate(() => window.innerHeight),
      ]);
      if (box && box.y < viewportHeight && box.y + box.height > 0) return;
    }
    await page.mouse.wheel(0, 420);
    await page.waitForTimeout(80);
  }
  await expect(link.first()).toBeVisible();
}

async function readRuntimeTimeline(page: Page) {
  return page.evaluate(() => {
    const names = [
      'flutter-bootstrap-start',
      'flutter-entrypoint-loaded',
      'flutter-engine-initialized',
      'flutter-first-frame-signal',
      'flutter-surface-reveal-start',
      'flutter-bootstrap-surface-removed',
    ];
    return names.map(
      (name) => performance.getEntriesByName(name, 'mark').at(-1)?.startTime,
    );
  });
}

async function readRevealSourceCount(page: Page) {
  return page.evaluate(() =>
    [
      'flutter-first-frame-event',
      'flutter-run-app-fallback',
      'flutter-glass-pane-fallback',
    ].reduce(
      (count, name) =>
        count + performance.getEntriesByName(name, 'mark').length,
      0,
    ),
  );
}

test('boots the production Wasm release with its security contract', async ({
  page,
}) => {
  const errors: string[] = [];
  const badResponses: string[] = [];
  const origin = new URL(test.info().project.use.baseURL as string).origin;

  page.on('pageerror', (error) => errors.push(error.message));
  page.on('console', (message) => {
    if (message.type() === 'error') errors.push(message.text());
  });
  page.on('response', (response) => {
    if (response.url().startsWith(origin) && response.status() >= 400) {
      badResponses.push(`${response.status()} ${response.url()}`);
    }
  });

  const wasmResponse = page.waitForResponse((response) =>
    response.url().includes('/main.dart.wasm?v='),
  );
  const runtimeResponse = page.waitForResponse((response) =>
    response.url().includes('/main.dart.mjs?v='),
  );
  const rendererResponse = page.waitForResponse((response) =>
    /\/canvaskit\/[0-9a-f]{40}\/skwasm\.wasm$/.test(response.url()),
  );

  const documentResponse = await page.goto('/', {
    waitUntil: 'domcontentloaded',
  });
  const [wasm, runtime, renderer] = await Promise.all([
    wasmResponse,
    runtimeResponse,
    rendererResponse,
  ]);

  expect(documentResponse?.status()).toBe(200);
  expect(wasm.status()).toBe(200);
  expect(wasm.url()).toMatch(/main\.dart\.wasm\?v=[0-9a-f]{16}$/);
  expect(wasm.headers()['content-type']).toContain('application/wasm');
  expect(wasm.headers()['cache-control']).toContain(
    localReleasePreview ? 'no-store' : 'max-age=31536000',
  );
  expect(runtime.status()).toBe(200);
  expect(runtime.headers()['content-type']).toContain('javascript');
  expect(renderer.status()).toBe(200);
  expect(renderer.headers()['cache-control']).toContain(
    localReleasePreview ? 'no-store' : 'max-age=31536000',
  );
  const preloadHints = await page.locator('head link').evaluateAll((links) =>
    links.map((link) => ({
      rel: link.getAttribute('rel'),
      href: link.getAttribute('href'),
      as: link.getAttribute('as'),
      type: link.getAttribute('type'),
      fetchpriority: link.getAttribute('fetchpriority'),
    })),
  );
  expect(preloadHints).toEqual(
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
  expect(documentResponse?.headers()['cross-origin-opener-policy']).toBe(
    'same-origin',
  );
  expect(documentResponse?.headers()['cross-origin-embedder-policy']).toBe(
    'credentialless',
  );
  expect(documentResponse?.headers()['content-security-policy']).toContain(
    "default-src 'self'",
  );

  await page.waitForSelector('flt-semantics-host', {
    state: 'attached',
    timeout: 75000,
  });
  await expect(page.locator('#bootstrap-surface')).toHaveCount(0);
  await expect(page.getByRole('heading').first()).toBeAttached();
  await expect(page).toHaveTitle(portfolio.site.title);
  const timeline = await readRuntimeTimeline(page);
  expect(timeline.every((value) => Number.isFinite(value))).toBe(true);
  expect(timeline).toEqual([...timeline].sort((a, b) => a! - b!));
  expect(await readRevealSourceCount(page)).toBe(1);
  expect(await page.evaluate(() => window.crossOriginIsolated)).toBe(true);
  expect(badResponses).toEqual([]);
  expect(errors).toEqual([]);
});

test('serves the complete professional narrative in production', async ({
  page,
  isMobile,
}) => {
  await page.emulateMedia({ reducedMotion: 'reduce' });
  await openPortfolio(page);
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
  const supportingSystem = supportingSystems[0];
  await scrollToHeading(page, supportingSystem.name);
  await expect(
    page.getByRole('img', { name: supportingSystem.artifact.alt }),
  ).toBeAttached();
  await scrollToText(page, supportingSystem.ownership);

  if (!isMobile) {
    const nextSystem = supportingSystems[1];
    await scrollToHeading(page, nextSystem.name);
    await scrollToLocator(
      page,
      page.getByRole('img', { name: nextSystem.artifact.alt }),
    );
  }
});

test('serves the production accessibility hierarchy', async ({
  page,
  isMobile,
}) => {
  await page.emulateMedia({ reducedMotion: 'reduce' });
  const accessibility = await page.context().newCDPSession(page);
  await accessibility.send('Accessibility.enable');
  await openPortfolio(page);
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

  await openChapterFromPalette(
    page,
    'Go to Open Source',
    /#\/proof$/,
    'Open Source',
  );
  const visibleContribution =
    portfolio.contributions.find((contribution) => contribution.featured) ??
    portfolio.contributions[0];
  expect(visibleContribution).toBeTruthy();
  await scrollToSemanticLink(page, visibleContribution.title);
  const proofTree = await accessibility.send('Accessibility.getFullAXTree');
  const proofLinks = proofTree.nodes
    .filter((node) => !node.ignored && node.role?.value === 'link')
    .map((node) => node.name?.value ?? '');
  const contributionStatus =
    visibleContribution.status === 'merged' ? 'Merged' : 'Under review';
  expect(proofLinks).toEqual(
    expect.arrayContaining([
      expect.stringContaining(
        `View pull request. ${visibleContribution.title}. ${visibleContribution.project}. ${contributionStatus}.`,
      ),
    ]),
  );

  await openChapterFromPalette(
    page,
    'Go to Work',
    /#\/projects$/,
    'Selected Work',
  );
  const projectsTree = await accessibility.send('Accessibility.getFullAXTree');
  const projectLinks = projectsTree.nodes
    .filter((node) => !node.ignored && node.role?.value === 'link')
    .map((node) => node.name?.value ?? '');
  const featuredSystem = portfolio.systems.find((system) => system.featured);
  const supportingSystem = portfolio.systems.find((system) => !system.featured);
  expect(featuredSystem).toBeTruthy();
  expect(supportingSystem).toBeTruthy();
  await scrollToSemanticLink(page, `Open project: ${featuredSystem.name}`);
  const visibleProjectsTree = await accessibility.send(
    'Accessibility.getFullAXTree',
  );
  const visibleProjectLinks = visibleProjectsTree.nodes
    .filter((node) => !node.ignored && node.role?.value === 'link')
    .map((node) => node.name?.value ?? '');
  expect(visibleProjectLinks).toEqual(
    expect.arrayContaining([`Open project: ${featuredSystem.name}`]),
  );
  expect(projectLinks).not.toContain('View source');
  expect(projectLinks).not.toContain('Website');

  await scrollToHeading(page, supportingSystem.name);
  const atlasHeaderTree = await accessibility.send(
    'Accessibility.getFullAXTree',
  );
  const atlasHeadings = atlasHeaderTree.nodes
    .filter((node) => !node.ignored && node.role?.value === 'heading')
    .map((node) => node.name?.value ?? '');
  const atlasDisclosureButtons = atlasHeaderTree.nodes.filter(
    (node) =>
      !node.ignored &&
      node.role?.value === 'button' &&
      node.properties?.some((property) => property.name === 'expanded'),
  );
  expect(atlasHeadings).toContain(supportingSystem.name);
  expect(atlasDisclosureButtons).toEqual([]);

  await scrollToLocator(
    page,
    page.getByRole('img', { name: supportingSystem.artifact.alt }),
  );
  const atlasArtifactTree = await accessibility.send(
    'Accessibility.getFullAXTree',
  );
  const atlasImages = atlasArtifactTree.nodes
    .filter((node) => !node.ignored && node.role?.value === 'image')
    .map((node) => node.name?.value ?? '');
  expect(atlasImages).toContain(supportingSystem.artifact.alt);

  await scrollToText(page, supportingSystem.evidence[0].label);
  const atlasEvidenceTree = await accessibility.send(
    'Accessibility.getFullAXTree',
  );
  const atlasEvidenceLinks = atlasEvidenceTree.nodes
    .filter((node) => !node.ignored && node.role?.value === 'link')
    .map((node) => node.name?.value ?? '');
  expect(atlasEvidenceLinks).toEqual(
    expect.arrayContaining([
      expect.stringContaining(
        `Open evidence: ${supportingSystem.name}, ${supportingSystem.evidence[0].label}`,
      ),
    ]),
  );
});

test('serves the localized Arabic command surface in production', async ({
  page,
  isMobile,
}) => {
  test.skip(isMobile, 'locale contract only needs one browser project');

  const runtimeErrors: string[] = [];
  page.on('pageerror', (error) => runtimeErrors.push(error.message));
  await page.emulateMedia({ reducedMotion: 'reduce' });
  await openPortfolio(page);
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

  const document = await request.get('/');
  expect(document.status()).toBe(200);
  const html = await document.text();
  expect(html).not.toContain('bootstrap-progress');
  expect(html).toContain('aria-busy="true"');
  expect(html).toContain('class="bootstrap-shell" aria-hidden="true"');
  expect(html).toContain(
    `data-content-version="${portfolio.content_version}"`,
  );
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

  const image = await request.get(portfolio.site.social_image);
  expect(image.status()).toBe(200);
  expect(image.headers()['content-type']).toContain('image/png');
  const png = await image.body();
  expect(png.subarray(1, 4).toString()).toBe('PNG');
  expect(png.readUInt32BE(16)).toBe(1200);
  expect(png.readUInt32BE(20)).toBe(630);

  const font = await request.get(
    '/assets/fallback_fonts/roboto/v32/KFOmCnqEu92Fr1Me4GZLCzYlKw.woff2',
  );
  expect(font.status()).toBe(200);
  expect(font.headers()['content-type']).toContain('font/woff2');

  for (const path of [
    '/assets/assets/fonts/inter/Inter-Variable.ttf',
    '/assets/assets/fonts/noto_sans_arabic/NotoSansArabic-Variable.ttf',
    '/assets/assets/fonts/noto_sans_devanagari/NotoSansDevanagari-Variable.ttf',
  ]) {
    const appFont = await request.get(path);
    expect(appFont.status(), path).toBe(200);
    expect(appFont.headers()['content-type'], path).toContain('font/ttf');
    if (!localReleasePreview) {
      expect(appFont.headers()['content-encoding'], path).toBe('gzip');
    }
  }

  const missing = await request.get('/assets/fallback_fonts/missing.woff2');
  expect(missing.status()).toBe(404);

  const rendererSymbols = await request.get(
    '/canvaskit/skwasm.js.symbols',
  );
  expect(rendererSymbols.status()).toBe(404);

  const version = await request.get('/version.json');
  expect(version.status()).toBe(200);
  expect(await version.json()).toMatchObject({
    version: packageMetadata.version,
  });
});
