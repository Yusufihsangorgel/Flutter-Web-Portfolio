import { expect, test, type Response } from "@playwright/test";
import { gzipSync } from "node:zlib";

const arabicPath = "noto_sans_arabic/NotoSansArabic-Variable.ttf";
const devanagariPath = "noto_sans_devanagari/NotoSansDevanagari-Variable.ttf";
const latinPaths = [
  "inter/Inter-Variable.ttf",
  "space_grotesk/SpaceGrotesk-Variable.ttf",
  "jetbrains_mono/JetBrainsMono-Variable.ttf",
];
const fontFile = /\.(?:ttf|otf|woff2?)(?:\?|$)/;
const budgetBytes = 350 * 1024;
const surface = "#bootstrap-surface";

test("English load stays within the font transfer budget", async ({ page }) => {
  const fontUrls: string[] = [];
  page.on("request", (request) => {
    if (fontFile.test(request.url())) fontUrls.push(request.url());
  });

  await page.goto("/", { waitUntil: "commit" });
  await expect(page.locator(surface)).toHaveCount(0, { timeout: 45000 });
  await page.waitForLoadState("networkidle");

  // Fetch each file again: DevTools drops bodies of requests the engine cancels early.
  const sizes = new Map<string, { raw: number; gzip: number }>();
  for (const url of new Set(fontUrls)) {
    const body = await (await page.request.get(url)).body();
    // The preview server sends fonts raw; production gzips them at level 6.
    sizes.set(url, { raw: body.length, gzip: gzipSync(body, { level: 6 }).length });
  }
  const total = (kind: "raw" | "gzip") =>
    fontUrls.reduce((sum, url) => sum + (sizes.get(url)?.[kind] ?? 0), 0);
  test.info().annotations.push(
    { type: "font bytes (raw)", description: String(total("raw")) },
    { type: "font bytes (gzip)", description: String(total("gzip")) },
  );

  expect(fontUrls.some((url) => url.includes(arabicPath))).toBe(false);
  expect(fontUrls.some((url) => url.includes(devanagariPath))).toBe(false);
  for (const path of latinPaths) {
    expect(fontUrls.some((url) => url.includes(path)), path).toBe(true);
  }
  expect(total("gzip")).toBeLessThanOrEqual(budgetBytes);
});

test("Arabic selection loads its font", async ({ page }) => {
  const runtimeFontResponses: Response[] = [];
  page.on("response", (response) => {
    if (!response.url().includes(arabicPath)) return;
    // The critical shell preloads the same file as a document font; only the engine's fetch is the runtime load.
    if (!["fetch", "xhr"].includes(response.request().resourceType())) return;
    runtimeFontResponses.push(response);
  });

  await page.goto("/", { waitUntil: "commit" });
  await expect(page.locator(surface)).toHaveCount(0, { timeout: 45000 });
  await page.getByRole("button", { name: /: English$/ }).click();
  await Promise.all([
    page.waitForNavigation({ waitUntil: "commit" }),
    page.getByRole("menuitem", { name: "AR العربية", exact: true }).click(),
  ]);
  await expect(page.locator("html")).toHaveAttribute("lang", "ar");
  await expect(page.locator(surface)).toHaveCount(0, { timeout: 45000 });
  expect(runtimeFontResponses.map((response) => response.status())).toContain(200);
});
