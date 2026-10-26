import { expect, test, type Page, type Request, type Route } from "./helpers/test_setup";
import {
  bootstrapLocaleCases,
  portfolio,
  required,
} from "./helpers/portfolio_test_helpers";

const fontLocales = [
  {
    locale: "ar",
    nativeName: "العربية",
    asset: "noto_sans_arabic/NotoSansArabic-Variable.ttf",
  },
  {
    locale: "hi",
    nativeName: "हिन्दी",
    asset: "noto_sans_devanagari/NotoSansDevanagari-Variable.ttf",
  },
] as const;

function isRuntimeFont(request: Request, fontUrl: URL) {
  const url = new URL(request.url());
  return url.origin === fontUrl.origin &&
    url.pathname === fontUrl.pathname &&
    ["fetch", "xhr"].includes(request.resourceType());
}

async function gateRuntimeFont(
  page: Page,
  fontUrl: URL,
  failLate: boolean,
) {
  let release!: () => void;
  const gate = new Promise<void>((resolve) => {
    release = resolve;
  });
  const pending: Promise<void>[] = [];
  const errors: unknown[] = [];
  const record = (error: unknown) => {
    errors.push(error);
  };
  let started = false;
  let released = false;
  let finished = false;
  const matches = (url: URL) =>
    url.origin === fontUrl.origin && url.pathname === fontUrl.pathname;
  const handler = (route: Route) => {
    const runtime = isRuntimeFont(route.request(), fontUrl);
    if (runtime) started = true;
    const work = runtime
      ? gate.then(() =>
          failLate ? route.abort("failed") : route.continue(),
        )
      : route.continue();
    const completion = work.then(() => {}, record);
    pending.push(completion);
    return completion;
  };
  const releaseGate = () => {
    released = true;
    release();
  };
  await page.route(matches, handler);
  return {
    release: releaseGate,
    isReleased: () => released,
    waitForStart: async () => {
      await expect.poll(() => started, { timeout: 10000 }).toBe(true);
    },
    finish: async () => {
      if (finished) return;
      finished = true;
      releaseGate();
      try {
        await page.unroute(matches, handler);
      } catch (error) {
        record(error);
      }
      await Promise.all(pending);
      expect(errors).toEqual([]);
    },
  };
}

type FontGate = Awaited<ReturnType<typeof gateRuntimeFont>>;

async function failNarrativeAsset(page: Page, base: URL) {
  const url = new URL("assets/assets/presentation/narrative.json", base);
  const matches = (value: URL) =>
    value.origin === url.origin && value.pathname === url.pathname;
  const pending: Promise<void>[] = [];
  const errors: unknown[] = [];
  const record = (error: unknown) => {
    errors.push(error);
  };
  let failed = false;
  let restored = false;
  const handler = (route: Route) => {
    const completion = route.fulfill({
      status: 503,
      contentType: "application/json",
      body: "",
    }).then(() => {
      failed = true;
    }, record);
    pending.push(completion);
    return completion;
  };
  await page.route(matches, handler);
  return {
    waitForFailure: async () => {
      await expect.poll(() => failed, { timeout: 10000 }).toBe(true);
    },
    restore: async () => {
      if (restored) return;
      restored = true;
      try {
        await page.unroute(matches, handler);
      } catch (error) {
        record(error);
      }
      await Promise.all(pending);
      expect(errors).toEqual([]);
    },
  };
}

type NarrativeFailure = Awaited<ReturnType<typeof failNarrativeAsset>>;

async function expectLanguageMenu(page: Page, nativeName: string) {
  const host = page.locator("flt-semantics-host");
  const button = host.getByRole("button", {
    name: new RegExp(`: ${nativeName}$`),
  });
  await expect(button).toBeVisible({ timeout: 10000 });
  await button.click();
  await expect(host.getByRole("menuitem")).toHaveCount(portfolio.site.locales.length);
  await page.keyboard.press("Escape");
  await expect(host.getByRole("menuitem")).toHaveCount(0);
}

function runtimeRetry(page: Page, label: string) {
  return page.locator("flt-semantics-host").getByRole("button", {
    name: label,
    exact: true,
  });
}

async function releaseRuntimeFont(
  page: Page,
  gate: FontGate,
  fontUrl: URL,
  failLate: boolean,
) {
  const options = {
    predicate: (request: Request) => isRuntimeFont(request, fontUrl),
    timeout: 10000,
  };
  const observing = failLate
    ? page.waitForEvent("requestfailed", options)
    : page.waitForEvent("requestfinished", options);
  gate.release();
  const request = await observing;
  if (!failLate) expect((await request.response())?.status()).toBe(200);
}

for (const flow of ["normal", "recovery"] as const) {
  for (const font of fontLocales) {
    test(`${flow} ${font.locale} startup remains usable with a pending runtime font`, async ({
      page,
      baseURL,
    }) => {
      const base = new URL(required(baseURL, "local preview URL"));
      expect(base.protocol).toBe("http:");
      expect(base.hostname).toBe("127.0.0.1");
      const locale = required(
        bootstrapLocaleCases.find((value) => value.locale === font.locale),
        `published ${font.locale} bootstrap locale`,
      );
      const fontUrl = new URL(`assets/assets/fonts/${font.asset}`, base);
      const failLate = flow === "recovery" && font.locale === "ar";
      const errors: string[] = [];
      page.on("pageerror", (error) => errors.push(error.message));
      const gate = await gateRuntimeFont(page, fontUrl, failLate);
      let narrative: NarrativeFailure | undefined;
      try {
        await page.addInitScript((value) => {
          window.localStorage.setItem("flutter.selected_language", JSON.stringify(value));
        }, font.locale);
        if (flow === "recovery") narrative = await failNarrativeAsset(page, base);
        await page.goto("/", { waitUntil: "domcontentloaded" });
        if (narrative) await narrative.waitForFailure();
        await gate.waitForStart();
        expect(gate.isReleased()).toBe(false);
        if (flow === "normal") {
          await expectLanguageMenu(page, font.nativeName);
        } else {
          const retry = runtimeRetry(page, locale.interface.accessibility.retry);
          await expect(retry).toBeVisible({ timeout: 10000 });
          await expect(retry).toBeEnabled();
        }
        expect(gate.isReleased()).toBe(false);
        await releaseRuntimeFont(page, gate, fontUrl, failLate);
        await gate.finish();
        if (narrative) {
          await narrative.restore();
          narrative = undefined;
          await Promise.all([
            page.waitForNavigation({ waitUntil: "domcontentloaded" }),
            runtimeRetry(page, locale.interface.accessibility.retry).click(),
          ]);
        }
        await expectLanguageMenu(page, font.nativeName);
        expect(errors).toEqual([]);
      } finally {
        gate.release();
        try {
          await narrative?.restore();
        } finally {
          await gate.finish();
        }
      }
    });
  }
}
