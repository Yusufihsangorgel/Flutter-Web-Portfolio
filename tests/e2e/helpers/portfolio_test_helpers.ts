import { expect, Page } from "@playwright/test";
import { readFileSync } from "node:fs";
import type {
  InterfaceTestData,
  PortfolioSystem,
  PortfolioTestData,
} from "../../support/portfolio_test_data";
import { waitForFrames } from "./semantics_scroll";

export const portfolio = JSON.parse(
  readFileSync("assets/content/portfolio.json", "utf8"),
) as PortfolioTestData;
export const packageMetadata = JSON.parse(
  readFileSync("package.json", "utf8"),
) as { version: string };
export const englishInterface = JSON.parse(
  readFileSync("assets/i18n/en.json", "utf8"),
) as InterfaceTestData;
const rightToLeftLocales = new Set(["ar", "fa", "he", "ur"]);
export const bootstrapLocaleCases = (portfolio.site.locales as string[])
  .filter((locale) => locale !== "en")
  .map((locale) => ({
    locale,
    direction: rightToLeftLocales.has(locale) ? "rtl" : "ltr",
    content: JSON.parse(
      readFileSync(`assets/content/locales/${locale}.json`, "utf8"),
    ),
    interface: JSON.parse(readFileSync(`assets/i18n/${locale}.json`, "utf8")),
  }));
export const firstContentSection =
  portfolio.experience.length > 0
    ? "experience"
    : portfolio.contributions.length > 0
      ? "proof"
      : portfolio.systems.length > 0
        ? "projects"
        : "about";

export function required<T>(value: T | undefined, label: string): T {
  if (value === undefined) throw new Error(`Expected ${label}.`);
  return value;
}

export async function openPortfolio(
  page: Page,
  options: { timeout?: number; requireOk?: boolean } = {},
) {
  const response = await page.goto("/", { waitUntil: "domcontentloaded" });
  if (options.requireOk) expect(response?.status()).toBe(200);
  await page.waitForSelector("flt-semantics-host", {
    state: "attached",
    timeout: options.timeout ?? 20000,
  });
  // The surface leaves after the first frame, so it shares the boot budget.
  await expect(page.locator("#bootstrap-surface")).toHaveCount(0, {
    timeout: options.timeout ?? 20000,
  });
  await expect(page.getByRole("heading").first()).toBeAttached();
  await expect(page).toHaveTitle(portfolio.site.title);
  await expect(page.locator("html")).toHaveAttribute(
    "data-render-quality",
    /^(essential|balanced|full)$/,
  );
}

export async function readAccessibilityTree(page: Page) {
  const session = await page.context().newCDPSession(page);
  await session.send("Accessibility.enable");
  return session;
}

export async function expectHeadingInViewport(page: Page, name: string) {
  const heading = page.getByRole("heading", { name, exact: true });
  await expect(heading).toBeAttached();
  await expect
    .poll(async () => {
      const [box, viewport] = await Promise.all([
        heading.boundingBox(),
        page.evaluate(() => ({
          width: window.innerWidth,
          height: window.innerHeight,
        })),
      ]);
      return Boolean(
        box &&
          box.width > 0 &&
          box.height > 0 &&
          box.x < viewport.width &&
          box.x + box.width > 0 &&
          box.y < viewport.height &&
          box.y + box.height > 0,
      );
    })
    .toBe(true);
}

export async function focusActionWithKeyboard(
  page: Page,
  accessibleName: string,
) {
  for (let attempt = 0; attempt < 100; attempt += 1) {
    const focused = await page.evaluate((name) => {
      const active = document.activeElement;
      if (!(active instanceof HTMLElement)) return false;
      return (
        active.getAttribute("aria-label") === name ||
        active.textContent?.trim() === name
      );
    }, accessibleName);
    if (focused) return;
    await page.keyboard.press("Tab");
    // Let Flutter synchronize its focus event.
    await waitForFrames(page, 2);
  }
  throw new Error(`Keyboard focus never reached: ${accessibleName}`);
}

export async function openChapterFromPalette(
  page: Page,
  command: string,
  hash: RegExp,
  heading: string,
) {
  await page.keyboard.press("Control+KeyK");
  const commandItem = page.getByText(command, { exact: true });
  await expect(commandItem).toBeVisible();
  await commandItem.click();
  await expect(page).toHaveURL(hash);
  await expectHeadingInViewport(page, heading);
}

export async function openChapterFromNavigation(
  page: Page,
  options: {
    isMobile: boolean;
    control: string;
    hash: RegExp;
    heading: string;
  },
) {
  if (options.isMobile) {
    await page
      .getByRole("button", { name: "Open navigation menu", exact: true })
      .click();
  }
  const target = page.getByRole("link", {
    name: options.control,
    exact: true,
  });
  await (options.isMobile ? target.last() : target.first()).click();
  await expect(page).toHaveURL(options.hash);
  await expectHeadingInViewport(page, options.heading);
}

export function expectedArtifact(page: Page, system: PortfolioSystem) {
  // Match the artifact selected at the tablet breakpoint.
  const compactViewport = (page.viewportSize()?.width ?? 0) < 900;
  return compactViewport && system.artifact.compact
    ? system.artifact.compact
    : system.artifact;
}

export async function readRuntimeTimeline(page: Page) {
  return page.evaluate(() => {
    const names = [
      "flutter-bootstrap-start",
      "flutter-entrypoint-loaded",
      "flutter-engine-initialized",
      "flutter-first-frame-signal",
      "flutter-surface-reveal-start",
      "flutter-bootstrap-surface-removed",
    ];
    return names.map(
      (name) => performance.getEntriesByName(name, "mark").at(-1)?.startTime,
    );
  });
}

export async function readRevealSourceCount(page: Page) {
  return page.evaluate(() =>
    [
      "flutter-first-frame-event",
      "flutter-run-app-fallback",
      "flutter-glass-pane-fallback",
    ].reduce(
      (count, name) =>
        count + performance.getEntriesByName(name, "mark").length,
      0,
    ),
  );
}
