import { expect, Page, test } from "@playwright/test";
import { readFileSync } from "node:fs";
import type { PortfolioTestData } from "../support/portfolio_test_data";

const portfolio = JSON.parse(
  readFileSync("assets/content/portfolio.json", "utf8"),
) as PortfolioTestData;
const english = JSON.parse(readFileSync("assets/i18n/en.json", "utf8")) as {
  projects_section: { evidence_index: string };
};

// Decoded response bodies are counted, so the budget does not depend on
// whether a host compresses images.
const firstVisitImageBudget = 400_000;
const compactBreakpoint = 900;
const imagePathPattern = /\.(avif|gif|ico|jpe?g|png|svg|webp)$/i;
const workPathPrefix = "/assets/assets/work/";

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

async function openPortfolio(page: Page) {
  await page.goto("/", { waitUntil: "domcontentloaded" });
  await page.waitForSelector("flt-semantics-host", {
    state: "attached",
    timeout: 20000,
  });
  await expect(page.locator("#bootstrap-surface")).toHaveCount(0);
  await expect(page.getByRole("heading").first()).toBeAttached();
}

// Scrolls until the evidence index heading reaches the upper part of the
// viewport, then one more viewport so its selected preview is on screen.
async function scrollThroughAtlas(page: Page) {
  const heading = page.getByRole("heading", {
    name: english.projects_section.evidence_index,
    exact: true,
  });
  const viewportHeight = await page.evaluate(() => window.innerHeight);
  for (let attempt = 0; attempt < 120; attempt += 1) {
    const box = (await heading.count()) > 0 ? await heading.first().boundingBox() : null;
    if (box && box.y < viewportHeight * 0.25) break;
    await page.mouse.wheel(0, 480);
    await page.waitForTimeout(60);
  }
  await expect(heading.first()).toBeAttached();
  for (let step = 0; step < 3; step += 1) {
    await page.mouse.wheel(0, viewportHeight / 3);
    await page.waitForTimeout(120);
  }
  await page.waitForTimeout(1000);
}

test("loads work images lazily within the first-visit image budget", async ({
  page,
}, testInfo) => {
  test.skip(portfolio.systems.length === 0, "work chapter is not authored");
  const images = recordImageTransfers(page);

  await openPortfolio(page);
  await page.waitForTimeout(1500);
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

  const compact = (page.viewportSize()?.width ?? 0) < compactBreakpoint;
  const authored = new Set(
    portfolio.systems.flatMap((system) =>
      [system.artifact.asset, system.artifact.compact?.asset].filter(
        (asset): asset is string => Boolean(asset),
      ),
    ),
  );
  for (const system of portfolio.systems.filter((entry) => entry.featured)) {
    const expected =
      compact && system.artifact.compact
        ? system.artifact.compact.asset
        : system.artifact.asset;
    expect(fetched, system.id).toContain(expected);
  }
  for (const asset of fetched) expect(authored, asset).toContain(asset);
  expect(new Set(fetched).size, "each work image is fetched once").toBe(
    fetched.length,
  );
  expect(totalBytes(visited)).toBeLessThanOrEqual(firstVisitImageBudget);
});
