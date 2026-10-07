import type { Locator, Page } from "@playwright/test";
import { waitForSemanticsSettled } from "./frame_waits";

export { waitForFrames, waitForSemanticsSettled } from "./frame_waits";

const MAX_SCROLL_ATTEMPTS = 48;
const MAX_POSITION_ATTEMPTS = 8;

export async function scrollAndSettle(page: Page, distance: number) {
  const before = await waitForSemanticsSettled(page);
  const pixelRatio = await page.evaluate(() => window.devicePixelRatio);
  // Emulated Chromium divides wheel deltas by the pixel ratio and Flutter divides them again.
  await page.mouse.wheel(0, distance * pixelRatio * pixelRatio);
  const after = await waitForSemanticsSettled(page, before);
  return after !== before;
}

async function readGeometry(page: Page, locator: Locator) {
  const [box, viewportHeight] = await Promise.all([
    (await locator.count()) > 0
      ? locator.first().boundingBox({ timeout: 1000 })
      : null,
    page.evaluate(() => window.innerHeight),
  ]);
  return { box, viewportHeight };
}

export async function scrollToLocator(
  page: Page,
  locator: Locator,
  step = 420,
) {
  await waitForSemanticsSettled(page);
  let geometry: Awaited<ReturnType<typeof readGeometry>> | undefined;
  for (let attempt = 0; attempt <= MAX_SCROLL_ATTEMPTS; attempt += 1) {
    geometry = await readGeometry(page, locator);
    const { box, viewportHeight } = geometry;
    if (box && box.height > 0 && box.y < viewportHeight && box.y + box.height > 0) {
      return locator.first();
    }
    if (attempt === MAX_SCROLL_ATTEMPTS) break;
    const discovery = Math.min(
      Math.max(step, viewportHeight * 0.8), viewportHeight * 0.9,
    );
    const distance = box && box.height > 0 ? box.y - viewportHeight / 2 : discovery;
    await scrollAndSettle(page, distance).catch((cause: unknown) => {
      throw new Error(`Wheel ${attempt + 1} failed for ${locator}; ` +
        `last geometry: ${JSON.stringify(geometry)}.`, { cause });
    });
  }
  throw new Error(`Target did not enter the viewport after ${MAX_SCROLL_ATTEMPTS} wheels: ` +
    `${locator}; last geometry: ${JSON.stringify(geometry)}.`);
}

export async function scrollToPosition(
  page: Page,
  locator: Locator,
  options: { targetY: number; tolerance?: number },
) {
  await scrollToLocator(page, locator);
  let geometry: Awaited<ReturnType<typeof readGeometry>> | undefined;
  for (let attempt = 0; attempt <= MAX_POSITION_ATTEMPTS; attempt += 1) {
    geometry = await readGeometry(page, locator);
    const delta = geometry.box ? geometry.box.y - options.targetY : null;
    if (delta !== null && Math.abs(delta) <= (options.tolerance ?? 1)) return;
    if (attempt === MAX_POSITION_ATTEMPTS || delta === null) break;
    await scrollAndSettle(page, delta).catch((cause: unknown) => {
      throw new Error(`Correction ${attempt + 1} failed for ${locator} at y=${options.targetY}; ` +
        `remaining=${delta}; last geometry: ${JSON.stringify(geometry)}.`, { cause });
    });
  }
  throw new Error(`Target did not reach y=${options.targetY} after ${MAX_POSITION_ATTEMPTS} corrections: ` +
    `${locator}; last geometry: ${JSON.stringify(geometry)}.`);
}

export async function scrollToHeading(page: Page, name: string) {
  const heading = page.getByRole("heading", { name, exact: true });
  return scrollToLocator(page, heading, 500);
}

// The hidden static document repeats the record, so text queries stay in Flutter's tree.
export function semanticsTree(page: Page): Locator {
  return page.locator("flt-semantics-host");
}

export async function scrollToText(page: Page, text: string) {
  return scrollToLocator(page, semanticsTree(page).getByText(text).first());
}

export async function scrollToSemanticLink(page: Page, title: string) {
  // Flutter's semantic <a> has no href, so getByRole("link") cannot match it.
  const link = page.locator("flt-semantics-host a").filter({ hasText: title });
  await link.first().waitFor({ state: "attached", timeout: 1200 }).catch(() => undefined);
  return scrollToLocator(page, link);
}
