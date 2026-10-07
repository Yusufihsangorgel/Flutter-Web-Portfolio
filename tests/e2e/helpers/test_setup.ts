import { test as base } from '@playwright/test';
import { readFileSync } from 'node:fs';

export * from '@playwright/test';

const content = JSON.parse(readFileSync('assets/content/portfolio.json', 'utf8')) as {
  site: { analytics?: { script_url: string } | null };
};
const analyticsHost = content.site.analytics
  ? new URL(content.site.analytics.script_url).hostname
  : null;

export const test = base.extend({
  context: async ({ context }, use) => {
    if (analyticsHost) {
      // Keep production unchanged; analytics never reaches the network in browser tests.
      await context.route(
        (url) => url.hostname === analyticsHost,
        (route) => route.fulfill({ body: '', contentType: 'application/javascript' }),
      );
    }
    await use(context);
  },
});
