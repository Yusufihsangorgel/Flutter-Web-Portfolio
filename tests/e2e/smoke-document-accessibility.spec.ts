import { expect, test } from "./helpers/test_setup";
import {
  expectHeadingInViewport,
  openChapterFromPalette,
  openPortfolio,
  portfolio,
} from "./helpers/portfolio_test_helpers";
import { scrollToLocator, semanticsTree } from "./helpers/semantics_scroll";

test("keeps every professional chapter in one accessible document", async ({
  page,
}) => {
  test.skip(
    portfolio.experience.length === 0 ||
      portfolio.contributions.length === 0 ||
      portfolio.systems.length === 0,
    "optional professional chapters are absent in a clean template",
  );
  await openPortfolio(page);
  const chapters = [
    ["Go to About", /#\/about$/, "About"],
    ["Go to Experience", /#\/experience$/, "Experience"],
    ["Go to Open Source", /#\/proof$/, "Open Source"],
    ["Go to Work", /#\/projects$/, "Selected Work"],
  ] as const;

  for (const [command, hash, heading] of chapters) {
    await openChapterFromPalette(page, command, hash, heading);
  }

  await openChapterFromPalette(
    page,
    "Go to Experience",
    /#\/experience$/,
    "Experience",
  );
  await expect(
    semanticsTree(page).getByText(portfolio.experience[0].company).first(),
  ).toBeAttached();
});

test("keeps the personal hero readable at 280 CSS pixels", async ({
  page,
  isMobile,
}) => {
  test.skip(isMobile, "one browser project covers the ultra-narrow contract");
  test.skip(
    portfolio.systems.length === 0,
    "the clean-template hero intentionally has no work action",
  );
  await page.setViewportSize({ width: 280, height: 653 });
  await page.emulateMedia({ reducedMotion: "reduce" });
  await openPortfolio(page);

  const heading = page.getByRole("heading", {
    name: `${portfolio.profile.display_name.accessible}, ${portfolio.profile.role}`,
  });
  await expectHeadingInViewport(
    page,
    `${portfolio.profile.display_name.accessible}, ${portfolio.profile.role}`,
  );
  const headingBox = await heading.boundingBox();
  expect(headingBox).not.toBeNull();
  expect(headingBox!.x).toBeGreaterThanOrEqual(0);
  expect(headingBox!.x + headingBox!.width).toBeLessThanOrEqual(280);

  for (const label of ["Explore my work", "Email me"]) {
    const action = page.getByRole("link", { name: label, exact: true });
    await scrollToLocator(page, action, 160);
    await expect(action).toBeVisible();
    const actionBox = await action.boundingBox();
    expect(actionBox, label).not.toBeNull();
    expect(actionBox!.x, label).toBeGreaterThanOrEqual(0);
    expect(actionBox!.x + actionBox!.width, label).toBeLessThanOrEqual(280);
  }
});
