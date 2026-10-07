import { expect, type Page } from '@playwright/test';
import { createHash } from 'node:crypto';
import { waitForFrames } from './semantics_scroll';

const visualMaskRegions = [
  ['narrative-rail', 'left:0;top:0;width:48px;height:100vh'],
  ['scrollbar', 'right:0;top:0;width:16px;height:100vh'],
] as const;
const STABLE_CAPTURES = 4;
const FRAMES_BETWEEN_CAPTURES = 5;

export async function settleCompositor(page: Page, frameCount = 3) {
  await waitForFrames(page, frameCount);
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

// Work artifacts load lazily. Each image's semantics node names its asset,
// and the app records a user-timing mark once that asset has been painted.
export async function readVisibleWorkArtifacts(page: Page) {
  return page.evaluate(() => {
    const prefix = 'work-artifact:';
    const counts = { visible: 0, ready: 0 };
    const artifacts = document.querySelectorAll(
      `[flt-semantics-identifier^="${prefix}"]`,
    );
    for (const artifact of artifacts) {
      const box = artifact.getBoundingClientRect();
      const visible =
        box.width > 0 &&
        box.height > 0 &&
        box.bottom > 0 &&
        box.right > 0 &&
        box.top < window.innerHeight &&
        box.left < window.innerWidth;
      if (!visible) continue;
      counts.visible += 1;
      const asset = (
        artifact.getAttribute('flt-semantics-identifier') ?? ''
      ).slice(prefix.length);
      const marks = performance.getEntriesByName(
        `work-artifact-painted:${asset}`,
        'mark',
      );
      if (marks.length > 0) counts.ready += 1;
    }
    return counts;
  });
}

export async function waitForWorkImagesPainted(page: Page) {
  await expect
    .poll(
      async () => {
        const { visible, ready } = await readVisibleWorkArtifacts(page);
        return visible - ready;
      },
      {
        message: 'A work image in the viewport was never painted.',
        timeout: 15000,
      },
    )
    .toBe(0);
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
