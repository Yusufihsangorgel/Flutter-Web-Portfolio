import { boardFrame, documentShell, escapeHtml } from './page.mjs';
import { fillTemplate } from './template.mjs';

const boardWidth = boardFrame.width;
const boardHeight = boardFrame.height;

const RELEASE_TEMPLATE_1 = Object.freeze([`<span>`, `</span>`]);

const RELEASE_TEMPLATE_2 = Object.freeze([
  `
    <main
      class="release"
      aria-label="`,
  ` release evidence"
    >
      <section class="release-copy">
        <div class="top-rule"></div>
        <p class="eyebrow">`,
  `</p>
        <img class="app-icon" src="`,
  `" alt="" />
        <h1>`,
  `</h1>
        <p class="descriptor">`,
  `</p>
        <div class="release-facts">
          <p>PUBLIC APP STORE LISTING</p>
          <p>`,
  `</p>
          <p>PHONE + TABLET SURFACES</p>
        </div>
      </section>
      <section class="screen-stage">
        <div class="stage-index">PRODUCT / RELEASE</div>
        <figure class="screen screen-primary">
          <div class="screen-crop">
            <img src="`,
  `" alt="" />
          </div>
          <figcaption>`,
  `</figcaption>
        </figure>
        <figure class="screen screen-secondary">
          <div class="screen-crop">
            <img src="`,
  `" alt="" />
          </div>
          <figcaption>`,
  `</figcaption>
        </figure>
        <div class="stage-rule"></div>
      </section>
    </main>
  `,
]);

const RELEASE_TEMPLATE_3 = Object.freeze([
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
      --rule: `,
  `;
    }

    .release {
      position: relative;
      display: grid;
      grid-template-columns: 550px 1050px;
      width: `,
  `px;
      height: `,
  `px;
      overflow: hidden;
      color: var(--ink);
      background: var(--paper);
    }

    .release-copy {
      position: relative;
      box-sizing: border-box;
      padding: 58px 62px 54px 70px;
      border-right: 1px solid var(--rule);
    }

    .top-rule {
      width: 100%;
      height: 6px;
      margin-bottom: 30px;
      background: var(--accent);
    }

    .eyebrow,
    .release-facts p,
    .stage-index,
    figcaption {
      margin: 0;
      font-size: 16px;
      font-weight: 700;
      letter-spacing: 0.12em;
      line-height: 1.2;
    }

    .eyebrow {
      margin-bottom: 48px;
    }

    .app-icon {
      display: block;
      width: 104px;
      height: 104px;
      margin-bottom: 34px;
      object-fit: cover;
      border: 1px solid color-mix(in srgb, var(--ink) 35%, transparent);
      border-radius: 22px;
    }

    h1 {
      margin: 0;
      font-size: 72px;
      font-weight: 800;
      letter-spacing: -0.055em;
      line-height: 0.92;
    }

    h1 span {
      display: block;
    }

    .descriptor {
      max-width: 390px;
      margin: 32px 0 0;
      font-size: 28px;
      font-weight: 500;
      letter-spacing: -0.025em;
      line-height: 1.25;
    }

    .release-facts {
      position: absolute;
      right: 62px;
      bottom: 56px;
      left: 70px;
      border-top: 1px solid var(--rule);
    }

    .release-facts p {
      padding: 13px 0 12px;
      border-bottom: 1px solid var(--rule);
      font-size: 13px;
      letter-spacing: 0.1em;
    }

    .screen-stage {
      position: relative;
      overflow: hidden;
      background: var(--stage);
      color: var(--stage-ink);
    }

    .stage-index {
      position: absolute;
      top: 62px;
      left: 68px;
      z-index: 2;
      font-size: 14px;
    }

    .screen {
      position: absolute;
      width: 360px;
      margin: 0;
    }

    .screen-primary {
      top: 92px;
      left: 102px;
    }

    .screen-secondary {
      top: 168px;
      left: 574px;
      width: 330px;
    }

    .screen-crop {
      width: 100%;
      aspect-ratio: 783 / 1392;
      overflow: hidden;
      background: #fff;
      border: 2px solid var(--stage-ink);
    }

    .screen-crop img {
      display: block;
      width: 100%;
      height: 100%;
      object-fit: cover;
    }

    figcaption {
      padding-top: 16px;
      font-size: 13px;
    }

    .stage-rule {
      position: absolute;
      right: 68px;
      bottom: 58px;
      left: 68px;
      height: 2px;
      background: var(--stage-ink);
    }
  `,
]);

export async function renderReleaseBoard(renderer, config) {
  const [icon, firstScreen, secondScreen] = await Promise.all([
    renderer.imageDataUrl(config.icon),
    renderer.imageDataUrl(config.screens[0].file),
    renderer.imageDataUrl(config.screens[1].file),
  ]);
  const titleLines = config.title
    .split('\n')
    .map((line) => fillTemplate(RELEASE_TEMPLATE_1, [escapeHtml(line)]))
    .join('');
  const palette = config.palette;

  const html = documentShell(
    fillTemplate(RELEASE_TEMPLATE_2, [
      escapeHtml(config.title.replace('\n', ' ')),
      escapeHtml(config.eyebrow),
      icon,
      titleLines,
      escapeHtml(config.descriptor),
      escapeHtml(config.platform),
      firstScreen,
      escapeHtml(config.screens[0].label),
      secondScreen,
      escapeHtml(config.screens[1].label),
    ]),
    fillTemplate(RELEASE_TEMPLATE_3, [
      palette.paper,
      palette.ink,
      palette.accent,
      palette.stage,
      palette.stageInk,
      palette.rule,
      boardWidth,
      boardHeight,
    ]),
  );

  await renderer.renderPage(html, config.output);
}
