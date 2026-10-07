import { expect, Locator, Page, test } from '@playwright/test';
import { readFileSync } from 'node:fs';
import type {
  InterfaceTestData,
  PortfolioTestData,
} from '../support/portfolio_test_data';
import {
  installVisualMasks,
  settleCompositor,
  waitForStableCanvas,
  waitForWorkImagesPainted,
} from './helpers/visual_capture';

const portfolio = JSON.parse(
  readFileSync('assets/content/portfolio.json', 'utf8'),
) as PortfolioTestData;
const english = JSON.parse(
  readFileSync('assets/i18n/en.json', 'utf8'),
) as InterfaceTestData;

test.skip(
  portfolio.experience.length === 0 &&
    portfolio.contributions.length === 0 &&
    portfolio.systems.length === 0,
  'demo visual baselines do not apply to an initialized empty portfolio',
);

test.skip(
  process.platform !== 'linux',
  'baselines are Linux-only; run `npm run test:visual:docker` on other hosts',
);

// Pin article titles so feed refreshes do not alter snapshots.
const sampleTitles = [
  'A short sample title',
  'A sample title long enough to wrap onto a second line at tablet width',
  'A sample title of middling length for the list',
  'A sample title that runs long enough to wrap onto a third line on the narrowest phone layout',
];
const writingSources = portfolio.writing_sources ?? [];
const frozenWriting = Array.from({ length: 12 }, (_, index) => ({
  title: `${sampleTitles[index % sampleTitles.length]} ${index + 1}`,
  url: `https://example.invalid/writing/${index + 1}`,
  source: writingSources[index % Math.max(writingSources.length, 1)]?.id ?? 'blog',
  date: `2026-01-${String(28 - index).padStart(2, '0')}`,
}));

test.beforeEach(async ({ page }) => {
  await page.emulateMedia({ reducedMotion: 'reduce' });
  await page.route('**/content/portfolio.json*', async (route) => {
    const response = await route.fetch();
    const document = await response.json();
    await route.fulfill({ response, json: { ...document, writing: frozenWriting } });
  });
});

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
  await waitForStableCanvas(page);
}

async function openStaticPortfolio(page: Page) {
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

async function scrollToVisualHeading(page: Page, name: string) {
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
        await waitForStableCanvas(page);
        return;
      }
    }
    await page.mouse.wheel(0, 500);
    await settleCompositor(page, 2);
  }
  await expect(heading).toBeVisible();
}

// Track the semantics scroll offset and heading positions inside Flutter's canvas.
async function readScrollProgress(page: Page) {
  return page.evaluate(() => {
    let scroller: Element | null = null;
    for (const overflow of document.querySelectorAll(
      'flt-semantics-scroll-overflow',
    )) {
      const parent = overflow.parentElement;
      if (!parent) continue;
      if (!scroller || parent.scrollHeight > scroller.scrollHeight) {
        scroller = parent;
      }
    }
    const headings = Array.from(
      document.querySelectorAll('h1,h2,h3,h4,h5,h6'),
    )
      .map(
        (heading) =>
          `${heading.tagName}|${heading.textContent}|${Math.round(
            heading.getBoundingClientRect().y,
          )}`,
      )
      .join('~');
    return {
      offset: scroller ? scroller.scrollTop : null,
      token: `${scroller ? scroller.scrollTop : 'detached'}#${headings}`,
    };
  });
}

const SCROLL_STALL_LIMIT = 6;
const CONVERGENCE_STALL_LIMIT = 24;
const SCROLL_ATTEMPT_CEILING = 1000;

function createScrollProgressGuard(page: Page) {
  let previousToken: string | null = null;
  let stalledAttempts = 0;
  return async function recordScrollAttempt() {
    const { offset, token } = await readScrollProgress(page);
    if (previousToken !== null && token === previousToken) {
      stalledAttempts += 1;
    } else {
      stalledAttempts = 0;
    }
    previousToken = token;
    return { offset, stalled: stalledAttempts >= SCROLL_STALL_LIMIT };
  };
}

async function scrollToChapterBoundary(page: Page, name: string) {
  const heading = page.getByRole('heading', { name, exact: true });
  const recordScrollAttempt = createScrollProgressGuard(page);
  let bestDistance = Number.POSITIVE_INFINITY;
  let attemptsSinceConvergence = 0;
  for (let attempt = 0; attempt < SCROLL_ATTEMPT_CEILING; attempt += 1) {
    if ((await heading.count()) === 0) {
      await page.mouse.wheel(0, 900);
      await settleCompositor(page, 2);
      const { offset, stalled } = await recordScrollAttempt();
      if (stalled) {
        throw new Error(
          `The ${name} chapter boundary never came into view: the document ` +
            `stopped scrolling at offset ${offset} after ${attempt + 1} ` +
            'attempts.',
        );
      }
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
        await waitForStableCanvas(page);
        const settledBox = await heading.boundingBox();
        if (settledBox && Math.abs(settledBox.y - targetY) <= 1) return;
      }
      if (Math.abs(delta) < bestDistance - 0.05) {
        bestDistance = Math.abs(delta);
        attemptsSinceConvergence = 0;
      } else {
        attemptsSinceConvergence += 1;
        if (attemptsSinceConvergence >= CONVERGENCE_STALL_LIMIT) {
          throw new Error(
            `Could not position the ${name} chapter boundary: the heading ` +
              `stopped converging ${bestDistance.toFixed(1)}px from the 70% ` +
              `mark after ${attempt + 1} attempts.`,
          );
        }
      }
      await page.mouse.wheel(0, Math.max(-640, Math.min(640, delta)));
    } else {
      await page.mouse.wheel(0, 500);
    }
    await settleCompositor(page, 2);
  }
  throw new Error(
    `Could not position the ${name} chapter boundary within ` +
      `${SCROLL_ATTEMPT_CEILING} attempts.`,
  );
}

async function scrollUntilHeadingRenders(
  page: Page,
  heading: Locator,
  name: string,
  step: number,
) {
  const recordScrollAttempt = createScrollProgressGuard(page);
  for (let attempt = 0; attempt < SCROLL_ATTEMPT_CEILING; attempt += 1) {
    if ((await heading.count()) > 0) {
      const box = await heading.boundingBox();
      if (box) return;
    }
    await page.mouse.wheel(0, step);
    await settleCompositor(page, 2);
    const { offset, stalled } = await recordScrollAttempt();
    if (stalled) {
      throw new Error(
        `The ${name} heading never rendered: the document stopped scrolling ` +
          `at offset ${offset} after ${attempt + 1} attempts.`,
      );
    }
  }
  throw new Error(
    `The ${name} heading never rendered within ` +
      `${SCROLL_ATTEMPT_CEILING} attempts.`,
  );
}

async function scrollToVisualText(page: Page, text: string) {
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

async function expectVisualSnapshot(page: Page, name: string) {
  await expect
    .poll(() =>
      page.evaluate(
        () => window.matchMedia('(prefers-reduced-motion: reduce)').matches,
      ),
    )
    .toBe(true);
  await waitForWorkImagesPainted(page);
  await settleCompositor(page, 2);
  await expect(page).toHaveScreenshot(name, {
    mask: await installVisualMasks(page),
  });
}

test('keeps the first meaningful paint visually aligned with the portfolio', async ({
  page,
}) => {
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
  await expectVisualSnapshot(page, 'critical-shell.png');
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
  await expectVisualSnapshot(page, 'hero.png');

  await openChapter(page, 'Go to Open Source', /#\/proof$/, 'Open Source');
  await expectVisualSnapshot(page, 'open-source.png');
  await scrollToVisualHeading(page, 'First Frame Lab');
  await expectVisualSnapshot(page, 'first-frame-lab.png');

  await openChapter(
    page,
    'Go to Work',
    /#\/projects$/,
    'Selected Work',
  );
  await expectVisualSnapshot(page, 'systems.png');

  const firstSupporting = portfolio.systems.find(
    (system) => !system.featured,
  );
  if (!firstSupporting) throw new Error('Expected supporting work.');
  await scrollToVisualHeading(page, firstSupporting.name);
  await expectVisualSnapshot(page, 'archive.png');
});

test('connects chapters during real document scrolling', async ({ page }) => {
  await openStaticPortfolio(page);

  await scrollToChapterBoundary(page, 'Experience');
  await expectVisualSnapshot(page, 'boundary-experience.png');

  await scrollToChapterBoundary(page, 'About');
  await expectVisualSnapshot(page, 'boundary-about.png');
});

test('keeps one content-anchored signal with reduced motion', async ({
  page,
}) => {
  await openStaticPortfolio(page);

  await scrollToChapterBoundary(page, 'Experience');
  await expectVisualSnapshot(page, 'narrative-stage-experience.png');

  const primaryCase = portfolio.systems.find((system) => system.featured);
  if (!primaryCase) throw new Error('Expected a primary professional case.');
  const heading = page.getByRole('heading', {
    name: primaryCase.name,
    exact: true,
  });
  await scrollUntilHeadingRenders(page, heading, primaryCase.name, 600);
  await expect(heading).toBeVisible();
  for (let attempt = 0; attempt < 24; attempt += 1) {
    const [box, viewportHeight] = await Promise.all([
      heading.boundingBox(),
      page.evaluate(() => window.innerHeight),
    ]);
    if (box && Math.abs(box.y - viewportHeight * 0.2) <= 2) break;
    await page.mouse.wheel(
      0,
      box ? box.y - viewportHeight * 0.2 : viewportHeight * 0.5,
    );
    await settleCompositor(page, 3);
  }
  await settleCompositor(page, 8);
  await expectVisualSnapshot(page, 'narrative-stage-work.png');
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
  let selector = await scrollToVisualText(page, selected.name);
  if (mobile) {
    await page
      .getByRole('button', {
        name: `${english.projects_section.select_evidence}: ${selected.name}`,
        exact: true,
      })
      .click();
    const selectedHeading = page.getByRole('heading', {
      name: selected.name,
      exact: true,
      level: 4,
    });
    selector = selectedHeading;
  }
  for (let attempt = 0; attempt < 24; attempt += 1) {
    const box = await selector.boundingBox();
    if (box && Math.abs(box.y - 120) <= 1) break;
    await page.mouse.wheel(0, box ? box.y - 120 : 360);
    await settleCompositor(page, 3);
  }
  const compactViewport = (page.viewportSize()?.width ?? 0) < 900;
  const expectedArtifact =
    compactViewport && selected.artifact.compact
      ? selected.artifact.compact
      : selected.artifact;
  const artifact = page.getByRole('img', { name: expectedArtifact.alt });
  await expect(artifact).toBeAttached();
  await settleCompositor(page, 8);
  await waitForStableCanvas(page);
  await expectVisualSnapshot(page, 'archive-selected.png');
});
