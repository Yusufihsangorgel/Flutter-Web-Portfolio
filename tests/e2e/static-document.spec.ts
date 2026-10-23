import { expect, test } from "./helpers/test_setup";
import { readFileSync } from "node:fs";
import { Script } from "node:vm";

test("loads the classic scripts without redeclaring a global binding", () => {
  const sources = [
    "history.js",
    "bootstrap_locales.js",
    "bootstrap_locale.js",
    "apply_bootstrap_locale.js",
    "static_document.js",
    "flutter_bootstrap.js",
    "retire_service_worker.js",
  ].map((script) => readFileSync(`web/${script}`, "utf8")
    .replace(/^\{\{flutter_js\}\}\r?\n\{\{flutter_build_config\}\}\r?\n/, ""));
  expect(() => new Script(sources.join("\n"))).not.toThrow();
});

type Linked = { url?: string };
type PortfolioContent = {
  site: { resume_enabled?: boolean };
  profile: {
    name: string;
    summary?: string;
    background?: string;
    links: Linked[];
  };
  sources?: Linked[];
  experience: unknown[];
  contributions: Array<Linked & { issue_url?: string }>;
  systems: Array<Linked & { evidence?: Linked[] }>;
  packages: Array<Linked & { repository?: string }>;
  writing: Linked[];
  writing_sources?: Array<Linked & { profile_url?: string }>;
};

const portfolio = JSON.parse(
  readFileSync("assets/content/portfolio.json", "utf8"),
) as PortfolioContent;

// Every non-empty chapter renders one h2; the optional ones are omitted when empty.
const chapterCount = [
  Boolean(portfolio.profile.summary || portfolio.profile.background),
  portfolio.experience.length > 0,
  portfolio.contributions.length > 0,
  portfolio.systems.length > 0,
  portfolio.packages.length > 0,
  portfolio.writing.length > 0,
].filter(Boolean).length;

const evidenceLinkCount = [
  ...portfolio.profile.links.map(({ url }) => url),
  ...(portfolio.sources ?? []).map(({ url }) => url),
  ...portfolio.contributions.flatMap(({ url, issue_url }) => [url, issue_url]),
  ...portfolio.systems.flatMap(({ url, evidence }) => [
    url,
    ...(evidence ?? []).map((item) => item.url),
  ]),
  ...portfolio.packages.flatMap(({ url, repository }) => [url, repository]),
  ...portfolio.writing.map(({ url }) => url),
  ...(portfolio.writing.length > 0
    ? (portfolio.writing_sources ?? []).flatMap(({ url, profile_url }) => [
        url,
        profile_url,
      ])
    : []),
].filter((url) => url?.startsWith("https://")).length;

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
    // Playwright's text engine skips <noscript>, so query the note by class.
    const note = page.locator(".noscript-recovery");
    await expect(note).toBeVisible();
    await expect(note).toHaveText("The interactive version needs JavaScript.");
    await expect(page.locator("#bootstrap-surface")).toBeHidden();
    await expect(page.locator("#static-document main")).toBeVisible();
    await expect(page.getByRole("navigation")).toBeVisible();
    expect(await page.evaluate(() => getComputedStyle(document.body).overflow)).toBe(
      "auto",
    );
    const heading = page.locator("h1");
    await expect(heading).toHaveCount(1);
    await expect(heading).toBeVisible();
    const containsProfileName = await heading.evaluate(
      (element, name) => element.textContent?.includes(name) ?? false,
      portfolio.profile.name,
    );
    expect(containsProfileName).toBe(true);
    expect(await page.locator("h2").count()).toBe(chapterCount);

    const secureLinks = page.locator('a[href^="https://"]');
    expect(await secureLinks.count()).toBeGreaterThanOrEqual(evidenceLinkCount);
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
    const resumeLink = page.locator('#static-document a[href="resume.pdf"]');
    await expect(resumeLink).toHaveCount(
      portfolio.site.resume_enabled === true ? 1 : 0,
    );
    if (portfolio.site.resume_enabled === true) {
      await expect(resumeLink).toHaveAccessibleName("Résumé (PDF)");
      const destination = await resumeLink.evaluate((anchor: HTMLAnchorElement) => ({
        actual: anchor.href,
        expected: new URL("resume.pdf", document.baseURI).href,
      }));
      expect(destination.actual).toBe(destination.expected);
    }
  } finally {
    await context.close();
  }
});

test("static resume anchor uses a Pages base even at a deep document URL", async (
  { browser },
  testInfo,
) => {
  const context = await browser.newContext({
    baseURL: testInfo.project.use.baseURL as string,
    javaScriptEnabled: false,
  });
  const page = await context.newPage();
  try {
    // Keep the built HTML intact except for the base of this Pages-path fixture.
    // No PDF response is mocked; the release verifier checks the actual artifact.
    await page.route("**/portfolio/deep/", async (route) => {
      const root = new URL("/", route.request().url());
      const response = await route.fetch({ url: root.href });
      const html = await response.text();
      expect(html).toMatch(/<base href="[^"]+">/);
      await route.fulfill({
        response,
        body: html.replace(/<base href="[^"]+">/, '<base href="/portfolio/">'),
      });
    });
    await page.goto("/portfolio/deep/", { waitUntil: "domcontentloaded" });
    const resumeLink = page.locator('#static-document a[href="resume.pdf"]');
    await expect(resumeLink).toHaveCount(portfolio.site.resume_enabled === true ? 1 : 0);
    if (portfolio.site.resume_enabled === true) {
      const expected = new URL("/portfolio/resume.pdf", page.url()).href;
      await expect(resumeLink).toHaveJSProperty("href", expected);
      expect(new URL("resume.pdf", page.url()).href).not.toBe(expected);
    }
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
  await expect(page.locator("html")).not.toHaveClass(/bootstrap-failed/);
  await expect(page.getByRole("heading", { level: 1 })).toHaveCount(1);
});
