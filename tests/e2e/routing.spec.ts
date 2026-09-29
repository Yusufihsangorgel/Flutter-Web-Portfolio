import { expect, test } from "@playwright/test";

test("returns static routes and reveals the proof hash route", async ({
  page,
  request,
}) => {
  const missingResponse = await request.get("/does-not-exist");
  expect(missingResponse.status()).toBe(404);

  const securityResponse = await request.get("/.well-known/security.txt");
  expect(securityResponse.status()).toBe(200);
  expect(securityResponse.headers()["content-type"]).toMatch(
    /^text\/plain(?:;|$)/i,
  );
  expect(await securityResponse.text()).toMatch(/^Contact:\s*.+$/m);

  const routeResponse = await page.goto("/#/proof", {
    waitUntil: "domcontentloaded",
  });
  expect(routeResponse?.status()).toBe(200);
  await page.waitForFunction(
    () => performance.getEntriesByName("flutter-bootstrap-surface-removed").length > 0,
  );
  await expect(page).toHaveURL(/#\/proof$/);
  await expect(page.locator("flt-semantics-host")).toBeAttached();
  await expect(page.locator("#bootstrap-surface")).toHaveCount(0);
  await expect(page.getByRole("heading", { level: 1 })).toBeVisible();
});
