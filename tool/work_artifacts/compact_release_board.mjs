import { compactDocumentShell, compactFrame, escapeHtml } from './page.mjs';
import { fillTemplate } from './template.mjs';

const compactWidth = compactFrame.width;
const compactHeight = compactFrame.height;

const COMPACT_RELEASE_TEMPLATE_1 = Object.freeze([
  `
    <main class="compact-release" aria-label="`,
  ` compact release evidence">
      <header>
        <div class="top-rule"></div>
        <p class="eyebrow">`,
  `</p>
        <div class="identity">
          <img class="app-icon" src="`,
  `" alt="" />
          <div>
            <h1>`,
  `</h1>
            <p class="descriptor">`,
  `</p>
          </div>
        </div>
      </header>
      <section class="stage">
        <figure class="primary">
          <img src="`,
  `" alt="" />
          <figcaption>PRIMARY RELEASE SURFACE</figcaption>
        </figure>
        <figure class="secondary">
          <img src="`,
  `" alt="" />
          <figcaption>SECONDARY FLOW</figcaption>
        </figure>
        <p class="platform">`,
  `</p>
      </section>
    </main>
  `,
]);

const COMPACT_RELEASE_TEMPLATE_2 = Object.freeze([
  `
    :root {
      --paper: `,
  `;
      --ink: `,
  `;
      --accent: `,
  `;
      --stage: `,
  `;
      --stage-ink: `,
  `;
    }

    .compact-release {
      width: `,
  `px;
      height: `,
  `px;
      overflow: hidden;
      color: var(--ink);
      background: var(--paper);
    }

    header {
      height: 330px;
      padding: 44px 52px 34px;
    }

    .top-rule {
      width: 100%;
      height: 6px;
      margin-bottom: 24px;
      background: var(--accent);
    }

    .eyebrow,
    figcaption,
    .platform {
      margin: 0;
      font-size: 13px;
      font-weight: 760;
      letter-spacing: 0.11em;
      line-height: 1.2;
    }

    .identity {
      display: grid;
      grid-template-columns: 104px 1fr;
      gap: 28px;
      align-items: center;
      margin-top: 38px;
    }

    .app-icon {
      width: 104px;
      height: 104px;
      object-fit: cover;
      border: 1px solid color-mix(in srgb, var(--ink) 32%, transparent);
      border-radius: 22px;
    }

    h1 {
      margin: 0;
      font-size: 58px;
      font-weight: 820;
      letter-spacing: -0.055em;
      line-height: 0.94;
    }

    .descriptor {
      margin: 16px 0 0;
      color: color-mix(in srgb, var(--ink) 75%, transparent);
      font-size: 21px;
      font-weight: 520;
      line-height: 1.25;
    }

    .stage {
      position: relative;
      height: 870px;
      overflow: hidden;
      color: var(--stage-ink);
      background: var(--stage);
    }

    figure {
      position: absolute;
      margin: 0;
    }

    figure img {
      display: block;
      width: 100%;
      aspect-ratio: 783 / 1392;
      object-fit: cover;
      background: #fff;
      border: 2px solid var(--stage-ink);
    }

    .primary {
      top: 42px;
      left: 50px;
      width: 400px;
    }

    .secondary {
      top: 196px;
      right: 42px;
      width: 250px;
    }

    figcaption {
      padding-top: 14px;
      font-size: 11px;
    }

    .platform {
      position: absolute;
      right: 44px;
      bottom: 40px;
      left: 50px;
      padding-top: 18px;
      border-top: 2px solid var(--stage-ink);
    }
  `,
]);

export async function renderCompactReleaseBoard(renderer, config) {
  const [icon, primary, secondary] = await Promise.all([
    renderer.imageDataUrl(config.icon),
    renderer.imageDataUrl(config.screens[0]),
    renderer.imageDataUrl(config.screens[1]),
  ]);
  const palette = config.palette;
  const html = compactDocumentShell(
    fillTemplate(COMPACT_RELEASE_TEMPLATE_1, [
      escapeHtml(config.title),
      escapeHtml(config.eyebrow),
      icon,
      escapeHtml(config.title),
      escapeHtml(config.descriptor),
      primary,
      secondary,
      escapeHtml(config.platform),
    ]),
    fillTemplate(COMPACT_RELEASE_TEMPLATE_2, [
      palette.paper,
      palette.ink,
      palette.accent,
      palette.stage,
      palette.stageInk,
      compactWidth,
      compactHeight,
    ]),
  );

  await renderer.renderCompactPage(html, config.output);
}
