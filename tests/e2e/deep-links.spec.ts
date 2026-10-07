import { expect, test } from "@playwright/test";
import { readFileSync } from "node:fs";
import { resolve } from "node:path";

const assets = resolve(__dirname, "../../assets");
const readJson = <T>(path: string) =>
  JSON.parse(readFileSync(resolve(assets, path), "utf8")) as T;

const chapters = readJson<{ chapters: Array<{ id: string }> }>(
  "presentation/narrative.json",
).chapters;
const interfaceCopy = readJson<Record<string, { title?: string }>>(
  "i18n/en.json",
);
const portfolio = readJson<{
  profile: { display_name: { accessible: string }; role: string };
  experience: unknown[];
  contributions: unknown[];
  systems: unknown[];
  packages?: unknown[];
  writing?: unknown[];
}>("content/portfolio.json");

const landingBudgetMs = 1000;
const observationMs = 3000;
const driftBudgetPx = 24;
const revealMark = "flutter-bootstrap-surface-removed";

// Mirrors PortfolioDocument.activeSections: empty chapters are not rendered.
const authoredItems: Record<string, number> = {
  experience: portfolio.experience.length,
  proof: portfolio.contributions.length,
  projects: portfolio.systems.length,
  packages: portfolio.packages?.length ?? 0,
  writing: portfolio.writing?.length ?? 0,
};

// One entry per animation frame on the page's own clock: milliseconds since
// the reveal mark and the heading's top edge, or null while it is not exposed.
type HeadingFrame = [elapsedMs: number, top: number | null];

declare global {
  interface Window {
    headingFrames: HeadingFrame[];
  }
}

// Runs inside the page from its first script, so the measurement does not
// depend on how quickly the test process can query the browser.
function recordHeadingFrames(args: { name: string; mark: string }) {
  const frames: HeadingFrame[] = [];
  window.headingFrames = frames;
  const nameOf = (element: Element) =>
    (element.getAttribute("aria-label") ?? element.textContent ?? "")
      .replace(/\s+/g, " ")
      .trim();
  const headingSelector = [
    '[role="heading"]',
    ...[1, 2, 3, 4, 5, 6].map((level) => `h${level}`),
  ]
    .map((selector) => `flt-semantics-host ${selector}`)
    .join(", ");
  const sample = () => {
    const [reveal] = performance.getEntriesByName(args.mark, "mark");
    if (reveal) {
      const heading = [...document.querySelectorAll(headingSelector)].find(
        (element) => nameOf(element) === args.name,
      );
      frames.push([
        performance.now() - reveal.startTime,
        heading?.getBoundingClientRect().top ?? null,
      ]);
    }
    requestAnimationFrame(sample);
  };
  requestAnimationFrame(sample);
}

function headingNameFor(chapterId: string) {
  const name =
    chapterId === "home"
      ? `${portfolio.profile.display_name.accessible}, ${portfolio.profile.role}`
      : interfaceCopy[`${chapterId}_section`]?.title;
  if (!name) throw new Error(`Missing heading for ${chapterId}`);
  return name;
}

function measureLanding(frames: HeadingFrame[], viewportHeight: number) {
  const landing = frames.find(
    ([, top]) =>
      top !== null && top >= -driftBudgetPx && top < viewportHeight / 2,
  );
  const landedTop = landing?.[1];
  if (!landing || landedTop == null) return null;
  const landedAtMs = landing[0];
  const drifts = frames
    .filter(([at]) => at >= landedAtMs && at <= landedAtMs + observationMs)
    .map(([, top]) =>
      top === null ? Number.POSITIVE_INFINITY : Math.abs(top - landedTop),
    );
  return { landedAtMs, driftPx: Math.max(...drifts) };
}

for (const chapter of chapters) {
  test(`cold deep link stays at ${chapter.id}`, async ({ page }) => {
    test.skip(
      authoredItems[chapter.id] === 0,
      `the ${chapter.id} chapter is not authored`,
    );
    const headingName = headingNameFor(chapter.id);
    await page.addInitScript(recordHeadingFrames, {
      name: headingName,
      mark: revealMark,
    });

    await page.goto(`/#/${chapter.id}`, { waitUntil: "domcontentloaded" });
    // Sampling runs on the page's frame clock until the observation window
    // after the latest permitted landing has been recorded.
    await page.waitForFunction(
      (horizonMs) => (window.headingFrames.at(-1)?.[0] ?? 0) >= horizonMs,
      landingBudgetMs + observationMs,
      { timeout: 30000 },
    );
    const { frames, viewportHeight } = await page.evaluate(() => ({
      frames: window.headingFrames,
      viewportHeight: innerHeight,
    }));

    expect(
      frames.some(([, top]) => top !== null),
      `"${headingName}" was never exposed in the semantics tree`,
    ).toBe(true);
    const landing = measureLanding(frames, viewportHeight);
    expect(
      landing,
      `"${headingName}" never reached the upper half of the viewport`,
    ).not.toBeNull();
    expect(landing?.landedAtMs, "ms after reveal").toBeLessThanOrEqual(
      landingBudgetMs,
    );
    expect(landing?.driftPx, "px moved after landing").toBeLessThanOrEqual(
      driftBudgetPx,
    );
  });
}
