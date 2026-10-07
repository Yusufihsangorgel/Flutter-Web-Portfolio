import type { Locator, Page } from "@playwright/test";

const SETTLED_FRAMES = 2;
const SETTLE_TIMEOUT_MS = 15000;

export async function waitForFrames(page: Page, count = 1) {
  return page.evaluate(
    ({ frames, timeoutMs }) =>
      new Promise<number>((resolve, reject) => {
        let frame = 0;
        let remaining = frames;
        const deadline = setTimeout(() => {
          cancelAnimationFrame(frame);
          reject(new Error(
            `No ${frames} animation frames within ${timeoutMs}ms.`,
          ));
        }, timeoutMs);
        const next = (timestamp: number) => {
          remaining -= 1;
          if (remaining <= 0) {
            clearTimeout(deadline);
            resolve(timestamp);
          } else frame = requestAnimationFrame(next);
        };
        frame = requestAnimationFrame(next);
      }),
    { frames: count, timeoutMs: SETTLE_TIMEOUT_MS },
  );
}

// Wait for stable semantics geometry after a possible scroll change.
export async function waitForSemanticsSettled(page: Page, changedFrom = "") {
  return page.evaluate(
    ({ changedFrom, stableFrames, timeoutMs }) =>
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
        let frame = 0;
        let previous = "";
        let stable = 0;
        let changed = changedFrom === "";
        const deadline = setTimeout(() => {
          cancelAnimationFrame(frame);
          reject(new Error(
            `The semantics tree did not ${changed ? "settle" : "change"} ` +
              `within ${timeoutMs}ms; last geometry: ${previous}.`,
          ));
        }, timeoutMs);
        const tick = () => {
          const current = geometry();
          changed ||= current !== "" && current !== changedFrom;
          stable =
            current !== "" && current === previous && changed
              ? stable + 1
              : 0;
          previous = current;
          if (stable >= stableFrames) {
            clearTimeout(deadline);
            resolve(current);
            return;
          }
          frame = requestAnimationFrame(tick);
        };
        frame = requestAnimationFrame(tick);
      }),
    {
      changedFrom,
      stableFrames: SETTLED_FRAMES,
      timeoutMs: SETTLE_TIMEOUT_MS,
    },
  );
}
export async function waitForStableBounds(locator: Locator) {
  return locator.evaluate((element) => new Promise<{ x: number; y: number; width: number; height: number }>((resolve, reject) => {
    const read = () => {
      const rect = element.getBoundingClientRect();
      return { x: rect.x, y: rect.y, width: rect.width, height: rect.height };
    };
    let previous = read();
    let stableFrames = 0;
    let frame = 0;
    const timeoutMs = 15000;
    const deadline = setTimeout(() => {
      cancelAnimationFrame(frame);
      reject(new Error(`Project row geometry did not settle within ${timeoutMs}ms: ${JSON.stringify(previous)}.`));
    }, timeoutMs);
    const tick = () => {
      const current = read();
      const stable =
        Math.abs(current.x - previous.x) < 0.1 &&
        Math.abs(current.y - previous.y) < 0.1 &&
        Math.abs(current.width - previous.width) < 0.1 &&
        Math.abs(current.height - previous.height) < 0.1;
      stableFrames = stable ? stableFrames + 1 : 0;
      previous = current;
      if (stableFrames >= 2) {
        clearTimeout(deadline);
        resolve(current);
        return;
      }
      frame = requestAnimationFrame(tick);
    };
    frame = requestAnimationFrame(tick);
  }));
}
