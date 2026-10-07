import { readFile } from 'node:fs/promises';
import path from 'node:path';

import { boardFrame, documentShell, escapeHtml } from './page.mjs';
import { fillTemplate } from './template.mjs';

const boardWidth = boardFrame.width;
const boardHeight = boardFrame.height;

const GATEWAY_TEMPLATE_1 = Object.freeze([
  `
        <div class="code-line">
          <span class="line-number">`,
  `</span>
          <code>`,
  `</code>
        </div>
      `,
]);

const GATEWAY_TEMPLATE_2 = Object.freeze([
  `
        <li>
          <span class="step-index">`,
  `</span>
          <div>
            <strong>`,
  `</strong>
            <small>`,
  `</small>
          </div>
        </li>
      `,
]);

const GATEWAY_TEMPLATE_3 = Object.freeze([
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
        <div class="code">`,
  `</div>
      </section>
      <section class="chain">
        <p class="chain-label">REQUEST ORDER</p>
        <ol>`,
  `</ol>
      </section>
      <footer>
        <span>HEALTH IS MOUNTED BEFORE TENANT + AUTH</span>
        <span>REFERENCE IMPLEMENTATION · GO / FIBER</span>
      </footer>
    </main>
  `,
]);

const GATEWAY_TEMPLATE_4 = Object.freeze([
  `
    .gateway {
      position: relative;
      width: `,
  `px;
      height: `,
  `px;
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
]);

export async function renderGatewayBoard(renderer) {
  const source = (
    await readFile(
      path.join(renderer.paths.sources, 'go-multitenant-gateway-server.go.txt'),
      'utf8',
    )
  ).trimEnd();
  const code = source
    .split('\n')
    .map((line, index) => {
      const renderedLine = line.length === 0 ? '&nbsp;' : syntaxHighlightGo(escapeHtml(line));
      return fillTemplate(GATEWAY_TEMPLATE_1, [String(index + 1).padStart(2, '0'), renderedLine]);
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
    .map(([index, name, note]) =>
      fillTemplate(GATEWAY_TEMPLATE_2, [index, escapeHtml(name), escapeHtml(note)]),
    )
    .join('');

  const html = documentShell(
    fillTemplate(GATEWAY_TEMPLATE_3, [code, steps]),
    fillTemplate(GATEWAY_TEMPLATE_4, [boardWidth, boardHeight]),
  );

  await renderer.renderPage(html, 'go-multitenant-gateway.jpg');
}

function syntaxHighlightGo(value) {
  return value
    .replace(/\b(app\.Use|modules\.Mount)\b/g, '<span class="function">$1</span>')
    .replace(/\b(recover\.New|health\.New|mw\.Auth)\b/g, '<span class="argument">$1</span>');
}
