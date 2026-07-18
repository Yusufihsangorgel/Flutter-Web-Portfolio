import { chromium } from "@playwright/test";
import { mkdir, readFile } from "node:fs/promises";
import { fileURLToPath } from "node:url";
import path from "node:path";

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");
const sources = path.join(root, "tool", "work_sources");
const output = path.join(root, "assets", "work");

const boardWidth = 1600;
const boardHeight = 1000;
const compactWidth = 900;
const compactHeight = 1200;

await mkdir(output, { recursive: true });

const browser = await chromium.launch({ headless: true });

try {
  const page = await browser.newPage({
    viewport: { width: boardWidth, height: boardHeight },
    deviceScaleFactor: 1,
  });

  await renderLiveCapture(page, {
    source: "fugasoft-solutions.png",
    output: "fugasoft-product.jpg",
    accessibleName: "FugaSoft live product website",
  });
  await renderDorseBoard(page);

  await renderReleaseBoard(page, {
    output: "aydinlik-release.jpg",
    eyebrow: "APP STORE RELEASE",
    title: "Aydınlık\nE-Gazete",
    descriptor: "Daily edition, archive and audio reader",
    platform: "iOS · version 3.1.2",
    icon: "aydinlik-icon.jpg",
    screens: [
      {
        file: "aydinlik-edition.png",
        label: "DAILY EDITION",
      },
      {
        file: "aydinlik-reader.jpg",
        label: "AUDIO READER",
      },
    ],
    palette: {
      paper: "#f2efe7",
      ink: "#151515",
      accent: "#c80808",
      stage: "#171717",
      stageInk: "#f8f5ed",
      rule: "#aaa69e",
    },
  });

  await renderReleaseBoard(page, {
    output: "bilim-utopya-release.jpg",
    eyebrow: "APP STORE RELEASE",
    title: "Bilim ve\nÜtopya",
    descriptor: "Issue reader and subscriber archive",
    platform: "iOS · version 1.0.1",
    icon: "bilim-icon.jpg",
    screens: [
      {
        file: "bilim-cover.jpg",
        label: "LISTING ISSUE",
      },
      {
        file: "bilim-archive.png",
        label: "SUBSCRIBER ARCHIVE",
      },
    ],
    palette: {
      paper: "#f5f0e2",
      ink: "#171717",
      accent: "#e6b900",
      stage: "#ffd83d",
      stageInk: "#171717",
      rule: "#a7975e",
    },
  });

  await renderGatewayBoard(page);

  await renderArchitectureBoard(page, {
    output: "queue-inspector.png",
    eyebrow: "QUEUE INSPECTION",
    title: "One interface.\nThree backends.",
    descriptor:
      "Six read-only MCP tools inspect Asynq, BullMQ, and Sidekiq without direct Redis editing.",
    stages: [
      "MCP CLIENT",
      "6 READ-ONLY TOOLS",
      "ASYNQ · BULLMQ · SIDEKIQ",
      "REDIS",
    ],
    footer: "github.com/Yusufihsangorgel/queue-inspector-mcp",
    footerLeft: "TYPESCRIPT · MCP · REDIS",
    footerRight: "READ-ONLY BY DEFAULT",
    palette: { paper: "#dce9ff", ink: "#111820", accent: "#1e51ff" },
  });
  await renderArchitectureBoard(page, {
    output: "redis-task-queue.png",
    eyebrow: "SERVER-SIDE DART",
    title: "Weighted work.\nExplicit failures.",
    descriptor:
      "A Redis-backed Dart queue with weighted scheduling, retries, and an explicit dead-letter path.",
    stages: [
      "ENQUEUE",
      "WEIGHTED QUEUE",
      "WORKER",
      "RETRY POLICY",
      "DEAD LETTER",
    ],
    footer: "github.com/Yusufihsangorgel/redis_task_queue",
    footerLeft: "DART · REDIS",
    footerRight: "RETRIES · DEAD LETTERS",
    palette: { paper: "#f2e6da", ink: "#171311", accent: "#b82418" },
  });
  await renderArchitectureBoard(page, {
    output: "portfolio-current.jpg",
    eyebrow: "FLUTTER WEB RUNTIME",
    title: "Canonical data.\nLocalized runtime.",
    descriptor:
      "Canonical data, complete locale overlays, accessible Flutter UI, Dart Wasm output, and browser regression tests.",
    stages: [
      "CANONICAL CONTENT",
      "7 LOCALES",
      "FLUTTER UI",
      "DART WASM · SKWASM",
      "PLAYWRIGHT",
    ],
    footer: "developeryusuf.com · production architecture",
    footerLeft: "FLUTTER 3.44.6 · DART WASM",
    footerRight: "7 LOCALES · PLAYWRIGHT",
    palette: { paper: "#f2eee5", ink: "#12110f", accent: "#1e51ff" },
  });
  await renderConstellationBoard(page);

  await renderCompactLandscapeBoard(page, {
    source: "fugasoft-solutions.png",
    sourceDirectory: sources,
    output: "fugasoft-product-compact.jpg",
    eyebrow: "OFFICIAL PRODUCT LINE",
    title: "FugaSoft",
    descriptor: "ERP and point-of-sale product family · fugasoft.com",
    palette: {
      paper: "#f2eee7",
      ink: "#151515",
      accent: "#ed0051",
      stage: "#ffffff",
      stageInk: "#151515",
    },
    position: "center top",
    fit: "cover",
  });
  await renderCompactDorseBoard(page);
  await renderCompactReleaseBoard(page, {
    output: "aydinlik-release-compact.jpg",
    eyebrow: "APP STORE RELEASE",
    title: "Aydınlık E-Gazete",
    descriptor: "Daily edition and audio reader",
    platform: "iOS · version 3.1.2",
    icon: "aydinlik-icon.jpg",
    screens: ["aydinlik-edition.png", "aydinlik-reader.jpg"],
    palette: {
      paper: "#f2efe7",
      ink: "#151515",
      accent: "#c80808",
      stage: "#171717",
      stageInk: "#f8f5ed",
    },
  });
  await renderCompactReleaseBoard(page, {
    output: "bilim-utopya-release-compact.jpg",
    eyebrow: "APP STORE RELEASE",
    title: "Bilim ve Ütopya",
    descriptor: "Issue reader and subscriber archive",
    platform: "iOS · version 1.0.1",
    icon: "bilim-icon.jpg",
    screens: ["bilim-cover.jpg", "bilim-archive.png"],
    palette: {
      paper: "#f5f0e2",
      ink: "#171717",
      accent: "#e6b900",
      stage: "#ffd83d",
      stageInk: "#171717",
    },
  });
  await renderCompactArchitectureBoard(page, {
    output: "queue-inspector-compact.jpg",
    eyebrow: "QUEUE INSPECTION",
    title: "Queue Inspector MCP",
    descriptor: "Six read-only tools across Asynq, BullMQ, and Sidekiq",
    stages: ["MCP CLIENT", "READ-ONLY TOOLS", "3 QUEUE ADAPTERS", "REDIS"],
    palette: {
      paper: "#dce9ff",
      ink: "#111820",
      accent: "#1e51ff",
      stage: "#0d141c",
      stageInk: "#dce9ff",
    },
  });
  await renderCompactArchitectureBoard(page, {
    output: "go-multitenant-gateway-compact.jpg",
    eyebrow: "REQUEST PIPELINE",
    title: "Multi-tenant Gateway",
    descriptor: "Explicit middleware order in one Go binary",
    stages: [
      "PUBLIC HEALTH",
      "TENANT CONTEXT",
      "RATE LIMIT",
      "JWT AUTH",
      "MODULE",
    ],
    palette: {
      paper: "#dce9ff",
      ink: "#111820",
      accent: "#1e51ff",
      stage: "#0c1218",
      stageInk: "#dce9ff",
    },
  });
  await renderCompactArchitectureBoard(page, {
    output: "redis-task-queue-compact.jpg",
    eyebrow: "SERVER-SIDE DART",
    title: "Redis Task Queue",
    descriptor: "Server-side Dart queue with retries and dead letters",
    stages: [
      "ENQUEUE",
      "WEIGHTED QUEUE",
      "WORKER",
      "RETRY POLICY",
      "DEAD LETTER",
    ],
    palette: {
      paper: "#dce9ff",
      ink: "#111820",
      accent: "#1e51ff",
      stage: "#0d141c",
      stageInk: "#dce9ff",
    },
  });
  await renderCompactLandscapeBoard(page, {
    source: "constellation-demo.png",
    sourceDirectory: output,
    output: "constellation-demo-compact.jpg",
    eyebrow: "OPEN ENGINEERING",
    title: "Constellation Particles",
    descriptor: "A reusable Flutter rendering package in motion",
    palette: {
      paper: "#dff8f2",
      ink: "#101820",
      accent: "#1f9d8b",
      stage: "#07111c",
      stageInk: "#dff8f2",
    },
    position: "center",
    fit: "cover",
  });
  await renderCompactArchitectureBoard(page, {
    output: "portfolio-current-compact.jpg",
    eyebrow: "FLUTTER WEB RUNTIME",
    title: "Flutter Web Portfolio",
    descriptor: "Canonical content to localized, tested browser output",
    stages: ["CONTENT", "7 LOCALES", "FLUTTER UI", "DART WASM", "PLAYWRIGHT"],
    palette: {
      paper: "#f2eee5",
      ink: "#12110f",
      accent: "#1e51ff",
      stage: "#f2eee5",
      stageInk: "#12110f",
    },
  });
} finally {
  await browser.close();
}

async function renderArchitectureBoard(page, config) {
  const stages = config.stages
    .map(
      (stage, index) => `
        <li>
          <span>${String(index + 1).padStart(2, "0")}</span>
          <strong>${escapeHtml(stage)}</strong>
        </li>`,
    )
    .join("");
  const title = config.title
    .split("\n")
    .map((line) => `<span>${escapeHtml(line)}</span>`)
    .join("");
  const { paper, ink, accent } = config.palette;
  const html = documentShell(
    `
    <main class="architecture" aria-label="${escapeHtml(config.title.replace("\n", " "))}">
      <header>
        <p class="eyebrow">${escapeHtml(config.eyebrow)}</p>
        <p class="repo">${escapeHtml(config.footer)}</p>
      </header>
      <section class="intro">
        <h1>${title}</h1>
        <p>${escapeHtml(config.descriptor)}</p>
      </section>
      <ol>${stages}</ol>
      <footer>
        <span>${escapeHtml(config.footerLeft)}</span>
        <span>${escapeHtml(config.footerRight)}</span>
      </footer>
    </main>
  `,
    `
    :root { --paper: ${paper}; --ink: ${ink}; --accent: ${accent}; }
    .architecture {
      position: relative;
      width: ${boardWidth}px;
      height: ${boardHeight}px;
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
      grid-template-columns: repeat(${config.stages.length}, minmax(0, 1fr));
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
  );
  await renderPage(page, html, config.output);
}

async function renderCompactArchitectureBoard(page, config) {
  const stages = config.stages
    .map(
      (stage, index) => `
        <li>
          <span>${String(index + 1).padStart(2, "0")}</span>
          <strong>${escapeHtml(stage)}</strong>
        </li>`,
    )
    .join("");
  const { paper, ink, accent, stage, stageInk } = config.palette;
  const html = compactDocumentShell(
    `
    <main class="compact-architecture" aria-label="${escapeHtml(config.title)}">
      <header>
        <div class="top-rule"></div>
        <p class="eyebrow">${escapeHtml(config.eyebrow)}</p>
        <h1>${escapeHtml(config.title)}</h1>
        <p class="descriptor">${escapeHtml(config.descriptor)}</p>
      </header>
      <section>
        <ol>${stages}</ol>
      </section>
    </main>
  `,
    `
    :root {
      --paper: ${paper}; --ink: ${ink}; --accent: ${accent};
      --stage: ${stage}; --stage-ink: ${stageInk};
    }
    .compact-architecture {
      width: ${compactWidth}px;
      height: ${compactHeight}px;
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
      min-height: ${Math.floor(700 / config.stages.length)}px;
      align-items: center;
      border-top: 1px solid color-mix(in srgb, var(--stage-ink) 34%, transparent);
    }
    li:last-child { border-bottom: 1px solid color-mix(in srgb, var(--stage-ink) 34%, transparent); }
    li span { color: var(--accent); font-size: 14px; font-weight: 800; }
    li strong { font-size: 25px; font-weight: 720; letter-spacing: -0.02em; }
  `,
  );
  await renderCompactPage(page, html, config.output);
}

async function renderConstellationBoard(page) {
  const demo = await imageDataUrl("constellation-demo.png");
  const html = documentShell(
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
      <section class="demo"><img src="${demo}" alt="" /></section>
    </main>
  `,
    `
    .constellation {
      display: grid;
      grid-template-columns: 620px 980px;
      width: ${boardWidth}px;
      height: ${boardHeight}px;
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
  );
  await renderPage(page, html, "constellation-demo.png");
}

async function renderLiveCapture(page, config) {
  const source = await imageDataUrl(config.source);
  const html = documentShell(
    `
    <main class="live-capture" aria-label="${escapeHtml(config.accessibleName)}">
      <img src="${source}" alt="" />
    </main>
  `,
    `
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
  `,
  );
  await renderPage(page, html, config.output);
}

async function renderDorseBoard(page) {
  const productScreen = await imageDataUrl("dorse-vehicle-settings.jpeg");
  const html = documentShell(
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
            <img src="${productScreen}" alt="" />
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
    `
    .dorse {
      display: grid;
      grid-template-columns: 610px 990px;
      width: ${boardWidth}px;
      height: ${boardHeight}px;
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
  );

  await renderPage(page, html, "dorse-product.jpg");
}

async function renderCompactDorseBoard(page) {
  const productScreen = await imageDataUrl("dorse-vehicle-settings.jpeg");
  const html = compactDocumentShell(
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
          <img src="${productScreen}" alt="" />
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
    `
    .compact-dorse {
      width: ${compactWidth}px;
      height: ${compactHeight}px;
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
  );

  await renderCompactPage(page, html, "dorse-product-compact.jpg");
}

async function renderCompactReleaseBoard(page, config) {
  const [icon, primary, secondary] = await Promise.all([
    imageDataUrl(config.icon),
    imageDataUrl(config.screens[0]),
    imageDataUrl(config.screens[1]),
  ]);
  const palette = config.palette;
  const html = compactDocumentShell(
    `
    <main class="compact-release" aria-label="${escapeHtml(config.title)} compact release evidence">
      <header>
        <div class="top-rule"></div>
        <p class="eyebrow">${escapeHtml(config.eyebrow)}</p>
        <div class="identity">
          <img class="app-icon" src="${icon}" alt="" />
          <div>
            <h1>${escapeHtml(config.title)}</h1>
            <p class="descriptor">${escapeHtml(config.descriptor)}</p>
          </div>
        </div>
      </header>
      <section class="stage">
        <figure class="primary">
          <img src="${primary}" alt="" />
          <figcaption>PRIMARY RELEASE SURFACE</figcaption>
        </figure>
        <figure class="secondary">
          <img src="${secondary}" alt="" />
          <figcaption>SECONDARY FLOW</figcaption>
        </figure>
        <p class="platform">${escapeHtml(config.platform)}</p>
      </section>
    </main>
  `,
    `
    :root {
      --paper: ${palette.paper};
      --ink: ${palette.ink};
      --accent: ${palette.accent};
      --stage: ${palette.stage};
      --stage-ink: ${palette.stageInk};
    }

    .compact-release {
      width: ${compactWidth}px;
      height: ${compactHeight}px;
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
  );

  await renderCompactPage(page, html, config.output);
}

async function renderCompactLandscapeBoard(page, config) {
  const source = await imageDataUrlFrom(
    path.join(config.sourceDirectory, config.source),
  );
  const palette = config.palette;
  const html = compactDocumentShell(
    `
    <main class="compact-landscape" aria-label="${escapeHtml(config.title)} compact evidence">
      <header>
        <div class="top-rule"></div>
        <p class="eyebrow">${escapeHtml(config.eyebrow)}</p>
        <h1>${escapeHtml(config.title)}</h1>
        <p class="descriptor">${escapeHtml(config.descriptor)}</p>
      </header>
      <section class="stage">
        <div class="media">
          <img src="${source}" alt="" />
        </div>
        <footer>
          <span>${escapeHtml(config.eyebrow)}</span>
          <span>PROJECT VIEW</span>
        </footer>
      </section>
    </main>
  `,
    `
    :root {
      --paper: ${palette.paper};
      --ink: ${palette.ink};
      --accent: ${palette.accent};
      --stage: ${palette.stage};
      --stage-ink: ${palette.stageInk};
    }

    .compact-landscape {
      width: ${compactWidth}px;
      height: ${compactHeight}px;
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
      object-fit: ${config.fit};
      object-position: ${config.position};
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
  );

  await renderCompactPage(page, html, config.output);
}

async function renderReleaseBoard(page, config) {
  const [icon, firstScreen, secondScreen] = await Promise.all([
    imageDataUrl(config.icon),
    imageDataUrl(config.screens[0].file),
    imageDataUrl(config.screens[1].file),
  ]);
  const titleLines = config.title
    .split("\n")
    .map((line) => `<span>${escapeHtml(line)}</span>`)
    .join("");
  const palette = config.palette;

  const html = documentShell(
    `
    <main
      class="release"
      aria-label="${escapeHtml(config.title.replace("\n", " "))} release evidence"
    >
      <section class="release-copy">
        <div class="top-rule"></div>
        <p class="eyebrow">${escapeHtml(config.eyebrow)}</p>
        <img class="app-icon" src="${icon}" alt="" />
        <h1>${titleLines}</h1>
        <p class="descriptor">${escapeHtml(config.descriptor)}</p>
        <div class="release-facts">
          <p>PUBLIC APP STORE LISTING</p>
          <p>${escapeHtml(config.platform)}</p>
          <p>PHONE + TABLET SURFACES</p>
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
  `,
    `
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
  `,
  );

  await renderPage(page, html, config.output);
}

async function renderGatewayBoard(page) {
  const source = (
    await readFile(
      path.join(sources, "go-multitenant-gateway-server.go.txt"),
      "utf8",
    )
  ).trimEnd();
  const code = source
    .split("\n")
    .map((line, index) => {
      const renderedLine =
        line.length === 0 ? "&nbsp;" : syntaxHighlightGo(escapeHtml(line));
      return `
        <div class="code-line">
          <span class="line-number">${String(index + 1).padStart(2, "0")}</span>
          <code>${renderedLine}</code>
        </div>
      `;
    })
    .join("");

  const steps = [
    ["01", "recover.New()", "panic boundary"],
    ["02", "health.New()", "public before chain"],
    ["03", "tenantMW", "registered tenant context"],
    ["04", "limiter", "per-tenant budget"],
    ["05", "mw.Auth(…)", "bearer verification"],
    ["06", "notesModule", "module handler"],
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
    .join("");

  const html = documentShell(
    `
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
  `,
    `
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
  `,
  );

  await renderPage(page, html, "go-multitenant-gateway.jpg");
}

async function renderPage(page, html, outputFile) {
  await page.setViewportSize({ width: boardWidth, height: boardHeight });
  await page.setContent(html, { waitUntil: "load" });
  await page.evaluate(async () => {
    await document.fonts.ready;
    await Promise.all(
      Array.from(document.images, (image) =>
        image.complete ? Promise.resolve() : image.decode(),
      ),
    );
  });
  const target = path.join(output, outputFile);
  const jpeg = path.extname(outputFile).toLowerCase() === ".jpg";
  await page.screenshot({
    path: target,
    type: jpeg ? "jpeg" : "png",
    quality: jpeg ? 86 : undefined,
    animations: "disabled",
  });
  process.stdout.write(`Rendered assets/work/${outputFile} at 1600x1000.\n`);
}

async function renderCompactPage(page, html, outputFile) {
  await page.setViewportSize({ width: compactWidth, height: compactHeight });
  await page.setContent(html, { waitUntil: "load" });
  await page.evaluate(async () => {
    await document.fonts.ready;
    await Promise.all(
      Array.from(document.images, (image) =>
        image.complete ? Promise.resolve() : image.decode(),
      ),
    );
  });
  const target = path.join(output, outputFile);
  await page.screenshot({
    path: target,
    type: "jpeg",
    quality: 88,
    animations: "disabled",
  });
  process.stdout.write(
    `Rendered assets/work/${outputFile} at ${compactWidth}x${compactHeight}.\n`,
  );
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

function compactDocumentShell(body, styles) {
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
          width: ${compactWidth}px;
          height: ${compactHeight}px;
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
  return imageDataUrlFrom(path.join(sources, fileName));
}

async function imageDataUrlFrom(filePath) {
  const fileName = path.basename(filePath);
  const extension = path.extname(fileName).toLowerCase();
  const mime =
    extension === ".png"
      ? "image/png"
      : extension === ".jpg" || extension === ".jpeg"
        ? "image/jpeg"
        : null;
  if (mime === null) {
    throw new Error(`Unsupported image extension: ${extension}`);
  }
  const data = await readFile(filePath);
  return `data:${mime};base64,${data.toString("base64")}`;
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
    .replaceAll("&", "&amp;")
    .replaceAll("<", "&lt;")
    .replaceAll(">", "&gt;")
    .replaceAll('"', "&quot;")
    .replaceAll("'", "&#039;");
}
