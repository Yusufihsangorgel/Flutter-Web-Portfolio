import { expect, test } from "@playwright/test";
import {
  expectHeadingInViewport,
  openChapterFromPalette,
  openPortfolio,
  portfolio,
} from "./helpers/portfolio_test_helpers";

test("preserves a direct chapter link without duplicating history", async ({
  page,
}) => {
  test.skip(portfolio.systems.length === 0, "work chapter is not authored");
  await page.goto("/#/projects", { waitUntil: "domcontentloaded" });
  const initialHistoryLength = await page.evaluate(() => history.length);
  await page.waitForSelector("flt-semantics-host", {
    state: "attached",
    timeout: 20000,
  });
  await expect(page.locator("#bootstrap-surface")).toHaveCount(0);
  await expect(page).toHaveURL(/#\/projects$/);
  await expectHeadingInViewport(page, "Selected Work");
  await expect
    .poll(() => page.evaluate(() => history.length))
    .toBe(initialHistoryLength);
});

test("canonicalizes an unknown chapter hash to the document origin", async ({
  page,
}) => {
  await page.goto("/#/unknown-chapter", { waitUntil: "domcontentloaded" });
  await page.waitForSelector("flt-semantics-host", {
    state: "attached",
    timeout: 20000,
  });
  await expect(page.locator("#bootstrap-surface")).toHaveCount(0);
  await expect.poll(() => page.evaluate(() => window.location.hash)).toBe("");
  await expectHeadingInViewport(
    page,
    `${portfolio.profile.display_name.accessible}, ${portfolio.profile.role}`,
  );
});

test("keeps explicit chapter navigation synchronized with history", async ({
  page,
}) => {
  test.skip(
    portfolio.experience.length === 0 || portfolio.systems.length === 0,
    "history contract requires authored experience and work chapters",
  );
  await openPortfolio(page);
  const initialHistoryLength = await page.evaluate(() => history.length);
  await openChapterFromPalette(
    page,
    "Go to Experience",
    /#\/experience$/,
    "Experience",
  );
  await openChapterFromPalette(
    page,
    "Go to Work",
    /#\/projects$/,
    "Selected Work",
  );
  await expect
    .poll(() => page.evaluate(() => history.length))
    .toBe(initialHistoryLength + 2);

  await page.goBack();
  await expect(page).toHaveURL(/#\/experience$/);
  await expectHeadingInViewport(page, "Experience");

  await page.goForward();
  await expect(page).toHaveURL(/#\/projects$/);
  await expectHeadingInViewport(page, "Selected Work");
});

test("does not mask chapter Back while the command palette is closing", async ({
  page,
}) => {
  test.skip(
    portfolio.experience.length === 0 || portfolio.systems.length === 0,
    "history contract requires authored experience and work chapters",
  );
  await openPortfolio(page);
  await openChapterFromPalette(
    page,
    "Go to Experience",
    /#\/experience$/,
    "Experience",
  );

  await page.keyboard.press("Control+KeyK");
  await page.getByText("Go to Work", { exact: true }).click();
  await expect(page).toHaveURL(/#\/projects$/);
  await page.evaluate(() => history.back());

  await expect(page).toHaveURL(/#\/experience$/);
  await expectHeadingInViewport(page, "Experience");
});

test("browser Back closes a command palette without consuming chapter history", async ({
  page,
}) => {
  test.skip(
    portfolio.experience.length === 0 || portfolio.systems.length === 0,
    "history contract requires authored experience and work chapters",
  );
  await openPortfolio(page);
  const initialHistoryLength = await page.evaluate(() => history.length);
  await openChapterFromPalette(
    page,
    "Go to Experience",
    /#\/experience$/,
    "Experience",
  );
  await openChapterFromPalette(
    page,
    "Go to Work",
    /#\/projects$/,
    "Selected Work",
  );

  await page.keyboard.press("Control+KeyK");
  const paletteCommand = page.getByText("Go to Experience", { exact: true });
  await expect(paletteCommand).toBeVisible();
  await page.evaluate(() => history.back());

  await expect(paletteCommand).not.toBeVisible();
  await expect(page).toHaveURL(/#\/projects$/);
  await expectHeadingInViewport(page, "Selected Work");
  await expect
    .poll(() => page.evaluate(() => history.length))
    .toBe(initialHistoryLength + 2);

  await page.evaluate(() => history.back());
  await expect(page).toHaveURL(/#\/experience$/);
  await expectHeadingInViewport(page, "Experience");
});

test("browser Back closes compact navigation without consuming chapter history", async ({
  page,
}, testInfo) => {
  test.skip(testInfo.project.name !== "mobile");
  test.skip(
    portfolio.experience.length === 0 || portfolio.systems.length === 0,
    "history contract requires authored experience and work chapters",
  );
  await openPortfolio(page);
  const initialHistoryLength = await page.evaluate(() => history.length);
  await openChapterFromPalette(
    page,
    "Go to Experience",
    /#\/experience$/,
    "Experience",
  );
  await openChapterFromPalette(
    page,
    "Go to Work",
    /#\/projects$/,
    "Selected Work",
  );

  await page
    .getByRole("button", { name: "Open navigation menu", exact: true })
    .click();
  const menuItem = page.getByRole("button", {
    name: "Experience",
    exact: true,
  });
  await expect(menuItem.last()).toBeVisible();
  await page.evaluate(() => history.back());

  await expect(menuItem.last()).not.toBeVisible();
  await expect(page).toHaveURL(/#\/projects$/);
  await expectHeadingInViewport(page, "Selected Work");
  await expect
    .poll(() => page.evaluate(() => history.length))
    .toBe(initialHistoryLength + 2);

  await page.evaluate(() => history.back());
  await expect(page).toHaveURL(/#\/experience$/);
  await expectHeadingInViewport(page, "Experience");
});
