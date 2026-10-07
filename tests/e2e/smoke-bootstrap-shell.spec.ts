import { expect, test } from "@playwright/test";
import type { Locator, Page } from "@playwright/test";
import {
  bootstrapLocaleCases,
  englishInterface,
  portfolio,
  required,
} from "./helpers/portfolio_test_helpers";

type BootstrapLocale = (typeof bootstrapLocaleCases)[number];
type CriticalScriptFont = { family: string; href: string };

function scriptFontFor(locale: string): CriticalScriptFont | undefined {
  if (locale === "ar") {
    return {
      family: "Noto Sans Arabic Critical",
      href: "assets/assets/fonts/noto_sans_arabic/NotoSansArabic-Variable.ttf",
    };
  }
  if (locale === "hi") {
    return {
      family: "Noto Sans Devanagari Critical",
      href: "assets/assets/fonts/noto_sans_devanagari/NotoSansDevanagari-Variable.ttf",
    };
  }
  return undefined;
}

async function expectArabicTitleOrder(shell: Locator) {
  const [primary, accent] = await Promise.all([
    shell.locator(".bootstrap-title > span").first().boundingBox(),
    shell.locator(".bootstrap-title-accent").boundingBox(),
  ]);
  expect(primary).not.toBeNull();
  expect(accent).not.toBeNull();
  expect(primary!.x).toBeLessThan(accent!.x);
}

async function expectCriticalFont(page: Page, shell: Locator, font: CriticalScriptFont) {
  await expect(
    page.locator(`head link[rel="preload"][as="font"][href$="${font.href}"]`),
  ).toHaveCount(1);
  const fonts = await shell.evaluate((element) => ({
    rail: getComputedStyle(element.querySelector(".bootstrap-rail")!).fontFamily,
    statement: getComputedStyle(
      element.querySelector(".bootstrap-statement")!,
    ).fontFamily,
    title: getComputedStyle(element.querySelector(".bootstrap-title")!)
      .fontFamily,
  }));
  expect(fonts.rail).toContain(font.family);
  expect(fonts.statement).toContain(font.family);
  expect(fonts.title).toContain("Space Grotesk Critical");
  expect(fonts.title).not.toContain(font.family);
}

async function expectLocaleFacts(shell: Locator, locale: BootstrapLocale) {
  const expectedFacts = [
    [locale.interface.home_section.based_in, locale.content.profile.location],
    [locale.interface.home_section.working_since, portfolio.profile.since],
    [locale.interface.home_section.focus, locale.content.profile.focus[0]],
  ];
  for (const [index, [label, value]] of expectedFacts.entries()) {
    const fact = shell.locator(".bootstrap-fact").nth(index);
    await expect(fact).toContainText(label);
    await expect(fact).toContainText(value);
  }
}

async function assertBootstrapLocale(page: Page, locale: BootstrapLocale) {
  await page.addInitScript((value) => {
    window.localStorage.setItem("flutter.selected_language", JSON.stringify(value));
  }, locale.locale);
  await page.route("**/flutter_bootstrap.js*", (route) =>
    route.fulfill({ body: "", contentType: "application/javascript", status: 200 }),
  );
  await page.goto("/", { waitUntil: "domcontentloaded" });
  const surface = page.locator("#bootstrap-surface");
  const shell = surface.locator(".bootstrap-shell");
  await expect(surface).toBeVisible();
  await expect(surface).toHaveAttribute(
    "aria-label",
    locale.interface.accessibility.loading_portfolio,
  );
  await expect(page.locator("html")).toHaveAttribute("lang", locale.locale);
  await expect(page.locator("html")).toHaveAttribute("dir", locale.direction);
  await expect(page).toHaveTitle(locale.content.site.title);
  await expect(shell).toHaveAttribute("data-locale", locale.locale);
  await expect(shell.locator(".bootstrap-rail")).toContainText(
    locale.content.profile.role,
  );
  await expect(shell.locator(".bootstrap-rail")).toContainText(
    locale.content.profile.location,
  );
  await expect(shell.locator(".bootstrap-statement")).toHaveText(
    locale.content.profile.headline,
  );
  await expect(shell.locator(".bootstrap-action")).toHaveText([
    locale.interface.home_section.view_work,
    locale.interface.home_section.email,
  ]);
  if (locale.locale === "ar") await expectArabicTitleOrder(shell);
  const font = scriptFontFor(locale.locale);
  if (font) await expectCriticalFont(page, shell, font);
  await expectLocaleFacts(shell, locale);
}

test("renders a JSON-derived critical shell before the first Flutter frame", async ({
  page,
}) => {
  let releaseWasm: (() => void) | undefined;
  const wasmGate = new Promise<void>((resolve) => {
    releaseWasm = resolve;
  });
  await page.route("**/main.dart.wasm*", async (route) => {
    await wasmGate;
    await route.continue();
  });

  await page.goto("/", { waitUntil: "domcontentloaded" });
  const shell = page.locator("#bootstrap-surface");
  await expect(shell).toBeVisible();
  await expect(shell).toHaveAttribute("aria-busy", "true");
  await expect(shell).toHaveAttribute(
    "aria-label",
    "Loading interactive portfolio",
  );
  await expect(shell.locator(".bootstrap-progress")).toHaveCount(0);
  const criticalShell = shell.locator(".bootstrap-shell");
  await expect(criticalShell).toBeVisible();
  await expect(criticalShell).toHaveAttribute("aria-hidden", "true");
  await expect(criticalShell).toHaveAttribute(
    "data-content-version",
    portfolio.content_version,
  );
  await expect(criticalShell.locator(".bootstrap-title")).toContainText(
    portfolio.profile.display_name.primary,
  );
  await expect(criticalShell.locator(".bootstrap-title-accent")).toHaveText(
    portfolio.profile.display_name.accent,
  );
  await expect(criticalShell.locator(".bootstrap-statement")).toHaveText(
    portfolio.profile.headline,
  );
  await expect(criticalShell.locator(".bootstrap-action")).toHaveText([
    ...(portfolio.systems.length > 0 ? ["Explore my work"] : []),
    "Email me",
  ]);
  const facts = criticalShell.locator(".bootstrap-fact");
  const expectedFacts = [
    portfolio.profile.location,
    portfolio.profile.since,
    portfolio.profile.focus[0],
  ];
  for (const [index, value] of expectedFacts.entries()) {
    await expect(facts.nth(index)).toContainText(value);
  }

  releaseWasm?.();
  await expect(shell).toHaveCount(0, { timeout: 20000 });
});

for (const bootstrapLocale of bootstrapLocaleCases) {
  test(`renders the saved ${bootstrapLocale.locale} locale before Flutter starts`, async ({
    page,
    isMobile,
  }) => {
    test.skip(
      isMobile,
      "one browser project covers the persisted critical shell",
    );
    await assertBootstrapLocale(page, bootstrapLocale);
  });
}

test("keeps the critical identity inside narrow and short viewports", async ({
  page,
  isMobile,
}) => {
  test.skip(isMobile, "one browser project covers the responsive HTML shell");
  await page.route("**/flutter_bootstrap.js*", (route) =>
    route.fulfill({
      body: "",
      contentType: "application/javascript",
      status: 200,
    }),
  );

  for (const viewport of [
    { width: 280, height: 653 },
    { width: 568, height: 320 },
  ]) {
    await page.setViewportSize(viewport);
    await page.goto("/", { waitUntil: "domcontentloaded" });
    const selectors = [
      ".bootstrap-rail",
      ".bootstrap-title",
      ".bootstrap-footer",
    ];
    for (const selector of selectors) {
      const box = await page.locator(selector).boundingBox();
      expect(box, selector).not.toBeNull();
      expect(box!.x, selector).toBeGreaterThanOrEqual(-1);
      expect(box!.y, selector).toBeGreaterThanOrEqual(-1);
      expect(box!.x + box!.width, selector).toBeLessThanOrEqual(
        viewport.width + 1,
      );
      expect(box!.y + box!.height, selector).toBeLessThanOrEqual(
        viewport.height + 1,
      );
    }
  }
});

test("retires the critical shell when a renderer omits the first-frame event", async ({
  page,
  isMobile,
}) => {
  test.skip(isMobile, "renderer fallback contract needs one browser project");

  await page.addInitScript(() => {
    const nativeAddEventListener = window.addEventListener;
    window.addEventListener = (function addEventListenerWithoutFlutterFrame(
      type: string,
      listener: EventListenerOrEventListenerObject,
      options?: boolean | AddEventListenerOptions,
    ) {
      if (type === "flutter-first-frame") return;
      nativeAddEventListener.call(window, type, listener, options);
    }) as typeof window.addEventListener;
  });

  await page.goto("/", { waitUntil: "domcontentloaded" });
  await page.waitForSelector("flt-semantics-host", {
    state: "attached",
    timeout: 20000,
  });
  await expect(page.locator("#bootstrap-surface")).toHaveCount(0, {
    timeout: 20000,
  });
  await expect(page.getByRole("heading").first()).toBeAttached();
  expect(
    await page.evaluate(
      () =>
        performance.getEntriesByName("flutter-run-app-fallback", "mark").length,
    ),
  ).toBe(1);
  expect(
    await page.evaluate(
      () =>
        performance.getEntriesByName("flutter-first-frame-signal", "mark")
          .length,
    ),
  ).toBe(1);
});

test("offers an accessible retry when the engine fails after its entrypoint loads", async ({
  page,
  isMobile,
}) => {
  test.skip(isMobile, "bootstrap recovery contract needs one browser project");
  await page.addInitScript(() => {
    type EntrypointOptions = {
      onEntrypointLoaded: (initializer: unknown) => unknown;
    };
    type Loader = { load: (options: EntrypointOptions) => Promise<unknown> };
    const flutter: { loader?: Loader } = {};
    let loader: Loader | undefined;
    Object.defineProperty(flutter, "loader", {
      configurable: true,
      get: () => loader,
      set: (value: Loader) => {
        const load = value.load.bind(value);
        value.load = (options) =>
          load({
            ...options,
            onEntrypointLoaded: () =>
              options.onEntrypointLoaded({
                initializeEngine: () =>
                  Promise.reject(new Error("engine initialization failed")),
              }),
          });
        loader = value;
      },
    });
    Object.assign(window, { _flutter: flutter });
  });

  await page.goto("/", { waitUntil: "domcontentloaded" });

  await expect(
    page.getByRole("button", { name: englishInterface.accessibility.retry }),
  ).toBeVisible({ timeout: 20000 });
  await expect(page.locator("#bootstrap-surface")).toHaveAttribute(
    "aria-busy",
    "false",
  );
  expect(
    await page.evaluate(
      () => performance.getEntriesByName("flutter-bootstrap-failed", "mark").length,
    ),
  ).toBe(1);
});

test("offers an accessible retry when the Wasm artifact cannot load", async ({
  page,
}) => {
  await page.route(/main\.dart\.(?:wasm|mjs|js)/, (route) =>
    route.abort("failed"),
  );
  await page.goto("/", { waitUntil: "domcontentloaded" });

  await expect(
    page.getByRole("button", {
      name: englishInterface.accessibility.retry,
    }),
  ).toBeVisible({
    timeout: 20000,
  });
  await expect(page.locator("#bootstrap-surface")).toHaveAttribute(
    "aria-label",
    englishInterface.accessibility.load_failure,
  );
  await expect(page.locator("#bootstrap-surface")).toHaveAttribute(
    "aria-busy",
    "false",
  );
  await expect(
    page.getByText(englishInterface.accessibility.load_failure),
  ).toBeVisible();
});

test("keeps bootstrap recovery in the saved locale", async ({
  page,
}, testInfo) => {
  test.skip(testInfo.project.name !== "desktop");
  const arabic = bootstrapLocaleCases.find(({ locale }) => locale === "ar");
  test.skip(!arabic, "the configured template does not publish Arabic");
  await page.addInitScript(() => {
    window.localStorage.setItem(
      "flutter.selected_language",
      JSON.stringify("ar"),
    );
  });
  await page.route(/main\.dart\.(?:wasm|mjs|js)/, (route) =>
    route.abort("failed"),
  );

  await page.goto("/", { waitUntil: "domcontentloaded" });

  await expect(
    page.getByRole("button", { name: arabic!.interface.accessibility.retry }),
  ).toBeVisible({ timeout: 20000 });
  await expect(page.locator("#bootstrap-surface")).toHaveAttribute(
    "aria-label",
    arabic!.interface.accessibility.load_failure,
  );
  await expect(page.locator("html")).toHaveAttribute("lang", "ar");
  await expect(page.locator("html")).toHaveAttribute("dir", "rtl");
});

test("offers a readable recovery document when JavaScript is disabled", async ({
  browser,
}, testInfo) => {
  test.skip(testInfo.project.name !== "desktop");
  const context = await browser.newContext({
    baseURL: testInfo.project.use.baseURL as string,
    javaScriptEnabled: false,
  });
  const page = await context.newPage();
  try {
    await page.goto("/", { waitUntil: "domcontentloaded" });
    const heading = page
      .locator("#static-document")
      .getByRole("heading", { level: 1 });
    await expect(heading).toBeVisible();
    await expect(heading).toContainText(portfolio.profile.name);
    await expect(page.locator(".noscript-recovery")).toHaveText(
      "The interactive version needs JavaScript.",
    );
    await expect(page.locator("#bootstrap-surface")).toBeHidden();
  } finally {
    await context.close();
  }
});
