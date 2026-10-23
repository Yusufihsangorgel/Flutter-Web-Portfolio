import { readFile } from "node:fs/promises";
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

async function openRevealedPage(page: Page, hash = "", path = "/") {
  await page.goto(`${path}${hash}`, { waitUntil: "domcontentloaded" });
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

const resumeHref = 'resume.pdf';

async function builtResumeUrl(page: Page) {
  return page.evaluate((href) => new URL(href, document.baseURI).href, resumeHref);
}

async function expectResumePopup(
  page: Page,
  anchor: ReturnType<Page['locator']>,
  resumeUrl: string,
) {
  const sourceUrl = page.url();
  // Chromium opens a blank viewer tab and downloads the PDF on the source page.
  const [opened, download] = await Promise.all([
    page.context().waitForEvent('page', { timeout: 15000 }),
    page.waitForEvent('download', { timeout: 15000 }),
    anchor.click(),
  ]);
  expect(opened).not.toBe(page);
  expect(download.url()).toBe(resumeUrl);
  expect((await readFile(await download.path())).subarray(0, 5).toString()).toBe('%PDF-');
  await expect(anchor).toHaveAttribute('target', '_blank');
  expect(page.url()).toBe(sourceUrl);
  await opened.close();
}

test('exposes the enabled resume in the hero and footer as real anchors', async ({ page }) => {
  test.skip(portfolio.site.resume_enabled !== true, 'the content disables the resume');
  await openRevealedPage(page);
  const resumeUrl = await builtResumeUrl(page);
  const anchor = page.locator(`flt-semantics-host a[href="${resumeUrl}"]`);
  await expect(anchor).toHaveCount(1);
  await expect(anchor).toHaveAccessibleName(englishInterface.documents.resume_pdf);
  await expect(anchor).toHaveAttribute('href', resumeUrl);
  const footerAnchor = await footerProfileAnchor(page, resumeUrl);
  await expect(footerAnchor).toHaveAccessibleName(englishInterface.documents.resume_pdf);
  await expect(footerAnchor).toHaveAttribute('href', resumeUrl);
  await expectResumePopup(page, footerAnchor, resumeUrl);
});

test('a deep document URL still links to the document-base PDF', async ({ page }) => {
  test.skip(portfolio.site.resume_enabled !== true, 'the content disables the resume');
  // Serve the real root document at a deep URL, as a history-fallback host does.
  // Its <base> stays at / while location.pathname is /portfolio/deep/.
  await page.route('**/portfolio/deep/', async (route) => {
    const root = new URL('/', route.request().url());
    await route.fulfill({ response: await route.fetch({ url: root.href }) });
  });
  await openRevealedPage(page, '', '/portfolio/deep/');
  const resumeUrl = await builtResumeUrl(page);
  expect(new URL(resumeUrl).pathname).toBe('/resume.pdf');
  expect(new URL(resumeHref, page.url()).href).not.toBe(resumeUrl);
  const anchor = page.locator(`flt-semantics-host a[href="${resumeUrl}"]`);
  await expect(anchor).toHaveCount(1);
  await expect(anchor).toHaveAccessibleName(englishInterface.documents.resume_pdf);
  await expect(anchor).toHaveAttribute('href', resumeUrl);
  await expectResumePopup(page, anchor, resumeUrl);
});

test('a Pages deep URL links to the PDF under its document base', async ({ page }, testInfo) => {
  test.skip(portfolio.site.resume_enabled !== true, 'the content disables the resume');
  const origin = new URL(testInfo.project.use.baseURL as string).origin;
  // A popup's first request bypasses page.route; serve its real PDF via the context.
  await page.context().route(
    (url) => url.origin === origin && url.pathname === '/portfolio/resume.pdf',
    async (route) => {
      const query = new URL(route.request().url()).search;
      await route.fulfill({ response: await route.fetch({ url: `${origin}/resume.pdf${query}` }) });
    },
  );
  await page.route(
    (url) => url.origin === origin && url.pathname.startsWith('/portfolio/'),
    async (route) => {
      const requested = new URL(route.request().url());
      const path = requested.pathname.slice('/portfolio'.length);
      const rootPath = path === '/deep/' ? '/' : path;
      const response = await route.fetch({ url: `${origin}${rootPath}${requested.search}` });
      if (path === '/deep/' && route.request().resourceType() === 'document') {
        const html = await response.text();
        expect(html).toContain('<base href="/">');
        await route.fulfill({
          response,
          body: html.replace('<base href="/">', '<base href="/portfolio/">'),
        });
        return;
      }
      await route.fulfill({ response });
    },
  );

  await openRevealedPage(page, '', '/portfolio/deep/');
  const resumeUrl = await builtResumeUrl(page);
  expect(resumeUrl).toBe(`${origin}/portfolio/resume.pdf`);
  const anchor = page.locator(`flt-semantics-host a[href="${resumeUrl}"]`);
  await expect(anchor).toHaveCount(1);
  await expect(anchor).toHaveAccessibleName(englishInterface.documents.resume_pdf);
  await expect(anchor).toHaveAttribute('href', resumeUrl);
  await expectResumePopup(page, anchor, resumeUrl);
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

test('the resume link opens the built PDF in a new tab', async ({ page }) => {
  test.skip(portfolio.site.resume_enabled !== true, 'the content disables the resume');
  await openRevealedPage(page);
  const resumeUrl = await builtResumeUrl(page);
  const response = await page.request.get(resumeUrl);
  expect(response.ok()).toBe(true);
  expect(response.headers()['content-type']).toContain('application/pdf');
  const pdfBytes = await response.body();
  expect(pdfBytes.subarray(0, 5).toString()).toBe('%PDF-');
  const anchor = page.locator(`flt-semantics-host a[href="${resumeUrl}"]`);
  await expect(anchor).toHaveAccessibleName(englishInterface.documents.resume_pdf);
  await expect(anchor).toHaveAttribute('href', resumeUrl);
  const sourceUrl = page.url();

  // Chromium downloads PDFs while opening a blank tab for the viewer.
  // Observe both effects without assuming that the viewer commits a URL.
  const [opened, download] = await Promise.all([
    page.context().waitForEvent('page'),
    page.waitForEvent('download'),
    anchor.click(),
  ]);

  expect(opened).not.toBe(page);
  await expect(anchor).toHaveAttribute('target', '_blank');
  expect(download.url()).toBe(resumeUrl);
  expect(download.suggestedFilename()).toBe('resume.pdf');
  expect(await readFile(await download.path())).toEqual(pdfBytes);
  expect(page.url()).toBe(sourceUrl);
  await opened.close();
});
