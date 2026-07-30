import { expect, Locator, Page, test } from '@playwright/test';
import { readFileSync } from 'node:fs';
import type {
  InterfaceTestData,
  PortfolioTestData,
} from '../support/portfolio_test_data';

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

async function openMotionPortfolio(page: Page) {
  await page.emulateMedia({
    colorScheme: 'light',
    reducedMotion: 'no-preference',
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
  await expect
    .poll(() =>
      page.evaluate(
        () => window.matchMedia('(prefers-reduced-motion: reduce)').matches,
      ),
    )
    .toBe(false);
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

// The portfolio is a single sliver inside the Wasm canvas, so `document` never
// scrolls and `scrollHeight` only ever reports the viewport height. The engine
// does publish the real offset on the semantics scroll container it maintains
// for assistive technology, and that is the one document-level scroll position
// an outside observer can read. Pair it with the geometry of every heading in
// the semantics tree: measured on the mobile profile, the offset alone never
// repeated across a 145-event traversal, while the heading fingerprint alone
// repeated for up to 11 consecutive events and was empty for 18 of them. So
// the offset carries the signal, and the headings keep the signal meaningful
// if a future engine release renames the container.
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

// A wheel event with document left to travel always moves the progress token.
// On the tallest profile (Pixel 7, 412x839) the longest run of unchanged token
// during a legitimate 145-event traversal was zero, so six consecutive
// motionless events mean the document has stopped scrolling, not that the page
// is long.
const SCROLL_STALL_LIMIT = 6;
// The convergence phase closes about 14.5% of the remaining distance per wheel
// event on a high-density profile, so progress there is slow but never absent:
// over the same traversal, the longest run of attempts that failed to improve
// the best distance by 0.05px was also zero. 24 leaves a wide margin.
const CONVERGENCE_STALL_LIMIT = 24;
// A runaway stop so a broken build cannot spin forever, not a travel budget:
// the stall guards above are what end a search. This sits five times above the
// deepest traversal measured here, the 185 attempts mobile needs to reach the
// About boundary and settle on it.
const SCROLL_ATTEMPT_CEILING = 1000;

// Bounds the scroll searches below by whether the document is still responding
// to wheel input, rather than by a fixed attempt count. A count is a hidden
// assertion about how long the page is: it starts failing as soon as the
// portfolio grows, and it silently tolerates the failure actually worth
// catching, a document that stops scrolling before the target is reached.
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
        await page.waitForTimeout(500);
        await settleCompositor(page, 4);
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

// Wheels a heading into the render tree, bounded by whether the document is
// still scrolling rather than by a fixed number of attempts.
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
  await scrollToHeading(page, 'First Frame Lab');
  await expect(page).toHaveScreenshot('first-frame-lab.png');

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

test('keeps one content-anchored signal in the default motion experience', async ({
  page,
}) => {
  await openMotionPortfolio(page);

  await scrollToChapterBoundary(page, 'Experience');
  await expect(page).toHaveScreenshot('narrative-stage-experience.png');

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
  // The narrative cursor is a pure function of scroll offset. On the mobile
  // profile, whose device pixel ratio damps wheel input the hardest, the
  // convergence attempts run out around 20px short of the 20% target, but they
  // do so deterministically, so the frame is stable from run to run. The cursor sits over the high-contrast
  // featured-work board, so scroll drift moves more antialiased edges than the
  // calmer Experience anchor above; the frame is held to the project-wide
  // screenshot tolerance, which already accounts for the live canvas.
  await expect(page).toHaveScreenshot('narrative-stage-work.png');
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
  let selector = await scrollToText(page, selected.name);
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
  // The renderer swaps in the portrait compact variant whenever the viewport
  // is narrower than the Flutter tablet breakpoint (900 logical pixels), so
  // the expected media must be chosen from the actual viewport width.
  const compactViewport = (page.viewportSize()?.width ?? 0) < 900;
  const expectedArtifact =
    compactViewport && selected.artifact.compact
      ? selected.artifact.compact
      : selected.artifact;
  const artifact = page.getByRole('img', { name: expectedArtifact.alt });
  await expect(artifact).toBeAttached();
  await settleCompositor(page, 8);
  await page.waitForTimeout(500);
  await expect(page).toHaveScreenshot('archive-selected.png');
});
