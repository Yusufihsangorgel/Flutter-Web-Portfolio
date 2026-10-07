import { expect, test } from "./helpers/test_setup";
import type { CDPSession, Page } from "@playwright/test";
import {
  englishInterface,
  expectHeadingInViewport,
  firstContentSection,
  focusActionWithKeyboard,
  openChapterFromNavigation,
  openChapterFromPalette,
  openPortfolio,
  portfolio,
  readAccessibilityTree,
  required,
} from "./helpers/portfolio_test_helpers";
import {
  scrollToSemanticLink,
  waitForFrames,
  waitForSemanticsSettled,
} from "./helpers/semantics_scroll";

async function assertInitialHierarchy(
  page: Page,
  isMobile: boolean,
  accessibility: CDPSession,
) {
  await expect(page.locator("html")).toHaveAttribute(
    "data-render-quality",
    "essential",
  );
  await expect(page.locator("html")).toHaveAttribute(
    "data-render-quality-reason",
    "reducedMotion",
  );
  const tree = await accessibility.send("Accessibility.getFullAXTree");
  const nodes = tree.nodes.filter((node) => !node.ignored);
  const headings = nodes
    .filter((node) => node.role?.value === "heading")
    .map((node) => ({
      name: node.name?.value ?? "",
      level: node.properties?.find((property) => property.name === "level")
        ?.value?.value,
    }));
  const controls = nodes
    .filter((node) => ["button", "link"].includes(node.role?.value ?? ""))
    .map((node) => node.name?.value ?? "");
  expect(headings).toContainEqual({
    name: `${portfolio.profile.display_name.accessible}, ${portfolio.profile.role}`,
    level: 1,
  });
  expect(controls).toEqual(
    expect.arrayContaining([
      "Skip to content",
      "Go to home",
      ...(isMobile
        ? ["Open navigation menu"]
        : ["About", "Experience", "Open Source", "Work"]),
      "Language menu: English",
    ]),
  );
  expect(controls.every((name) => name.trim().length > 0)).toBe(true);
  expect(controls.join("\n")).not.toMatch(
    /Profile PROFILE|Show menu|Scroll to top|🇬🇧/,
  );
}

async function assertAboutHierarchy(page: Page, accessibility: CDPSession) {
  const tree = await accessibility.send("Accessibility.getFullAXTree");
  const heading = tree.nodes.find(
    (node) =>
      !node.ignored &&
      node.role?.value === "heading" &&
      node.name?.value === "About",
  );
  expect(
    heading?.properties?.find((property) => property.name === "level")?.value
      ?.value,
  ).toBe(2);
  await scrollToSemanticLink(page, portfolio.profile.links[0].label);
  const linksTree = await accessibility.send("Accessibility.getFullAXTree");
  const links = linksTree.nodes
    .filter((node) => !node.ignored && node.role?.value === "link")
    .map((node) => node.name?.value ?? "");
  expect(links).toEqual(
    expect.arrayContaining(portfolio.profile.links.map((link) => link.label)),
  );
}

async function assertContributionHierarchy(
  page: Page,
  isMobile: boolean,
  accessibility: CDPSession,
) {
  await openChapterFromNavigation(page, {
    isMobile,
    control: "Open Source",
    hash: /#\/proof$/,
    heading: "Open Source",
  });
  const contribution = required(
    portfolio.contributions.find((item) => item.featured) ??
      portfolio.contributions[0],
    "a visible contribution",
  );
  expect(contribution).toBeTruthy();
  await scrollToSemanticLink(page, contribution.title);
  const tree = await accessibility.send("Accessibility.getFullAXTree");
  const links = tree.nodes
    .filter((node) => !node.ignored && node.role?.value === "link")
    .map((node) => node.name?.value ?? "");
  const status = contribution.status === "merged" ? "Merged" : "Under review";
  expect(links).toEqual(
    expect.arrayContaining([
      expect.stringContaining(
        `View pull request. ${contribution.title}. ${contribution.project}. ${status}.`,
      ),
    ]),
  );
}

async function assertProjectHierarchy(
  page: Page,
  isMobile: boolean,
  accessibility: CDPSession,
) {
  await openChapterFromNavigation(page, {
    isMobile,
    control: "Work",
    hash: /#\/projects$/,
    heading: "Selected Work",
  });
  const tree = await accessibility.send("Accessibility.getFullAXTree");
  const links = tree.nodes
    .filter((node) => !node.ignored && node.role?.value === "link")
    .map((node) => node.name?.value ?? "");
  const system = required(
    portfolio.systems.find((item) => item.featured),
    "a featured system",
  );
  expect(system).toBeTruthy();
  const evidenceLabel = `${englishInterface.projects_section.open_evidence}: ${system.name}, ${system.evidence[0].label}`;
  await scrollToSemanticLink(page, evidenceLabel);
  const visibleTree = await accessibility.send("Accessibility.getFullAXTree");
  const visibleLinks = visibleTree.nodes
    .filter((node) => !node.ignored && node.role?.value === "link")
    .map((node) => node.name?.value ?? "");
  expect(visibleLinks).toEqual(expect.arrayContaining([evidenceLabel]));
  expect(links).not.toEqual(
    expect.arrayContaining([expect.stringContaining("Open project:")]),
  );
  expect(links).not.toContain("View source");
  expect(links).not.toContain("Website");
}

test("publishes a clean heading and control hierarchy", async ({
  page,
  isMobile,
}) => {
  test.skip(
    portfolio.experience.length === 0 ||
      portfolio.contributions.length === 0 ||
      portfolio.systems.length === 0,
    "optional professional chapters are absent in a clean template",
  );
  await page.emulateMedia({ reducedMotion: "reduce" });
  const accessibility = await readAccessibilityTree(page);
  await openPortfolio(page);
  await assertInitialHierarchy(page, isMobile, accessibility);
  if (isMobile) {
    await page
      .getByRole("button", { name: "Open navigation menu", exact: true })
      .click();
  }
  const aboutControl = page.getByRole("link", {
    name: "About",
    exact: true,
  });
  await (isMobile ? aboutControl.last() : aboutControl.first()).click();
  await expect(page).toHaveURL(/#\/about$/);
  await expect(page.getByRole("heading", { name: "About" })).toBeAttached();
  await assertAboutHierarchy(page, accessibility);
  await assertContributionHierarchy(page, isMobile, accessibility);
  await assertProjectHierarchy(page, isMobile, accessibility);
});

test("the first Tab reveals the skip link, which enters the main document", async ({
  page,
  isMobile,
}) => {
  test.skip(
    isMobile,
    "hardware-keyboard traversal is covered by the desktop browser project",
  );
  // Still chrome, so only the skip link can change the pixels below.
  await page.emulateMedia({ reducedMotion: "reduce" });
  await openPortfolio(page);
  const skipLink = page.getByRole("button", {
    name: englishInterface.accessibility.skip_to_content,
    exact: true,
  });
  await expect(skipLink).toBeAttached();
  const area = required(
    (await skipLink.boundingBox()) ?? undefined,
    "skip link geometry",
  );
  const hiddenPixels = await page.screenshot({ clip: area });

  await page.keyboard.press("Tab");

  await expect(skipLink).toBeFocused();
  // The pixels under the link change only if it is painted above the chrome.
  await expect
    .poll(async () => {
      const pixels = await page.screenshot({ clip: area });
      return !pixels.equals(hiddenPixels);
    })
    .toBe(true);
  await page.keyboard.press("Enter");

  if (firstContentSection !== "about") {
    await expect(page).toHaveURL(new RegExp(`#/${firstContentSection}$`));
  }
  const target = page.locator('[flt-semantics-identifier="main-content"]');
  await expect(target).toBeInViewport();
  await expect(target).toBeFocused();
  await waitForFrames(page, 2);
  await expect(target).toBeFocused();
});

test("back-to-top is a keyboard link that follows on Enter only", async ({
  page,
  isMobile,
}) => {
  test.skip(
    isMobile,
    "hardware-keyboard traversal is covered by the desktop browser project",
  );
  test.skip(
    portfolio.experience.length === 0 || portfolio.systems.length === 0,
    "the authored navigation path requires experience and work chapters",
  );
  await openPortfolio(page);
  const backToTop = page.getByRole("link", {
    name: englishInterface.accessibility.back_to_top,
    exact: true,
  });
  await expect(backToTop).toHaveCount(0);
  await openChapterFromPalette(
    page,
    "Go to Work",
    /#\/projects$/,
    "Selected Work",
  );
  await expect(backToTop).toBeVisible();
  await focusActionWithKeyboard(
    page,
    englishInterface.accessibility.back_to_top,
  );

  // Space is not a link activation key, so the document must not move.
  const settled = await waitForSemanticsSettled(page);
  const hashBeforeSpace = await page.evaluate(() => location.hash);
  await page.keyboard.press("Space");
  expect(await waitForSemanticsSettled(page)).toBe(settled);
  expect(await page.evaluate(() => location.hash)).toBe(hashBeforeSpace);
  await expect(backToTop).toBeVisible();

  await page.keyboard.press("Enter");
  await expect(page).toHaveURL(/#\/$/);
  await expect(backToTop).toHaveCount(0);
  await expectHeadingInViewport(
    page,
    `${portfolio.profile.display_name.accessible}, ${portfolio.profile.role}`,
  );
});

test("back-to-top activates from the compact touch layout", async ({
  page,
  isMobile,
}) => {
  test.skip(!isMobile, "compact touch control belongs to the mobile project");
  await openPortfolio(page);
  await openChapterFromNavigation(page, {
    isMobile: true,
    control: "Work",
    hash: /#\/projects$/,
    heading: "Selected Work",
  });
  const backToTop = page.getByRole("link", {
    name: englishInterface.accessibility.back_to_top,
    exact: true,
  });
  await expect(backToTop).toBeVisible();
  await backToTop.click();
  await expect(page).toHaveURL(/#\/$/);
  await expect(backToTop).toHaveCount(0);
});
