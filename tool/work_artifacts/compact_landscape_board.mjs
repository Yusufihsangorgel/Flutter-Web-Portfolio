import { compactDocumentShell, compactFrame, escapeHtml } from './page.mjs';
import { fillTemplate } from './template.mjs';

const compactWidth = compactFrame.width;
const compactHeight = compactFrame.height;

const COMPACT_LANDSCAPE_TEMPLATE_1 = Object.freeze([
  `
    <main class="compact-landscape" aria-label="`,
  ` compact evidence">
      <header>
        <div class="top-rule"></div>
        <p class="eyebrow">`,
  `</p>
        <h1>`,
  `</h1>
        <p class="descriptor">`,
  `</p>
      </header>
      <section class="stage">
        <div class="media">
          <img src="`,
  `" alt="" />
        </div>
        <footer>
          <span>`,
  `</span>
          <span>PROJECT VIEW</span>
        </footer>
      </section>
    </main>
  `,
]);

const COMPACT_LANDSCAPE_TEMPLATE_2 = Object.freeze([
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

    .compact-landscape {
      width: `,
  `px;
      height: `,
  `px;
      overflow: hidden;
      color: var(--ink);
      background: var(--paper);
    }

    header {
      height: 370px;
      padding: 44px 52px 34px;
    }

    .top-rule {
      width: 100%;
      height: 6px;
      margin-bottom: 24px;
      background: var(--accent);
    }

    .eyebrow,
    footer {
      margin: 0;
      font-size: 13px;
      font-weight: 760;
      letter-spacing: 0.11em;
      line-height: 1.2;
    }

    h1 {
      max-width: 790px;
      margin: 42px 0 0;
      font-size: 67px;
      font-weight: 840;
      letter-spacing: -0.058em;
      line-height: 0.92;
    }

    .descriptor {
      max-width: 750px;
      margin: 22px 0 0;
      color: color-mix(in srgb, var(--ink) 75%, transparent);
      font-size: 23px;
      font-weight: 520;
      line-height: 1.3;
    }

    .stage {
      position: relative;
      height: 830px;
      padding: 48px 48px 0;
      background: var(--stage);
    }

    .media {
      width: 804px;
      height: 620px;
      overflow: hidden;
      background: var(--stage);
      border: 1px solid color-mix(in srgb, var(--paper) 55%, transparent);
    }

    .media img {
      display: block;
      width: 100%;
      height: 100%;
      object-fit: `,
  `;
      object-position: `,
  `;
    }

    footer {
      display: flex;
      justify-content: space-between;
      margin-top: 38px;
      padding-top: 18px;
      color: var(--stage-ink);
      border-top: 1px solid color-mix(in srgb, var(--stage-ink) 60%, transparent);
      font-size: 11px;
    }
  `,
]);

export async function renderCompactLandscapeBoard(renderer, config) {
  const source = config.renderedBoard
    ? renderer.renderedDataUrl(config.renderedBoard)
    : await renderer.imageDataUrl(config.source);
  const palette = config.palette;
  const html = compactDocumentShell(
    fillTemplate(COMPACT_LANDSCAPE_TEMPLATE_1, [
      escapeHtml(config.title),
      escapeHtml(config.eyebrow),
      escapeHtml(config.title),
      escapeHtml(config.descriptor),
      source,
      escapeHtml(config.eyebrow),
    ]),
    fillTemplate(COMPACT_LANDSCAPE_TEMPLATE_2, [
      palette.paper,
      palette.ink,
      palette.accent,
      palette.stage,
      palette.stageInk,
      compactWidth,
      compactHeight,
      config.fit,
      config.position,
    ]),
  );

  await renderer.renderCompactPage(html, config.output);
}
