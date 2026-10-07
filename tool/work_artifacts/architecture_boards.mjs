import {
  compactDocumentShell,
  compactFrame,
  documentShell,
  boardFrame,
  escapeHtml,
} from './page.mjs';
import { fillTemplate } from './template.mjs';

const boardWidth = boardFrame.width;
const boardHeight = boardFrame.height;
const compactWidth = compactFrame.width;
const compactHeight = compactFrame.height;

const ARCHITECTURE_TEMPLATE_1 = Object.freeze([
  `
        <li>
          <span>`,
  `</span>
          <strong>`,
  `</strong>
        </li>`,
]);

const ARCHITECTURE_TEMPLATE_2 = Object.freeze([`<span>`, `</span>`]);

const ARCHITECTURE_TEMPLATE_3 = Object.freeze([
  `
    <main class="architecture" aria-label="`,
  `">
      <header>
        <p class="eyebrow">`,
  `</p>
        <p class="repo">`,
  `</p>
      </header>
      <section class="intro">
        <h1>`,
  `</h1>
        <p>`,
  `</p>
      </section>
      <ol>`,
  `</ol>
      <footer>
        <span>`,
  `</span>
        <span>`,
  `</span>
      </footer>
    </main>
  `,
]);

const ARCHITECTURE_TEMPLATE_4 = Object.freeze([
  `
    :root { --paper: `,
  `; --ink: `,
  `; --accent: `,
  `; }
    .architecture {
      position: relative;
      width: `,
  `px;
      height: `,
  `px;
      overflow: hidden;
      padding: 54px 68px 48px;
      color: var(--ink);
      background: var(--paper);
    }
    .architecture::before {
      position: absolute;
      inset: 0 auto 0 0;
      width: 12px;
      content: '';
      background: var(--accent);
    }
    header, footer {
      display: flex;
      justify-content: space-between;
      padding-bottom: 18px;
      border-bottom: 1px solid color-mix(in srgb, var(--ink) 28%, transparent);
      font-size: 13px;
      font-weight: 750;
      letter-spacing: 0.1em;
    }
    header p, footer { margin: 0; }
    .eyebrow { color: var(--accent); }
    .repo { color: color-mix(in srgb, var(--ink) 64%, transparent); }
    .intro {
      display: grid;
      grid-template-columns: minmax(0, 1.08fr) minmax(360px, 0.62fr);
      gap: 90px;
      align-items: end;
      margin-top: 74px;
    }
    h1 {
      display: grid;
      margin: 0;
      font-size: 76px;
      font-weight: 820;
      letter-spacing: -0.06em;
      line-height: 0.94;
    }
    .intro > p {
      margin: 0 0 8px;
      color: color-mix(in srgb, var(--ink) 74%, transparent);
      font-size: 24px;
      font-weight: 520;
      line-height: 1.45;
    }
    ol {
      display: grid;
      grid-template-columns: repeat(`,
  `, minmax(0, 1fr));
      gap: 12px;
      padding: 0;
      margin: 92px 0 0;
      list-style: none;
    }
    li {
      position: relative;
      min-height: 220px;
      padding: 28px 24px;
      border: 1px solid color-mix(in srgb, var(--ink) 34%, transparent);
      background: color-mix(in srgb, var(--paper) 90%, white);
    }
    li:not(:last-child)::after {
      position: absolute;
      top: 50%;
      right: -17px;
      z-index: 2;
      width: 22px;
      height: 2px;
      content: '';
      background: var(--accent);
    }
    li span {
      display: block;
      color: var(--accent);
      font-size: 13px;
      font-weight: 800;
      letter-spacing: 0.1em;
    }
    li strong {
      display: block;
      margin-top: 92px;
      font-size: 19px;
      font-weight: 760;
      letter-spacing: -0.025em;
      line-height: 1.15;
    }
    footer {
      position: absolute;
      right: 68px;
      bottom: 44px;
      left: 68px;
      padding: 18px 0 0;
      border-top: 1px solid color-mix(in srgb, var(--ink) 28%, transparent);
      border-bottom: 0;
      color: color-mix(in srgb, var(--ink) 62%, transparent);
      font-size: 11px;
    }
  `,
]);

export async function renderArchitectureBoard(renderer, config) {
  const stages = config.stages
    .map((stage, index) =>
      fillTemplate(ARCHITECTURE_TEMPLATE_1, [
        String(index + 1).padStart(2, '0'),
        escapeHtml(stage),
      ]),
    )
    .join('');
  const title = config.title
    .split('\n')
    .map((line) => fillTemplate(ARCHITECTURE_TEMPLATE_2, [escapeHtml(line)]))
    .join('');
  const { paper, ink, accent } = config.palette;
  const html = documentShell(
    fillTemplate(ARCHITECTURE_TEMPLATE_3, [
      escapeHtml(config.title.replaceAll('\n', ' ')),
      escapeHtml(config.eyebrow),
      escapeHtml(config.footer),
      title,
      escapeHtml(config.descriptor),
      stages,
      escapeHtml(config.footerLeft),
      escapeHtml(config.footerRight),
    ]),
    fillTemplate(ARCHITECTURE_TEMPLATE_4, [
      paper,
      ink,
      accent,
      boardWidth,
      boardHeight,
      config.stages.length,
    ]),
  );
  await renderer.renderPage(html, config.output);
}

const COMPACT_ARCHITECTURE_TEMPLATE_1 = Object.freeze([
  `
        <li>
          <span>`,
  `</span>
          <strong>`,
  `</strong>
        </li>`,
]);

const COMPACT_ARCHITECTURE_TEMPLATE_2 = Object.freeze([
  `
    <main class="compact-architecture" aria-label="`,
  `">
      <header>
        <div class="top-rule"></div>
        <p class="eyebrow">`,
  `</p>
        <h1>`,
  `</h1>
        <p class="descriptor">`,
  `</p>
      </header>
      <section>
        <ol>`,
  `</ol>
      </section>
    </main>
  `,
]);

const COMPACT_ARCHITECTURE_TEMPLATE_3 = Object.freeze([
  `
    :root {
      --paper: `,
  `; --ink: `,
  `; --accent: `,
  `;
      --stage: `,
  `; --stage-ink: `,
  `;
    }
    .compact-architecture {
      width: `,
  `px;
      height: `,
  `px;
      overflow: hidden;
      color: var(--ink);
      background: var(--paper);
    }
    header { height: 370px; padding: 44px 52px 32px; }
    .top-rule { height: 6px; background: var(--accent); }
    .eyebrow {
      margin: 24px 0 0;
      color: var(--accent);
      font-size: 13px;
      font-weight: 800;
      letter-spacing: 0.11em;
    }
    h1 {
      margin: 48px 0 0;
      font-size: 62px;
      font-weight: 840;
      letter-spacing: -0.058em;
      line-height: 0.94;
    }
    .descriptor {
      max-width: 760px;
      margin: 20px 0 0;
      color: color-mix(in srgb, var(--ink) 74%, transparent);
      font-size: 22px;
      line-height: 1.35;
    }
    section {
      height: 830px;
      padding: 46px 52px;
      color: var(--stage-ink);
      background: var(--stage);
    }
    ol { padding: 0; margin: 0; list-style: none; }
    li {
      display: grid;
      grid-template-columns: 72px 1fr;
      min-height: `,
  `px;
      align-items: center;
      border-top: 1px solid color-mix(in srgb, var(--stage-ink) 34%, transparent);
    }
    li:last-child { border-bottom: 1px solid color-mix(in srgb, var(--stage-ink) 34%, transparent); }
    li span { color: var(--accent); font-size: 14px; font-weight: 800; }
    li strong { font-size: 25px; font-weight: 720; letter-spacing: -0.02em; }
  `,
]);

export async function renderCompactArchitectureBoard(renderer, config) {
  const stages = config.stages
    .map((stage, index) =>
      fillTemplate(COMPACT_ARCHITECTURE_TEMPLATE_1, [
        String(index + 1).padStart(2, '0'),
        escapeHtml(stage),
      ]),
    )
    .join('');
  const { paper, ink, accent, stage, stageInk } = config.palette;
  const html = compactDocumentShell(
    fillTemplate(COMPACT_ARCHITECTURE_TEMPLATE_2, [
      escapeHtml(config.title),
      escapeHtml(config.eyebrow),
      escapeHtml(config.title),
      escapeHtml(config.descriptor),
      stages,
    ]),
    fillTemplate(COMPACT_ARCHITECTURE_TEMPLATE_3, [
      paper,
      ink,
      accent,
      stage,
      stageInk,
      compactWidth,
      compactHeight,
      Math.floor(700 / config.stages.length),
    ]),
  );
  await renderer.renderCompactPage(html, config.output);
}
