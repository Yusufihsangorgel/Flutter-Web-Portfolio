import { readFile, stat } from 'node:fs/promises';
import path from 'node:path';
import { gzipSync } from 'node:zlib';

import { evidenceUrls } from './render_static_document.mjs';

/** @type {Array<[string, (portfolio: any) => boolean]>} */
const chapterFields = [
  ['About', (p) => Boolean(p.profile?.summary || p.profile?.background)],
  ['Experience', (p) => Boolean(p.experience?.length)],
  ['Open Source contributions', (p) => Boolean(p.contributions?.length)],
  ['Work', (p) => Boolean(p.systems?.length)],
  ['Packages', (p) => Boolean(p.packages?.length)],
  ['Writing', (p) => Boolean(p.writing?.length)],
];
const compressible = new Set([
  '.js',
  '.mjs',
  '.wasm',
  '.json',
  '.html',
  '.txt',
  '.xml',
  '.svg',
  '.ttf',
  '.otf',
]);

export function checkDocument(index, portfolio) {
  const issues = [];
  const staticMarkup = index.match(
    /<!-- static-document:start -->([\s\S]*?)<!-- static-document:end -->/,
  )?.[1];
  if (!staticMarkup || !staticMarkup.includes('id="static-document"')) {
    return ['static document is missing'];
  }
  issues.push(...checkStaticHeadings(staticMarkup, portfolio));
  const anchors = [...staticMarkup.matchAll(/<a\b[^>]*\bhref="([^"]+)"[^>]*>/g)].map((match) =>
    decodeAttribute(match[1]),
  );
  const remaining = [...anchors];
  for (const url of evidenceUrls(portfolio)) {
    const index = remaining.indexOf(new URL(url).href);
    if (index < 0) issues.push(`static document is missing evidence link: ${url}`);
    else remaining.splice(index, 1);
  }
  for (const [, attributes] of index.matchAll(/<script\b([^>]*)>/gi)) {
    if (
      /\bsrc\s*=/.test(attributes) ||
      /\btype\s*=\s*["']application\/ld\+json["']/.test(attributes)
    )
      continue;
    issues.push('index.html contains inline executable script');
  }
  if (index.includes('X-UA-Compatible')) issues.push('obsolete browser compatibility meta remains');
  return issues;
}

export function checkCompression(files) {
  const issues = [];
  for (const { name, bytes, compressed } of files) {
    if (!compressible.has(path.extname(name).toLowerCase()) || bytes.length <= 1024) continue;
    const expected = gzipSync(bytes, { level: 9 });
    if (!compressed?.equals(expected)) issues.push(`${name}.gz is missing or stale`);
  }
  return issues;
}

export function checkMetadata(version, portfolio) {
  const issues = [];
  if (!/^[0-9a-f]{40}$/.test(version.commit ?? '')) issues.push('version.json commit is invalid');
  if (version.content_version !== portfolio.content_version)
    issues.push('version.json content_version is stale');
  const timestamp = Date.parse(version.built_at);
  if (!Number.isFinite(timestamp) || new Date(timestamp).toISOString() !== version.built_at) {
    issues.push('version.json built_at is invalid');
  }
  return issues;
}

export async function verifyReleaseDocument(root, portfolio, releaseFiles) {
  const issues = [];
  try {
    const index = await readFile(path.join(root, 'index.html'), 'utf8');
    issues.push(...checkDocument(index, portfolio));
    issues.push(...(await verifyCriticalShell(root, index, portfolio)));
  } catch {
    issues.push('index.html is missing');
  }
  try {
    const version = JSON.parse(await readFile(path.join(root, 'version.json'), 'utf8'));
    issues.push(...checkMetadata(version, portfolio));
  } catch {
    issues.push('version.json is missing or invalid');
  }
  for (const file of releaseFiles.filter((name) => !name.endsWith('.gz'))) {
    if (!compressible.has(path.extname(file).toLowerCase())) continue;
    const metadata = await stat(file);
    if (metadata.size <= 1024) continue;
    const bytes = await readFile(file);
    let compressed = null;
    try {
      compressed = await readFile(`${file}.gz`);
    } catch {
      compressed = null;
    }
    issues.push(...checkCompression([{ name: path.relative(root, file), bytes, compressed }]));
  }
  return issues;
}

async function verifyCriticalShell(root, index, portfolio) {
  const issues = [];
  issues.push(...checkShellStructure(index));
  const bootstrap = await readFile(path.join(root, 'flutter_bootstrap.js'), 'utf8');
  const releaseId = bootstrap.match(/"mainWasmPath":"main\.dart\.wasm\?v=([0-9a-f]{16})"/)?.[1];
  const engine = bootstrap.match(/"engineRevision":"([0-9a-f]{40})"/)?.[1];
  for (const hint of [
    `href="main.dart.wasm?v=${releaseId}"`,
    `href="main.dart.mjs?v=${releaseId}"`,
    `href="canvaskit/${engine}/skwasm.wasm"`,
  ])
    if (!index.includes(hint)) issues.push(`critical preload is missing: ${hint}`);
  if ((index.match(/<!-- release-preloads:start -->/g) ?? []).length !== 1) {
    issues.push('release preload markers are missing');
  }
  issues.push(...checkShellCopy(index, portfolio));
  const localeScript = await readFile(path.join(root, 'bootstrap_locale.js'), 'utf8');
  const data = await readFile(path.join(root, 'bootstrap_locales.js'), 'utf8');
  const locales = JSON.parse(
    data.match(/^window\.__portfolioBootstrapLocales = ([\s\S]*);\s*$/)?.[1] ?? 'null',
  );
  if (!locales || !localeScript.includes("localStorage.getItem('flutter.selected_language')")) {
    issues.push('critical shell locale selection is missing');
    return issues;
  }
  for (const locale of portfolio.site?.locales ?? []) {
    issues.push(
      ...(await verifyLocale(root, locale, locale === 'en' ? portfolio : null, locales[locale])),
    );
  }
  return issues;
}

async function verifyLocale(root, locale, english, generated) {
  const portfolio =
    english ??
    JSON.parse(
      await readFile(
        path.join(root, 'assets', 'assets', 'content', 'locales', `${locale}.json`),
        'utf8',
      ),
    );
  const translations = JSON.parse(
    await readFile(path.join(root, 'assets', 'assets', 'i18n', `${locale}.json`), 'utf8'),
  );
  const expected = [
    portfolio.profile?.role,
    portfolio.profile?.location,
    portfolio.profile?.headline,
    translations.accessibility?.loading_portfolio,
    translations.accessibility?.load_failure,
    translations.accessibility?.retry,
  ];
  if (
    !generated ||
    expected.some(
      (value) =>
        typeof value !== 'string' || !JSON.stringify(generated).includes(escapeHtml(value)),
    )
  ) {
    return [`critical shell is missing ${locale} locale content`];
  }
  return [];
}

function decodeAttribute(value) {
  return value.replace(
    /&(?:amp|quot|#39|lt|gt);/g,
    (entity) =>
      ({
        '&amp;': '&',
        '&quot;': '"',
        '&#39;': "'",
        '&lt;': '<',
        '&gt;': '>',
      })[entity],
  );
}

function escapeHtml(value) {
  return value.replace(
    /[&<>"']/g,
    (character) =>
      ({
        '&': '&amp;',
        '<': '&lt;',
        '>': '&gt;',
        '"': '&quot;',
        "'": '&#39;',
      })[character],
  );
}

function checkStaticHeadings(staticMarkup, portfolio) {
  const issues = [];
  issues.push(...checkStaticTitle(staticMarkup, portfolio));
  const expectedChapters = chapterFields.filter(([, present]) => present(portfolio));
  if ((staticMarkup.match(/<h2\b/g) ?? []).length !== expectedChapters.length) {
    issues.push('static document chapter count is stale');
  }
  for (const [title, present] of chapterFields) {
    const actual = (staticMarkup.match(new RegExp(`<h2>${title}</h2>`, 'g')) ?? []).length;
    if (actual !== Number(present(portfolio)))
      issues.push(`static document chapter ${title} is stale`);
  }
  for (const [title] of expectedChapters) {
    const id = title === 'Open Source contributions' ? 'open-source' : title.toLowerCase();
    if (!staticMarkup.includes(`href="#${id}"`))
      issues.push(`static document navigation is missing ${title}`);
  }
  return issues;
}

function checkShellStructure(index) {
  const issues = [];
  if (index.includes('bootstrap-progress'))
    issues.push('critical shell has a synthetic loading cue');
  if (!index.includes('aria-busy="true"')) issues.push('critical shell loading state is missing');
  if (!index.includes('class="bootstrap-shell" aria-hidden="true"'))
    issues.push('critical shell is missing');
  if ((index.match(/<!-- bootstrap-content:start -->/g) ?? []).length !== 1) {
    issues.push('bootstrap content markers are missing');
  }
  return issues;
}

function checkShellCopy(index, portfolio) {
  const issues = [];
  for (const value of [
    portfolio.content_version,
    portfolio.profile?.name,
    portfolio.profile?.role,
    portfolio.profile?.headline,
    portfolio.profile?.location,
  ]) {
    if (typeof value !== 'string' || !index.includes(escapeHtml(value))) {
      issues.push('critical shell is stale');
      break;
    }
  }
  return issues;
}

function checkStaticTitle(staticMarkup, portfolio) {
  const issues = [];
  if ((staticMarkup.match(/id="static-document"/g) ?? []).length !== 1) {
    issues.push('static document id must be unique');
  }
  if ((staticMarkup.match(/<h1\b/g) ?? []).length !== 1)
    issues.push('static document needs one h1');
  if (!staticMarkup.includes(`<h1>${escapeHtml(portfolio.profile?.name ?? '')}</h1>`)) {
    issues.push('static document h1 is stale');
  }
  return issues;
}
