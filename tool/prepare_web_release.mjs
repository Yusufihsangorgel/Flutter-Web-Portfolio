import { createHash } from 'node:crypto';
import {
  copyFile,
  mkdir,
  readFile,
  readdir,
  rename,
  rm,
  stat,
  unlink,
  writeFile,
} from 'node:fs/promises';
import path from 'node:path';
import process from 'node:process';
import { renderStaticDocument } from './render_static_document.mjs';
import {
  collectFiles,
  formatBytes,
  normalizeNoticeWhitespace,
  precompressAssets,
  removeEmptyDirectories,
  resolveReleaseCommit,
  writeLegacyServiceWorkerKillSwitch,
} from './release/bundle_helpers.mjs';
import { renderLocaleData, renderReleaseIndex } from './release/render_release_index.mjs';

const webRoot = path.resolve(process.env.WEB_ROOT ?? 'build/web');
const files = await collectFiles(webRoot);
const symbolFiles = files.filter((file) => file.endsWith('.symbols'));

const unreachableRendererFiles = files.filter((file) => {
  if (file.endsWith('.symbols')) return false;
  const segments = path.relative(webRoot, file).split(path.sep);
  if (segments[0] !== 'canvaskit') return false;
  return (
    segments.includes('experimental_webparagraph') ||
    segments.at(-1).startsWith('wimp.')
  );
});

const removedBytes = (
  await Promise.all(
    symbolFiles.map(async (file) => {
      const metadata = await stat(file);
      await unlink(file);
      return metadata.size;
    }),
  )
).reduce((total, size) => total + size, 0);

const removedRendererBytes = (
  await Promise.all(
    unreachableRendererFiles.map(async (file) => {
      const metadata = await stat(file);
      await unlink(file);
      return metadata.size;
    }),
  )
).reduce((total, size) => total + size, 0);
await removeEmptyDirectories(path.join(webRoot, 'canvaskit'));

const releaseId = await createReleaseId();
const bootstrapPath = path.join(webRoot, 'flutter_bootstrap.js');
const bootstrap = await readFile(bootstrapPath, 'utf8');
const engineRevision = extractEngineRevision(bootstrap);
const versionedBootstrap = versionEntrypoints(bootstrap, releaseId);
await writeFile(bootstrapPath, versionedBootstrap);
await versionRendererDirectory(engineRevision);
await injectReleasePreloads(releaseId, engineRevision);
await injectBootstrapShell();
await writeLegacyServiceWorkerKillSwitch(webRoot);
await normalizeNoticeWhitespace(webRoot);
for (const file of ['_headers', '_redirects']) {
  await copyFile(path.resolve('web', file), path.join(webRoot, file));
}
await copyFile(
  path.resolve('tool', 'toolchain.json'),
  path.join(webRoot, 'release-toolchain.json'),
);
await writeReleaseMetadata();
const compressedAssets = await precompressAssets(webRoot);

console.log(
  `Removed ${symbolFiles.length} renderer symbol files (${formatBytes(removedBytes)}) from the public release.`,
);
console.log(
  `Removed ${unreachableRendererFiles.length} unreachable renderer variant files (${formatBytes(removedRendererBytes)}) from the public release.`,
);
console.log(
  `Versioned entrypoints as ${releaseId} and renderer assets as ${engineRevision}.`,
);
console.log(`Precompressed ${compressedAssets} text assets.`);

async function createReleaseId() {
  const hash = createHash('sha256');
  for (const file of ['main.dart.wasm', 'main.dart.mjs', 'main.dart.js']) {
    hash.update(await readFile(path.join(webRoot, file)));
  }
  return hash.digest('hex').slice(0, 16);
}

function extractEngineRevision(bootstrap) {
  const match = bootstrap.match(/"engineRevision":"([0-9a-f]{40})"/);
  if (!match) {
    throw new Error('flutter_bootstrap.js does not contain an engine revision');
  }
  return match[1];
}

function versionEntrypoints(bootstrap, releaseId) {
  const entrypoints = {
    mainWasmPath: 'main.dart.wasm',
    jsSupportRuntimePath: 'main.dart.mjs',
    mainJsPath: 'main.dart.js',
  };
  let output = bootstrap;
  for (const [key, file] of Object.entries(entrypoints)) {
    const pattern = new RegExp(
      `"${key}":"${file.replaceAll('.', '\\.')}(?:\\?v=[0-9a-f]+)?"`,
    );
    if (!pattern.test(output)) {
      throw new Error(`flutter_bootstrap.js does not contain ${key}`);
    }
    output = output.replace(pattern, `"${key}":"${file}?v=${releaseId}"`);
  }
  return output;
}

async function versionRendererDirectory(engineRevision) {
  const rendererRoot = path.join(webRoot, 'canvaskit');
  const entries = await readdir(rendererRoot, { withFileTypes: true });
  const versionPattern = /^[0-9a-f]{40}$/;
  const looseEntries = entries.filter(
    (entry) => !(entry.isDirectory() && versionPattern.test(entry.name)),
  );
  const versionDirectory = path.join(rendererRoot, engineRevision);

  if (looseEntries.length === 0) {
    await stat(versionDirectory);
    return;
  }

  await Promise.all(
    entries
      .filter(
        (entry) => entry.isDirectory() && versionPattern.test(entry.name),
      )
      .map((entry) =>
        rm(path.join(rendererRoot, entry.name), {
          recursive: true,
          force: true,
        }),
      ),
  );
  await mkdir(versionDirectory, { recursive: true });
  await Promise.all(
    looseEntries.map((entry) =>
      rename(
        path.join(rendererRoot, entry.name),
        path.join(versionDirectory, entry.name),
      ),
    ),
  );
}

async function injectReleasePreloads(releaseId, engineRevision) {
  const indexPath = path.join(webRoot, 'index.html');
  const index = await readFile(indexPath, 'utf8');
  const withoutPreviousHints = index.replace(
    /\n?\s*<!-- release-preloads:start -->[\s\S]*?<!-- release-preloads:end -->\n?/,
    '\n',
  );
  const preloadBlock = `  <!-- release-preloads:start -->
  <link rel="preload" href="main.dart.wasm?v=${releaseId}" as="fetch" type="application/wasm" crossorigin fetchpriority="high">
  <link rel="modulepreload" href="main.dart.mjs?v=${releaseId}" crossorigin fetchpriority="high">
  <link rel="preload" href="canvaskit/${engineRevision}/skwasm.wasm" as="fetch" type="application/wasm" crossorigin fetchpriority="high">
  <!-- release-preloads:end -->`;

  if (!withoutPreviousHints.includes('</head>')) {
    throw new Error('index.html does not contain a closing head tag');
  }
  await writeFile(
    indexPath,
    withoutPreviousHints.replace('</head>', `${preloadBlock}\n</head>`),
  );
}

async function injectBootstrapShell() {
  const portfolio = JSON.parse(await readFile(path.join(
    webRoot, 'assets', 'assets', 'content', 'portfolio.json'), 'utf8'));
  const locales = portfolio.site?.locales;
  if (!Array.isArray(locales) || !locales.length ||
    new Set(locales).size !== locales.length || !locales.includes('en')) {
    throw new Error('site.locales must contain unique locale codes including en');
  }
  const context = {
    portfolio,
    contentVersion: requiredString(portfolio.content_version, 'content_version'),
    displayName: requiredDisplayName(portfolio.profile?.display_name),
    since: requiredString(portfolio.profile?.since, 'profile.since'),
    hasWork: Boolean(portfolio.systems?.length),
    hasEmail: requiredString(portfolio.profile?.email, 'profile.email').includes('@'),
  };
  const shellLocales = {};
  for (const locale of locales) {
    shellLocales[locale] = await buildShellLocale(locale, context);
  }
  await writeFile(path.join(webRoot, 'bootstrap_locales.js'),
    renderLocaleData(shellLocales));
  const indexPath = path.join(webRoot, 'index.html');
  const index = await readFile(indexPath, 'utf8');
  await writeFile(indexPath, renderReleaseIndex(index,
    shellLocales.en.markup, renderStaticDocument(portfolio)));
}

async function buildShellLocale(value, context) {
  const locale = requiredString(value, 'site.locales[]');
  if (!/^[a-z]{2}(?:-[A-Z]{2})?$/.test(locale)) {
    throw new Error(`Unsupported bootstrap locale code: ${locale}`);
  }
  const localePortfolio = locale === 'en' ? context.portfolio :
    JSON.parse(await readFile(path.join(webRoot, 'assets', 'assets', 'content',
      'locales', `${locale}.json`), 'utf8'));
  if (locale !== 'en' && localePortfolio.locale !== locale) {
    throw new Error(`content locale ${locale} does not declare its locale code`);
  }
  const translations = JSON.parse(await readFile(path.join(
    webRoot, 'assets', 'assets', 'i18n', `${locale}.json`), 'utf8'));
  const accessibility = translations.accessibility;
  const copy = {};
  for (const [key, field] of [
    ['loadingPortfolio', 'loading_portfolio'],
    ['loadFailure', 'load_failure'],
    ['retry', 'retry'],
  ]) {
    copy[key] = requiredString(accessibility?.[field],
      `i18n.${locale}.accessibility.${field}`);
  }
  return {
    direction: locale.startsWith('ar') ? 'rtl' : 'ltr',
    fontHref: bootstrapFontHref(locale),
    title: requiredString(localePortfolio.site?.title, `${locale}.site.title`),
    copy,
    markup: renderBootstrapShell({
      ...context, profile: localePortfolio.profile, translations, locale,
    }),
  };
}

function bootstrapFontHref(locale) {
  if (locale === 'ar') {
    return 'assets/assets/fonts/noto_sans_arabic/NotoSansArabic-Variable.ttf';
  }
  if (locale === 'hi') {
    return 'assets/assets/fonts/noto_sans_devanagari/NotoSansDevanagari-Variable.ttf';
  }
  return null;
}

function renderBootstrapShell({
  contentVersion,
  displayName,
  profile,
  since,
  translations,
  hasWork,
  hasEmail,
  locale,
}) {
  const role = requiredString(profile?.role, `${locale}.profile.role`);
  const location = requiredString(
    profile?.location,
    `${locale}.profile.location`,
  );
  const headline = requiredString(
    profile?.headline,
    `${locale}.profile.headline`,
  );
  const focus = profile?.focus;
  if (!Array.isArray(focus) || focus.length < 3) {
    throw new Error(`${locale}.profile.focus must contain at least three values`);
  }
  const primaryFocus = requiredString(focus[0], `${locale}.profile.focus[0]`);
  const { factMarkup, actions } = renderShellDetails({
    translations, location, since, primaryFocus, hasWork, hasEmail, locale,
  });
  return `    <div class="bootstrap-shell" aria-hidden="true" data-content-version="${escapeHtml(contentVersion)}" data-locale="${escapeHtml(locale)}">
      <div class="bootstrap-rail">
        <span>${escapeHtml(role)}</span>
        <span class="bootstrap-rail-end">
          <span>${escapeHtml(location)}</span>
        </span>
      </div>
      <div class="bootstrap-stage">
        <p class="bootstrap-title">
        <span>${escapeHtml(displayName.primary)}</span>
        <span class="bootstrap-title-accent">${escapeHtml(displayName.accent)}</span>
        </p>
      </div>
      <div class="bootstrap-footer">
        <div class="bootstrap-statement-group">
          <p class="bootstrap-statement">${escapeHtml(headline)}</p>${actions}
        </div>
        <ul class="bootstrap-facts">
${factMarkup}
        </ul>
      </div>
    </div>`;
}

function renderShellDetails({
  translations, location, since, primaryFocus, hasWork, hasEmail, locale,
}) {
  const home = translations.home_section;
  const viewWork = requiredString(home?.view_work,
    `i18n.${locale}.home_section.view_work`);
  const emailLabel = requiredString(home?.email,
    `i18n.${locale}.home_section.email`);
  const facts = [
    [requiredString(home?.based_in, `i18n.${locale}.home_section.based_in`), location],
    [requiredString(home?.working_since,
      `i18n.${locale}.home_section.working_since`), since],
    [requiredString(home?.focus, `i18n.${locale}.home_section.focus`), primaryFocus],
  ];
  const factMarkup = facts.map(([label, value]) => `      <li class="bootstrap-fact">
        <span class="bootstrap-fact-label">${escapeHtml(label)}</span>
        ${escapeHtml(value)}
      </li>`).join('\n');
  const actionMarkup = [
    hasWork ? `            <span class="bootstrap-action bootstrap-action--primary">${escapeHtml(viewWork)}</span>` : '',
    hasEmail ? `            <span class="bootstrap-action">${escapeHtml(emailLabel)}</span>` : '',
  ].filter(Boolean).join('\n');
  return {
    factMarkup,
    actions: actionMarkup
      ? `\n          <div class="bootstrap-actions">\n${actionMarkup}\n          </div>`
      : '',
  };
}

function requiredString(value, path) {
  if (typeof value !== 'string' || value.trim().length === 0) {
    throw new Error(`${path} must be a non-empty string`);
  }
  return value.trim();
}

function requiredDisplayName(value) {
  const displayName = {};
  for (const field of ['primary', 'accent', 'navigation', 'accessible']) {
    displayName[field] = requiredString(
      value?.[field],
      `profile.display_name.${field}`,
    );
  }
  return displayName;
}

function escapeHtml(value) {
  return value.replace(/[&<>"']/g, (character) => {
    const entities = {
      '&': '&amp;',
      '<': '&lt;',
      '>': '&gt;',
      '"': '&quot;',
      "'": '&#39;',
    };
    return entities[character];
  });
}

async function writeReleaseMetadata() {
  const file = path.join(webRoot, 'version.json');
  const version = JSON.parse(await readFile(file, 'utf8'));
  const portfolio = JSON.parse(await readFile(
    path.resolve('assets', 'content', 'portfolio.json'), 'utf8'));
  const commit = resolveReleaseCommit();
  if (!/^[0-9a-f]{40}$/.test(commit)) throw new Error('Invalid commit hash');
  const epoch = process.env.SOURCE_DATE_EPOCH;
  const timestamp = epoch === undefined ? Date.now() : Number(epoch) * 1000;
  if (!Number.isFinite(timestamp)) throw new Error('Invalid SOURCE_DATE_EPOCH');
  version.commit = commit;
  version.content_version = requiredString(portfolio.content_version, 'content_version');
  version.built_at = new Date(timestamp).toISOString();
  await writeFile(file, `${JSON.stringify(version)}\n`);
}
