import { expect, test, type Response } from "@playwright/test";

const arabicPath = "noto_sans_arabic/NotoSansArabic-Variable.ttf";
const devanagariPath = "noto_sans_devanagari/NotoSansDevanagari-Variable.ttf";

test("English load stays within the font transfer budget", async ({ page }) => {
  const fontResponses: Response[] = [];
  page.on("response", (response) => {
    if (!/\.(ttf|otf|woff2?)(?:\?|$)/.test(response.url())) return;
    fontResponses.push(response);
  });

  await page.goto("/", { waitUntil: "networkidle" });
  await expect(page.getByRole("heading").first()).toBeAttached();
  await page.waitForLoadState("networkidle");
  const fontRequests = fontResponses.map((response) => response.url());
  const fontBytes = (await Promise.all(fontResponses.map((response) => response.body())))
    .reduce((total, body) => total + body.length, 0);
  test.info().annotations.push({ type: "font bytes", description: String(fontBytes) });
  expect(fontRequests.some((url) => url.includes(arabicPath))).toBe(false);
  expect(fontRequests.some((url) => url.includes(devanagariPath))).toBe(false);
  expect(fontBytes).toBeLessThanOrEqual(350 * 1024);
});

test("Arabic selection loads its font", async ({ page }) => {
  const runtimeFontResponses: Response[] = [];
  page.on("response", (response) => {
    if (!response.url().includes(arabicPath)) return;
    if (!["fetch", "xhr"].includes(response.request().resourceType())) return;
    runtimeFontResponses.push(response);
  });

  await page.goto("/", { waitUntil: "domcontentloaded" });
  await expect(page.getByRole("heading").first()).toBeAttached();
  await page.getByRole("button", { name: /: English$/ }).click();
  await Promise.all([
    page.waitForNavigation({ waitUntil: "domcontentloaded" }),
    page.getByRole("menuitem", { name: "AR العربية", exact: true }).click(),
  ]);
  await expect(page.locator("html")).toHaveAttribute("lang", "ar");
  await expect(page.getByRole("heading").first()).toBeAttached();
  await page.waitForLoadState("networkidle");
  expect(runtimeFontResponses.some((response) => response.status() === 200)).toBe(true);
});
