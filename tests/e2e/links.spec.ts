import { expect, Page, test } from "./helpers/test_setup";
import {
  englishInterface,
  portfolio,
  required,
} from "./helpers/portfolio_test_helpers";
import { scrollToLocator } from "./helpers/semantics_scroll";

const profileLink = portfolio.profile.links.find((link) =>
  /^https?:\/\//.test(link.url),
);
const featured = required(
  portfolio.systems.find((system) => system.featured && system.evidence.length > 0),
  "featured case with evidence",
);
const featuredEvidence = required(featured.evidence[0], "featured evidence");

async function openRevealedPage(page: Page, hash = "") {
  await page.goto(`/${hash}`, { waitUntil: "domcontentloaded" });
  await page.waitForSelector("flt-semantics-host", {
    state: "attached",
    timeout: 20000,
  });
  await expect(page.locator("#bootstrap-surface")).toHaveCount(0, {
    timeout: 20000,
  });
  await expect(page.getByRole("heading").first()).toBeAttached();
}

// Flutter drops semantics for content outside the viewport, so the footer's
// profile anchors exist only once the last chapter has been scrolled through.
async function footerProfileAnchor(page: Page, url: string) {
  await openRevealedPage(page, "#/about");
  const viewport = page.viewportSize();
  await page.mouse.move(
    (viewport?.width ?? 800) / 2,
    (viewport?.height ?? 600) / 2,
  );
  return scrollToLocator(
    page,
    page.locator(`flt-semantics-host a[href="${url}"]`),
    900,
  );
}

async function featuredEvidenceAnchor(page: Page) {
  await openRevealedPage(page, "#/projects");
  const name = `${englishInterface.projects_section.open_evidence}: ${featured.name}, ${featuredEvidence.label}`;
  return scrollToLocator(
    page,
    page.locator("flt-semantics-host").getByRole("link", { name, exact: true }),
    900,
  );
}

// The persistent navigation on wide layouts, the menu overlay on narrow ones.
async function navigationLinks(page: Page, isMobile: boolean) {
  if (isMobile) {
    await page
      .getByRole("button", { name: "Open navigation menu", exact: true })
      .click();
  }
  const links = page.locator(
    `flt-semantics-host a[href*="#/"]:not([href$="#/"])`,
  );
  await expect(links.first()).toBeVisible();
  return links;
}

function hashOf(page: Page, href: string | null) {
  expect(href, "navigation anchor href").not.toBeNull();
  return new URL(href!, page.url()).hash;
}

test("exposes the profile links as real anchors", async ({ page }) => {
  test.skip(!profileLink, "the profile publishes no web link");
  const anchor = await footerProfileAnchor(page, profileLink!.url);

  await expect(anchor).toHaveAttribute("href", profileLink!.url);
  await expect(
    page.getByRole("link", { name: profileLink!.label, exact: true }),
  ).not.toHaveCount(0);
});

test("exposes the navigation as real in-page anchors", async ({
  page,
  isMobile,
}) => {
  await openRevealedPage(page);
  const links = await navigationLinks(page, isMobile);

  expect(hashOf(page, await links.first().getAttribute("href"))).toMatch(
    /^#\/[a-z]+$/,
  );
});

test("a plain click on a navigation link stays inside the app", async ({
  page,
  isMobile,
}) => {
  await openRevealedPage(page);
  const links = await navigationLinks(page, isMobile);
  const expectedHash = hashOf(page, await links.first().getAttribute("href"));
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
  await expect
    .poll(() => page.evaluate(() => history.length))
    .toBe(entriesBefore + 1);
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
  const links = await navigationLinks(page, isMobile);
  const expectedHash = hashOf(page, await links.first().getAttribute("href"));
  const hashBefore = await page.evaluate(() => location.hash);
  // Only the new tab's URL matters; answer its document without booting a second app.
  const origin = new URL(page.url()).origin;
  await page.context().route(
    (url) => url.origin === origin && url.pathname === "/",
    (route) =>
      route.request().resourceType() === "document"
        ? route.fulfill({ contentType: "text/html", body: "<title>tab</title>" })
        : route.fallback(),
  );

  const [opened] = await Promise.all([
    page.context().waitForEvent("page"),
    links.first().click({ modifiers: ["ControlOrMeta"] }),
  ]);

  // A popup reports about:blank until its navigation commits.
  await opened.waitForURL((url) => url.protocol !== "about:", {
    waitUntil: "commit",
  });
  expect(new URL(opened.url()).hash).toBe(expectedHash);
  expect(await page.evaluate(() => location.hash)).toBe(hashBefore);
  await opened.close();
});

test("featured evidence exposes its full name and real destination", async ({ page }) => {
  const anchor = await featuredEvidenceAnchor(page);
  await expect(anchor).toHaveAttribute("href", featuredEvidence.url);
});

test("modified click on featured evidence opens its destination in a new tab", async ({
  page,
  isMobile,
}) => {
  test.skip(isMobile, "Modifier clicks are a desktop pointer gesture.");
  const anchor = await featuredEvidenceAnchor(page);
  const hashBefore = await page.evaluate(() => location.hash);
  expect(hashBefore).toBe("#/projects");

  const destination = new URL(featuredEvidence.url);
  // Answer the external document locally; never request the live destination.
  await page.context().route(
    (url) => url.origin === destination.origin,
    (route) =>
      route.request().resourceType() === "document"
        ? route.fulfill({ contentType: "text/html", body: "<title>evidence</title>" })
        : route.abort(),
  );
  const [opened] = await Promise.all([
    page.context().waitForEvent("page"),
    anchor.click({ modifiers: ["ControlOrMeta"] }),
  ]);
  await opened.waitForURL((url) => url.protocol !== "about:", {
    waitUntil: "commit",
  });
  expect(opened.url()).toBe(destination.href);
  expect(await page.evaluate(() => location.hash)).toBe(hashBefore);
  await opened.close();
});

test("an external profile link opens in a new tab", async ({ page }) => {
  test.skip(!profileLink, "the profile publishes no web link");
  const expectedUrl = new URL(profileLink!.url).href;
  await page
    .context()
    .route(`${profileLink!.url}**`, (route) =>
      route.fulfill({
        contentType: "text/html",
        body: "<title>profile</title>",
      }),
    );
  const anchor = await footerProfileAnchor(page, profileLink!.url);

  const [opened] = await Promise.all([
    page.context().waitForEvent("page"),
    anchor.click(),
  ]);

  await opened.waitForURL((url) => url.protocol !== "about:", {
    waitUntil: "commit",
  });
  expect(opened.url()).toBe(expectedUrl);
  expect(new URL(page.url()).pathname).toBe("/");
});
