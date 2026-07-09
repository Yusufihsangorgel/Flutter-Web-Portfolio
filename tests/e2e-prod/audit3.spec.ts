import { test, Page } from '@playwright/test';

const URL = 'https://developeryusuf.com';

async function load(page: Page) {
  await page.goto(URL, { waitUntil: 'domcontentloaded' });
  await page.waitForSelector('flt-glass-pane, canvas', { timeout: 45000 }).catch(() => {});
  await page.waitForTimeout(5000);
}

test.setTimeout(240000);

test('scroll via mouse wheel + collect section screenshots', async ({ page }, testInfo) => {
  await load(page);
  const size = page.viewportSize()!;
  const cx = Math.floor(size.width / 2);
  const cy = Math.floor(size.height / 2);

  for (let i = 0; i < 12; i++) {
    await page.mouse.move(cx, cy);
    await page.mouse.wheel(0, size.height * 0.9);
    await page.waitForTimeout(1200);
    await page.screenshot({ path: testInfo.outputPath(`wheel-${i}.png`) });
  }
});

test('click flag top-right on desktop, inspect change', async ({ page }, testInfo) => {
  await load(page);
  const size = page.viewportSize()!;
  if (size.width < 800) test.skip();

  await page.screenshot({ path: testInfo.outputPath('lang-before.png') });
  // flag approx: right edge ~ 30px, top ~ 30-40px
  await page.mouse.click(size.width - 30, 35);
  await page.waitForTimeout(2500);
  await page.screenshot({ path: testInfo.outputPath('lang-after.png') });
});

test('mobile: flag in header region', async ({ page }, testInfo) => {
  await load(page);
  const size = page.viewportSize()!;
  if (size.width >= 800) test.skip();
  await page.screenshot({ path: testInfo.outputPath('mob-before.png') });
  await page.mouse.click(size.width - 30, 35);
  await page.waitForTimeout(2500);
  await page.screenshot({ path: testInfo.outputPath('mob-after-flag.png') });
  // hamburger
  await page.reload();
  await page.waitForTimeout(5000);
  await page.mouse.click(25, 35);
  await page.waitForTimeout(2000);
  await page.screenshot({ path: testInfo.outputPath('mob-after-hamburger.png') });
});
