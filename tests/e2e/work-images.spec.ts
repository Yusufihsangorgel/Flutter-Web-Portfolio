import { expect, Page, test } from "@playwright/test";
import { readFileSync } from "node:fs";
import {
  expectedArtifact,
  openPortfolio,
  portfolio,
} from "./helpers/portfolio_test_helpers";
import {
  scrollAndSettle,
  scrollToLocator,
  waitForFrames,
  waitForSemanticsSettled,
} from "./helpers/semantics_scroll";

const evidenceIndexHeading = (
  JSON.parse(readFileSync("assets/i18n/en.json", "utf8")) as {
    projects_section: { evidence_index: string };
  }
).projects_section.evidence_index;

// Decoded response bodies are counted, so the budget does not depend on
// whether a host compresses images.
const firstVisitImageBudget = 400_000;
const imagePathPattern = /\.(avif|gif|ico|jpe?g|png|svg|webp)$/i;
const workPathPrefix = "/assets/assets/work/";
// Lazy images are requested from a post-frame check after layout.
const lazyCheckFrames = 10;

type ImageTransfer = { path: string; bytes: number };

function recordImageTransfers(page: Page) {
  const transfers: ImageTransfer[] = [];
  const pending: Promise<void>[] = [];
  page.on("response", (response) => {
    const url = new URL(response.url());
    const contentType = response.headers()["content-type"] ?? "";
    if (!imagePathPattern.test(url.pathname) && !contentType.startsWith("image/")) {
      return;
    }
    pending.push(
      response
        .body()
        .then((body) => {
          transfers.push({
            path: decodeURIComponent(url.pathname),
            bytes: body.byteLength,
          });
        })
        .catch(() => undefined),
    );
  });
  return {
    async settled(): Promise<ImageTransfer[]> {
      await waitForFrames(page, lazyCheckFrames);
      await page.waitForLoadState("networkidle");
      await Promise.all(pending);
      return [...transfers];
    },
  };
}

function totalBytes(transfers: ImageTransfer[]) {
  return transfers.reduce((sum, transfer) => sum + transfer.bytes, 0);
}

function workAssets(transfers: ImageTransfer[]) {
  return transfers
    .filter((transfer) => transfer.path.startsWith(workPathPrefix))
    .map((transfer) => transfer.path.slice("/assets/".length));
}

// Brings the evidence index heading into view, then scrolls far enough for
// its selected preview to be on screen.
async function scrollThroughAtlas(page: Page) {
  const { viewportHeight, pixelRatio } = await page.evaluate(() => ({
    viewportHeight: window.innerHeight,
    pixelRatio: window.devicePixelRatio,
  }));
  // Flutter divides wheel deltas by the device pixel ratio.
  const step = viewportHeight * 0.5 * pixelRatio;
  const heading = page.getByRole("heading", {
    name: evidenceIndexHeading,
    exact: true,
  });
  await scrollToLocator(page, heading, step);
  await scrollAndSettle(page, step);
  await scrollAndSettle(page, step);
  await waitForSemanticsSettled(page);
}

test("loads work images lazily within the first-visit image budget", async ({
  page,
}, testInfo) => {
  test.skip(portfolio.systems.length === 0, "work chapter is not authored");
  const images = recordImageTransfers(page);

  await openPortfolio(page);
  await waitForSemanticsSettled(page);
  const initial = await images.settled();
  testInfo.annotations.push({
    type: "first-load image bytes",
    description: String(totalBytes(initial)),
  });
  expect(workAssets(initial), "no work image before the atlas nears").toEqual([]);
  expect(totalBytes(initial)).toBeLessThanOrEqual(firstVisitImageBudget);

  await scrollThroughAtlas(page);
  const visited = await images.settled();
  const fetched = workAssets(visited);
  testInfo.annotations.push({
    type: "image bytes after the atlas",
    description: `${totalBytes(visited)} (${fetched.length} work images)`,
  });

  const authored = new Set(
    portfolio.systems.flatMap((system) =>
      [system.artifact.asset, system.artifact.compact?.asset].filter(
        (asset): asset is string => Boolean(asset),
      ),
    ),
  );
  for (const system of portfolio.systems.filter((entry) => entry.featured)) {
    expect(fetched, system.id).toContain(expectedArtifact(page, system).asset);
  }
  for (const asset of fetched) expect(authored, asset).toContain(asset);
  expect(new Set(fetched).size, "each work image is fetched once").toBe(
    fetched.length,
  );
  expect(totalBytes(visited)).toBeLessThanOrEqual(firstVisitImageBudget);
});
