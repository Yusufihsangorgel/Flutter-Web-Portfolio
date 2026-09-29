import { expect, test } from "@playwright/test";

declare global {
  interface Window {
    policyViolations: string[];
  }
}

test("keeps the page free of CSP violations through the first interaction", async ({
  page,
}) => {
  await page.addInitScript(() => {
    window.policyViolations = [];
    document.addEventListener("securitypolicyviolation", (event) => {
      window.policyViolations.push(event.violatedDirective);
    });
  });

  const response = await page.goto("/", { waitUntil: "domcontentloaded" });
  if (!process.env.PLAYWRIGHT_BASE_URL) {
    expect(response).not.toBeNull();
    const headers = response!.headers();
    expect(headers["strict-transport-security"]).toBeTruthy();

    const scriptSource = headers["content-security-policy"]
      ?.split(";")
      .map((directive) => directive.trim())
      .find((directive) => /^script-src\s/i.test(directive));
    expect(scriptSource).toBeTruthy();
    expect(scriptSource).not.toMatch(/'unsafe-(?:inline|eval)'/i);
  }

  await page.waitForFunction(
    () => performance.getEntriesByName("flutter-bootstrap-surface-removed").length > 0,
  );
  await page.keyboard.press("Tab");
  await page.evaluate(
    () => new Promise<void>((resolve) => requestAnimationFrame(() => resolve())),
  );

  expect(await page.evaluate(() => window.policyViolations)).toEqual([]);
});
