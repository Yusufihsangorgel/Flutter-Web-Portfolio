import { test, expect, Page } from '@playwright/test';

const URL = 'https://developeryusuf.com';

async function waitForFlutter(page: Page) {
  await page.goto(URL, { waitUntil: 'domcontentloaded' });
  // Flutter renders into a canvas/flt-glass-pane. Wait for it.
  await page.waitForSelector('flt-glass-pane, flutter-view, canvas', { timeout: 45000 }).catch(() => {});
  await page.waitForTimeout(4000);
}

test.describe('developeryusuf.com audit', () => {
  test('loads + screenshots', async ({ page }, testInfo) => {
    const consoleErrors: string[] = [];
    page.on('pageerror', (e) => consoleErrors.push('pageerror: ' + e.message));
    page.on('console', (m) => { if (m.type() === 'error') consoleErrors.push('console: ' + m.text()); });

    const resp = await page.goto(URL, { waitUntil: 'domcontentloaded' });
    expect(resp?.status()).toBeLessThan(400);
    await page.waitForSelector('flt-glass-pane, flutter-view, canvas', { timeout: 45000 }).catch(() => {});
    await page.waitForTimeout(5000);

    await page.screenshot({ path: testInfo.outputPath('home-desktop.png'), fullPage: true });

    const semantics = await page.evaluate(() => {
      const root = document.querySelector('flt-semantics-host') || document.body;
      return (root as HTMLElement).innerText || '';
    });
    await testInfo.attach('semantics-text', { body: semantics, contentType: 'text/plain' });

    // lang attribute
    const htmlLang = await page.evaluate(() => document.documentElement.lang);
    await testInfo.attach('html-lang', { body: String(htmlLang || '(empty)'), contentType: 'text/plain' });

    // raw untranslated keys
    const rawKeys = /\b[a-z][a-zA-Z0-9_]+\.[a-z][a-zA-Z0-9_]+\b/.test(semantics) ? semantics.match(/\b[a-z][a-zA-Z0-9_]+\.[a-z][a-zA-Z0-9_]+\b/g) : [];
    await testInfo.attach('possible-raw-keys', { body: JSON.stringify(rawKeys?.slice(0, 30) ?? []), contentType: 'application/json' });

    await testInfo.attach('console-errors', { body: consoleErrors.join('\n') || '(none)', contentType: 'text/plain' });
    console.log('AUDIT_HTMLLANG=' + JSON.stringify(htmlLang));
    console.log('AUDIT_SEM_LEN=' + semantics.length);
    console.log('AUDIT_SEM_SNIPPET=' + JSON.stringify(semantics.slice(0, 3000)));
    console.log('AUDIT_CONSOLE_ERRORS=' + JSON.stringify(consoleErrors));
  });

  test('theme toggle (if present)', async ({ page }, testInfo) => {
    await waitForFlutter(page);
    const beforeBg = await page.evaluate(() => getComputedStyle(document.body).backgroundColor);
    // Flutter semantics buttons usually have aria-label. Try theme/dark/light toggles.
    const btn = page.locator('flt-semantics[role="button"]').filter({ hasText: /theme|dark|light|tema|koyu|aç/i }).first();
    const count = await btn.count();
    if (count > 0) {
      await btn.click({ force: true }).catch(() => {});
      await page.waitForTimeout(1500);
      await page.screenshot({ path: testInfo.outputPath('after-theme.png'), fullPage: true });
    }
    const afterBg = await page.evaluate(() => getComputedStyle(document.body).backgroundColor);
    await testInfo.attach('theme-bg', { body: `before=${beforeBg}\nafter=${afterBg}\ntoggleFound=${count}`, contentType: 'text/plain' });
    console.log('THEME_BEFORE=' + beforeBg + ' AFTER=' + afterBg + ' TOGGLES=' + count);
  });

  test('language toggle (if present)', async ({ page }, testInfo) => {
    await waitForFlutter(page);
    const getText = async () => {
      return await page.evaluate(() => {
        const root = document.querySelector('flt-semantics-host') || document.body;
        return (root as HTMLElement).innerText || '';
      });
    };
    const before = await getText();
    const langBtn = page.locator('flt-semantics[role="button"]').filter({ hasText: /EN|TR|english|türkçe|turkce|language|dil/i }).first();
    const count = await langBtn.count();
    if (count > 0) {
      await langBtn.click({ force: true }).catch(() => {});
      await page.waitForTimeout(1500);
    }
    const after = await getText();
    await testInfo.attach('i18n-before', { body: before.slice(0, 2000), contentType: 'text/plain' });
    await testInfo.attach('i18n-after', { body: after.slice(0, 2000), contentType: 'text/plain' });
    await testInfo.attach('i18n-togglecount', { body: String(count), contentType: 'text/plain' });
    await page.screenshot({ path: testInfo.outputPath('after-lang.png'), fullPage: true });
    console.log('I18N_TOGGLES=' + count);
    console.log('I18N_BEFORE=' + JSON.stringify(before.slice(0, 1500)));
    console.log('I18N_AFTER=' + JSON.stringify(after.slice(0, 1500)));
  });
});
