import { test } from '@playwright/test';
const URL = 'https://developeryusuf.com';
test.setTimeout(180000);

test('switch to Turkish, inspect consistency', async ({ page }, testInfo) => {
  await page.goto(URL, { waitUntil: 'domcontentloaded' });
  await page.waitForSelector('canvas', { timeout: 45000 }).catch(() => {});
  await page.waitForTimeout(6000);
  const size = page.viewportSize()!;
  if (size.width < 800) test.skip();
  // open language dropdown
  await page.mouse.click(size.width - 30, 35);
  await page.waitForTimeout(1500);
  await page.screenshot({ path: testInfo.outputPath('drop-open.png') });
  // click top-most flag row (Türkçe) — first item right below flag. Dropdown visible around x≈1350, first item y≈80
  // From screenshot earlier Türkçe was first
  await page.mouse.click(size.width - 60, 80);
  await page.waitForTimeout(2500);
  await page.screenshot({ path: testInfo.outputPath('after-tr-home.png') });
  // navigate sections
  for (let i = 0; i < 14; i++) {
    await page.mouse.move(size.width/2, size.height/2);
    await page.mouse.wheel(0, 500);
    await page.waitForTimeout(2000);
    await page.screenshot({ path: testInfo.outputPath(`tr-${String(i).padStart(2, '0')}.png`) });
  }
});
