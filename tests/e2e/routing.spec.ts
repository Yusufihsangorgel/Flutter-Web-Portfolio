import { expect, test } from "@playwright/test";
import { readFileSync } from "node:fs";

const portfolio = JSON.parse(
  readFileSync("assets/content/portfolio.json", "utf8"),
) as { contributions: unknown[] };
// A clean template has no contributions chapter, but every record has About.
const hashRoute = portfolio.contributions.length > 0 ? "proof" : "about";

test("returns static routes and reveals the hash route", async ({
  page,
  request,
}) => {
  const missingResponse = await request.get("/does-not-exist");
  expect(missingResponse.status()).toBe(404);

  const nestedMissing = await page.goto("/deep/missing/path");
  expect(nestedMissing?.status()).toBe(404);
  await expect(
    page.getByRole("link", { name: "Return to the home page" }),
  ).toHaveJSProperty("href", new URL("/", page.url()).href);

  const securityResponse = await request.get("/.well-known/security.txt");
  expect(securityResponse.status()).toBe(200);
  expect(securityResponse.headers()["content-type"]).toMatch(
    /^text\/plain(?:;|$)/i,
  );
  expect(await securityResponse.text()).toMatch(/^Contact:\s*.+$/m);

  const routeResponse = await page.goto(`/#/${hashRoute}`, {
    waitUntil: "domcontentloaded",
  });
  expect(routeResponse?.status()).toBe(200);
  await page.waitForFunction(
    () => performance.getEntriesByName("flutter-bootstrap-surface-removed").length > 0,
  );
  await expect(page).toHaveURL(new RegExp(`#/${hashRoute}$`));
  await expect(page.locator("flt-semantics-host")).toBeAttached();
  await expect(page.locator("#bootstrap-surface")).toHaveCount(0);
  // The hero h1 is not in the semantics tree when the route lands below it.
  await expect(page.getByRole("heading").first()).toBeAttached();
});
