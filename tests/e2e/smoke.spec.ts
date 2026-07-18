import { expect, Page, test } from "@playwright/test";
import { readFileSync } from "node:fs";
import type {
  InterfaceTestData,
  PortfolioTestData,
} from "../support/portfolio_test_data";

const portfolio = JSON.parse(
  readFileSync("assets/content/portfolio.json", "utf8"),
) as PortfolioTestData;
const packageMetadata = JSON.parse(
  readFileSync("package.json", "utf8"),
) as { version: string };
const englishInterface = JSON.parse(
  readFileSync("assets/i18n/en.json", "utf8"),
) as InterfaceTestData;
const rightToLeftLocales = new Set(["ar", "fa", "he", "ur"]);
const bootstrapLocaleCases = (portfolio.site.locales as string[])
  .filter((locale) => locale !== "en")
  .map((locale) => ({
    locale,
    direction: rightToLeftLocales.has(locale) ? "rtl" : "ltr",
    content: JSON.parse(
      readFileSync(`assets/content/locales/${locale}.json`, "utf8"),
    ),
    interface: JSON.parse(readFileSync(`assets/i18n/${locale}.json`, "utf8")),
  }));
const firstContentSection =
  portfolio.experience.length > 0
    ? "experience"
    : portfolio.contributions.length > 0
      ? "proof"
      : portfolio.systems.length > 0
        ? "projects"
        : "about";

function required<T>(value: T | undefined, label: string): T {
  if (value === undefined) throw new Error(`Expected ${label}.`);
  return value;
}

async function openPortfolio(page: Page) {
  await page.goto("/", { waitUntil: "domcontentloaded" });
  await page.waitForSelector("flt-semantics-host", {
    state: "attached",
    timeout: 20000,
  });
  await expect(page.locator("#bootstrap-surface")).toHaveCount(0);
  await expect(page.getByRole("heading").first()).toBeAttached();
  await expect(page).toHaveTitle(portfolio.site.title);
  await expect(page.locator("html")).toHaveAttribute(
    "data-render-quality",
    /^(essential|balanced|full)$/,
  );
}

async function readAccessibilityTree(page: Page) {
  const session = await page.context().newCDPSession(page);
  await session.send("Accessibility.enable");
  return session;
}

async function expectHeadingInViewport(page: Page, name: string) {
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

async function focusActionWithKeyboard(page: Page, accessibleName: string) {
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
    // Flutter's web semantics bridge updates the browser focus target before
    // it dispatches the matching FocusNode event. One frame between real Tab
    // presses keeps those two focus trees synchronized, as they are for a
    // person traversing the document from a hardware keyboard.
    await page.waitForTimeout(32);
  }
  throw new Error(`Keyboard focus never reached: ${accessibleName}`);
}

async function openChapterFromPalette(
  page: Page,
  command: string,
  hash: RegExp,
  heading: string,
) {
  await page.keyboard.press("Control+KeyK");
  await page.getByText(command, { exact: true }).click();
  await expect(page).toHaveURL(hash);
  await expectHeadingInViewport(page, heading);
}

async function openChapterFromNavigation(
  page: Page,
  isMobile: boolean,
  control: string,
  hash: RegExp,
  heading: string,
) {
  if (isMobile) {
    await page
      .getByRole("button", { name: "Open navigation menu", exact: true })
      .click();
  }
  const target = page.getByRole("button", { name: control, exact: true });
  await (isMobile ? target.last() : target.first()).click();
  await expect(page).toHaveURL(hash);
  await expectHeadingInViewport(page, heading);
}

async function scrollToSemanticLink(page: Page, title: string) {
  // Flutter exposes this tappable Semantics node to Chromium's AX tree as a
  // link, but its generated <a> intentionally has no href. Playwright's DOM
  // role selector therefore cannot see it; the CDP AX assertion below still
  // verifies the real link role and accessible name.
  const link = page.locator("flt-semantics-host a").filter({ hasText: title });
  // Route navigation animates the Flutter scroll position. Give the target
  // semantics node a chance to enter the viewport before sending wheel input,
  // otherwise mobile emulation can race past the short link target.
  await link
    .first()
    .waitFor({ state: "attached", timeout: 1200 })
    .catch(() => undefined);
  for (let attempt = 0; attempt < 80; attempt += 1) {
    if ((await link.count()) > 0) {
      const [box, viewportHeight] = await Promise.all([
        link.first().boundingBox(),
        page.evaluate(() => window.innerHeight),
      ]);
      if (box && box.y < viewportHeight && box.y + box.height > 0) return;
    }
    await page.mouse.wheel(0, 420);
    await page.waitForTimeout(80);
  }
  await expect(link.first()).toBeVisible();
}

async function readRuntimeTimeline(page: Page) {
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

async function readRevealSourceCount(page: Page) {
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

test("boots the Flutter experience without browser errors", async ({
  page,
}) => {
  const errors: string[] = [];
  page.on("pageerror", (error) => errors.push(error.message));
  page.on("console", (message) => {
    if (message.type() === "error") errors.push(message.text());
  });
  page.on("response", (response) => {
    if (response.status() >= 400) {
      errors.push(`HTTP ${response.status()} ${response.url()}`);
    }
  });

  const response = await page.goto("/", { waitUntil: "domcontentloaded" });
  expect(response?.status()).toBe(200);
  await page.waitForSelector("flt-semantics-host", {
    state: "attached",
    timeout: 20000,
  });
  await expect(page.locator("#bootstrap-surface")).toHaveCount(0);
  await expect(page.getByRole("heading").first()).toBeAttached();
  const timeline = await readRuntimeTimeline(page);
  expect(timeline.every((value) => Number.isFinite(value))).toBe(true);
  expect(timeline).toEqual([...timeline].sort((a, b) => a! - b!));
  expect(await readRevealSourceCount(page)).toBe(1);
  expect(
    await page.evaluate(
      () =>
        performance.getEntriesByName(
          "flutter-bootstrap-to-first-frame",
          "measure",
        ).length,
    ),
  ).toBe(1);
  expect(errors).toEqual([]);
});

test("serves every authored primary and compact work artifact as an image", async ({
  request,
}) => {
  const workAssets = portfolio.systems
    .flatMap((system) => [
      system.artifact.asset,
      system.artifact.compact?.asset,
    ])
    .filter((asset): asset is string => Boolean(asset));

  expect(workAssets.length).toBe(portfolio.systems.length * 2);
  expect(new Set(workAssets).size).toBe(workAssets.length);
  for (const asset of workAssets) {
    const releasePath = asset.startsWith("assets/")
      ? `/assets/${asset}`
      : `/${asset}`;
    const response = await request.get(releasePath);
    expect(response.status(), asset).toBe(200);
    expect(response.headers()["content-type"], asset).toMatch(/^image\//);
    expect((await response.body()).byteLength, asset).toBeGreaterThan(0);
  }
});

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
  await expect(page.locator("html")).toHaveAttribute(
    "data-render-quality",
    "essential",
  );
  await expect(page.locator("html")).toHaveAttribute(
    "data-render-quality-reason",
    "reducedMotion",
  );

  const initialTree = await accessibility.send("Accessibility.getFullAXTree");
  const initialNodes = initialTree.nodes.filter((node) => !node.ignored);
  const headings = initialNodes
    .filter((node) => node.role?.value === "heading")
    .map((node) => ({
      name: node.name?.value ?? "",
      level: node.properties?.find((property) => property.name === "level")
        ?.value?.value,
    }));
  const controls = initialNodes
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

  if (isMobile) {
    await page
      .getByRole("button", { name: "Open navigation menu", exact: true })
      .click();
  }
  const aboutControl = page.getByRole("button", {
    name: "About",
    exact: true,
  });
  await (isMobile ? aboutControl.last() : aboutControl.first()).click();
  await expect(page).toHaveURL(/#\/about$/);
  await expect(page.getByRole("heading", { name: "About" })).toBeAttached();

  const sectionTree = await accessibility.send("Accessibility.getFullAXTree");
  const sectionHeading = sectionTree.nodes.find(
    (node) =>
      !node.ignored &&
      node.role?.value === "heading" &&
      node.name?.value === "About",
  );
  expect(
    sectionHeading?.properties?.find((property) => property.name === "level")
      ?.value?.value,
  ).toBe(2);

  await scrollToSemanticLink(page, portfolio.profile.links[0].label);
  const aboutTree = await accessibility.send("Accessibility.getFullAXTree");
  const aboutLinks = aboutTree.nodes
    .filter((node) => !node.ignored && node.role?.value === "link")
    .map((node) => node.name?.value ?? "");
  expect(aboutLinks).toEqual(
    expect.arrayContaining(portfolio.profile.links.map((link) => link.label)),
  );

  await openChapterFromNavigation(
    page,
    isMobile,
    "Open Source",
    /#\/proof$/,
    "Open Source",
  );
  const visibleContribution = required(
    portfolio.contributions.find((contribution) => contribution.featured) ??
      portfolio.contributions[0],
    "a visible contribution",
  );
  expect(visibleContribution).toBeTruthy();
  await scrollToSemanticLink(page, visibleContribution.title);
  const proofTree = await accessibility.send("Accessibility.getFullAXTree");
  const proofLinks = proofTree.nodes
    .filter((node) => !node.ignored && node.role?.value === "link")
    .map((node) => node.name?.value ?? "");

  const contributionStatus =
    visibleContribution.status === "merged" ? "Merged" : "Under review";
  expect(proofLinks).toEqual(
    expect.arrayContaining([
      expect.stringContaining(
        `View pull request. ${visibleContribution.title}. ${visibleContribution.project}. ${contributionStatus}.`,
      ),
    ]),
  );

  await openChapterFromNavigation(
    page,
    isMobile,
    "Work",
    /#\/projects$/,
    "Selected Work",
  );

  const projectsTree = await accessibility.send("Accessibility.getFullAXTree");
  const projectLinks = projectsTree.nodes
    .filter((node) => !node.ignored && node.role?.value === "link")
    .map((node) => node.name?.value ?? "");
  const featuredSystem = required(
    portfolio.systems.find((system) => system.featured),
    "a featured system",
  );
  expect(featuredSystem).toBeTruthy();
  const featuredEvidence = featuredSystem.evidence[0];
  const evidenceSemanticLabel = `${englishInterface.projects_section.open_evidence}: ${featuredSystem.name}, ${featuredEvidence.label}`;
  await scrollToSemanticLink(page, evidenceSemanticLabel);
  const visibleProjectsTree = await accessibility.send(
    "Accessibility.getFullAXTree",
  );
  const visibleProjectLinks = visibleProjectsTree.nodes
    .filter((node) => !node.ignored && node.role?.value === "link")
    .map((node) => node.name?.value ?? "");
  expect(visibleProjectLinks).toEqual(
    expect.arrayContaining([evidenceSemanticLabel]),
  );
  expect(projectLinks).not.toEqual(
    expect.arrayContaining([expect.stringContaining("Open project:")]),
  );
  expect(projectLinks).not.toContain("View source");
  expect(projectLinks).not.toContain("Website");
});

test("skip link moves keyboard focus into the main document", async ({
  page,
  isMobile,
}) => {
  test.skip(
    isMobile,
    "hardware-keyboard traversal is covered by the desktop browser project",
  );
  await openPortfolio(page);
  const skipLink = page.getByRole("button", {
    name: englishInterface.accessibility.skip_to_content,
    exact: true,
  });
  await focusActionWithKeyboard(
    page,
    englishInterface.accessibility.skip_to_content,
  );
  await page.keyboard.press("Enter");

  if (firstContentSection !== "about") {
    await expect(page).toHaveURL(new RegExp(`#/${firstContentSection}$`));
  }
  await expect
    .poll(() =>
      page.evaluate(
        () =>
          document.activeElement !== document.body &&
          document.activeElement?.getAttribute("aria-label") !==
            "Skip to content",
      ),
    )
    .toBe(true);
});

test("back-to-top is keyboard focusable and activates with Space", async ({
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
  const backToTop = page.getByRole("button", {
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
  await page.keyboard.press("Space");

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
  await openChapterFromNavigation(
    page,
    true,
    "Work",
    /#\/projects$/,
    "Selected Work",
  );
  const backToTop = page.getByRole("button", {
    name: englishInterface.accessibility.back_to_top,
    exact: true,
  });
  await expect(backToTop).toBeVisible();
  await backToTop.click();
  await expect(page).toHaveURL(/#\/$/);
  await expect(backToTop).toHaveCount(0);
});

test("keeps desktop project rows stable during pointer-driven evidence changes", async ({
  page,
}, testInfo) => {
  test.skip(testInfo.project.name !== "desktop");
  const supporting = portfolio.systems.filter((system) => !system.featured);
  test.skip(
    supporting.length < 3,
    "hover stability needs three supporting projects",
  );
  const initial = required(supporting[0], "an initial supporting project");
  const preferredTargetIndex = supporting.findIndex(
    (system) => system.id === "redis-task-queue",
  );
  const target = required(
    (preferredTargetIndex > 0 && preferredTargetIndex < supporting.length - 1
      ? supporting[preferredTargetIndex]
      : undefined) ??
      supporting.at(-2),
    "a later supporting project",
  );
  const targetIndex = supporting.indexOf(target);
  const tracked = supporting.slice(targetIndex, targetIndex + 3);
  test.skip(tracked.length < 2, "hover stability needs adjacent project rows");

  await openPortfolio(page);
  await openChapterFromPalette(
    page,
    "Go to Work",
    /#\/projects$/,
    "Selected Work",
  );

  const rowFor = (name: string) =>
    page.getByRole("button", {
      name: `${englishInterface.projects_section.select_evidence}: ${name}`,
      exact: true,
    });
  const targetRow = rowFor(target.name);
  for (let attempt = 0; attempt < 80; attempt += 1) {
    if ((await targetRow.count()) > 0 && (await targetRow.boundingBox())) break;
    await page.mouse.wheel(0, 500);
    await page.waitForTimeout(32);
  }
  await expect(targetRow).toBeVisible();
  // Match the lower-index viewport where the production failure was observed,
  // with the hovered row and its following neighbours all under the pointer.
  const visibleTargetBounds = required(
    (await targetRow.boundingBox()) ?? undefined,
    `${target.name} visible bounds`,
  );
  await page.mouse.wheel(0, visibleTargetBounds.y - 420);
  await page.waitForTimeout(160);

  const baseline = new Map<
    string,
    NonNullable<Awaited<ReturnType<typeof targetRow.boundingBox>>>
  >();
  for (const system of tracked) {
    const row = rowFor(system.name);
    await expect(row).toBeVisible();
    baseline.set(
      system.id,
      required(
        (await row.boundingBox()) ?? undefined,
        `${system.name} row bounds`,
      ),
    );
  }

  const targetBounds = required(
    baseline.get(target.id),
    `${target.name} baseline bounds`,
  );
  await page.mouse.move(
    targetBounds.x + targetBounds.width / 2,
    targetBounds.y + targetBounds.height / 2,
  );

  const targetPreview = page.getByRole("heading", {
    name: target.name,
    exact: true,
    level: 4,
  });
  await expect
    .poll(() => targetPreview.count(), { timeout: 160 })
    .toBe(1);
  expect(
    await page
      .getByRole("heading", {
        name: initial.name,
        exact: true,
        level: 4,
      })
      .count(),
  ).toBe(0);

  // Keep the pointer stationary across the full former transition window.
  // Every sample must retain the exact hitboxes, not merely settle back later.
  for (let sample = 0; sample < 10; sample += 1) {
    await page.waitForTimeout(32);
    for (const system of tracked) {
      const before = required(
        baseline.get(system.id),
        `${system.name} baseline bounds`,
      );
      const after = required(
        (await rowFor(system.name).boundingBox()) ?? undefined,
        `${system.name} bounds after hover`,
      );
      expect(after.x).toBeCloseTo(before.x, 1);
      expect(after.y).toBeCloseTo(before.y, 1);
      expect(after.width).toBeCloseTo(before.width, 1);
      expect(after.height).toBeCloseTo(before.height, 1);
    }
  }
});

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
    await page.addInitScript((locale) => {
      window.localStorage.setItem(
        "flutter.selected_language",
        JSON.stringify(locale),
      );
    }, bootstrapLocale.locale);
    await page.route("**/flutter_bootstrap.js*", (route) =>
      route.fulfill({
        body: "",
        contentType: "application/javascript",
        status: 200,
      }),
    );

    await page.goto("/", { waitUntil: "domcontentloaded" });
    const shell = page.locator("#bootstrap-surface");
    const criticalShell = shell.locator(".bootstrap-shell");
    await expect(shell).toBeVisible();
    await expect(shell).toHaveAttribute(
      "aria-label",
      bootstrapLocale.interface.accessibility.loading_portfolio,
    );
    await expect(page.locator("html")).toHaveAttribute(
      "lang",
      bootstrapLocale.locale,
    );
    await expect(page.locator("html")).toHaveAttribute(
      "dir",
      bootstrapLocale.direction,
    );
    await expect(page).toHaveTitle(bootstrapLocale.content.site.title);
    await expect(criticalShell).toHaveAttribute(
      "data-locale",
      bootstrapLocale.locale,
    );
    await expect(criticalShell.locator(".bootstrap-rail")).toContainText(
      bootstrapLocale.content.profile.role,
    );
    await expect(criticalShell.locator(".bootstrap-rail")).toContainText(
      bootstrapLocale.content.profile.location,
    );
    await expect(criticalShell.locator(".bootstrap-statement")).toHaveText(
      bootstrapLocale.content.profile.headline,
    );
    await expect(criticalShell.locator(".bootstrap-action")).toHaveText([
      bootstrapLocale.interface.home_section.view_work,
      bootstrapLocale.interface.home_section.email,
    ]);
    if (bootstrapLocale.locale === "ar") {
      const [primaryBox, accentBox] = await Promise.all([
        criticalShell.locator(".bootstrap-title > span").first().boundingBox(),
        criticalShell.locator(".bootstrap-title-accent").boundingBox(),
      ]);
      expect(primaryBox).not.toBeNull();
      expect(accentBox).not.toBeNull();
      expect(primaryBox!.x).toBeLessThan(accentBox!.x);
    }
    const scriptFont =
      bootstrapLocale.locale === "ar"
        ? {
            family: "Noto Sans Arabic Critical",
            href: "assets/assets/fonts/noto_sans_arabic/NotoSansArabic-Variable.ttf",
          }
        : bootstrapLocale.locale === "hi"
          ? {
              family: "Noto Sans Devanagari Critical",
              href: "assets/assets/fonts/noto_sans_devanagari/NotoSansDevanagari-Variable.ttf",
            }
          : null;
    if (scriptFont) {
      await expect(
        page.locator(
          `head link[rel="preload"][as="font"][href$="${scriptFont.href}"]`,
        ),
      ).toHaveCount(1);
      const shellFonts = await criticalShell.evaluate((element) => ({
        rail: getComputedStyle(element.querySelector(".bootstrap-rail")!)
          .fontFamily,
        statement: getComputedStyle(
          element.querySelector(".bootstrap-statement")!,
        ).fontFamily,
        title: getComputedStyle(element.querySelector(".bootstrap-title")!)
          .fontFamily,
      }));
      expect(shellFonts.rail).toContain(scriptFont.family);
      expect(shellFonts.statement).toContain(scriptFont.family);
      expect(shellFonts.title).toContain("Space Grotesk Critical");
      expect(shellFonts.title).not.toContain(scriptFont.family);
    }
    const expectedFacts = [
      [
        bootstrapLocale.interface.home_section.based_in,
        bootstrapLocale.content.profile.location,
      ],
      [
        bootstrapLocale.interface.home_section.working_since,
        portfolio.profile.since,
      ],
      [
        bootstrapLocale.interface.home_section.focus,
        bootstrapLocale.content.profile.focus[0],
      ],
    ];
    for (const [index, [label, value]] of expectedFacts.entries()) {
      const fact = criticalShell.locator(".bootstrap-fact").nth(index);
      await expect(fact).toContainText(label);
      await expect(fact).toContainText(value);
    }
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
    await expect(
      page.getByRole("heading", { name: "JavaScript is required" }),
    ).toBeVisible();
    await expect(page.locator(".noscript-recovery")).toContainText(
      "Enable JavaScript in your browser",
    );
    await expect(page.locator("#bootstrap-surface")).toBeHidden();
  } finally {
    await context.close();
  }
});

test("runs the Wasm/SkWasm path with cross-origin isolation", async ({
  page,
}) => {
  const wasmResponse = page.waitForResponse((response) =>
    response.url().includes("/main.dart.wasm?v="),
  );
  const runtimeResponse = page.waitForResponse((response) =>
    response.url().includes("/main.dart.mjs?v="),
  );
  const rendererResponse = page.waitForResponse((response) =>
    /\/canvaskit\/[0-9a-f]{40}\/skwasm\.wasm$/.test(response.url()),
  );

  const documentResponse = await page.goto("/", {
    waitUntil: "domcontentloaded",
  });
  const wasm = await wasmResponse;
  const runtime = await runtimeResponse;
  const renderer = await rendererResponse;

  expect(wasm.status()).toBe(200);
  expect(wasm.url()).toMatch(/main\.dart\.wasm\?v=[0-9a-f]{16}$/);
  expect(wasm.headers()["content-type"]).toContain("application/wasm");
  expect(runtime.status()).toBe(200);
  expect(runtime.url()).toMatch(/main\.dart\.mjs\?v=[0-9a-f]{16}$/);
  expect(runtime.headers()["content-type"]).toContain("javascript");
  expect(renderer.status()).toBe(200);
  const preloadHints = await page.locator("head link").evaluateAll((links) =>
    links.map((link) => ({
      rel: link.getAttribute("rel"),
      href: link.getAttribute("href"),
      as: link.getAttribute("as"),
      type: link.getAttribute("type"),
      fetchpriority: link.getAttribute("fetchpriority"),
    })),
  );
  expect(preloadHints).toEqual(
    expect.arrayContaining([
      expect.objectContaining({
        rel: "preload",
        href: expect.stringMatching(/^main\.dart\.wasm\?v=[0-9a-f]{16}$/),
        as: "fetch",
        type: "application/wasm",
        fetchpriority: "high",
      }),
      expect.objectContaining({
        rel: "modulepreload",
        href: expect.stringMatching(/^main\.dart\.mjs\?v=[0-9a-f]{16}$/),
        fetchpriority: "high",
      }),
      expect.objectContaining({
        rel: "preload",
        href: expect.stringMatching(/^canvaskit\/[0-9a-f]{40}\/skwasm\.wasm$/),
        as: "fetch",
        type: "application/wasm",
        fetchpriority: "high",
      }),
    ]),
  );
  expect(documentResponse?.headers()["cross-origin-opener-policy"]).toBe(
    "same-origin",
  );
  expect(documentResponse?.headers()["cross-origin-embedder-policy"]).toBe(
    "credentialless",
  );
  expect(documentResponse?.headers()["content-security-policy"]).toContain(
    "default-src 'self'",
  );
  expect(documentResponse?.headers()["content-security-policy"]).not.toContain(
    "formspree.io",
  );
  expect(await page.evaluate(() => window.crossOriginIsolated)).toBe(true);
});

test("retires the legacy service worker without keeping a registration", async ({
  page,
}) => {
  await page.goto("/", { waitUntil: "domcontentloaded" });
  await page.evaluate(async () => {
    const cache = await caches.open("unrelated-origin-contract");
    await cache.put(
      new Request("https://unrelated.example/static.css"),
      new Response("unrelated"),
    );
  });
  await page.evaluate(async () => {
    await navigator.serviceWorker.register("/flutter_service_worker.js");
  });

  await expect
    .poll(
      () =>
        page.evaluate(async () => {
          const registrations =
            await navigator.serviceWorker.getRegistrations();
          return registrations.length;
        }),
      { timeout: 10000 },
    )
    .toBe(0);
  expect(
    await page.evaluate(async () =>
      (await caches.keys()).includes("unrelated-origin-contract"),
    ),
  ).toBe(true);
  await page.evaluate(() => caches.delete("unrelated-origin-contract"));
});

test("serves same-origin fallback fonts without masking missing assets", async ({
  request,
}) => {
  const font = await request.get(
    "/assets/fallback_fonts/roboto/v32/KFOmCnqEu92Fr1Me4GZLCzYlKw.woff2",
  );
  expect(font.status()).toBe(200);
  expect(font.headers()["content-type"]).toContain("font/woff2");

  for (const path of [
    "/assets/assets/fonts/inter/Inter-Variable.ttf",
    "/assets/assets/fonts/noto_sans_arabic/NotoSansArabic-Variable.ttf",
    "/assets/assets/fonts/noto_sans_devanagari/NotoSansDevanagari-Variable.ttf",
  ]) {
    const appFont = await request.get(path);
    expect(appFont.status(), path).toBe(200);
    expect(appFont.headers()["content-type"], path).toContain("font/ttf");
  }

  const missing = await request.get("/assets/fallback_fonts/missing.woff2");
  expect(missing.status()).toBe(404);
});

test("ships the social preview at the declared large-card dimensions", async ({
  request,
}) => {
  const response = await request.get(portfolio.site.social_image);
  expect(response.status()).toBe(200);
  expect(response.headers()["content-type"]).toContain("image/png");

  const png = await response.body();
  expect(png.subarray(1, 4).toString()).toBe("PNG");
  expect(png.readUInt32BE(16)).toBe(1200);
  expect(png.readUInt32BE(20)).toBe(630);
});

test("does not publish renderer debug symbols", async ({ request }) => {
  const response = await request.get("/canvaskit/skwasm.js.symbols");
  expect(response.status()).toBe(404);

  const version = await request.get("/version.json");
  expect(version.status()).toBe(200);
  expect(await version.json()).toMatchObject({
    version: packageMetadata.version,
  });
});

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
    page.getByText(portfolio.experience[0].company).first(),
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
    const action = page.getByRole("button", { name: label, exact: true });
    for (let attempt = 0; attempt < 24; attempt += 1) {
      const box =
        (await action.count()) > 0 ? await action.boundingBox() : null;
      if (box && box.y < 653 && box.y + box.height > 0) break;
      await page.mouse.wheel(0, 160);
      await page.waitForTimeout(60);
    }
    await expect(action).toBeVisible();
    const actionBox = await action.boundingBox();
    expect(actionBox, label).not.toBeNull();
    expect(actionBox!.x, label).toBeGreaterThanOrEqual(0);
    expect(actionBox!.x + actionBox!.width, label).toBeLessThanOrEqual(280);
  }
});

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
