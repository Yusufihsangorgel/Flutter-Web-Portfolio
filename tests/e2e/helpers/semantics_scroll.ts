import { expect, Locator, Page } from "@playwright/test";

const SETTLED_FRAMES = 6;
const MAX_FRAMES_FOR_CHANGE = 60;
const SETTLE_TIMEOUT_MS = 15000;
const MAX_SCROLL_ATTEMPTS = 80;

export async function waitForFrames(page: Page, count = 1) {
  return page.evaluate(
    (frames) =>
      new Promise<number>((resolve) => {
        let remaining = frames;
        const next = (timestamp: number) => {
          remaining -= 1;
          if (remaining <= 0) resolve(timestamp);
          else requestAnimationFrame(next);
        };
        requestAnimationFrame(next);
      }),
    count,
  );
}

// Wait for stable semantics geometry after a possible scroll change.
export async function waitForSemanticsSettled(page: Page, changedFrom = "") {
  return page.evaluate(
    ({ changedFrom, stableFrames, maxFramesForChange, timeoutMs }) =>
      new Promise<string>((resolve, reject) => {
        const geometry = () => {
          const nodes = document.querySelectorAll("flt-semantics-host *");
          if (nodes.length === 0) return "";
          let hash = nodes.length;
          for (const node of nodes) {
            hash =
              (hash * 31 + Math.round(node.getBoundingClientRect().top)) | 0;
          }
          return String(hash);
        };
        const started = performance.now();
        let frames = 0;
        let previous = "";
        let stable = 0;
        const tick = () => {
          frames += 1;
          const current = geometry();
          const waitingForChange =
            current === changedFrom && frames < maxFramesForChange;
          stable =
            current !== "" && current === previous && !waitingForChange
              ? stable + 1
              : 0;
          previous = current;
          if (stable >= stableFrames) return resolve(current);
          if (performance.now() - started > timeoutMs) {
            return reject(new Error("The semantics tree did not settle."));
          }
          requestAnimationFrame(tick);
        };
        requestAnimationFrame(tick);
      }),
    {
      changedFrom,
      stableFrames: SETTLED_FRAMES,
      maxFramesForChange: MAX_FRAMES_FOR_CHANGE,
      timeoutMs: SETTLE_TIMEOUT_MS,
    },
  );
}

export async function scrollAndSettle(page: Page, distance: number) {
  const before = await waitForSemanticsSettled(page);
  await page.mouse.wheel(0, distance);
  const after = await waitForSemanticsSettled(page, before);
  return after !== before;
}

async function isInViewport(page: Page, locator: Locator) {
  if ((await locator.count()) === 0) return false;
  const [box, viewportHeight] = await Promise.all([
    locator.first().boundingBox(),
    page.evaluate(() => window.innerHeight),
  ]);
  return Boolean(box && box.y < viewportHeight && box.y + box.height > 0);
}

export async function scrollToLocator(
  page: Page,
  locator: Locator,
  step = 420,
) {
  await waitForSemanticsSettled(page);
  for (let attempt = 0; attempt < MAX_SCROLL_ATTEMPTS; attempt += 1) {
    if (await isInViewport(page, locator)) return locator.first();
    await scrollAndSettle(page, step);
  }
  await expect(locator.first()).toBeVisible();
  return locator.first();
}

export async function scrollToHeading(page: Page, name: string) {
  const heading = page.getByRole("heading", { name, exact: true });
  return scrollToLocator(page, heading, 500);
}

export async function scrollToText(page: Page, text: string) {
  return scrollToLocator(page, page.getByText(text).first());
}

export async function scrollToSemanticLink(page: Page, title: string) {
  // Flutter's semantic <a> has no href, so getByRole("link") cannot match it.
  const link = page.locator("flt-semantics-host a").filter({ hasText: title });
  await link.first().waitFor({ state: "attached", timeout: 1200 }).catch(() => undefined);
  return scrollToLocator(page, link);
}
