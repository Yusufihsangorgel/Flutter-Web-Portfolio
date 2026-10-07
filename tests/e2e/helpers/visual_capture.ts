import { expect, type Page } from '@playwright/test';
import { createHash } from 'node:crypto';

const visualMaskRegions = [
  ['narrative-rail', 'left:0;top:0;width:48px;height:100vh'],
  ['scrollbar', 'right:0;top:0;width:16px;height:100vh'],
] as const;
const STABLE_CAPTURES = 4;
const FRAMES_BETWEEN_CAPTURES = 5;

export async function settleCompositor(page: Page, frameCount = 3) {
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

export async function installVisualMasks(page: Page) {
  await page.evaluate((regions) => {
    for (const [name, bounds] of regions) {
      if (document.querySelector(`[data-visual-mask="${name}"]`)) continue;
      const element = document.createElement('div');
      element.dataset.visualMask = name;
      element.setAttribute('aria-hidden', 'true');
      element.style.cssText = `position:fixed;${bounds};opacity:0;pointer-events:none`;
      document.body.append(element);
    }
  }, visualMaskRegions);
  return visualMaskRegions.map(([name]) =>
    page.locator(`[data-visual-mask="${name}"]`),
  );
}

// Wait for consecutive masked captures to match.
export async function waitForStableCanvas(page: Page) {
  const mask = await installVisualMasks(page);
  let previous = '';
  let identical = 0;
  await expect
    .poll(
      async () => {
        const capture = await page.screenshot({
          animations: 'disabled',
          caret: 'hide',
          mask,
          scale: 'css',
        });
        const digest = createHash('sha1').update(capture).digest('hex');
        identical = digest === previous ? identical + 1 : 1;
        previous = digest;
        if (identical < STABLE_CAPTURES) {
          await settleCompositor(page, FRAMES_BETWEEN_CAPTURES);
        }
        return identical >= STABLE_CAPTURES;
      },
      {
        intervals: [0],
        message: 'The canvas never stopped changing.',
        timeout: 20000,
      },
    )
    .toBe(true);
}
