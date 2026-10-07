import { boardFrame, compactDocumentShell, compactFrame, documentShell } from './page.mjs';
import { fillTemplate } from './template.mjs';

const boardWidth = boardFrame.width;
const boardHeight = boardFrame.height;
const compactWidth = compactFrame.width;
const compactHeight = compactFrame.height;

const DORSE_TEMPLATE_1 = Object.freeze([
  `
    <main class="dorse" aria-label="Dorse public product evidence">
      <section class="copy">
        <div class="top-rule"></div>
        <p class="eyebrow">PRODUCT WORKFLOW</p>
        <p class="wordmark">dorse</p>
        <h1>Fleet vehicle<br />and trailer<br />management.</h1>
        <p class="descriptor">
          A public mobile workflow for vehicles and trailers, shown from the
          company's current product material.
        </p>
        <div class="facts">
          <p>FLUTTER MOBILE CLIENT</p>
          <p>PUBLIC COMPANY MATERIAL</p>
          <p>PUBLIC CAPTURE · 2026</p>
        </div>
      </section>
      <section class="stage">
        <p class="stage-index">MOBILE / FLEET</p>
        <figure>
          <div class="screen">
            <img src="`,
  `" alt="" />
          </div>
          <figcaption>
            Vehicle and trailer management · source: dorseapp.com
          </figcaption>
        </figure>
        <div class="stage-note">
          <span>VEHICLES</span>
          <span>TRAILERS</span>
          <span>FLEET</span>
        </div>
        <div class="stage-rule"></div>
      </section>
    </main>
  `,
]);

const DORSE_TEMPLATE_2 = Object.freeze([
  `
    .dorse {
      display: grid;
      grid-template-columns: 610px 990px;
      width: `,
  `px;
      height: `,
  `px;
      overflow: hidden;
      color: #171513;
      background: #f2eee7;
    }

    .copy {
      position: relative;
      padding: 58px 68px 54px 72px;
      border-right: 1px solid #a9a39b;
    }

    .top-rule {
      width: 100%;
      height: 6px;
      margin-bottom: 30px;
      background: #f65049;
    }

    .eyebrow,
    .facts p,
    .stage-index,
    figcaption,
    .stage-note {
      margin: 0;
      font-size: 13px;
      font-weight: 750;
      letter-spacing: 0.12em;
      line-height: 1.2;
    }

    .eyebrow {
      margin-bottom: 58px;
    }

    .wordmark {
      margin: 0 0 24px;
      color: #f65049;
      font-size: 29px;
      font-weight: 850;
      letter-spacing: -0.055em;
    }

    h1 {
      margin: 0;
      font-size: 65px;
      font-weight: 800;
      letter-spacing: -0.055em;
      line-height: 0.94;
    }

    .descriptor {
      max-width: 430px;
      margin: 34px 0 0;
      color: #4d4944;
      font-size: 24px;
      font-weight: 500;
      letter-spacing: -0.025em;
      line-height: 1.34;
    }

    .facts {
      position: absolute;
      right: 68px;
      bottom: 56px;
      left: 72px;
      border-top: 1px solid #a9a39b;
    }

    .facts p {
      padding: 13px 0 12px;
      border-bottom: 1px solid #a9a39b;
    }

    .stage {
      position: relative;
      overflow: hidden;
      color: #fff9f2;
      background: #171513;
    }

    .stage-index {
      position: absolute;
      top: 62px;
      left: 68px;
      color: #f65049;
    }

    figure {
      position: absolute;
      top: 54px;
      left: 250px;
      width: 414px;
      margin: 0;
    }

    .screen {
      width: 414px;
      height: 896px;
      overflow: hidden;
      background: #fff;
      border: 2px solid #fff9f2;
    }

    .screen img {
      display: block;
      width: 100%;
      height: 100%;
      object-fit: cover;
    }

    figcaption {
      position: absolute;
      top: 0;
      left: 448px;
      width: 210px;
      color: #a9a39b;
      font-size: 12px;
      line-height: 1.55;
    }

    .stage-note {
      position: absolute;
      top: 330px;
      right: 68px;
      display: grid;
      gap: 24px;
      color: #fff9f2;
      font-size: 12px;
    }

    .stage-note span {
      padding-bottom: 10px;
      border-bottom: 1px solid #5a5651;
    }

    .stage-rule {
      position: absolute;
      right: 68px;
      bottom: 47px;
      left: 706px;
      height: 2px;
      background: #f65049;
    }
  `,
]);

export async function renderDorseBoard(renderer) {
  const productScreen = await renderer.imageDataUrl('dorse-vehicle-settings.jpeg');
  const html = documentShell(
    fillTemplate(DORSE_TEMPLATE_1, [productScreen]),
    fillTemplate(DORSE_TEMPLATE_2, [boardWidth, boardHeight]),
  );

  await renderer.renderPage(html, 'dorse-product.jpg');
}

const COMPACT_DORSE_TEMPLATE_1 = Object.freeze([
  `
    <main class="compact-dorse" aria-label="Dorse compact product evidence">
      <header>
        <div class="top-rule"></div>
        <p class="eyebrow">PRODUCT WORKFLOW</p>
        <h1>Dorse</h1>
        <p class="descriptor">Fleet vehicle and trailer management</p>
      </header>
      <section class="stage">
        <figure>
          <img src="`,
  `" alt="" />
        </figure>
        <aside>
          <p class="index">MOBILE / FLEET</p>
          <p class="note">
            Actual vehicle settings screen from the company's public product
            material.
          </p>
          <div class="facts">
            <span>VEHICLES</span>
            <span>TRAILERS</span>
            <span>FLUTTER</span>
          </div>
        </aside>
      </section>
    </main>
  `,
]);

const COMPACT_DORSE_TEMPLATE_2 = Object.freeze([
  `
    .compact-dorse {
      width: `,
  `px;
      height: `,
  `px;
      overflow: hidden;
      color: #171513;
      background: #f2eee7;
    }

    header {
      height: 310px;
      padding: 44px 54px 36px;
    }

    .top-rule {
      width: 100%;
      height: 6px;
      margin-bottom: 24px;
      background: #f65049;
    }

    .eyebrow,
    .index,
    .facts {
      margin: 0;
      font-size: 13px;
      font-weight: 750;
      letter-spacing: 0.12em;
      line-height: 1.2;
    }

    h1 {
      margin: 36px 0 0;
      font-size: 76px;
      font-weight: 850;
      letter-spacing: -0.06em;
      line-height: 0.9;
    }

    .descriptor {
      margin: 20px 0 0;
      color: #4d4944;
      font-size: 25px;
      font-weight: 550;
      letter-spacing: -0.025em;
    }

    .stage {
      position: relative;
      height: 890px;
      overflow: hidden;
      color: #fff9f2;
      background: #171513;
    }

    figure {
      position: absolute;
      top: 40px;
      left: 52px;
      width: 390px;
      height: 844px;
      margin: 0;
      overflow: hidden;
      background: #fff;
      border: 2px solid #fff9f2;
    }

    figure img {
      display: block;
      width: 100%;
      height: 100%;
      object-fit: cover;
    }

    aside {
      position: absolute;
      top: 54px;
      right: 48px;
      width: 302px;
    }

    .index {
      color: #f65049;
    }

    .note {
      margin: 58px 0 0;
      color: #c1bab1;
      font-size: 20px;
      font-weight: 520;
      line-height: 1.45;
    }

    .facts {
      display: grid;
      gap: 0;
      margin-top: 64px;
      color: #fff9f2;
      font-size: 12px;
    }

    .facts span {
      padding: 18px 0;
      border-top: 1px solid #5a5651;
    }

    .facts span:last-child {
      border-bottom: 1px solid #5a5651;
    }
  `,
]);

export async function renderCompactDorseBoard(renderer) {
  const productScreen = await renderer.imageDataUrl('dorse-vehicle-settings.jpeg');
  const html = compactDocumentShell(
    fillTemplate(COMPACT_DORSE_TEMPLATE_1, [productScreen]),
    fillTemplate(COMPACT_DORSE_TEMPLATE_2, [compactWidth, compactHeight]),
  );

  await renderer.renderCompactPage(html, 'dorse-product-compact.jpg');
}
