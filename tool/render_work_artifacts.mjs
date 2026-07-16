import { chromium } from '@playwright/test';
import { copyFile, mkdir, readFile } from 'node:fs/promises';
import { fileURLToPath } from 'node:url';
import path from 'node:path';

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const sources = path.join(root, 'tool', 'work_sources');
const output = path.join(root, 'assets', 'work');

const boardWidth = 1600;
const boardHeight = 1000;

await mkdir(output, { recursive: true });

const browser = await chromium.launch({ headless: true });

try {
  const page = await browser.newPage({
    viewport: { width: boardWidth, height: boardHeight },
    deviceScaleFactor: 1,
  });

  await renderLiveCapture(page, {
    source: 'fugasoft-home.png',
    output: 'fugasoft-product.jpg',
    accessibleName: 'FugaSoft live product website',
  });
  await renderLiveCapture(page, {
    source: 'dorse-home.png',
    output: 'dorse-product.jpg',
    accessibleName: 'Dorse live logistics platform website',
  });

  await renderReleaseBoard(page, {
    output: 'aydinlik-release.jpg',
    eyebrow: 'PUBLIC APP STORE RELEASE',
    title: 'Aydınlık\nE-Gazete',
    descriptor: 'Daily edition, archive and audio reader',
    platform: 'iOS · version 3.1.2',
    icon: 'aydinlik-icon.jpg',
    screens: [
      {
        file: 'aydinlik-edition.png',
        label: 'DAILY EDITION',
      },
      {
        file: 'aydinlik-reader.jpg',
        label: 'AUDIO READER',
      },
    ],
    palette: {
      paper: '#f2efe7',
      ink: '#151515',
      accent: '#c80808',
      stage: '#171717',
      stageInk: '#f8f5ed',
      rule: '#aaa69e',
    },
  });

  await renderReleaseBoard(page, {
    output: 'bilim-utopya-release.jpg',
    eyebrow: 'PUBLIC APP STORE RELEASE',
    title: 'Bilim ve\nÜtopya',
    descriptor: 'Issue reader and subscriber archive',
    platform: 'iOS · version 1.0.1',
    icon: 'bilim-icon.jpg',
    screens: [
      {
        file: 'bilim-cover.jpg',
        label: 'LISTING ISSUE',
      },
      {
        file: 'bilim-archive.png',
        label: 'SUBSCRIBER ARCHIVE',
      },
    ],
    palette: {
      paper: '#f5f0e2',
      ink: '#171717',
      accent: '#e6b900',
      stage: '#ffd83d',
      stageInk: '#171717',
      rule: '#a7975e',
    },
  });

  await renderReleaseBoard(page, {
    output: 'galvapedia-release.jpg',
    eyebrow: 'PUBLIC APP STORE RELEASE',
    title: 'Galvapedia',
    descriptor: 'Industrial galvanizing reference and calculators',
    platform: 'iOS · version 2.0.14',
    icon: 'galvapedia-icon.jpg',
    screens: [
      {
        file: 'galvapedia-home.png',
        label: 'REFERENCE MODULES',
      },
      {
        file: 'galvapedia-calculator.png',
        label: 'ZINC CALCULATOR',
      },
    ],
    palette: {
      paper: '#eeeae2',
      ink: '#181818',
      accent: '#c90000',
      stage: '#9d0000',
      stageInk: '#fffaf2',
      rule: '#a49c91',
    },
  });

  await renderGatewayBoard(page);

  await copyFile(
    path.join(sources, 'queue-inspector-cover.png'),
    path.join(output, 'queue-inspector.png'),
  );
  process.stdout.write(
    'Copied assets/work/queue-inspector.png at its authored 1600x840 ratio.\n',
  );
} finally {
  await browser.close();
}

async function renderLiveCapture(page, config) {
  const source = await imageDataUrl(config.source);
  const html = documentShell(`
    <main class="live-capture" aria-label="${escapeHtml(config.accessibleName)}">
      <img src="${source}" alt="" />
    </main>
  `, `
    .live-capture {
      width: ${boardWidth}px;
      height: ${boardHeight}px;
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
  `);
  await renderPage(page, html, config.output);
}

async function renderReleaseBoard(page, config) {
  const [icon, firstScreen, secondScreen] = await Promise.all([
    imageDataUrl(config.icon),
    imageDataUrl(config.screens[0].file),
    imageDataUrl(config.screens[1].file),
  ]);
  const titleLines = config.title
    .split('\n')
    .map((line) => `<span>${escapeHtml(line)}</span>`)
    .join('');
  const palette = config.palette;

  const html = documentShell(`
    <main
      class="release"
      aria-label="${escapeHtml(config.title.replace('\n', ' '))} release evidence"
    >
      <section class="release-copy">
        <div class="top-rule"></div>
        <p class="eyebrow">${escapeHtml(config.eyebrow)}</p>
        <img class="app-icon" src="${icon}" alt="" />
        <h1>${titleLines}</h1>
        <p class="descriptor">${escapeHtml(config.descriptor)}</p>
        <div class="release-facts">
          <p>SHIPPED PRODUCT</p>
          <p>${escapeHtml(config.platform)}</p>
          <p>FIRST-PARTY LISTING EVIDENCE</p>
        </div>
      </section>
      <section class="screen-stage">
        <div class="stage-index">PRODUCT / RELEASE</div>
        <figure class="screen screen-primary">
          <div class="screen-crop">
            <img src="${firstScreen}" alt="" />
          </div>
          <figcaption>${escapeHtml(config.screens[0].label)}</figcaption>
        </figure>
        <figure class="screen screen-secondary">
          <div class="screen-crop">
            <img src="${secondScreen}" alt="" />
          </div>
          <figcaption>${escapeHtml(config.screens[1].label)}</figcaption>
        </figure>
        <div class="stage-rule"></div>
      </section>
    </main>
  `, `
    :root {
      --paper: ${palette.paper};
      --ink: ${palette.ink};
      --accent: ${palette.accent};
      --stage: ${palette.stage};
      --stage-ink: ${palette.stageInk};
      --rule: ${palette.rule};
    }

    .release {
      position: relative;
      display: grid;
      grid-template-columns: 550px 1050px;
      width: ${boardWidth}px;
      height: ${boardHeight}px;
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
  `);

  await renderPage(page, html, config.output);
}

async function renderGatewayBoard(page) {
  const source = (
    await readFile(
      path.join(sources, 'go-multitenant-gateway-server.go.txt'),
      'utf8',
    )
  ).trimEnd();
  const code = source
    .split('\n')
    .map((line, index) => {
      const renderedLine =
        line.length === 0
          ? '&nbsp;'
          : syntaxHighlightGo(escapeHtml(line));
      return `
        <div class="code-line">
          <span class="line-number">${String(index + 1).padStart(2, '0')}</span>
          <code>${renderedLine}</code>
        </div>
      `;
    })
    .join('');

  const steps = [
    ['01', 'recover.New()', 'panic boundary'],
    ['02', 'health.New()', 'public before chain'],
    ['03', 'tenantMW', 'registered tenant context'],
    ['04', 'limiter', 'per-tenant budget'],
    ['05', 'mw.Auth(…)', 'bearer verification'],
    ['06', 'notesModule', 'module handler'],
  ]
    .map(
      ([index, name, note]) => `
        <li>
          <span class="step-index">${index}</span>
          <div>
            <strong>${escapeHtml(name)}</strong>
            <small>${escapeHtml(note)}</small>
          </div>
        </li>
      `,
    )
    .join('');

  const html = documentShell(`
    <main class="gateway" aria-label="Go multi-tenant gateway source evidence">
      <header>
        <p class="repo">github.com/Yusufihsangorgel/go-multitenant-gateway</p>
        <p class="commit">PUBLIC MAIN BRANCH · SOURCE EXCERPT</p>
      </header>
      <div class="title-block">
        <p>ACTUAL SOURCE WIRING</p>
        <h1>One request.<br />One ordered chain.</h1>
      </div>
      <section class="source">
        <div class="source-head">
          <span>internal/server/server.go</span>
          <span>EXCERPT</span>
        </div>
        <div class="code">${code}</div>
      </section>
      <section class="chain">
        <p class="chain-label">REQUEST ORDER</p>
        <ol>${steps}</ol>
      </section>
      <footer>
        <span>HEALTH IS MOUNTED BEFORE TENANT + AUTH</span>
        <span>REFERENCE IMPLEMENTATION · GO / FIBER</span>
      </footer>
    </main>
  `, `
    .gateway {
      position: relative;
      width: ${boardWidth}px;
      height: ${boardHeight}px;
      overflow: hidden;
      color: #edf3f7;
      background: #0c1218;
    }

    .gateway::before {
      position: absolute;
      top: 0;
      bottom: 0;
      left: 66px;
      width: 2px;
      content: '';
      background: #4da3ff;
    }

    header {
      position: absolute;
      top: 48px;
      right: 68px;
      left: 98px;
      display: flex;
      justify-content: space-between;
      padding-bottom: 18px;
      border-bottom: 1px solid #34404a;
    }

    header p,
    .title-block p,
    .source-head,
    .chain-label,
    footer {
      margin: 0;
      font-size: 15px;
      font-weight: 700;
      letter-spacing: 0.11em;
      line-height: 1.2;
    }

    .repo {
      color: #75b8ff;
    }

    .commit {
      color: #8d99a5;
    }

    .title-block {
      position: absolute;
      top: 132px;
      left: 98px;
    }

    .title-block p,
    .chain-label {
      color: #75b8ff;
    }

    .title-block h1 {
      margin: 18px 0 0;
      font-size: 64px;
      font-weight: 750;
      letter-spacing: -0.045em;
      line-height: 0.98;
    }

    .source {
      position: absolute;
      top: 370px;
      left: 98px;
      width: 890px;
      border-top: 1px solid #52606c;
      border-bottom: 1px solid #52606c;
    }

    .source-head {
      display: flex;
      justify-content: space-between;
      padding: 17px 0 16px;
      color: #8d99a5;
      border-bottom: 1px solid #34404a;
      font-size: 13px;
    }

    .code {
      padding: 23px 0 26px;
    }

    .code-line {
      display: grid;
      grid-template-columns: 58px 1fr;
      min-height: 48px;
      align-items: center;
    }

    .line-number {
      color: #48545f;
      font-family: ui-monospace, SFMono-Regular, Menlo, Monaco, Consolas, monospace;
      font-size: 17px;
    }

    code {
      color: #eaf1f6;
      font-family: ui-monospace, SFMono-Regular, Menlo, Monaco, Consolas, monospace;
      font-size: 27px;
      line-height: 1.25;
    }

    .function {
      color: #72b7ff;
    }

    .argument {
      color: #f1c977;
    }

    .chain {
      position: absolute;
      top: 138px;
      right: 68px;
      width: 440px;
    }

    .chain ol {
      padding: 0;
      margin: 34px 0 0;
      list-style: none;
      border-top: 1px solid #52606c;
    }

    .chain li {
      display: grid;
      grid-template-columns: 54px 1fr;
      gap: 16px;
      min-height: 102px;
      align-items: center;
      border-bottom: 1px solid #34404a;
    }

    .step-index {
      color: #75b8ff;
      font-family: ui-monospace, SFMono-Regular, Menlo, Monaco, Consolas, monospace;
      font-size: 16px;
    }

    .chain strong,
    .chain small {
      display: block;
    }

    .chain strong {
      font-family: ui-monospace, SFMono-Regular, Menlo, Monaco, Consolas, monospace;
      font-size: 23px;
      font-weight: 550;
    }

    .chain small {
      padding-top: 8px;
      color: #8d99a5;
      font-size: 15px;
      font-weight: 500;
    }

    footer {
      position: absolute;
      right: 68px;
      bottom: 47px;
      left: 98px;
      display: flex;
      justify-content: space-between;
      padding-top: 17px;
      color: #8d99a5;
      border-top: 1px solid #34404a;
      font-size: 12px;
    }
  `);

  await renderPage(page, html, 'go-multitenant-gateway.jpg');
}

async function renderPage(page, html, outputFile) {
  await page.setContent(html, { waitUntil: 'load' });
  await page.evaluate(async () => {
    await document.fonts.ready;
    await Promise.all(
      Array.from(document.images, (image) =>
        image.complete ? Promise.resolve() : image.decode(),
      ),
    );
  });
  const target = path.join(output, outputFile);
  const jpeg = path.extname(outputFile).toLowerCase() === '.jpg';
  await page.screenshot({
    path: target,
    type: jpeg ? 'jpeg' : 'png',
    quality: jpeg ? 86 : undefined,
    animations: 'disabled',
  });
  process.stdout.write(`Rendered assets/work/${outputFile} at 1600x1000.\n`);
}

function documentShell(body, styles) {
  return `<!doctype html>
  <html lang="en">
    <head>
      <meta charset="utf-8" />
      <meta name="viewport" content="width=device-width, initial-scale=1" />
      <style>
        * {
          box-sizing: border-box;
        }

        html,
        body {
          width: ${boardWidth}px;
          height: ${boardHeight}px;
          margin: 0;
          overflow: hidden;
        }

        body {
          font-family: Arial, Helvetica, sans-serif;
          text-rendering: geometricPrecision;
        }

        ${styles}
      </style>
    </head>
    <body>${body}</body>
  </html>`;
}

async function imageDataUrl(fileName) {
  const filePath = path.join(sources, fileName);
  const extension = path.extname(fileName).toLowerCase();
  const mime =
    extension === '.png'
      ? 'image/png'
      : extension === '.jpg' || extension === '.jpeg'
        ? 'image/jpeg'
        : null;
  if (mime === null) {
    throw new Error(`Unsupported image extension: ${extension}`);
  }
  const data = await readFile(filePath);
  return `data:${mime};base64,${data.toString('base64')}`;
}

function syntaxHighlightGo(value) {
  return value
    .replace(
      /\b(app\.Use|modules\.Mount)\b/g,
      '<span class="function">$1</span>',
    )
    .replace(
      /\b(recover\.New|health\.New|mw\.Auth)\b/g,
      '<span class="argument">$1</span>',
    );
}

function escapeHtml(value) {
  return value
    .replaceAll('&', '&amp;')
    .replaceAll('<', '&lt;')
    .replaceAll('>', '&gt;')
    .replaceAll('"', '&quot;')
    .replaceAll("'", '&#039;');
}
