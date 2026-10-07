import { expect, type Page } from '@playwright/test';
import { createHash } from 'node:crypto';
import { waitForFrames } from './semantics_scroll';

const STABLE_CAPTURES = 4;
// Spans the scrollbar's 600 ms hide delay and 300 ms fade across four captures.
const CAPTURE_INTERVAL_MS = 350;
const FRAMES_BETWEEN_CAPTURES = 5;

export async function settleCompositor(page: Page, frameCount = 3) {
  await waitForFrames(page, frameCount);
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

// Wait for consecutive full-viewport captures to match.
export async function waitForStableCanvas(page: Page) {
  let previous = '';
  let identical = 0;
  await expect
    .poll(
      async () => {
        const capture = await page.screenshot({
          animations: 'disabled',
          caret: 'hide',
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
        intervals: [CAPTURE_INTERVAL_MS],
        message: 'The canvas never stopped changing.',
        timeout: 20000,
      },
    )
    .toBe(true);
}
