import { test, Page } from '@playwright/test';

const URL = 'https://developeryusuf.com';

async function load(page: Page) {
  await page.goto(URL, { waitUntil: 'domcontentloaded' });
  await page.waitForSelector('flt-glass-pane, canvas', { timeout: 45000 }).catch(() => {});
  await page.waitForTimeout(5000);
  // Enable Flutter semantics by clicking the hidden placeholder
  const placeholder = page.locator('flt-semantics-placeholder').first();
  if (await placeholder.count()) {
    await placeholder.click({ force: true }).catch(() => {});
    await page.waitForTimeout(1000);
  }
}

async function readSemantics(page: Page) {
  return await page.evaluate(() => {
    const host = document.querySelector('flt-semantics-host');
    return host ? (host as HTMLElement).innerText : '';
  });
}

test('interact via flag + hamburger, scroll sections, dump semantics', async ({ page, viewport }, testInfo) => {
  await load(page);

  // Full-page screenshots at multiple scroll positions to see all sections
  const vh = viewport?.height ?? 900;
  const totalHeight = await page.evaluate(() => document.body.scrollHeight || document.documentElement.scrollHeight);
  const shots: string[] = [];
  for (let y = 0, i = 0; y < Math.min(totalHeight, 12000); y += vh, i++) {
    await page.evaluate((yy) => window.scrollTo(0, yy), y);
    await page.waitForTimeout(1200);
    const p = testInfo.outputPath(`scroll-${i}.png`);
    await page.screenshot({ path: p });
    shots.push(p);
  }
  console.log('SCROLL_SHOTS=' + shots.length);

  // Try clicking top-right (flag) — approximate coords
  const size = page.viewportSize()!;
  // go back to top first
  await page.evaluate(() => window.scrollTo(0, 0));
  await page.waitForTimeout(500);
  const flagX = size.width - 30;
  const flagY = 35;
  await page.mouse.click(flagX, flagY);
  await page.waitForTimeout(2000);
  await page.screenshot({ path: testInfo.outputPath('after-flag-click.png'), fullPage: false });

  // Dump semantics after enabling a11y
  const sem = await readSemantics(page);
  console.log('SEM_AFTER_FLAG_LEN=' + sem.length);
  console.log('SEM_AFTER_FLAG=' + JSON.stringify(sem.slice(0, 4000)));

  // Click again to toggle back
  await page.mouse.click(flagX, flagY);
  await page.waitForTimeout(1500);
  await page.screenshot({ path: testInfo.outputPath('after-flag-click2.png'), fullPage: false });

  // Mobile hamburger test
  if (size.width < 800) {
    await page.mouse.click(20, 35);
    await page.waitForTimeout(1500);
    await page.screenshot({ path: testInfo.outputPath('after-hamburger.png'), fullPage: false });
  }
});
