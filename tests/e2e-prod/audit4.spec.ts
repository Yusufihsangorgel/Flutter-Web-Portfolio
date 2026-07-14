import { test, Page } from '@playwright/test';
const URL = 'https://developeryusuf.com';

test.setTimeout(180000);

test('slow scroll desktop, wait for content to render', async ({ page }, testInfo) => {
  const size = { width: 1440, height: 900 };
  await page.goto(URL, { waitUntil: 'domcontentloaded' });
  await page.waitForSelector('canvas', { timeout: 45000 }).catch(() => {});
  await page.waitForTimeout(6000);
  const cx = size.width / 2, cy = size.height / 2;

  const anchors = ['About', 'Experience', 'Proof', 'Blog', 'Projects', 'Contact'];
  for (let i = 0; i < 14; i++) {
    await page.mouse.move(cx, cy);
    await page.mouse.wheel(0, 500);
    await page.waitForTimeout(2500); // give animations & entries time
    await page.screenshot({ path: testInfo.outputPath(`slow-${String(i).padStart(2, '0')}.png`) });
  }
});

test('click nav item Blog directly', async ({ page }, testInfo) => {
  await page.goto(URL, { waitUntil: 'domcontentloaded' });
  await page.waitForSelector('canvas', { timeout: 45000 }).catch(() => {});
  await page.waitForTimeout(6000);
  // nav items appear centered top. Click at approximate BLOG coord for 1440 viewport:
  // Previously saw: ABOUT EXPERIENCE PROOF BLOG PROJECTS CONTACT
  await page.mouse.click(1150, 40); // rough BLOG location
  await page.waitForTimeout(3000);
  await page.screenshot({ path: testInfo.outputPath('nav-blog.png') });

  await page.mouse.click(1220, 40); // PROJECTS
  await page.waitForTimeout(3000);
  await page.screenshot({ path: testInfo.outputPath('nav-projects.png') });

  await page.mouse.click(1300, 40); // CONTACT
  await page.waitForTimeout(3000);
  await page.screenshot({ path: testInfo.outputPath('nav-contact.png') });
});
