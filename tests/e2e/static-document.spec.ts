import { expect, test } from "@playwright/test";
import { readFileSync } from "node:fs";

type Linked = { url?: string };
type PortfolioContent = {
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
