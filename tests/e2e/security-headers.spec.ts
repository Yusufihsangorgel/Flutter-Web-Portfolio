import { expect, test, type ConsoleMessage, type Page } from "@playwright/test";
import { readFileSync } from "node:fs";

declare global {
  interface Window {
    policyViolations: string[];
    analyticsLoaded?: boolean;
  }
}

const portfolio = JSON.parse(
  readFileSync("assets/content/portfolio.json", "utf8"),
) as { site: { analytics?: { script_url: string } | null } };
const analyticsUrl = portfolio.site.analytics?.script_url;

const runtimes = [
  { name: "Wasm", forceJavaScript: false },
  { name: "JavaScript", forceJavaScript: true },
] as const;

async function recordPolicyViolations(page: Page, forceJavaScript: boolean) {
  await page.addInitScript((forceJs) => {
    window.policyViolations = [];
    document.addEventListener("securitypolicyviolation", (event) => {
      window.policyViolations.push(`${event.violatedDirective} ${event.blockedURI}`);
    });
    // Flutter selects its Wasm build only when a WasmGC probe validates.
    if (forceJs) {
      Object.defineProperty(WebAssembly, "validate", { value: () => false });
    }
  }, forceJavaScript);
  if (analyticsUrl) {
    await page.route(analyticsUrl, (route) =>
      route.fulfill({
        contentType: "text/javascript",
        body: "window.analyticsLoaded = true;",
      }),
    );
  }
}

test("sends HSTS and a script policy without unsafe directives", async ({
  request,
}) => {
  test.skip(
    !!process.env.PLAYWRIGHT_BASE_URL,
    "the preview server applies the checked-in host headers",
  );
  const headers = (await request.get("/")).headers();
  expect(headers["strict-transport-security"]).toBeTruthy();

  const scriptSource = headers["content-security-policy"]
    ?.split(";")
    .map((directive) => directive.trim())
    .find((directive) => /^script-src\s/i.test(directive));
  expect(scriptSource).toBeTruthy();
  expect(scriptSource).toContain("'wasm-unsafe-eval'");
  expect(scriptSource).not.toMatch(/'unsafe-(?:inline|eval)'/i);
});

for (const runtime of runtimes) {
  test(`keeps the ${runtime.name} runtime free of CSP violations through the first interaction`, async ({
    page,
  }) => {
    await recordPolicyViolations(page, runtime.forceJavaScript);
    const requested: string[] = [];
    page.on("request", (request) => requested.push(new URL(request.url()).pathname));
    // Violations inside workers never reach the document listener; Chromium logs them.
    const policyErrors: string[] = [];
    const watchConsole = (message: ConsoleMessage) => {
      if (message.type() === "error" && /Content Security Policy/i.test(message.text())) {
        policyErrors.push(message.text());
      }
    };
    page.on("console", watchConsole);
    page.on("worker", (worker) => worker.on("console", watchConsole));

    await page.goto("/", { waitUntil: "domcontentloaded" });
    // A blocked runtime never reveals, so stop waiting at the first violation.
    await page.waitForFunction(
      () =>
        window.policyViolations.length > 0 ||
        performance.getEntriesByName("flutter-bootstrap-surface-removed").length > 0,
    );
    await page.keyboard.press("Tab");
    await page.evaluate(
      () => new Promise<void>((resolve) => requestAnimationFrame(() => resolve())),
    );

    expect(await page.evaluate(() => window.policyViolations)).toEqual([]);
    expect(policyErrors).toEqual([]);
    // The loader fetches main.dart.js only for the JavaScript build; the Wasm
    // binaries are preloaded for every browser, so they cannot tell the two apart.
    expect(requested.includes("/main.dart.js")).toBe(runtime.forceJavaScript);
    expect(await page.evaluate(() => "_flutter_skwasmInstance" in window)).toBe(
      !runtime.forceJavaScript,
    );
    await expect(page.locator("flt-semantics-host")).toBeAttached();
    if (analyticsUrl) {
      expect(await page.evaluate(() => window.analyticsLoaded)).toBe(true);
    }
  });
}
