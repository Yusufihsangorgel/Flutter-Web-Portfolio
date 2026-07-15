import { expect, Page, test } from '@playwright/test';

async function settleCompositor(page: Page, frameCount = 3) {
  await page.evaluate(
    (frames) =>
      new Promise<void>((resolve) => {
        let remaining = frames;
        const next = () => {
          remaining -= 1;
          if (remaining === 0) {
            resolve();
            return;
          }
          window.requestAnimationFrame(next);
        };
        window.requestAnimationFrame(next);
      }),
    frameCount,
  );
}

async function openStaticPortfolio(page: Page) {
  await page.emulateMedia({
    colorScheme: 'dark',
    reducedMotion: 'reduce',
  });
  await page.goto('/', { waitUntil: 'domcontentloaded' });
  await page.waitForSelector('flt-semantics-host', {
    state: 'attached',
    timeout: 20000,
  });
  await expect(page.locator('#bootstrap-surface')).toHaveCount(0);
  await expect(page.getByRole('heading').first()).toBeAttached();
  await expect(page.locator('html')).toHaveAttribute(
    'data-render-quality',
    'essential',
  );
  await settleCompositor(page);
}

async function openChapter(page: Page, command: string, hash: RegExp) {
  await page.keyboard.press('Control+KeyK');
  await page.getByText(command, { exact: true }).click();
  await expect(page).toHaveURL(hash);
  await settleCompositor(page);
}

test('keeps the first meaningful paint visually aligned with the portfolio', async ({
  page,
}) => {
  await page.emulateMedia({
    colorScheme: 'dark',
    reducedMotion: 'reduce',
  });

  await page.route('**/flutter_bootstrap.js*', (route) =>
    route.fulfill({
      body: '',
      contentType: 'application/javascript',
      status: 200,
    }),
  );

  await page.goto('/', { waitUntil: 'domcontentloaded' });
  await expect(page.locator('#bootstrap-surface')).toBeVisible();
  await settleCompositor(page);
  await expect(page).toHaveScreenshot('critical-shell.png');
});

test('preserves the editorial sequence across responsive viewports', async ({
  page,
}) => {
  await openStaticPortfolio(page);
  await expect(page).toHaveScreenshot('hero.png');

  await openChapter(page, 'Go to Open Source', /#\/proof$/);
  await expect(page).toHaveScreenshot('open-source.png');

  await openChapter(page, 'Go to Systems', /#\/projects$/);
  await expect(
    page.getByRole('heading', { name: 'Selected Systems' }),
  ).toBeAttached();
  await expect(page).toHaveScreenshot('systems.png');
});
