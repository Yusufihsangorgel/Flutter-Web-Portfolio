import { expect, test } from "./helpers/test_setup";
import type { Page, Response } from "@playwright/test";

async function expectWasmPreloads(page: Page) {
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
}

function expectIsolationHeaders(response: Response | null) {
  expect(response?.headers()["cross-origin-opener-policy"]).toBe("same-origin");
  expect(response?.headers()["cross-origin-embedder-policy"]).toBe(
    "credentialless",
  );
  expect(response?.headers()["content-security-policy"]).toContain(
    "default-src 'self'",
  );
  expect(response?.headers()["content-security-policy"]).not.toContain(
    "formspree.io",
  );
}

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
  await expectWasmPreloads(page);
  expectIsolationHeaders(documentResponse);
  expect(await page.evaluate(() => window.crossOriginIsolated)).toBe(true);
});
