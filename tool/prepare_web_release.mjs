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

const webRoot = path.resolve(process.env.WEB_ROOT ?? 'build/web');
const files = await collectFiles(webRoot);
const symbolFiles = files.filter((file) => file.endsWith('.symbols'));

// This release can only ever request the skwasm/skwasm_heavy Wasm renderers
// plus the chromium/full CanvasKit fallbacks. The wimp and
// experimental_webparagraph variants are reachable solely through engine
// configuration (`enableWimp`, `canvasKitVariant`) that neither the build
// config nor index.html sets, so they are unreachable deployment weight.
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
await writeLegacyServiceWorkerKillSwitch();
await normalizeNoticeWhitespace();
await copyStaticHostSidecars();
await copyFile(
  path.resolve('tool', 'toolchain.json'),
  path.join(webRoot, 'release-toolchain.json'),
);

console.log(
  `Removed ${symbolFiles.length} renderer symbol files (${formatBytes(removedBytes)}) from the public release.`,
);
console.log(
  `Removed ${unreachableRendererFiles.length} unreachable renderer variant files (${formatBytes(removedRendererBytes)}) from the public release.`,
);
console.log(
  `Versioned entrypoints as ${releaseId} and renderer assets as ${engineRevision}.`,
);

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
  const contentPath = path.join(
    webRoot,
    'assets',
    'assets',
    'content',
    'portfolio.json',
  );
  const portfolio = JSON.parse(await readFile(contentPath, 'utf8'));
  const contentVersion = requiredString(
    portfolio.content_version,
    'content_version',
  );
  const displayName = requiredDisplayName(portfolio.profile?.display_name);
  const since = requiredString(portfolio.profile?.since, 'profile.since');
  const email = requiredString(portfolio.profile?.email, 'profile.email');
  const hasWork = Array.isArray(portfolio.systems) && portfolio.systems.length > 0;
  const hasEmail = email.includes('@');
  const locales = portfolio.site?.locales;
  if (
    !Array.isArray(locales) ||
    locales.length === 0 ||
    new Set(locales).size !== locales.length ||
    !locales.includes('en')
  ) {
    throw new Error('site.locales must contain unique locale codes including en');
  }

  const shellLocales = {};
  for (const localeValue of locales) {
    const locale = requiredString(localeValue, 'site.locales[]');
    if (!/^[a-z]{2}(?:-[A-Z]{2})?$/.test(locale)) {
      throw new Error(`Unsupported bootstrap locale code: ${locale}`);
    }
    const localePortfolio = locale === 'en'
      ? portfolio
      : JSON.parse(
          await readFile(
            path.join(
              webRoot,
              'assets',
              'assets',
              'content',
              'locales',
              `${locale}.json`,
            ),
            'utf8',
          ),
        );
    if (locale !== 'en' && localePortfolio.locale !== locale) {
      throw new Error(`content locale ${locale} does not declare its locale code`);
    }
    const translations = JSON.parse(
      await readFile(
        path.join(webRoot, 'assets', 'assets', 'i18n', `${locale}.json`),
        'utf8',
      ),
    );
    shellLocales[locale] = {
      direction: locale.startsWith('ar') ? 'rtl' : 'ltr',
      fontHref: bootstrapFontHref(locale),
      title: requiredString(localePortfolio.site?.title, `${locale}.site.title`),
      copy: {
        loadingPortfolio: requiredString(
          translations.accessibility?.loading_portfolio,
          `i18n.${locale}.accessibility.loading_portfolio`,
        ),
        loadFailure: requiredString(
          translations.accessibility?.load_failure,
          `i18n.${locale}.accessibility.load_failure`,
        ),
        retry: requiredString(
          translations.accessibility?.retry,
          `i18n.${locale}.accessibility.retry`,
        ),
      },
      markup: renderBootstrapShell({
        contentVersion,
        displayName,
        profile: localePortfolio.profile,
        since,
        translations,
        hasWork,
        hasEmail,
        locale,
      }),
    };
  }

  const localeBootstrap = `<script id="bootstrap-locale-state">
      (function selectBootstrapLocale() {
        'use strict';
        var locales = ${jsonForInlineScript(shellLocales)};
        var selected = 'en';
        try {
          var stored = window.localStorage.getItem('flutter.selected_language');
          if (stored !== null) {
            var decoded = stored;
            try { decoded = JSON.parse(stored); } catch (_) {}
            if (typeof decoded === 'string') selected = decoded;
          }
        } catch (_) {}
        if (!Object.prototype.hasOwnProperty.call(locales, selected)) {
          selected = 'en';
        }
        var shell = document.querySelector('#bootstrap-surface .bootstrap-shell');
        var surface = document.getElementById('bootstrap-surface');
        document.documentElement.lang = selected;
        document.documentElement.dir = locales[selected].direction;
        document.title = locales[selected].title;
        window.__portfolioBootstrapLocale = locales[selected].copy;
        if (locales[selected].fontHref) {
          var fontPreload = document.createElement('link');
          fontPreload.rel = 'preload';
          fontPreload.as = 'font';
          fontPreload.type = 'font/ttf';
          fontPreload.crossOrigin = 'anonymous';
          fontPreload.href = locales[selected].fontHref;
          document.head.appendChild(fontPreload);
        }
        if (surface) {
          surface.setAttribute('aria-label', locales[selected].copy.loadingPortfolio);
        }
        if (shell) shell.outerHTML = locales[selected].markup;
      })();
    </script>`;
  const shell = `    <!-- bootstrap-content:start -->
${shellLocales.en.markup}
    ${localeBootstrap}
    <!-- bootstrap-content:end -->`;

  const indexPath = path.join(webRoot, 'index.html');
  const index = await readFile(indexPath, 'utf8');
  const marker = /\s*<!-- bootstrap-content:start -->[\s\S]*?<!-- bootstrap-content:end -->/;
  if (!marker.test(index)) {
    throw new Error('index.html does not contain the bootstrap content markers');
  }
  await writeFile(indexPath, index.replace(marker, `\n${shell}`));
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
  const home = translations.home_section;
  const viewWork = requiredString(
    home?.view_work,
    `i18n.${locale}.home_section.view_work`,
  );
  const emailLabel = requiredString(
    home?.email,
    `i18n.${locale}.home_section.email`,
  );
  const facts = [
    [requiredString(home?.based_in, `i18n.${locale}.home_section.based_in`), location],
    [
      requiredString(
        home?.working_since,
        `i18n.${locale}.home_section.working_since`,
      ),
      since,
    ],
    [requiredString(home?.focus, `i18n.${locale}.home_section.focus`), primaryFocus],
  ];
  const factMarkup = facts
    .map(
      ([label, value]) => `      <li class="bootstrap-fact">
        <span class="bootstrap-fact-label">${escapeHtml(label)}</span>
        ${escapeHtml(value)}
      </li>`,
    )
    .join('\n');
  const actionMarkup = [
    hasWork
      ? `            <span class="bootstrap-action bootstrap-action--primary">${escapeHtml(viewWork)}</span>`
      : '',
    hasEmail
      ? `            <span class="bootstrap-action">${escapeHtml(emailLabel)}</span>`
      : '',
  ]
    .filter(Boolean)
    .join('\n');
  const actions = actionMarkup
    ? `\n          <div class="bootstrap-actions">\n${actionMarkup}\n          </div>`
    : '';
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

function jsonForInlineScript(value) {
  return JSON.stringify(value).replace(/[<>&\u2028\u2029]/g, (character) => ({
    '<': '\\u003c',
    '>': '\\u003e',
    '&': '\\u0026',
    '\u2028': '\\u2028',
    '\u2029': '\\u2029',
  })[character]);
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

async function normalizeNoticeWhitespace() {
  const noticesPath = path.join(webRoot, 'assets', 'NOTICES');
  const notices = await readFile(noticesPath, 'utf8');
  const normalized = notices.replace(/[\t ]+$/gm, '');
  if (normalized !== notices) await writeFile(noticesPath, normalized);
}

async function copyStaticHostSidecars() {
  for (const file of ['_headers', '_redirects']) {
    await copyFile(path.resolve('web', file), path.join(webRoot, file));
  }
}

async function writeLegacyServiceWorkerKillSwitch() {
  const source = `'use strict';

self.addEventListener('install', (event) => {
  self.skipWaiting();
});

self.addEventListener('activate', (event) => {
  event.waitUntil((async () => {
    const scope = self.registration.scope;
    const names = await caches.keys();
    await Promise.all(names.map(async (name) => {
      const cache = await caches.open(name);
      const requests = await cache.keys();
      if (
        requests.length > 0 &&
        requests.every((request) => request.url.startsWith(scope))
      ) {
        await caches.delete(name);
      }
    }));
    await self.registration.unregister();
  })());
});
`;
  await writeFile(path.join(webRoot, 'flutter_service_worker.js'), source);
}

async function collectFiles(directory) {
  const entries = await readdir(directory, { withFileTypes: true });
  const nested = await Promise.all(
    entries.map(async (entry) => {
      const entryPath = path.join(directory, entry.name);
      return entry.isDirectory() ? collectFiles(entryPath) : [entryPath];
    }),
  );
  return nested.flat();
}

async function removeEmptyDirectories(directory) {
  const entries = await readdir(directory, { withFileTypes: true });
  await Promise.all(
    entries
      .filter((entry) => entry.isDirectory())
      .map((entry) => removeEmptyDirectories(path.join(directory, entry.name))),
  );
  if ((await readdir(directory)).length === 0) {
    await rm(directory, { recursive: true, force: true });
  }
}

function formatBytes(bytes) {
  return `${(bytes / 1024 / 1024).toFixed(2)} MiB`;
}
