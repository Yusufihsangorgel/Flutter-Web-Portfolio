import AxeBuilder from "@axe-core/playwright";
import { expect, test } from "@playwright/test";

test("has no serious or critical accessibility violations after reveal", async ({
  page,
}) => {
  await page.goto("/", { waitUntil: "domcontentloaded" });
  await page.waitForFunction(
    () =>
      performance.getEntriesByName("flutter-surface-reveal-start", "mark")
        .length === 1 && !document.querySelector("#bootstrap-surface"),
  );

  // Flutter's paint-only canvas has no document structure for axe to inspect.
  const results = await new AxeBuilder({ page })
    .exclude("flt-glass-pane canvas")
    .analyze();
  const violations = results.violations.filter(({ impact }) =>
    ["serious", "critical"].includes(impact ?? ""),
  );

  expect(violations, JSON.stringify(violations, null, 2)).toEqual([]);
});
