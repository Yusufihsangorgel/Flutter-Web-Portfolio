import type { Locator, Page } from "@playwright/test";
import { waitForSemanticsSettled } from "./frame_waits";

export { waitForFrames, waitForSemanticsSettled } from "./frame_waits";

const MAX_SCROLL_ATTEMPTS = 48;
const MAX_POSITION_ATTEMPTS = 8;

export async function scrollAndSettle(page: Page, distance: number) {
  const before = await waitForSemanticsSettled(page);
  const pixelRatio = await page.evaluate(() => window.devicePixelRatio);
  // Keep the existing DPR² conversion for known-box corrections.
  await page.mouse.wheel(0, distance * pixelRatio * pixelRatio);
  // No public Flutter wheel-completion or scroll-boundary signal is available here.
  // An unchanged tree must reach the bounded change deadline, not be treated as a no-op.
  await waitForSemanticsSettled(page, before);
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

type ScrollAnchor = {
  id: string;
  name: string;
  top: number;
  width: number;
  height: number;
};

async function readScrollAnchors(page: Page): Promise<ScrollAnchor[]> {
  return page.evaluate(() => Array.from(
    document.querySelectorAll("flt-semantics-host [id]"),
    (node) => {
      const { top, width, height } = node.getBoundingClientRect();
      return { id: node.id, name: node.getAttribute("aria-label") ?? node.textContent ?? "",
        top, width, height };
    },
  ));
}

function observedMovement(before: ScrollAnchor[], after: ScrollAnchor[]) {
  const current = new Map(after.map((anchor) => [anchor.id, anchor]));
  return before.reduce((movement, anchor) => {
    const next = current.get(anchor.id);
    if (!next || !anchor.name || anchor.name !== next.name ||
      anchor.width !== next.width || anchor.height !== next.height) return movement;
    // Fixed controls contribute zero; clipping or recycled content cannot calibrate a wheel.
    return Math.max(movement, Math.abs(anchor.top - next.top));
  }, 0);
}

async function discoverAndSettle(
  page: Page, distance: number, viewportHeight: number,
) {
  const token = await waitForSemanticsSettled(page);
  const pixelRatio = await page.evaluate(() => window.devicePixelRatio);
  const before = await readScrollAnchors(page);
  // The selected-card path never amplifies an input using a previous wheel's gain:
  // traces show both delta/DPR and delta/DPR², and virtualization can remove feedback.
  const delta = distance * Math.min(1, pixelRatio * pixelRatio);
  await page.mouse.wheel(0, delta);
  await waitForSemanticsSettled(page, token);
  const movement = observedMovement(before, await readScrollAnchors(page));
  if (movement > viewportHeight) {
    throw new Error(`Discovery moved ${movement}px, beyond the ${viewportHeight}px viewport.`);
  }
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
        `last geometry: ${JSON.stringify(geometry)}; ` +
        `${cause instanceof Error ? cause.message : String(cause)}`, { cause });
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

export async function scrollToSemanticGroup(page: Page, name: string) {
  // Flutter may merge narrative Text widgets into an aria-label-only group.
  return scrollToLocator(page, semanticsTree(page).getByRole("group", { name, exact: true }));
}

async function scrollToNearbyLocator(page: Page, locator: Locator, from: Locator) {
  await waitForSemanticsSettled(page);
  const start = await readGeometry(page, from);
  if (!start.box || start.box.width <= 0 || start.box.height <= 0 ||
    start.box.y >= start.viewportHeight || start.box.y + start.box.height <= 0) {
    throw new Error(`Starting artifact must be in the viewport: ${from}; ${JSON.stringify(start)}.`);
  }
  let geometry: Awaited<ReturnType<typeof readGeometry>> | undefined;
  for (let attempt = 0; attempt <= MAX_SCROLL_ATTEMPTS; attempt += 1) {
    geometry = await readGeometry(page, locator);
    const { box, viewportHeight } = geometry;
    if (box && box.height > 0 && box.y < viewportHeight && box.y + box.height > 0) {
      return locator.first();
    }
    if (attempt === MAX_SCROLL_ATTEMPTS) break;
    const limit = viewportHeight * 0.8;
    const distance = box && box.height > 0
      ? Math.max(-limit, Math.min(limit, box.y - viewportHeight / 2)) : limit;
    await discoverAndSettle(page, distance, viewportHeight).catch((cause: unknown) => {
      throw new Error(`Nearby wheel ${attempt + 1} failed for ${locator}; ` +
        `last geometry: ${JSON.stringify(geometry)}; ` +
        `${cause instanceof Error ? cause.message : String(cause)}`, { cause });
    });
  }
  throw new Error(`Nearby target did not enter the viewport after ${MAX_SCROLL_ATTEMPTS} wheels: ` +
    `${locator}; last geometry: ${JSON.stringify(geometry)}.`);
}

export async function scrollToSemanticLink(
  page: Page, title: string, options: { from?: Locator } = {},
) {
  const link = page.locator("flt-semantics-host a[flt-tappable]").filter({ hasText: title });
  await link.first().waitFor({ state: "attached", timeout: 1200 }).catch(() => undefined);
  // Only use the bounded path after the caller has selected the card and exposed its artifact.
  return options.from ? scrollToNearbyLocator(page, link, options.from) : scrollToLocator(page, link);
}
