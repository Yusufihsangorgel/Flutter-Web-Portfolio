import { expect, Page, test } from './helpers/test_setup';
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
import {
  scrollToLocator,
  scrollToPosition,
  semanticsTree,
} from './helpers/semantics_scroll';

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
  await scrollToLocator(page, heading);
  const box = await heading.boundingBox();
  const height = await page.evaluate(() => window.innerHeight);
  const targetY = Math.min(140, height * 0.18);
  if (box && box.y > targetY) {
    await scrollToPosition(page, heading, { targetY });
  }
  await page.evaluate(() => document.fonts.ready);
  await settleCompositor(page, 8);
  await waitForStableCanvas(page);
}

async function scrollToChapterBoundary(page: Page, name: string) {
  const heading = page.getByRole('heading', { name, exact: true });
  const targetY = Math.round(
    await page.evaluate(() => window.innerHeight) * 0.7,
  );
  await page.evaluate(() => document.fonts.ready);
  await scrollToPosition(page, heading, { targetY });
  await settleCompositor(page, 8);
  await waitForStableCanvas(page);
  const box = await heading.boundingBox();
  expect(box, `Missing settled geometry for ${name}.`).not.toBeNull();
  expect(
    Math.abs(box!.y - targetY),
    `${name}: last geometry ${JSON.stringify(box)}`,
  ).toBeLessThanOrEqual(1);
}

async function scrollToVisualText(page: Page, text: string) {
  return scrollToLocator(page, semanticsTree(page).getByText(text).first());
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
  await scrollToLocator(page, heading);
  await expect(heading).toBeVisible();
  const viewportHeight = await page.evaluate(() => window.innerHeight);
  await scrollToPosition(page, heading, {
    targetY: viewportHeight * 0.2,
    tolerance: 2,
  });
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
  await scrollToPosition(page, selector, { targetY: 120 });
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
