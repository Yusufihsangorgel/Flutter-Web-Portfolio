import { expect, test } from "@playwright/test";
import { readFileSync } from "node:fs";

type PortfolioContent = {
  profile: { name: string };
};

const portfolio = JSON.parse(
  readFileSync("assets/content/portfolio.json", "utf8"),
) as PortfolioContent;

test("serves the semantic document when JavaScript is disabled", async (
  { browser },
  testInfo,
) => {
  const context = await browser.newContext({
    baseURL: testInfo.project.use.baseURL as string,
    javaScriptEnabled: false,
  });
  const page = await context.newPage();

  try {
    await page.goto("/", { waitUntil: "domcontentloaded" });
    const heading = page.locator("h1");
    await expect(heading).toHaveCount(1);
    await expect(heading).toBeVisible();
    const containsProfileName = await heading.evaluate(
      (element, name) => element.textContent?.includes(name) ?? false,
      portfolio.profile.name,
    );
    expect(containsProfileName).toBe(true);
    expect(await page.locator("h2").count()).toBeGreaterThanOrEqual(6);

    const secureLinks = page.locator('a[href^="https://"]');
    expect(await secureLinks.count()).toBeGreaterThanOrEqual(30);
    const invalidLinks = await secureLinks.evaluateAll((anchors) =>
      anchors.filter((anchor) => {
        try {
          return new URL(anchor.getAttribute("href") ?? "").protocol !== "https:";
        } catch {
          return true;
        }
      }).length,
    );
    expect(invalidLinks).toBe(0);
  } finally {
    await context.close();
  }
});

test("hides the static document from assistive technology after reveal", async ({
  page,
}) => {
  await page.goto("/", { waitUntil: "domcontentloaded" });
  await page.waitForFunction(
    () => performance.getEntriesByName("flutter-bootstrap-surface-removed").length > 0,
  );

  const staticDocument = page.locator("#static-document");
  await expect(staticDocument).toHaveAttribute("hidden", "");
  await expect(staticDocument).toHaveAttribute("inert", "");
  await expect(page.getByRole("heading", { level: 1 })).toHaveCount(1);
});
