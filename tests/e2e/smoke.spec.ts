import { expect, Page, test } from '@playwright/test';

async function openPortfolio(page: Page) {
  await page.goto('/', { waitUntil: 'domcontentloaded' });
  await page.waitForSelector('flt-semantics-host', {
    state: 'attached',
    timeout: 20000,
  });
  await expect(page.getByRole('heading').first()).toBeAttached();
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
  await expect(page.getByRole('heading').first()).toBeAttached();
  await expect(page.locator('#bootstrap-surface')).toHaveCount(0);
  expect(errors).toEqual([]);
});

test('offers an accessible retry when the Wasm artifact cannot load', async ({
  page,
}) => {
  await page.route('**/main.dart.wasm', (route) => route.abort('failed'));
  await page.goto('/', { waitUntil: 'domcontentloaded' });

  await expect(page.getByText('FLUTTER WEB / BOOT FAILED')).toBeVisible({
    timeout: 20000,
  });
  await expect(page.getByRole('button', { name: 'RETRY' })).toBeVisible();
  await expect(page.locator('#bootstrap-surface')).toHaveAttribute(
    'aria-label',
    'The Flutter experience could not start',
  );
});

test('runs the Wasm/SkWasm path with cross-origin isolation', async ({ page }) => {
  const wasmResponse = page.waitForResponse(
    (response) => response.url().endsWith('/main.dart.wasm'),
  );
  const runtimeResponse = page.waitForResponse(
    (response) => response.url().endsWith('/main.dart.mjs'),
  );

  const documentResponse = await page.goto('/', {
    waitUntil: 'domcontentloaded',
  });
  const wasm = await wasmResponse;
  const runtime = await runtimeResponse;

  expect(wasm.status()).toBe(200);
  expect(wasm.headers()['content-type']).toContain('application/wasm');
  expect(runtime.status()).toBe(200);
  expect(runtime.headers()['content-type']).toContain('javascript');
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

test('exposes the live Engineering Lab through the keyboard', async ({ page }) => {
  await openPortfolio(page);
  await page.keyboard.press('Control+Shift+KeyL');

  await expect(page.getByText('ENGINEERING LAB / LIVE')).toBeAttached();
  await expect(page.getByText('Dart WebAssembly')).toBeAttached();
  await expect(page.getByText('SkWasm', { exact: true })).toBeAttached();
  await expect(page.getByText('main.dart.wasm')).toBeAttached();
  await expect(page.getByText('Active', { exact: true })).toBeAttached();
  await expect(page.getByText('Flutter scheduler telemetry')).toBeAttached();
});

test('keeps section hashes synchronized with browser history', async ({ page }) => {
  await openPortfolio(page);
  await page.keyboard.press('Control+KeyK');
  await page.getByText('Go to Projects', { exact: true }).click({ force: true });
  await expect(page).toHaveURL(/#\/projects$/);

  await page.goBack();
  await expect.poll(() => page.evaluate(() => window.location.hash)).toBe('');
});
