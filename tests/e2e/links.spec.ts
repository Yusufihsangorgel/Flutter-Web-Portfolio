import { readFile } from "node:fs/promises";
import { resolve } from "node:path";
import { expect, Page, test } from "@playwright/test";

type PortfolioLinks = {
  profile: { links: Array<{ label: string; url: string }> };
};

async function profileUrl(label: string): Promise<string> {
  const portfolio = JSON.parse(
    await readFile(
      resolve(__dirname, "../../assets/content/portfolio.json"),
      "utf8",
    ),
  ) as PortfolioLinks;
  const url = portfolio.profile.links.find((link) => link.label === label)?.url;
  if (!url) throw new Error(`Missing ${label} profile link`);
  return url;
}

async function openRevealedPage(page: Page, hash = "") {
  await page.goto(`/${hash}`);
  await page.waitForSelector("flt-semantics-host", { state: "attached" });
  await expect(page.locator("#bootstrap-surface")).toHaveCount(0);
  await expect(page.getByRole("heading").first()).toBeAttached();
}

// Flutter drops semantics for content outside the viewport, so the footer's
// profile links only exist once the last chapter has been scrolled through.
async function openFooterProfileLinks(page: Page) {
  await openRevealedPage(page, "#/about");
  const viewport = page.viewportSize();
  await page.mouse.move((viewport?.width ?? 800) / 2, (viewport?.height ?? 600) / 2);
  const profileLinks = page.locator(
    `flt-semantics-host a[href^="https://github.com/"]`,
  );
  await expect
    .poll(
      async () => {
        if ((await profileLinks.count()) === 0) await page.mouse.wheel(0, 1600);
        return profileLinks.count();
      },
      { timeout: 20000, intervals: [250] },
    )
    .toBeGreaterThan(0);
}

// The persistent navigation on wide layouts, the menu overlay on narrow ones.
async function navigationLinks(page: Page) {
  const links = page.locator(
    `flt-semantics-host a[href*="#/"]:not([href$="#/"])`,
  );
  if ((await links.count()) === 0) {
    await page.getByRole("button", { name: "Open navigation menu" }).click();
  }
  await expect(links).not.toHaveCount(0);
  return links;
}

test("exposes the profile links as real anchors", async ({ page }) => {
  const expectedProfileUrl = await profileUrl("GitHub");
  await openFooterProfileLinks(page);

  const profileLinks = page.getByRole("link", { name: "GitHub", exact: true });
  await expect(profileLinks).not.toHaveCount(0);
  await expect(profileLinks.first()).toHaveAttribute("href", expectedProfileUrl);
});

test("exposes the navigation as real in-page anchors", async ({ page }) => {
  await openRevealedPage(page);
  const links = await navigationLinks(page);
  const href = await links.first().getAttribute("href");
  expect(href).not.toBeNull();
  expect(new URL(href!, page.url()).hash).toContain("#/");
});

test("a plain click on a navigation link stays inside the app", async ({
  page,
}) => {
  await openRevealedPage(page);
  const links = await navigationLinks(page);
  const href = await links.first().getAttribute("href");
  const expectedHash = new URL(href!, page.url()).hash;
  await page.evaluate(() => {
    const counter = window as unknown as { browserNavigations: number };
    counter.browserNavigations = 0;
    window.addEventListener("portfolio-popstate", () => {
      counter.browserNavigations += 1;
    });
  });
  const entriesBefore = await page.evaluate(() => history.length);

  await links.first().click();

  await expect
    .poll(() => page.evaluate(() => location.hash))
    .toBe(expectedHash);
  expect(await page.evaluate(() => history.length)).toBe(entriesBefore + 1);
  expect(
    await page.evaluate(
      () =>
        (window as unknown as { browserNavigations: number })
          .browserNavigations,
    ),
  ).toBe(0);
});

test("a modified click on a navigation link opens a new tab", async ({
  page,
  isMobile,
}) => {
  test.skip(isMobile, "Modifier clicks are a desktop pointer gesture.");
  await openRevealedPage(page);
  const links = await navigationLinks(page);
  const href = await links.first().getAttribute("href");
  const hashBefore = await page.evaluate(() => location.hash);

  const [opened] = await Promise.all([
    page.context().waitForEvent("page"),
    links.first().click({ modifiers: ["ControlOrMeta"] }),
  ]);

  // A popup reports about:blank until its navigation commits.
  await expect
    .poll(() => new URL(opened.url()).hash)
    .toBe(new URL(href!, page.url()).hash);
  expect(await page.evaluate(() => location.hash)).toBe(hashBefore);
});

test("an external profile link opens in a new tab", async ({ page }) => {
  const expectedProfileUrl = await profileUrl("GitHub");
  await page.context().route(`${expectedProfileUrl}**`, (route) =>
    route.fulfill({ contentType: "text/html", body: "<title>profile</title>" }),
  );
  await openFooterProfileLinks(page);
  const link = page
    .getByRole("link", { name: "GitHub", exact: true })
    .first();

  const [opened] = await Promise.all([
    page.context().waitForEvent("page"),
    link.click(),
  ]);

  await opened.waitForLoadState();
  expect(opened.url()).toBe(expectedProfileUrl);
  expect(new URL(page.url()).pathname).toBe("/");
});
