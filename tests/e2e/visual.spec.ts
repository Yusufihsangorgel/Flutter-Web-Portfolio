import { expect, Page, test } from '@playwright/test';
import { readFileSync } from 'node:fs';

const portfolio = JSON.parse(
  readFileSync('assets/content/portfolio.json', 'utf8'),
);
const english = JSON.parse(readFileSync('assets/i18n/en.json', 'utf8'));

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

async function waitForHeadingInViewport(page: Page, name: string) {
  const heading = page.getByRole('heading', { name, exact: true });
  await expect(heading).toBeVisible();
  await expect
    .poll(async () => {
      const [box, viewport] = await Promise.all([
        heading.boundingBox(),
        page.evaluate(() => ({
          height: window.innerHeight,
          width: window.innerWidth,
        })),
      ]);
      if (!box) return false;
      return (
        box.width > 0 &&
        box.height > 0 &&
        box.x < viewport.width &&
        box.x + box.width > 0 &&
        box.y < viewport.height &&
        box.y + box.height > 0
      );
    })
    .toBe(true);
  await page.evaluate(() => document.fonts.ready);
  await settleCompositor(page, 8);
  // Flutter's semantics tree can lead the SkWasm surface by a few frames on
  // CPU-constrained Linux runners. Give the compositor one bounded maturity
  // window, then require another frame sequence before taking a baseline.
  await page.waitForTimeout(2000);
  await settleCompositor(page, 4);
}

async function openStaticPortfolio(page: Page) {
  await page.emulateMedia({
    colorScheme: 'light',
    reducedMotion: 'reduce',
  });
  await page.goto('/', { waitUntil: 'domcontentloaded' });
  await page.waitForSelector('flt-semantics-host', {
    state: 'attached',
    timeout: 20000,
  });
  await expect(page.locator('#bootstrap-surface')).toHaveCount(0);
  await waitForHeadingInViewport(
    page,
    `${portfolio.profile.display_name.accessible}, ${portfolio.profile.role}`,
  );
  await expect(page.locator('html')).toHaveAttribute(
    'data-render-quality',
    'essential',
  );
}

async function openChapter(
  page: Page,
  command: string,
  hash: RegExp,
  heading: string,
) {
  await page.keyboard.press('Control+KeyK');
  await page.getByText(command, { exact: true }).click();
  await expect(page).toHaveURL(hash);
  await waitForHeadingInViewport(page, heading);
}

async function scrollToHeading(page: Page, name: string) {
  const heading = page.getByRole('heading', { name, exact: true });
  for (let attempt = 0; attempt < 80; attempt += 1) {
    if ((await heading.count()) > 0) {
      const [box, viewportHeight] = await Promise.all([
        heading.boundingBox(),
        page.evaluate(() => window.innerHeight),
      ]);
      if (box && box.y < viewportHeight && box.y + box.height > 0) {
        const targetY = Math.min(140, viewportHeight * 0.18);
        await page.mouse.wheel(0, Math.max(0, box.y - targetY));
        await page.evaluate(() => document.fonts.ready);
        await settleCompositor(page, 8);
        await page.waitForTimeout(1000);
        await settleCompositor(page, 4);
        return;
      }
    }
    await page.mouse.wheel(0, 500);
    await settleCompositor(page, 2);
  }
  await expect(heading).toBeVisible();
}

async function scrollToChapterBoundary(page: Page, name: string) {
  const heading = page.getByRole('heading', { name, exact: true });
  for (let attempt = 0; attempt < 180; attempt += 1) {
    if ((await heading.count()) === 0) {
      await page.mouse.wheel(0, 900);
      await settleCompositor(page, 2);
      continue;
    }
    const [box, viewportHeight] = await Promise.all([
      heading.boundingBox(),
      page.evaluate(() => window.innerHeight),
    ]);
    if (box) {
      const targetY = Math.round(viewportHeight * 0.7);
      const delta = box.y - targetY;
      if (Math.abs(delta) <= 1) {
        await page.evaluate(() => document.fonts.ready);
        await settleCompositor(page, 8);
        await page.waitForTimeout(500);
        await settleCompositor(page, 4);
        const settledBox = await heading.boundingBox();
        if (settledBox && Math.abs(settledBox.y - targetY) <= 1) return;
      }
      await page.mouse.wheel(0, Math.max(-640, Math.min(640, delta)));
    } else {
      await page.mouse.wheel(0, 500);
    }
    await settleCompositor(page, 2);
  }
  throw new Error(`Could not position the ${name} chapter boundary.`);
}

async function scrollToText(page: Page, text: string) {
  const target = page.getByText(text).first();
  for (let attempt = 0; attempt < 80; attempt += 1) {
    if ((await target.count()) > 0) {
      const [box, viewportHeight] = await Promise.all([
        target.boundingBox(),
        page.evaluate(() => window.innerHeight),
      ]);
      if (box && box.y < viewportHeight && box.y + box.height > 0) {
        return target;
      }
    }
    await page.mouse.wheel(0, 420);
    await settleCompositor(page, 2);
  }
  await expect(target).toBeVisible();
  return target;
}

test('keeps the first meaningful paint visually aligned with the portfolio', async ({
  page,
}) => {
  await page.emulateMedia({
    colorScheme: 'light',
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
  await expect(
    page.getByRole('button', {
      name: english.home_section.view_work,
      exact: true,
    }),
  ).toBeVisible();
  if ((page.viewportSize()?.width ?? 0) >= 900) {
    await expect(
      page.getByText(`${portfolio.profile.since} →`, { exact: true }).first(),
    ).toBeVisible();
  }
  await expect(page).toHaveScreenshot('hero.png');

  await openChapter(page, 'Go to Open Source', /#\/proof$/, 'Open Source');
  await expect(page).toHaveScreenshot('open-source.png');

  await openChapter(
    page,
    'Go to Work',
    /#\/projects$/,
    'Selected Work',
  );
  await expect(page).toHaveScreenshot('systems.png');

  const firstSupporting = portfolio.systems.find(
    (system) => !system.featured,
  );
  if (!firstSupporting) throw new Error('Expected supporting work.');
  await scrollToHeading(page, firstSupporting.name);
  await expect(page).toHaveScreenshot('archive.png');
});

test('connects chapters during real document scrolling', async ({ page }) => {
  await openStaticPortfolio(page);

  await scrollToChapterBoundary(page, 'Experience');
  await expect(page).toHaveScreenshot('boundary-experience.png');

  await scrollToChapterBoundary(page, 'About');
  await expect(page).toHaveScreenshot('boundary-about.png');
});

test('renders a real supporting-work artifact in the atlas', async (
  { page },
  testInfo,
) => {
  await openStaticPortfolio(page);
  await openChapter(page, 'Go to Work', /#\/projects$/, 'Selected Work');
  const supporting = portfolio.systems.filter((system) => !system.featured);
  const mobile = testInfo.project.name === 'mobile';
  const selected = mobile
    ? supporting[0]
    : supporting.find(
        (system) => system.artifact.width > system.artifact.height,
      );
  if (!selected) throw new Error('Expected a landscape supporting artifact.');
  const selector = await scrollToText(page, selected.name);
  const artifact = page.getByRole('img', { name: selected.artifact.alt });
  await expect(artifact).toBeAttached();
  for (let attempt = 0; attempt < 24; attempt += 1) {
    const box = await selector.boundingBox();
    if (box && Math.abs(box.y - 120) <= 1) break;
    await page.mouse.wheel(0, box ? box.y - 120 : 360);
    await settleCompositor(page, 3);
  }
  await settleCompositor(page, 8);
  await page.waitForTimeout(500);
  await expect(page).toHaveScreenshot('archive-selected.png');
});
