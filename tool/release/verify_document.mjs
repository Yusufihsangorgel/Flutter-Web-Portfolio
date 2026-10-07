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
  issues.push(...verifyCriticalPreloads(index, bootstrap));
  const shell =
    index.match(/<!-- bootstrap-content:start -->([\s\S]*?)<!-- bootstrap-content:end -->/)?.[1] ??
    '';
  issues.push(...checkShellCopy(shell, portfolio));
  const localeScript = await readFile(path.join(root, 'bootstrap_locale.js'), 'utf8');
  const data = await readFile(path.join(root, 'bootstrap_locales.js'), 'utf8');
  const locales = JSON.parse(
    data.match(/^window\.__portfolioBootstrapLocales = ([\s\S]*);\s*$/)?.[1] ?? 'null',
  );
  const localeSteps = [
    "localStorage.getItem('flutter.selected_language')",
    'decoded = JSON.parse(stored)',
    'document.documentElement.dir = locale.direction',
  ];
  if (!locales || !localeSteps.every((step) => localeScript.includes(step))) {
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

function verifyCriticalPreloads(index, bootstrap) {
  const issues = [];
  const releaseId = bootstrap.match(/"mainWasmPath":"main\.dart\.wasm\?v=([0-9a-f]{16})"/)?.[1];
  const engine = bootstrap.match(/"engineRevision":"([0-9a-f]{40})"/)?.[1];
  if (!releaseId || !engine) issues.push('critical preload identifiers cannot be derived');
  else {
    const hints = [
      `rel="preload" href="main.dart.wasm?v=${releaseId}" as="fetch" type="application/wasm" crossorigin fetchpriority="high"`,
      `rel="modulepreload" href="main.dart.mjs?v=${releaseId}" crossorigin fetchpriority="high"`,
      `rel="preload" href="canvaskit/${engine}/skwasm.wasm" as="fetch" type="application/wasm" crossorigin fetchpriority="high"`,
    ];
    for (const hint of hints) {
      if (!index.includes(hint)) issues.push(`critical preload is missing: ${hint}`);
    }
  }
  if ((index.match(/<!-- release-preloads:start -->/g) ?? []).length !== 1) {
    issues.push('release preload markers are missing');
  }
  return issues;
}

async function verifyLocale(root, locale, english, generated) {
  const portfolio = await loadLocalePortfolio(root, locale, english);
  const translations = await loadLocaleTranslations(root, locale);
  const expected = collectExpectedCopy(portfolio, translations);
  if (
    !isValidTitle(portfolio, generated) ||
    !isValidCopy(translations, generated) ||
    !hasValidMarkup(expected, generated)
  ) {
    return [`critical shell is missing ${locale} locale content`];
  }
  return [];
}

/**
 * @param {string} root
 * @param {string} locale
 * @param {any} english
 * @returns {Promise<any>}
 */
async function loadLocalePortfolio(root, locale, english) {
  if (english) return english;
  return JSON.parse(
    await readFile(
      path.join(root, 'assets', 'assets', 'content', 'locales', `${locale}.json`),
      'utf8',
    ),
  );
}

/**
 * @param {string} root
 * @param {string} locale
 * @returns {Promise<any>}
 */
async function loadLocaleTranslations(root, locale) {
  return JSON.parse(
    await readFile(path.join(root, 'assets', 'assets', 'i18n', `${locale}.json`), 'utf8'),
  );
}

/**
 * @param {any} portfolio
 * @param {any} translations
 * @returns {Array<string | undefined>}
 */
function collectExpectedCopy(portfolio, translations) {
  const home = translations.home_section;
  const expected = [
    portfolio.profile?.role,
    portfolio.profile?.location,
    portfolio.profile?.headline,
    portfolio.profile?.focus?.[0],
    home?.based_in,
    home?.working_since,
    home?.focus,
  ];
  pushConditionalCopy(portfolio, home, expected);
  return expected;
}

/**
 * @param {any} portfolio
 * @param {any} home
 * @param {Array<string | undefined>} expected
 * @returns {void}
 */
function pushConditionalCopy(portfolio, home, expected) {
  if (hasWorkSystems(portfolio)) expected.push(home?.view_work);
  if (hasContactEmail(portfolio)) expected.push(home?.email);
}

/**
 * @param {any} portfolio
 * @returns {boolean}
 */
function hasWorkSystems(portfolio) {
  return (portfolio.systems?.length ?? 0) > 0;
}

/**
 * @param {any} portfolio
 * @returns {boolean}
 */
function hasContactEmail(portfolio) {
  return typeof portfolio.profile?.email === 'string' && portfolio.profile.email.includes('@');
}

/**
 * @param {any} translations
 * @param {any} generated
 * @returns {boolean}
 */
function isValidCopy(translations, generated) {
  const copyFields = [
    ['loadingPortfolio', 'loading_portfolio'],
    ['loadFailure', 'load_failure'],
    ['retry', 'retry'],
  ];
  return copyFields.every(([key, field]) => {
    const value = translations.accessibility?.[field];
    return typeof value === 'string' && generated?.copy?.[key] === value;
  });
}

/**
 * @param {any} portfolio
 * @param {any} generated
 * @returns {boolean}
 */
function isValidTitle(portfolio, generated) {
  return typeof portfolio.site?.title === 'string' && generated?.title === portfolio.site.title;
}

/**
 * @param {Array<string | undefined>} expected
 * @param {any} generated
 * @returns {boolean}
 */
function hasValidMarkup(expected, generated) {
  return expected.every(
    (value) => typeof value === 'string' && generated?.markup?.includes(escapeHtml(value)),
  );
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

function checkShellCopy(shell, portfolio) {
  const issues = [];
  for (const value of [
    portfolio.content_version,
    portfolio.profile?.role,
    portfolio.profile?.headline,
    portfolio.profile?.location,
    portfolio.profile?.since,
    portfolio.profile?.focus?.[0],
    portfolio.profile?.display_name?.primary,
    portfolio.profile?.display_name?.accent,
  ]) {
    if (typeof value !== 'string' || !shell.includes(escapeHtml(value))) {
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
