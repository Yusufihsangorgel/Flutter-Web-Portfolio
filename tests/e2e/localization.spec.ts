import { expect, Locator, Page, test } from "@playwright/test";
import { readFileSync } from "node:fs";
import {
  scrollAndSettle,
  semanticsTree,
  waitForSemanticsSettled,
} from "./helpers/semantics_scroll";

type PortfolioSystem = {
  id: string;
  featured: boolean;
  kind: string;
  year: string;
  technologies: string[];
  artifact: {
    caption: string;
    compact: { caption: string };
  };
};

type PortfolioData = {
  site: { locales: string[]; title: string };
  profile: {
    role: string;
    headline: string;
    display_name: { accessible: string };
  };
  experience: unknown[];
  contributions: unknown[];
  systems: PortfolioSystem[];
};

type InterfaceCatalog = {
  about_section: { title: string };
  experience_section: { title: string };
  proof_section: { title: string };
  projects_section: { title: string };
};

type ContentChapter = "about" | "experience" | "proof" | "projects";

type ContentCatalog = {
  site: { title: string };
  profile: { role: string; headline: string };
  systems: Record<
    string,
    {
      kind: string;
      year: string;
      technologies: string[];
      artifact: { caption: string; compact_caption: string };
    }
  >;
};

const portfolio = JSON.parse(
  readFileSync("assets/content/portfolio.json", "utf8"),
) as PortfolioData;
const nativeLanguageNames = {
  en: "English",
  tr: "Türkçe",
  de: "Deutsch",
  fr: "Français",
  es: "Español",
  ar: "العربية",
  hi: "हिन्दी",
} as const;
type LocaleCode = keyof typeof nativeLanguageNames;
const localeCodes = (portfolio.site.locales as string[]).map((locale) => {
  if (!(locale in nativeLanguageNames)) {
    throw new Error(`No native language label is defined for ${locale}.`);
  }
  return locale as LocaleCode;
});
const activeSections = [
  "home",
  ...(portfolio.experience.length > 0 ? ["experience"] : []),
  ...(portfolio.contributions.length > 0 ? ["proof"] : []),
  ...(portfolio.systems.length > 0 ? ["projects"] : []),
  "about",
] as const;
const preservedChapter = (
  activeSections.includes("projects")
    ? "projects"
    : activeSections.find((section) => section !== "home")
) as ContentChapter;

const interfaceCatalogs = Object.fromEntries(
  localeCodes.map((locale) => [
    locale,
    JSON.parse(readFileSync(`assets/i18n/${locale}.json`, "utf8")),
  ]),
) as Record<LocaleCode, InterfaceCatalog>;

const contentCatalogs = Object.fromEntries(
  localeCodes
    .filter((locale) => locale !== "en")
    .map((locale) => [
      locale,
      JSON.parse(readFileSync(`assets/content/locales/${locale}.json`, "utf8")),
    ]),
) as Partial<Record<LocaleCode, ContentCatalog>>;

function localizedRecord(locale: LocaleCode) {
  const localization = contentCatalogs[locale];
  const featuredSystem = portfolio.systems.find((system) => system.featured);

  if (locale === "en" || !localization) {
    return {
      title: portfolio.site.title as string,
      role: portfolio.profile.role as string,
      headline: portfolio.profile.headline as string,
      systemKind: featuredSystem?.kind as string | undefined,
      systemYear: featuredSystem?.year as string | undefined,
      systemTechnologies: featuredSystem?.technologies as string[] | undefined,
      artifactCaption: featuredSystem?.artifact.caption as string | undefined,
      compactCaption: featuredSystem?.artifact.compact.caption as
        string | undefined,
    };
  }

  const system = featuredSystem
    ? localization.systems[featuredSystem.id]
    : undefined;
  return {
    title: localization.site.title as string,
    role: localization.profile.role as string,
    headline: localization.profile.headline as string,
    systemKind: system?.kind as string | undefined,
    systemYear: system?.year as string | undefined,
    systemTechnologies: system?.technologies as string[] | undefined,
    artifactCaption: system?.artifact.caption as string | undefined,
    compactCaption: system?.artifact.compact_caption as string | undefined,
  };
}

async function waitForPortfolio(page: Page) {
  await page.waitForSelector("flt-semantics-host", {
    state: "attached",
    timeout: 20000,
  });
  // The surface leaves after the first frame, so it shares the boot budget.
  await expect(page.locator("#bootstrap-surface")).toHaveCount(0, {
    timeout: 20000,
  });
  await expect(page.getByRole("heading").first()).toBeAttached();
}

async function expectDocumentLocale(page: Page, locale: LocaleCode) {
  await expect(page.locator("html")).toHaveAttribute("lang", locale);
  await expect(page.locator("html")).toHaveAttribute(
    "dir",
    locale === "ar" ? "rtl" : "ltr",
  );
  await expect(page).toHaveTitle(localizedRecord(locale).title);
}

async function switchLocale(
  page: Page,
  current: LocaleCode,
  target: LocaleCode,
) {
  const escapedName = nativeLanguageNames[current].replace(
    /[.*+?^${}()|[\]\\]/g,
    "\\$&",
  );
  await page
    .getByRole("button", { name: new RegExp(`: ${escapedName}$`) })
    .click();
  const targetItem = page.getByRole("menuitem", {
    name: `${target.toUpperCase()} ${nativeLanguageNames[target]}`,
    exact: true,
  });
  await Promise.all([
    page.waitForNavigation({ waitUntil: "domcontentloaded" }),
    targetItem.click(),
  ]);
  await waitForPortfolio(page);
  await expectDocumentLocale(page, target);
}

async function navigateToChapter(page: Page, chapter: "home" | ContentChapter) {
  await page.evaluate((target) => {
    const hash = target === "home" ? "#/" : `#/${target}`;
    window.history.pushState(null, "", hash);
    window.dispatchEvent(new Event("portfolio-popstate"));
  }, chapter);
  await expect(page).toHaveURL(
    chapter === "home" ? /#\/$/ : new RegExp(`#/${chapter}$`),
  );
}

function chapterHeading(locale: LocaleCode, chapter: ContentChapter) {
  const catalog = interfaceCatalogs[locale];
  switch (chapter) {
    case "about":
      return catalog.about_section.title;
    case "experience":
      return catalog.experience_section.title;
    case "proof":
      return catalog.proof_section.title;
    case "projects":
      return catalog.projects_section.title;
  }
}

async function expectNoHorizontalOverflow(page: Page) {
  await expect
    .poll(() =>
      page.evaluate(
        () =>
          document.documentElement.scrollWidth <=
          document.documentElement.clientWidth + 1,
      ),
    )
    .toBe(true);
}

async function expectInViewport(page: Page, locator: Locator) {
  await expect(locator).toBeAttached();
  await expect
    .poll(async () => {
      const [box, viewport] = await Promise.all([
        locator.boundingBox(),
        pageSize(page),
      ]);
      return Boolean(
        box &&
        box.width > 0 &&
        box.height > 0 &&
        box.y < viewport.height &&
        box.y + box.height > 0,
      );
    })
    .toBe(true);
}

async function pageSize(page: Page) {
  return page.evaluate(() => ({
    width: window.innerWidth,
    height: window.innerHeight,
  }));
}

async function revealText(page: Page, text: string) {
  await waitForSemanticsSettled(page);
  for (let attempt = 0; attempt < 80; attempt += 1) {
    const semanticGroup = page.getByRole("group", {
      name: new RegExp(text.replace(/[.*+?^${}()|[\]\\]/g, "\\$&"), "i"),
    });
    const authored = semanticsTree(page).getByText(text, { exact: false });
    const upper = semanticsTree(page).getByText(text.toUpperCase(), {
      exact: false,
    });
    if ((await semanticGroup.count()) > 0) return semanticGroup.first();
    if ((await authored.count()) > 0) return authored.first();
    if ((await upper.count()) > 0) return upper.first();
    await scrollAndSettle(page, 360);
  }
  throw new Error(`Localized text never entered the semantics tree: ${text}`);
}

type LocalizedRecord = ReturnType<typeof localizedRecord>;

function collectRuntimeErrors(page: Page) {
  const errors: string[] = [];
  page.on("pageerror", (error) => errors.push(`pageerror: ${error.message}`));
  page.on("console", (message) => {
    if (message.type() === "error") errors.push(`console: ${message.text()}`);
  });
  page.on("response", (response) => {
    if (response.status() >= 400) {
      errors.push(`HTTP ${response.status()} ${response.url()}`);
    }
  });
  return errors;
}
async function assertLocalizedHome(
  page: Page,
  locale: LocaleCode,
  expected: LocalizedRecord,
) {
  await navigateToChapter(page, "home");
  const heading = page.getByRole("heading", {
    name: `${portfolio.profile.display_name.accessible}, ${expected.role}`,
    exact: true,
  });
  await expectInViewport(page, heading);
  const semantics = semanticsTree(page);
  await expect(
    semantics.getByText(expected.headline, { exact: true }),
  ).toBeAttached();
  if (locale !== "en") {
    await expect(
      semantics.getByText(portfolio.profile.headline, { exact: true }),
    ).toHaveCount(0);
    await expect(
      semantics.getByText(portfolio.profile.role, { exact: true }),
    ).toHaveCount(0);
  }
  await expectNoHorizontalOverflow(page);
}

async function assertNoEnglishProjectCopy(page: Page, expected: LocalizedRecord) {
  const semantics = semanticsTree(page);
  await expect(
    semantics.getByText(portfolio.systems[0].kind, { exact: true }),
  ).toHaveCount(0);
  if (portfolio.systems[0].year !== expected.systemYear) {
    await expect(
      semantics.getByText(portfolio.systems[0].year, { exact: true }),
    ).toHaveCount(0);
  }
  for (const technology of portfolio.systems[0].technologies) {
    if (!expected.systemTechnologies!.includes(technology)) {
      await expect(
        semantics.getByText(technology, { exact: true }),
      ).toHaveCount(0);
    }
  }
  await expect(
    semantics.getByText(portfolio.systems[0].artifact.caption, { exact: true }),
  ).toHaveCount(0);
}

async function assertLocalizedProjects(
  page: Page,
  locale: LocaleCode,
  expected: LocalizedRecord,
  interfaceCopy: InterfaceCatalog,
) {
  if (portfolio.systems.length === 0) return;
  await navigateToChapter(page, "projects");
  const heading = page.getByRole("heading", {
    name: interfaceCopy.projects_section.title,
    exact: true,
  });
  await expectInViewport(page, heading);
  await expect(await revealText(page, expected.systemKind!)).toBeAttached();
  await expect(await revealText(page, expected.systemYear!)).toBeAttached();
  for (const technology of expected.systemTechnologies!) {
    await expect(await revealText(page, technology)).toBeAttached();
  }
  const compact = (page.viewportSize()?.width ?? 1440) < 900;
  const caption = compact ? expected.compactCaption! : expected.artifactCaption!;
  await expect(await revealText(page, caption)).toBeAttached();
  if (locale !== "en") await assertNoEnglishProjectCopy(page, expected);
  await expectNoHorizontalOverflow(page);
}

async function assertReloadAndHistory(page: Page, locale: LocaleCode) {
  await page.reload({ waitUntil: "domcontentloaded" });
  await waitForPortfolio(page);
  await expectDocumentLocale(page, locale);
  if (portfolio.systems.length > 0) {
    await expect(page).toHaveURL(/#\/projects$/);
    await page.goBack();
    await expect(page).toHaveURL(/#\/$/);
    await expectDocumentLocale(page, locale);
    await page.goForward();
    await expect(page).toHaveURL(/#\/projects$/);
    await expectDocumentLocale(page, locale);
    return;
  }
  await expect
    .poll(() => page.evaluate(() => window.location.hash))
    .toMatch(/^(?:|#\/)$/);
}

test.describe("complete portfolio localization", () => {
  test.setTimeout(240000);

  test("preserves the active chapter while switching locales", async ({
    page,
  }) => {
    test.skip(
      !localeCodes.includes("tr") || !localeCodes.includes("ar"),
      "the initialized portfolio exposes only its authored locales",
    );
    await page.emulateMedia({ reducedMotion: "reduce" });
    await page.goto("/#/", { waitUntil: "domcontentloaded" });
    await waitForPortfolio(page);

    await navigateToChapter(page, preservedChapter);
    await switchLocale(page, "en", "tr");
    await expect(page).toHaveURL(new RegExp(`#/${preservedChapter}$`));
    await expect(
      page.getByRole("heading", {
        name: chapterHeading("tr", preservedChapter),
        exact: true,
      }),
    ).toBeAttached();

    await switchLocale(page, "tr", "ar");
    await expect(page).toHaveURL(new RegExp(`#/${preservedChapter}$`));
    await expect(
      page.getByRole("heading", {
        name: chapterHeading("ar", preservedChapter),
        exact: true,
      }),
    ).toBeAttached();
  });

  for (const locale of localeCodes) {
    test(`keeps ${locale} complete across reload and history`, async ({ page }) => {
      const errors = collectRuntimeErrors(page);
      await page.emulateMedia({ reducedMotion: "reduce" });
      await page.goto("/#/", { waitUntil: "domcontentloaded" });
      await waitForPortfolio(page);
      if (locale !== "en") await switchLocale(page, "en", locale);
      const expected = localizedRecord(locale);
      await expectDocumentLocale(page, locale);
      await assertLocalizedHome(page, locale, expected);
      await assertLocalizedProjects(
        page,
        locale,
        expected,
        interfaceCatalogs[locale],
      );
      await assertReloadAndHistory(page, locale);
      expect(errors).toEqual([]);
    });
  }
});
