import { expect, Locator, Page, test } from "@playwright/test";
import { readFileSync } from "node:fs";
import { resolve } from "node:path";

const assets = resolve(__dirname, "../../assets");
const readJson = <T>(path: string) =>
  JSON.parse(readFileSync(resolve(assets, path), "utf8")) as T;

const chapters = readJson<{ chapters: Array<{ id: string }> }>(
  "presentation/narrative.json",
).chapters;
const interfaceCopy = readJson<Record<string, { title?: string }>>(
  "i18n/en.json",
);
const portfolio = readJson<{
  profile: { display_name: { accessible: string }; role: string };
}>("content/portfolio.json");

async function expectHeadingAtTarget(page: Page, heading: Locator) {
  await expect
    .poll(
      async () => {
        if ((await heading.count()) === 0) return false;
        const box = await heading.boundingBox();
        const timing = await page.evaluate(() => ({
          elapsed:
            performance.now() -
            performance.getEntriesByName(
              "flutter-bootstrap-surface-removed",
              "mark",
            )[0].startTime,
          height: innerHeight,
        }));
        return (
          box !== null &&
          timing.elapsed <= 1000 &&
          box.y >= -24 &&
          box.y < timing.height / 2
        );
      },
      { timeout: 1000 },
    )
    .toBe(true);
}

async function maximumHeadingDrift(heading: Locator) {
  return heading.evaluate(
    (element) =>
      new Promise<number>((resolve) => {
        const initial = element.getBoundingClientRect().top;
        let maximum = 0;
        const started = performance.now();
        const sample = () => {
          maximum = Math.max(
            maximum,
            Math.abs(element.getBoundingClientRect().top - initial),
          );
          if (performance.now() - started >= 3000) {
            resolve(maximum);
          } else {
            requestAnimationFrame(sample);
          }
        };
        requestAnimationFrame(sample);
      }),
  );
}

for (const chapter of chapters) {
  test(`cold deep link stays at ${chapter.id}`, async ({ page }) => {
    const headingName =
      chapter.id === "home"
        ? `${portfolio.profile.display_name.accessible}, ${portfolio.profile.role}`
        : interfaceCopy[`${chapter.id}_section`]?.title;
    if (!headingName) throw new Error(`Missing heading for ${chapter.id}`);

    await page.goto(`/#/${chapter.id}`, { waitUntil: "domcontentloaded" });
    await page.waitForFunction(
      () =>
        performance.getEntriesByName(
          "flutter-bootstrap-surface-removed",
          "mark",
        ).length > 0,
    );
    const heading = page.getByRole("heading", {
      name: headingName,
      exact: true,
    });
    await expectHeadingAtTarget(page, heading);
    const movement = await maximumHeadingDrift(heading);
    expect(movement).toBeLessThanOrEqual(24);
  });
}
