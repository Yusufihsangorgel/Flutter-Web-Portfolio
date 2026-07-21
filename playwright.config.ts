import { defineConfig, devices } from '@playwright/test';

const externalBaseUrl = process.env.PLAYWRIGHT_BASE_URL;
const previewPort = Number(process.env.PORTFOLIO_TEST_PORT ?? 43177);
if (!Number.isInteger(previewPort) || previewPort < 1024 || previewPort > 65535) {
  throw new Error('PORTFOLIO_TEST_PORT must be an integer from 1024 to 65535.');
}
const previewUrl = `http://127.0.0.1:${previewPort}`;

export default defineConfig({
  testDir: './tests/e2e',
  snapshotPathTemplate:
    '{testDir}/{testFilePath}-snapshots/{arg}{-projectName}-{platform}{ext}',
  timeout: 60000,
  expect: {
    timeout: 10000,
    toHaveScreenshot: {
      animations: 'disabled',
      caret: 'hide',
      // The narrative stage renders a live Wasm canvas behind every section.
      // On the GPU-less CI runner that canvas rasterises a hair differently
      // from run to run, so a sub-two-percent pixel delta is background noise,
      // not a regression. Real layout or content changes move far more than
      // this. `animations: 'disabled'` only freezes CSS, not the canvas.
      maxDiffPixelRatio: 0.02,
      scale: 'css',
      threshold: 0.2,
    },
  },
  fullyParallel: true,
  // Each worker boots and compiles an isolated Wasm renderer. Serial execution
  // keeps cold-cache CI runs deterministic on constrained hosts.
  workers: 1,
  forbidOnly: !!process.env.CI,
  retries: process.env.CI ? 1 : 0,
  reporter: process.env.CI ? [['github'], ['html', { open: 'never' }]] : 'list',
  use: {
    baseURL: externalBaseUrl ?? previewUrl,
    trace: 'retain-on-failure',
    screenshot: 'only-on-failure',
  },
  ...(externalBaseUrl
    ? {}
    : { webServer: {
        command: 'node tool/serve_web.mjs',
        url: previewUrl,
        env: { PORT: String(previewPort) },
        reuseExistingServer: false,
        timeout: 15000,
      } }),
  projects: [
    {
      name: 'desktop',
      use: {
        ...devices['Desktop Chrome'],
        colorScheme: 'light',
        locale: 'en-US',
        timezoneId: 'UTC',
        viewport: { width: 1440, height: 900 },
      },
    },
    {
      name: 'mobile',
      use: {
        ...devices['Pixel 7'],
        colorScheme: 'light',
        locale: 'en-US',
        timezoneId: 'UTC',
      },
    },
    {
      name: 'tablet-visual',
      testMatch: /(visual|localization)\.spec\.ts/,
      use: {
        ...devices['iPad Pro 11'],
        browserName: 'chromium',
        colorScheme: 'light',
        locale: 'en-US',
        timezoneId: 'UTC',
      },
    },
  ],
});
