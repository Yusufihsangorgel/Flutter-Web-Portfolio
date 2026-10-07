import { defineConfig, devices } from '@playwright/test';
import { readFileSync } from 'node:fs';

const portfolio = JSON.parse(readFileSync('assets/content/portfolio.json', 'utf8'));
const productionBaseUrl = new URL(portfolio.site.url);
if (productionBaseUrl.protocol !== 'https:') throw new Error('Production browser checks require HTTPS.');

export default defineConfig({
  testDir: './tests/e2e-prod',
  testMatch: 'portfolio.spec.ts',
  timeout: 90000,
  expect: { timeout: 15000 },
  fullyParallel: false,
  workers: 1,
  reporter: [['list'], ['json', { outputFile: 'test-results/results.json' }]],
  use: {
    baseURL: productionBaseUrl.toString(),
    trace: 'retain-on-failure',
    screenshot: 'only-on-failure',
    ignoreHTTPSErrors: false,
  },
  projects: [
    {
      name: 'desktop',
      use: {
        ...devices['Desktop Chrome'],
        viewport: { width: 1440, height: 900 },
      },
    },
    { name: 'mobile', use: { ...devices['Pixel 7'] } },
  ],
});
