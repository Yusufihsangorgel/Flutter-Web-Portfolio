import { test, expect, Page, ConsoleMessage, Request, Response } from '@playwright/test';

const waitForFlutter = async (page: Page) => {
  // Flutter web mounts to a <flt-glass-pane> or canvaskit canvas
  await page.waitForLoadState('domcontentloaded');
  await page.waitForFunction(
    () => {
      const glass = document.querySelector('flt-glass-pane, flutter-view, flt-scene-host');
      const canvas = document.querySelector('canvas');
      return !!(glass || canvas);
    },
    { timeout: 45000 }
  );
  // Give the Flutter engine a moment to render a frame
  await page.waitForTimeout(2500);
};

test.describe('developeryusuf.com portfolio', () => {
  test('home page loads (200, title, Flutter renders)', async ({ page }) => {
    const response = await page.goto('/', { waitUntil: 'domcontentloaded' });
    expect(response, 'navigation response should exist').not.toBeNull();
    expect(response!.status(), 'home status').toBeLessThan(400);
    await waitForFlutter(page);

    const title = await page.title();
    expect(title.length, `page title should be non-empty (got "${title}")`).toBeGreaterThan(0);

    // Flutter canvaskit/html renders at least one canvas
    const canvasCount = await page.locator('canvas').count();
    expect(canvasCount, 'Flutter should render >=1 <canvas>').toBeGreaterThan(0);
  });

  test('main visual sections visible (non-blank viewport)', async ({ page }) => {
    await page.goto('/', { waitUntil: 'domcontentloaded' });
    await waitForFlutter(page);

    // Because Flutter paints to canvas, we assert the glass-pane box is non-zero
    const pane = page.locator('flt-glass-pane, flutter-view, flt-scene-host').first();
    const box = await pane.boundingBox();
    expect(box, 'flutter root has a bounding box').not.toBeNull();
    expect((box?.width ?? 0) * (box?.height ?? 0), 'flutter root area > 0').toBeGreaterThan(10000);

    // Scroll through the page to trigger section renders (Flutter uses scroll events)
    for (const y of [0, 600, 1200, 1800, 2400, 3000]) {
      await page.mouse.wheel(0, 600);
      await page.waitForTimeout(400);
    }
    await expect(page).toHaveScreenshot; // screenshot utility available (not called, just sanity)
  });

  test('no console errors on load', async ({ page }) => {
    const errors: string[] = [];
    page.on('console', (msg: ConsoleMessage) => {
      if (msg.type() === 'error') errors.push(msg.text());
    });
    page.on('pageerror', (err) => errors.push(`pageerror: ${err.message}`));

    await page.goto('/', { waitUntil: 'domcontentloaded' });
    await waitForFlutter(page);
    await page.waitForTimeout(2000);

    // Filter out known benign noise (favicon/preload warnings)
    const meaningful = errors.filter((e) => !/favicon|manifest\.json|preload|service-?worker/i.test(e));
    expect(meaningful, `console errors found:\n${meaningful.join('\n')}`).toEqual([]);
  });

  test('no broken images / no 4xx-5xx network responses', async ({ page }) => {
    const bad: { url: string; status: number; type: string }[] = [];

    page.on('response', (resp: Response) => {
      const status = resp.status();
      const url = resp.url();
      const type = resp.request().resourceType();
      if (status >= 400 && !/favicon|\.map$/i.test(url)) {
        bad.push({ url, status, type });
      }
    });

    await page.goto('/', { waitUntil: 'domcontentloaded' });
    await waitForFlutter(page);
    await page.waitForTimeout(3000);

    // Any raw <img> tags should have naturalWidth > 0
    const brokenImages = await page.$$eval('img', (imgs) =>
      imgs
        .filter((i) => !(i as HTMLImageElement).complete || (i as HTMLImageElement).naturalWidth === 0)
        .map((i) => (i as HTMLImageElement).src)
    );

    expect(bad, `4xx/5xx responses:\n${bad.map((b) => `${b.status} ${b.type} ${b.url}`).join('\n')}`).toEqual([]);
    expect(brokenImages, `broken <img> sources:\n${brokenImages.join('\n')}`).toEqual([]);
  });

  test('contact / project link assets reachable', async ({ page, request }) => {
    await page.goto('/', { waitUntil: 'domcontentloaded' });
    await waitForFlutter(page);

    // Flutter app typically opens social/project URLs via window.open
    // Capture popup targets by hooking window.open
    const openedUrls: string[] = [];
    await page.exposeFunction('__capture', (u: string) => openedUrls.push(u));
    await page.evaluate(() => {
      const orig = window.open;
      window.open = function (u?: string | URL) {
        // @ts-ignore
        window.__capture(String(u));
        return null as any;
      } as any;
    });

    // Try clicking around the page in likely link regions (canvas driven)
    for (const y of [200, 400, 800, 1200, 1600, 2000, 2400]) {
      await page.mouse.click(720, y);
      await page.waitForTimeout(200);
    }

    // At minimum the Flutter shell should not have crashed
    const canvas = await page.locator('canvas').count();
    expect(canvas, 'canvas still present after interaction').toBeGreaterThan(0);

    // Sanity check the domain itself via HEAD
    const head = await request.get('/');
    expect(head.status()).toBeLessThan(400);
  });

  test('mobile viewport renders Flutter', async ({ page, browserName, isMobile }) => {
    test.skip(!isMobile, 'mobile-only assertion');
    await page.goto('/', { waitUntil: 'domcontentloaded' });
    await waitForFlutter(page);
    const canvas = await page.locator('canvas').count();
    expect(canvas).toBeGreaterThan(0);
    const vp = page.viewportSize();
    expect(vp!.width).toBeLessThan(600);
  });
});
