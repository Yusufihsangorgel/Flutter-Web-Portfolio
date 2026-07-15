import { expect, Page, test } from '@playwright/test';

async function openPortfolio(page: Page) {
  const response = await page.goto('/', { waitUntil: 'domcontentloaded' });
  expect(response?.status()).toBe(200);
  await page.waitForSelector('flt-semantics-host', {
    state: 'attached',
    timeout: 75000,
  });
  await expect(page.locator('#bootstrap-surface')).toHaveCount(0);
  await expect(page.getByRole('heading').first()).toBeAttached();
}

async function readRuntimeTimeline(page: Page) {
  return page.evaluate(() => {
    const names = [
      'flutter-bootstrap-start',
      'flutter-entrypoint-loaded',
      'flutter-engine-initialized',
      'flutter-first-frame-event',
      'flutter-surface-reveal-start',
      'flutter-bootstrap-surface-removed',
    ];
    return names.map(
      (name) => performance.getEntriesByName(name, 'mark').at(-1)?.startTime,
    );
  });
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
  expect(wasm.headers()['cache-control']).toContain('max-age=31536000');
  expect(runtime.status()).toBe(200);
  expect(runtime.headers()['content-type']).toContain('javascript');
  expect(renderer.status()).toBe(200);
  expect(renderer.headers()['cache-control']).toContain('max-age=31536000');
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
  const timeline = await readRuntimeTimeline(page);
  expect(timeline.every((value) => Number.isFinite(value))).toBe(true);
  expect(timeline).toEqual([...timeline].sort((a, b) => a! - b!));
  expect(await page.evaluate(() => window.crossOriginIsolated)).toBe(true);
  expect(badResponses).toEqual([]);
  expect(errors).toEqual([]);
});

test('serves the complete professional narrative in production', async ({
  page,
}) => {
  await openPortfolio(page);
  await expect(page.getByRole('heading', { name: 'About Me' })).toBeAttached();
  await expect(page.getByRole('heading', { name: 'Experience' })).toBeAttached();
  await expect(page.getByRole('heading', { name: 'Open Source' })).toBeAttached();
  await expect(page.getByRole('heading', { name: 'Selected Systems' })).toBeAttached();
  await expect(
    page.getByText('Software Engineer — Cross-platform'),
  ).toBeAttached();
});

test('serves the production accessibility hierarchy', async ({
  page,
  isMobile,
}) => {
  await page.emulateMedia({ reducedMotion: 'reduce' });
  const accessibility = await page.context().newCDPSession(page);
  await accessibility.send('Accessibility.enable');
  await openPortfolio(page);

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

  expect(headings).toContainEqual({ name: 'SOFTWARE ENGINEER.', level: 1 });
  expect(controls).toEqual(
    expect.arrayContaining([
      'Skip to content',
      'Back to top',
      ...(isMobile
        ? ['Open navigation menu']
        : ['About', 'Experience', 'Open Source', 'Systems']),
      'Language menu: English',
    ]),
  );
  expect(controls.every((name) => name.trim().length > 0)).toBe(true);
  expect(controls.join('\n')).not.toMatch(
    /Profile PROFILE|Show menu|Scroll to top|🇬🇧/,
  );

  await expect(
    page.getByRole('heading', { name: 'Selected Systems' }),
  ).toBeAttached();

  const projectsTree = await accessibility.send(
    'Accessibility.getFullAXTree',
  );
  const projectLinks = projectsTree.nodes
    .filter((node) => !node.ignored && node.role?.value === 'link')
    .map((node) => node.name?.value ?? '');
  expect(projectLinks).toContain('View source: Flutter Web Portfolio');
  expect(projectLinks).toContain(
    'Open pull request. Wait for web rendering before the first-frame event. '
      + 'Flutter · under review · 2026-07-15',
  );
  expect(projectLinks).toEqual(
    expect.arrayContaining(['GitHub', 'LinkedIn', 'Writing']),
  );
  expect(projectLinks).not.toContain('View source');
  expect(projectLinks).not.toContain('Website');
});

test('serves the localized Arabic command surface in production', async ({
  page,
  isMobile,
}) => {
  test.skip(isMobile, 'locale contract only needs one browser project');

  const runtimeErrors: string[] = [];
  page.on('pageerror', (error) => runtimeErrors.push(error.message));
  await openPortfolio(page);
  await page.keyboard.press('Control+KeyK');
  await page.getByText('Switch to العربية', { exact: true }).click();

  await expect(page.locator('html')).toHaveAttribute('lang', 'ar');
  await expect(page.locator('html')).toHaveAttribute('dir', 'rtl');
  await expect(page.getByText('عرض المشاريع', { exact: true })).toBeAttached();
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
  expect(html).toContain('class="bootstrap-progress"');
  expect(html).toContain('aria-busy="true"');
  expect(html).not.toContain('class="bootstrap-title"');
  expect(html).toContain(
    'content="https://developeryusuf.com/assets/og/engineering-showcase.png"',
  );
  expect(html).toContain('<meta property="og:image:width" content="1200">');
  expect(html).toContain('<meta property="og:image:height" content="630">');

  const image = await request.get('/assets/og/engineering-showcase.png');
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
    '/assets/assets/fonts/instrument_serif/InstrumentSerif-Regular.ttf',
    '/assets/assets/fonts/instrument_serif/InstrumentSerif-Italic.ttf',
    '/assets/assets/fonts/noto_sans_arabic/NotoSansArabic-Variable.ttf',
    '/assets/assets/fonts/noto_sans_devanagari/NotoSansDevanagari-Variable.ttf',
  ]) {
    const appFont = await request.get(path);
    expect(appFont.status(), path).toBe(200);
    expect(appFont.headers()['content-type'], path).toContain('font/ttf');
    expect(appFont.headers()['content-encoding'], path).toBe('gzip');
  }

  const missing = await request.get('/assets/fallback_fonts/missing.woff2');
  expect(missing.status()).toBe(404);

  const rendererSymbols = await request.get(
    '/canvaskit/skwasm.js.symbols',
  );
  expect(rendererSymbols.status()).toBe(404);

  const version = await request.get('/version.json');
  expect(version.status()).toBe(200);
  expect(await version.json()).toMatchObject({ version: '1.3.0' });
});
