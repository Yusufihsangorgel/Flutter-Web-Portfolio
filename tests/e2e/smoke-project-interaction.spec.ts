import { expect, Locator, Page, test } from "@playwright/test";
import {
  englishInterface,
  openChapterFromPalette,
  openPortfolio,
  portfolio,
  required,
} from "./helpers/portfolio_test_helpers";
import {
  scrollAndSettle,
  scrollToLocator,
  waitForFrames,
} from "./helpers/semantics_scroll";
import type { PortfolioSystem } from "../support/portfolio_test_data";

type RowBounds = NonNullable<Awaited<ReturnType<Locator["boundingBox"]>>>;
type TrackedRow = { id: string; name: string; locator: Locator };

const FORMER_TRANSITION_MS = 320;
const MIN_SAMPLES = 10;
const PREVIEW_FRAME_BUDGET = 10;

function rowFor(page: Page, name: string) {
  return page.getByRole("button", {
    name: `${englishInterface.projects_section.select_evidence}: ${name}`,
    exact: true,
  });
}

function selectTrackedSystems(systems: PortfolioSystem[]) {
  const initial = required(systems[0], "an initial supporting project");
  const preferredIndex = systems.findIndex(
    (system) => system.id === "redis-task-queue",
  );
  const target = required(
    (preferredIndex > 0 && preferredIndex < systems.length - 1
      ? systems[preferredIndex]
      : undefined) ?? systems.at(-2),
    "a later supporting project",
  );
  const targetIndex = systems.indexOf(target);
  return {
    initial,
    target,
    tracked: systems.slice(targetIndex, targetIndex + 3),
  };
}

async function stableBounds(locator: Locator): Promise<RowBounds> {
  return locator.evaluate(async (element) => {
    const read = () => {
      const rect = element.getBoundingClientRect();
      return { x: rect.x, y: rect.y, width: rect.width, height: rect.height };
    };
    let previous = read();
    let stableFrames = 0;
    for (let frame = 0; frame < 120; frame += 1) {
      await new Promise<void>((resolve) => requestAnimationFrame(() => resolve()));
      const current = read();
      const stable =
        Math.abs(current.x - previous.x) < 0.1 &&
        Math.abs(current.y - previous.y) < 0.1 &&
        Math.abs(current.width - previous.width) < 0.1 &&
        Math.abs(current.height - previous.height) < 0.1;
      stableFrames = stable ? stableFrames + 1 : 0;
      previous = current;
      if (stableFrames >= 2) return current;
    }
    throw new Error("Project row geometry did not settle.");
  });
}

async function captureBaseline(rows: TrackedRow[]) {
  const baseline = new Map<string, RowBounds>();
  for (const row of rows) {
    await expect(row.locator).toBeVisible();
    baseline.set(row.id, await stableBounds(row.locator));
  }
  return baseline;
}

async function assertRowsStayInPlace(
  page: Page,
  rows: TrackedRow[],
  baseline: Map<string, RowBounds>,
) {
  const started = await waitForFrames(page);
  let elapsed = 0;
  for (let sample = 0; sample < MIN_SAMPLES || elapsed < FORMER_TRANSITION_MS; sample += 1) {
    elapsed = (await waitForFrames(page)) - started;
    for (const row of rows) {
      const before = required(baseline.get(row.id), `${row.name} baseline bounds`);
      const after = await row.locator.boundingBox();
      expect(after).not.toBeNull();
      expect(after!.x).toBeCloseTo(before.x, 1);
      expect(after!.y).toBeCloseTo(before.y, 1);
      expect(after!.width).toBeCloseTo(before.width, 1);
      expect(after!.height).toBeCloseTo(before.height, 1);
    }
  }
}

test("keeps desktop project rows stable during pointer-driven evidence changes", async ({
  page,
}, testInfo) => {
  test.skip(testInfo.project.name !== "desktop");
  const supporting = portfolio.systems.filter((system) => !system.featured);
  test.skip(
    supporting.length < 3,
    "hover stability needs three supporting projects",
  );
  const { initial, target, tracked } = selectTrackedSystems(supporting);
  test.skip(tracked.length < 2, "hover stability needs adjacent project rows");

  await openPortfolio(page);
  await openChapterFromPalette(
    page,
    "Go to Work",
    /#\/projects$/,
    "Selected Work",
  );
  const targetRow = rowFor(page, target.name);
  await scrollToLocator(page, targetRow, 500);
  await expect(targetRow).toBeVisible();
  const visibleBounds = await stableBounds(targetRow);
  await scrollAndSettle(page, visibleBounds.y - 420);

  const rows = tracked.map((system) => ({
    id: system.id,
    name: system.name,
    locator: rowFor(page, system.name),
  }));
  const baseline = await captureBaseline(rows);
  const targetBounds = required(baseline.get(target.id), "target baseline bounds");
  await page.mouse.move(
    targetBounds.x + targetBounds.width / 2,
    targetBounds.y + targetBounds.height / 2,
  );
  const preview = (name: string) =>
    page.getByRole("heading", { name, exact: true, level: 4 });
  for (let frame = 0; frame < PREVIEW_FRAME_BUDGET; frame += 1) {
    if ((await preview(target.name).count()) === 1) break;
    await waitForFrames(page);
  }
  expect(await preview(target.name).count()).toBe(1);
  expect(await preview(initial.name).count()).toBe(0);
  await assertRowsStayInPlace(page, rows, baseline);
});
