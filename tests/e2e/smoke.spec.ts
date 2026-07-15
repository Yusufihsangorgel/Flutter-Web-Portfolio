import { expect, Page, test } from '@playwright/test';
import { readFileSync } from 'node:fs';

const portfolio = JSON.parse(
  readFileSync('assets/content/portfolio.json', 'utf8'),
);

async function openPortfolio(page: Page) {
  await page.goto('/', { waitUntil: 'domcontentloaded' });
  await page.waitForSelector('flt-semantics-host', {
    state: 'attached',
    timeout: 20000,
  });
  await expect(page.locator('#bootstrap-surface')).toHaveCount(0);
  await expect(page.getByRole('heading').first()).toBeAttached();
  await expect(page.locator('html')).toHaveAttribute(
    'data-render-quality',
    /^(essential|balanced|cinematic)$/,
  );
}

async function readAccessibilityTree(page: Page) {
  const session = await page.context().newCDPSession(page);
  await session.send('Accessibility.enable');
  return session;
}

async function openChapterFromPalette(
  page: Page,
  command: string,
  hash: RegExp,
  heading: string,
) {
  await page.keyboard.press('Control+KeyK');
  await page.getByText(command, { exact: true }).click();
  await expect(page).toHaveURL(hash);
  await expect(
    page.getByRole('heading', { name: heading, exact: true }),
  ).toBeAttached();
}

async function openChapterFromNavigation(
  page: Page,
  isMobile: boolean,
  control: string,
  hash: RegExp,
  heading: string,
) {
  if (isMobile) {
    await page
      .getByRole('button', { name: 'Open navigation menu', exact: true })
      .click();
  }
  const target = page.getByRole('button', { name: control, exact: true });
  await (isMobile ? target.last() : target.first()).click();
  await expect(page).toHaveURL(hash);
  await expect(
    page.getByRole('heading', { name: heading, exact: true }),
  ).toBeAttached();
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

test('boots the Flutter experience without browser errors', async ({ page }) => {
  const errors: string[] = [];
  page.on('pageerror', (error) => errors.push(error.message));
  page.on('console', (message) => {
    if (message.type() === 'error') errors.push(message.text());
  });
  page.on('response', (response) => {
    if (response.status() >= 400) {
      errors.push(`HTTP ${response.status()} ${response.url()}`);
    }
  });

  const response = await page.goto('/', { waitUntil: 'domcontentloaded' });
  expect(response?.status()).toBe(200);
  await page.waitForSelector('flt-semantics-host', {
    state: 'attached',
    timeout: 20000,
  });
  await expect(page.locator('#bootstrap-surface')).toHaveCount(0);
  await expect(page.getByRole('heading').first()).toBeAttached();
  const timeline = await readRuntimeTimeline(page);
  expect(timeline.every((value) => Number.isFinite(value))).toBe(true);
  expect(timeline).toEqual([...timeline].sort((a, b) => a! - b!));
  expect(await readRevealSourceCount(page)).toBe(1);
  expect(
    await page.evaluate(
      () =>
        performance.getEntriesByName(
          'flutter-bootstrap-to-first-frame',
          'measure',
        ).length,
    ),
  ).toBe(1);
  expect(errors).toEqual([]);
});

test('publishes a clean heading and control hierarchy', async ({
  page,
  isMobile,
}) => {
  await page.emulateMedia({ reducedMotion: 'reduce' });
  const accessibility = await readAccessibilityTree(page);
  await openPortfolio(page);
  await expect(page.locator('html')).toHaveAttribute(
    'data-render-quality',
    'essential',
  );
  await expect(page.locator('html')).toHaveAttribute(
    'data-render-quality-reason',
    'reducedMotion',
  );

  const initialTree = await accessibility.send(
    'Accessibility.getFullAXTree',
  );
  const initialNodes = initialTree.nodes.filter((node) => !node.ignored);
  const headings = initialNodes
    .filter((node) => node.role?.value === 'heading')
    .map((node) => ({
      name: node.name?.value ?? '',
      level: node.properties?.find((property) => property.name === 'level')
        ?.value?.value,
    }));
  const controls = initialNodes
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

  if (isMobile) {
    await page
      .getByRole('button', { name: 'Open navigation menu', exact: true })
      .click();
  }
  const aboutControl = page.getByRole('button', {
    name: 'About',
    exact: true,
  });
  await (isMobile ? aboutControl.last() : aboutControl.first()).click();
  await expect(page).toHaveURL(/#\/about$/);
  await expect(page.getByRole('heading', { name: 'About' })).toBeAttached();

  const sectionTree = await accessibility.send(
    'Accessibility.getFullAXTree',
  );
  const sectionHeading = sectionTree.nodes.find(
    (node) =>
      !node.ignored &&
      node.role?.value === 'heading' &&
      node.name?.value === 'About',
  );
  expect(
    sectionHeading?.properties?.find((property) => property.name === 'level')
      ?.value?.value,
  ).toBe(2);

  const aboutLinks = sectionTree.nodes
    .filter((node) => !node.ignored && node.role?.value === 'link')
    .map((node) => node.name?.value ?? '');
  expect(aboutLinks).toEqual(
    expect.arrayContaining(
      portfolio.profile.links.map((link) => link.label),
    ),
  );

  await openChapterFromNavigation(
    page,
    isMobile,
    'Open Source',
    /#\/proof$/,
    'Open Source',
  );
  const proofTree = await accessibility.send('Accessibility.getFullAXTree');
  const proofLinks = proofTree.nodes
    .filter((node) => !node.ignored && node.role?.value === 'link')
    .map((node) => node.name?.value ?? '');

  const visibleContribution = portfolio.contributions[0];
  expect(visibleContribution).toBeTruthy();
  const contributionStatus =
    visibleContribution.status === 'merged' ? 'Merged' : 'Under review';
  expect(proofLinks).toContain(
    `View pull request. ${visibleContribution.title}. `
      + `${visibleContribution.project} · ${contributionStatus} · ${visibleContribution.date}`,
  );

  await openChapterFromNavigation(
    page,
    isMobile,
    'Work',
    /#\/projects$/,
    'Selected Work',
  );

  const projectsTree = await accessibility.send(
    'Accessibility.getFullAXTree',
  );
  const projectLinks = projectsTree.nodes
    .filter((node) => !node.ignored && node.role?.value === 'link')
    .map((node) => node.name?.value ?? '');
  const featuredSystem = portfolio.systems.find((system) => system.featured);
  expect(featuredSystem).toBeTruthy();
  expect(projectLinks).toEqual(
    expect.arrayContaining([
      `Open project: ${featuredSystem.name}`,
    ]),
  );
  expect(projectLinks).not.toContain('View source');
  expect(projectLinks).not.toContain('Website');
});

test('renders a JSON-derived critical shell before the first Flutter frame', async ({
  page,
}) => {
  let releaseWasm: (() => void) | undefined;
  const wasmGate = new Promise<void>((resolve) => {
    releaseWasm = resolve;
  });
  await page.route('**/main.dart.wasm*', async (route) => {
    await wasmGate;
    await route.continue();
  });

  await page.goto('/', { waitUntil: 'domcontentloaded' });
  const shell = page.locator('#bootstrap-surface');
  await expect(shell).toBeVisible();
  await expect(shell).toHaveAttribute('aria-busy', 'true');
  await expect(shell).toHaveAttribute('aria-label', 'Loading interactive portfolio');
  await expect(shell.locator('.bootstrap-progress')).toHaveCount(0);
  const criticalShell = shell.locator('.bootstrap-shell');
  await expect(criticalShell).toBeVisible();
  await expect(criticalShell).toHaveAttribute('aria-hidden', 'true');
  await expect(criticalShell).toHaveAttribute(
    'data-content-version',
    portfolio.content_version,
  );
  await expect(criticalShell.locator('.bootstrap-title')).toContainText(
    portfolio.profile.display_name.primary,
  );
  await expect(
    criticalShell.locator('.bootstrap-title-accent'),
  ).toHaveText(portfolio.profile.display_name.accent);
  await expect(criticalShell.locator('.bootstrap-statement')).toHaveText(
    portfolio.profile.headline,
  );
  await expect(criticalShell.locator('.bootstrap-action')).toHaveText([
    'View selected work',
    'GitHub',
  ]);
  const facts = criticalShell.locator('.bootstrap-fact');
  const expectedFacts = [
    portfolio.profile.location,
    portfolio.profile.since,
    portfolio.profile.focus[0],
  ];
  for (const [index, value] of expectedFacts.entries()) {
    await expect(facts.nth(index)).toContainText(value);
  }

  releaseWasm?.();
  await expect(shell).toHaveCount(0, { timeout: 20000 });
});

test('keeps the critical identity inside narrow and short viewports', async ({
  page,
  isMobile,
}) => {
  test.skip(isMobile, 'one browser project covers the responsive HTML shell');
  await page.route('**/flutter_bootstrap.js*', (route) =>
    route.fulfill({
      body: '',
      contentType: 'application/javascript',
      status: 200,
    }),
  );

  for (const viewport of [
    { width: 280, height: 653 },
    { width: 568, height: 320 },
  ]) {
    await page.setViewportSize(viewport);
    await page.goto('/', { waitUntil: 'domcontentloaded' });
    const selectors = [
      '.bootstrap-rail',
      '.bootstrap-title',
      '.bootstrap-footer',
    ];
    for (const selector of selectors) {
      const box = await page.locator(selector).boundingBox();
      expect(box, selector).not.toBeNull();
      expect(box!.x, selector).toBeGreaterThanOrEqual(-1);
      expect(box!.y, selector).toBeGreaterThanOrEqual(-1);
      expect(box!.x + box!.width, selector).toBeLessThanOrEqual(
        viewport.width + 1,
      );
      expect(box!.y + box!.height, selector).toBeLessThanOrEqual(
        viewport.height + 1,
      );
    }
  }
});

test('retires the critical shell when a renderer omits the first-frame event', async ({
  page,
  isMobile,
}) => {
  test.skip(isMobile, 'renderer fallback contract needs one browser project');

  await page.addInitScript(() => {
    const nativeAddEventListener = window.addEventListener;
    window.addEventListener = function addEventListenerWithoutFlutterFrame(
      type,
      listener,
      options,
    ) {
      if (type === 'flutter-first-frame') return;
      nativeAddEventListener.call(window, type, listener, options);
    };
  });

  await page.goto('/', { waitUntil: 'domcontentloaded' });
  await page.waitForSelector('flt-semantics-host', {
    state: 'attached',
    timeout: 20000,
  });
  await expect(page.locator('#bootstrap-surface')).toHaveCount(0, {
    timeout: 20000,
  });
  await expect(page.getByRole('heading').first()).toBeAttached();
  expect(
    await page.evaluate(
      () =>
        performance.getEntriesByName('flutter-run-app-fallback', 'mark')
          .length,
    ),
  ).toBe(1);
  expect(
    await page.evaluate(
      () =>
        performance.getEntriesByName('flutter-first-frame-signal', 'mark')
          .length,
    ),
  ).toBe(1);
});

test('offers an accessible retry when the Wasm artifact cannot load', async ({
  page,
}) => {
  await page.route(/main\.dart\.(?:wasm|mjs|js)/, (route) =>
    route.abort('failed'),
  );
  await page.goto('/', { waitUntil: 'domcontentloaded' });

  await expect(page.getByRole('button', { name: 'Retry' })).toBeVisible({
    timeout: 20000,
  });
  await expect(page.locator('#bootstrap-surface')).toHaveAttribute(
    'aria-label',
    'The portfolio could not start',
  );
  await expect(page.locator('#bootstrap-surface')).toHaveAttribute(
    'aria-busy',
    'false',
  );
  await expect(
    page.getByText('The portfolio could not load. Please try again.'),
  ).toBeVisible();
});

test('runs the Wasm/SkWasm path with cross-origin isolation', async ({ page }) => {
  const wasmResponse = page.waitForResponse(
    (response) => response.url().includes('/main.dart.wasm?v='),
  );
  const runtimeResponse = page.waitForResponse(
    (response) => response.url().includes('/main.dart.mjs?v='),
  );
  const rendererResponse = page.waitForResponse(
    (response) =>
      /\/canvaskit\/[0-9a-f]{40}\/skwasm\.wasm$/.test(response.url()),
  );

  const documentResponse = await page.goto('/', {
    waitUntil: 'domcontentloaded',
  });
  const wasm = await wasmResponse;
  const runtime = await runtimeResponse;
  const renderer = await rendererResponse;

  expect(wasm.status()).toBe(200);
  expect(wasm.url()).toMatch(/main\.dart\.wasm\?v=[0-9a-f]{16}$/);
  expect(wasm.headers()['content-type']).toContain('application/wasm');
  expect(runtime.status()).toBe(200);
  expect(runtime.url()).toMatch(/main\.dart\.mjs\?v=[0-9a-f]{16}$/);
  expect(runtime.headers()['content-type']).toContain('javascript');
  expect(renderer.status()).toBe(200);
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
  expect(documentResponse?.headers()['content-security-policy']).not.toContain(
    'formspree.io',
  );
  expect(await page.evaluate(() => window.crossOriginIsolated)).toBe(true);
});

test('retires the legacy service worker without keeping a registration', async ({
  page,
}) => {
  await page.goto('/', { waitUntil: 'domcontentloaded' });
  await page.evaluate(async () => {
    const cache = await caches.open('unrelated-origin-contract');
    await cache.put(
      new Request('https://unrelated.example/static.css'),
      new Response('unrelated'),
    );
  });
  await page.evaluate(async () => {
    await navigator.serviceWorker.register('/flutter_service_worker.js');
  });

  await expect
    .poll(
      () =>
        page.evaluate(async () => {
          const registrations =
            await navigator.serviceWorker.getRegistrations();
          return registrations.length;
        }),
      { timeout: 10000 },
    )
    .toBe(0);
  expect(
    await page.evaluate(async () =>
      (await caches.keys()).includes('unrelated-origin-contract'),
    ),
  ).toBe(true);
  await page.evaluate(() => caches.delete('unrelated-origin-contract'));
});

test('serves same-origin fallback fonts without masking missing assets', async ({
  request,
}) => {
  const font = await request.get(
    '/assets/fallback_fonts/roboto/v32/KFOmCnqEu92Fr1Me4GZLCzYlKw.woff2',
  );
  expect(font.status()).toBe(200);
  expect(font.headers()['content-type']).toContain('font/woff2');

  for (const path of [
    '/assets/assets/fonts/inter/Inter-Variable.ttf',
    '/assets/assets/fonts/instrument_serif/InstrumentSerif-Regular.ttf',
    '/assets/assets/fonts/noto_sans_arabic/NotoSansArabic-Variable.ttf',
    '/assets/assets/fonts/noto_sans_devanagari/NotoSansDevanagari-Variable.ttf',
  ]) {
    const appFont = await request.get(path);
    expect(appFont.status(), path).toBe(200);
    expect(appFont.headers()['content-type'], path).toContain('font/ttf');
  }

  const missing = await request.get('/assets/fallback_fonts/missing.woff2');
  expect(missing.status()).toBe(404);
});

test('ships the social preview at the declared large-card dimensions', async ({
  request,
}) => {
  const response = await request.get(portfolio.site.social_image);
  expect(response.status()).toBe(200);
  expect(response.headers()['content-type']).toContain('image/png');

  const png = await response.body();
  expect(png.subarray(1, 4).toString()).toBe('PNG');
  expect(png.readUInt32BE(16)).toBe(1200);
  expect(png.readUInt32BE(20)).toBe(630);
});

test('does not publish renderer debug symbols', async ({ request }) => {
  const response = await request.get('/canvaskit/skwasm.js.symbols');
  expect(response.status()).toBe(404);

  const version = await request.get('/version.json');
  expect(version.status()).toBe(200);
  expect(await version.json()).toMatchObject({ version: '1.5.0' });
});

test('keeps every professional chapter in one accessible document', async ({
  page,
}) => {
  await openPortfolio(page);
  const chapters = [
    ['Go to About', /#\/about$/, 'About'],
    ['Go to Experience', /#\/experience$/, 'Experience'],
    ['Go to Open Source', /#\/proof$/, 'Open Source'],
    ['Go to Work', /#\/projects$/, 'Selected Work'],
  ] as const;

  for (const [command, hash, heading] of chapters) {
    await openChapterFromPalette(page, command, hash, heading);
  }

  await openChapterFromPalette(
    page,
    'Go to Experience',
    /#\/experience$/,
    'Experience',
  );
  await expect(
    page.getByText(portfolio.experience[0].company).first(),
  ).toBeAttached();
});

test('keeps the personal hero readable at 280 CSS pixels', async ({
  page,
  isMobile,
}) => {
  test.skip(isMobile, 'one browser project covers the ultra-narrow contract');
  await page.setViewportSize({ width: 280, height: 653 });
  await page.emulateMedia({ reducedMotion: 'reduce' });
  await openPortfolio(page);

  const heading = page.getByRole('heading', {
    name: `${portfolio.profile.display_name.accessible}, ${portfolio.profile.role}`,
  });
  const work = page.getByRole('button', { name: 'View selected work' });
  const github = page.getByRole('button', { name: 'GitHub', exact: true });
  const [headingBox, workBox, githubBox] = await Promise.all([
    heading.boundingBox(),
    work.boundingBox(),
    github.boundingBox(),
  ]);

  for (const [label, box] of [
    ['heading', headingBox],
    ['work action', workBox],
    ['GitHub action', githubBox],
  ] as const) {
    expect(box, label).not.toBeNull();
    expect(box!.x, label).toBeGreaterThanOrEqual(0);
    expect(box!.x + box!.width, label).toBeLessThanOrEqual(280);
  }
  expect(headingBox!.y + headingBox!.height).toBeLessThan(workBox!.y);
  expect(workBox!.y + workBox!.height).toBeLessThanOrEqual(githubBox!.y);
});

test('switches to the application-owned Arabic catalog', async ({ page }) => {
  const runtimeErrors: string[] = [];
  page.on('pageerror', (error) => runtimeErrors.push(error.message));
  await openPortfolio(page);
  await page.keyboard.press('Control+KeyK');
  await page.getByText('Go to Work', { exact: true }).click();
  await expect(page).toHaveURL(/#\/projects$/);

  await page.keyboard.press('Control+KeyK');
  await page.getByText('Switch to العربية', { exact: true }).click();

  await expect
    .poll(() => page.locator('html').getAttribute('lang'))
    .toBe('ar');
  await expect(page).toHaveURL(/#\/projects$/);
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

test('switches to the application-owned Hindi catalog', async ({ page }) => {
  await openPortfolio(page);
  await page.keyboard.press('Control+KeyK');
  await page.getByText('Switch to हिन्दी', { exact: true }).click();

  await expect
    .poll(() => page.locator('html').getAttribute('lang'))
    .toBe('hi');
  await expect(page.locator('html')).toHaveAttribute('dir', 'ltr');
  await expect(page.getByText('प्रोजेक्ट देखें', { exact: true })).toBeAttached();
});

test('keeps section hashes synchronized with browser history', async ({ page }) => {
  await openPortfolio(page);
  await page.keyboard.press('Control+KeyK');
  const projectsCommand = page.getByText('Go to Work', { exact: true });
  await expect(projectsCommand).toBeVisible();
  await projectsCommand.click();
  await expect(page).toHaveURL(/#\/projects$/);

  await page.goBack();
  await expect.poll(() => page.evaluate(() => window.location.hash)).toBe('');
});
