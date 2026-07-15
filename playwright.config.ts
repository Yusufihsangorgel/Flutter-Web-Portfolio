import { defineConfig, devices } from '@playwright/test';

export default defineConfig({
  testDir: './tests/e2e',
  snapshotPathTemplate:
    '{testDir}/{testFilePath}-snapshots/{arg}{-projectName}{ext}',
  timeout: 60000,
  expect: {
    timeout: 10000,
    toHaveScreenshot: {
      animations: 'disabled',
      caret: 'hide',
      maxDiffPixelRatio: 0.003,
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
    baseURL: process.env.PLAYWRIGHT_BASE_URL ?? 'http://127.0.0.1:4173',
    trace: 'retain-on-failure',
    screenshot: 'only-on-failure',
  },
  webServer: process.env.PLAYWRIGHT_BASE_URL
    ? undefined
    : {
        command: 'node tool/serve_web.mjs',
        url: 'http://127.0.0.1:4173',
        reuseExistingServer: !process.env.CI,
        timeout: 15000,
      },
  projects: [
    {
      name: 'desktop',
      use: {
        ...devices['Desktop Chrome'],
        colorScheme: 'dark',
        locale: 'en-US',
        timezoneId: 'UTC',
        viewport: { width: 1440, height: 900 },
      },
    },
    {
      name: 'mobile',
      use: {
        ...devices['Pixel 7'],
        colorScheme: 'dark',
        locale: 'en-US',
        timezoneId: 'UTC',
      },
    },
    {
      name: 'tablet-visual',
      testMatch: /visual\.spec\.ts/,
      use: {
        ...devices['iPad Pro 11'],
        colorScheme: 'dark',
        locale: 'en-US',
        timezoneId: 'UTC',
      },
    },
  ],
});
