import { expect, Page, test } from '@playwright/test';

async function openPortfolio(page: Page) {
  const response = await page.goto('/', { waitUntil: 'domcontentloaded' });
  expect(response?.status()).toBe(200);
  await page.waitForSelector('flt-semantics-host', {
    state: 'attached',
    timeout: 75000,
  });
  await expect(page.getByRole('heading').first()).toBeAttached();
  await expect(page.locator('#bootstrap-surface')).toHaveCount(0);
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
  await expect(page.getByRole('heading').first()).toBeAttached();
  await expect(page.locator('#bootstrap-surface')).toHaveCount(0);
  expect(await page.evaluate(() => window.crossOriginIsolated)).toBe(true);
  expect(badResponses).toEqual([]);
  expect(errors).toEqual([]);
});

test('exposes interactive engineering evidence in production', async ({ page }) => {
  await openPortfolio(page);
  await page.keyboard.press('Control+Shift+KeyL');

  await expect(page.getByText('ENGINEERING LAB / LIVE')).toBeAttached();
  await expect(page.getByText('Dart WebAssembly')).toBeAttached();
  await expect(page.getByText('SkWasm', { exact: true })).toBeAttached();
  await expect(page.getByText('main.dart.wasm')).toBeAttached();
  await expect(page.getByText('Flutter scheduler telemetry')).toBeAttached();
});

test('serves the localized Arabic command surface in production', async ({
  page,
  isMobile,
}) => {
  test.skip(isMobile, 'locale contract only needs one browser project');

  await openPortfolio(page);
  await page.keyboard.press('Control+KeyK');
  await page.getByText('Switch to العربية', { exact: true }).click();

  await expect(page.locator('html')).toHaveAttribute('lang', 'ar');
  await expect(page.locator('html')).toHaveAttribute('dir', 'rtl');
  await expect(page.getByText('استكشاف الأنظمة', { exact: true })).toBeAttached();
});

test('serves the declared production sharing and font assets', async ({
  request,
  isMobile,
}) => {
  test.skip(isMobile, 'static release contract only needs one browser project');

  const document = await request.get('/');
  expect(document.status()).toBe(200);
  const html = await document.text();
  expect(html).toContain('class="bootstrap-title"');
  expect(html).toContain('aria-busy="true"');
  expect(html).toContain('Preparing the live canvas');
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

  const missing = await request.get('/assets/fallback_fonts/missing.woff2');
  expect(missing.status()).toBe(404);

  const rendererSymbols = await request.get(
    '/canvaskit/skwasm.js.symbols',
  );
  expect(rendererSymbols.status()).toBe(404);

  const version = await request.get('/version.json');
  expect(version.status()).toBe(200);
  expect(await version.json()).toMatchObject({ version: '1.1.0' });
});
