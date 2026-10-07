import { expect, test } from "./helpers/test_setup";
import {
  packageMetadata,
  portfolio,
  readRevealSourceCount,
  readRuntimeTimeline,
} from "./helpers/portfolio_test_helpers";

test("boots the Flutter experience without browser errors", async ({
  page,
}) => {
  const errors: string[] = [];
  page.on("pageerror", (error) => errors.push(error.message));
  page.on("console", (message) => {
    if (message.type() === "error") errors.push(message.text());
  });
  page.on("response", (response) => {
    if (response.status() >= 400) {
      errors.push(`HTTP ${response.status()} ${response.url()}`);
    }
  });

  const response = await page.goto("/", { waitUntil: "domcontentloaded" });
  expect(response?.status()).toBe(200);
  await page.waitForSelector("flt-semantics-host", {
    state: "attached",
    timeout: 20000,
  });
  await expect(page.locator("#bootstrap-surface")).toHaveCount(0);
  await expect(page.getByRole("heading").first()).toBeAttached();
  const timeline = await readRuntimeTimeline(page);
  expect(timeline.every((value) => Number.isFinite(value))).toBe(true);
  expect(timeline).toEqual([...timeline].sort((a, b) => a! - b!));
  expect(await readRevealSourceCount(page)).toBe(1);
  expect(
    await page.evaluate(
      () =>
        performance.getEntriesByName(
          "flutter-bootstrap-to-first-frame",
          "measure",
        ).length,
    ),
  ).toBe(1);
  expect(errors).toEqual([]);
});

test("serves every authored primary and compact work artifact as an image", async ({
  request,
}) => {
  const workAssets = portfolio.systems
    .flatMap((system) => [
      system.artifact.asset,
      system.artifact.compact?.asset,
    ])
    .filter((asset): asset is string => Boolean(asset));

  expect(workAssets.length).toBe(portfolio.systems.length * 2);
  expect(new Set(workAssets).size).toBe(workAssets.length);
  for (const asset of workAssets) {
    const releasePath = asset.startsWith("assets/")
      ? `/assets/${asset}`
      : `/${asset}`;
    const response = await request.get(releasePath);
    expect(response.status(), asset).toBe(200);
    expect(response.headers()["content-type"], asset).toMatch(/^image\//);
    expect((await response.body()).byteLength, asset).toBeGreaterThan(0);
  }
});

test("retires the legacy service worker without keeping a registration", async ({
  page,
}) => {
  await page.goto("/", { waitUntil: "domcontentloaded" });
  await page.evaluate(async () => {
    const cache = await caches.open("unrelated-origin-contract");
    await cache.put(
      new Request("https://unrelated.example/static.css"),
      new Response("unrelated"),
    );
  });
  await page.evaluate(async () => {
    await navigator.serviceWorker.register("/flutter_service_worker.js");
  });

  await expect
    .poll(
      () =>
        page.evaluate(async () => {
          const registrations =
            await navigator.serviceWorker.getRegistrations();
          return registrations.length;
        }),
      { timeout: 10000 },
    )
    .toBe(0);
  expect(
    await page.evaluate(async () =>
      (await caches.keys()).includes("unrelated-origin-contract"),
    ),
  ).toBe(true);
  await page.evaluate(() => caches.delete("unrelated-origin-contract"));
});

test("serves same-origin fallback fonts without masking missing assets", async ({
  request,
}) => {
  const font = await request.get(
    "/assets/fallback_fonts/roboto/v32/KFOmCnqEu92Fr1Me4GZLCzYlKw.woff2",
  );
  expect(font.status()).toBe(200);
  expect(font.headers()["content-type"]).toContain("font/woff2");

  for (const path of [
    "/assets/assets/fonts/inter/Inter-Variable.ttf",
    "/assets/assets/fonts/noto_sans_arabic/NotoSansArabic-Variable.ttf",
    "/assets/assets/fonts/noto_sans_devanagari/NotoSansDevanagari-Variable.ttf",
  ]) {
    const appFont = await request.get(path);
    expect(appFont.status(), path).toBe(200);
    expect(appFont.headers()["content-type"], path).toContain("font/ttf");
  }

  const missing = await request.get("/assets/fallback_fonts/missing.woff2");
  expect(missing.status()).toBe(404);
});

test("ships the social preview at the declared large-card dimensions", async ({
  request,
}) => {
  const response = await request.get(portfolio.site.social_image);
  expect(response.status()).toBe(200);
  expect(response.headers()["content-type"]).toContain("image/png");

  const png = await response.body();
  expect(png.subarray(1, 4).toString()).toBe("PNG");
  expect(png.readUInt32BE(16)).toBe(1200);
  expect(png.readUInt32BE(20)).toBe(630);
});

test("does not publish renderer debug symbols", async ({ request }) => {
  const response = await request.get("/canvaskit/skwasm.js.symbols");
  expect(response.status()).toBe(404);

  const version = await request.get("/version.json");
  expect(version.status()).toBe(200);
  expect(await version.json()).toMatchObject({
    version: packageMetadata.version,
  });
});
