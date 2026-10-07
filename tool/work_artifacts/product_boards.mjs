import { boardFrame, documentShell, escapeHtml } from './page.mjs';
import { fillTemplate } from './template.mjs';

const boardWidth = boardFrame.width;
const boardHeight = boardFrame.height;

const CONSTELLATION_TEMPLATE_1 = Object.freeze([
  `
    <main class="constellation" aria-label="Constellation Particles rendering demo">
      <section class="copy">
        <p class="eyebrow">FLUTTER RENDERING PACKAGE</p>
        <h1>Local neighbours,<br />not every pair.</h1>
        <p class="descriptor">A dependency-free CustomPainter field with pointer interaction and spatial-grid lookup.</p>
        <ul>
          <li>CustomPainter</li><li>Pointer input</li><li>Spatial grid</li><li>No runtime dependencies</li>
        </ul>
      </section>
      <section class="demo"><img src="`,
  `" alt="" /></section>
    </main>
  `,
]);

const CONSTELLATION_TEMPLATE_2 = Object.freeze([
  `
    .constellation {
      display: grid;
      grid-template-columns: 620px 980px;
      width: `,
  `px;
      height: `,
  `px;
      overflow: hidden;
      color: #eafbf6;
      background: #07111c;
    }
    .copy { padding: 64px 58px 52px 72px; border-right: 1px solid #28404a; }
    .eyebrow { margin: 0; color: #58d6bf; font-size: 14px; font-weight: 800; letter-spacing: .1em; }
    h1 { margin: 92px 0 0; font-size: 68px; line-height: .96; letter-spacing: -.055em; }
    .descriptor { margin: 34px 0 0; color: #a9c2c4; font-size: 23px; line-height: 1.45; }
    ul { padding: 0; margin: 94px 0 0; list-style: none; border-top: 1px solid #35505a; }
    li { padding: 16px 0; border-bottom: 1px solid #35505a; font-size: 14px; font-weight: 700; letter-spacing: .06em; }
    .demo { display: grid; place-items: center; padding: 70px; background: #0b1825; }
    .demo img { display: block; width: 840px; height: 525px; object-fit: cover; border: 1px solid #58d6bf; }
  `,
]);

export async function renderConstellationBoard(renderer) {
  const demo = await renderer.imageDataUrl('constellation-demo.png');
  const html = documentShell(
    fillTemplate(CONSTELLATION_TEMPLATE_1, [demo]),
    fillTemplate(CONSTELLATION_TEMPLATE_2, [boardWidth, boardHeight]),
  );
  await renderer.renderPage(html, 'constellation-demo.png');
}

const LIVE_CAPTURE_TEMPLATE_1 = Object.freeze([
  `
    <main class="live-capture" aria-label="`,
  `">
      <img src="`,
  `" alt="" />
    </main>
  `,
]);

const LIVE_CAPTURE_TEMPLATE_2 = Object.freeze([
  `
    .live-capture {
      width: `,
  `px;
      height: `,
  `px;
      overflow: hidden;
      background: #111;
    }

    .live-capture img {
      display: block;
      width: 100%;
      height: 100%;
      object-fit: cover;
      object-position: center top;
    }
  `,
]);

export async function renderLiveCapture(renderer, config) {
  const source = await renderer.imageDataUrl(config.source);
  const html = documentShell(
    fillTemplate(LIVE_CAPTURE_TEMPLATE_1, [escapeHtml(config.accessibleName), source]),
    fillTemplate(LIVE_CAPTURE_TEMPLATE_2, [boardWidth, boardHeight]),
  );
  await renderer.renderPage(html, config.output);
}
