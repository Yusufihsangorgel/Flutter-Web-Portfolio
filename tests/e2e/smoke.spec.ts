import { expect, Page, test } from '@playwright/test';

async function openPortfolio(page: Page) {
  await page.goto('/', { waitUntil: 'domcontentloaded' });
  await page.waitForSelector('flt-semantics-host', {
    state: 'attached',
    timeout: 20000,
  });
  await expect(page.locator('#bootstrap-surface')).toHaveCount(0);
  await expect(page.getByRole('heading').first()).toBeAttached();
}

async function readAccessibilityTree(page: Page) {
  const session = await page.context().newCDPSession(page);
  await session.send('Accessibility.enable');
  return session;
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
  expect(errors).toEqual([]);
});

test('publishes a clean heading and control hierarchy', async ({
  page,
  isMobile,
}) => {
  await page.emulateMedia({ reducedMotion: 'reduce' });
  const accessibility = await readAccessibilityTree(page);
  await openPortfolio(page);

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

  expect(headings).toContainEqual({ name: 'SENIOR FLUTTER ENGINEER.', level: 1 });
  expect(controls).toEqual(
    expect.arrayContaining([
      'Skip to content',
      'Back to top',
      ...(isMobile
        ? ['Open navigation menu']
        : ['About', 'Experience', 'Approach', 'Projects']),
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
  await expect(page.getByRole('heading', { name: 'About Me' })).toBeAttached();

  const sectionTree = await accessibility.send(
    'Accessibility.getFullAXTree',
  );
  const sectionHeading = sectionTree.nodes.find(
    (node) =>
      !node.ignored &&
      node.role?.value === 'heading' &&
      node.name?.value === 'About Me',
  );
  expect(
    sectionHeading?.properties?.find((property) => property.name === 'level')
      ?.value?.value,
  ).toBe(2);

  await expect(
    page.getByRole('heading', { name: 'Selected Work' }),
  ).toBeAttached();

  const projectsTree = await accessibility.send(
    'Accessibility.getFullAXTree',
  );
  const projectLinks = projectsTree.nodes
    .filter((node) => !node.ignored && node.role?.value === 'link')
    .map((node) => node.name?.value ?? '');
  expect(projectLinks).toContain('Open Project: FakeCallApp');
  expect(projectLinks).not.toContain('Open Project');
  expect(projectLinks).not.toContain('Website');
});

test('paints an accessible portfolio shell before the Wasm canvas', async ({
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
  await expect(
    shell.getByRole('heading', { name: 'SENIOR FLUTTER ENGINEER.' }),
  ).toBeVisible();
  await expect(shell.getByText('Product-minded Flutter engineering')).toBeVisible();
  await expect(shell.getByText('Preparing the portfolio')).toBeVisible();

  releaseWasm?.();
  await expect(shell).toHaveCount(0, { timeout: 20000 });
});

test('offers an accessible retry when the Wasm artifact cannot load', async ({
  page,
}) => {
  await page.route('**/main.dart.wasm*', (route) => route.abort('failed'));
  await page.goto('/', { waitUntil: 'domcontentloaded' });

  await expect(page.getByText('The portfolio could not start')).toBeVisible({
    timeout: 20000,
  });
  await expect(page.getByRole('button', { name: 'Retry' })).toBeVisible();
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
});

test('serves same-origin fallback fonts without masking missing assets', async ({
  request,
}) => {
  const font = await request.get(
    '/assets/fallback_fonts/roboto/v32/KFOmCnqEu92Fr1Me4GZLCzYlKw.woff2',
  );
  expect(font.status()).toBe(200);
  expect(font.headers()['content-type']).toContain('font/woff2');

  const missing = await request.get('/assets/fallback_fonts/missing.woff2');
  expect(missing.status()).toBe(404);
});

test('ships the social preview at the declared large-card dimensions', async ({
  request,
}) => {
  const response = await request.get('/assets/og/engineering-showcase.png');
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
  expect(await version.json()).toMatchObject({ version: '1.1.0' });
});

test('keeps every professional chapter in one accessible document', async ({
  page,
}) => {
  await openPortfolio(page);
  await expect(page.getByRole('heading', { name: 'About Me' })).toBeAttached();
  await expect(page.getByRole('heading', { name: 'Experience' })).toBeAttached();
  await expect(page.getByRole('heading', { name: 'How I Work' })).toBeAttached();
  await expect(
    page.getByRole('heading', { name: 'Selected Work' }),
  ).toBeAttached();
  await expect(page.getByText('Mobile Team Lead')).toBeAttached();
});

test('switches to the application-owned Arabic catalog', async ({ page }) => {
  await openPortfolio(page);
  await page.keyboard.press('Control+KeyK');
  await page.getByText('Switch to العربية', { exact: true }).click();

  await expect
    .poll(() => page.locator('html').getAttribute('lang'))
    .toBe('ar');
  await expect(page.locator('html')).toHaveAttribute('dir', 'rtl');
  await expect(page.getByText('عرض المشاريع', { exact: true })).toBeAttached();

  await page.keyboard.press('Control+KeyK');
  await expect(
    page.getByText('الانتقال إلى المشاريع', { exact: true }),
  ).toBeVisible();
});

test('keeps section hashes synchronized with browser history', async ({ page }) => {
  await openPortfolio(page);
  await page.keyboard.press('Control+KeyK');
  const projectsCommand = page.getByText('Go to Projects', { exact: true });
  await expect(projectsCommand).toBeVisible();
  await projectsCommand.click();
  await expect(page).toHaveURL(/#\/projects$/);

  await page.goBack();
  await expect.poll(() => page.evaluate(() => window.location.hash)).toBe('');
});
