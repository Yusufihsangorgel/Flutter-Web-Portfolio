import assert from 'node:assert/strict';
import { mkdir, mkdtemp, readFile, rm, writeFile } from 'node:fs/promises';
import os from 'node:os';
import path from 'node:path';
import test from 'node:test';

import { renderLocaleData } from './render_release_index.mjs';
import { verifyReleaseDocument } from './verify_document.mjs';

const portfolio = {
  content_version: '1.2.3',
  profile: {
    name: 'Example',
    role: 'Engineer',
    summary: 'About',
    links: [{ url: 'https://example.com/profile' }],
  },
  experience: [],
  contributions: [],
  systems: [],
  packages: [],
  writing: [],
};

async function writeTree(root, files) {
  for (const [relative, content] of Object.entries(files)) {
    if (content === null) continue;
    const target = path.join(root, relative);
    await mkdir(path.dirname(target), { recursive: true });
    await writeFile(target, content);
  }
}

const shellPortfolio = {
  ...portfolio,
  site: { title: 'Example portfolio', locales: ['en'] },
  profile: {
    ...portfolio.profile,
    display_name: { primary: 'Example', accent: 'Portfolio' },
    headline: 'Building software',
    location: 'Remote',
    since: '2020',
    focus: ['Testing'],
    email: 'contact@example.com',
  },
};
const shellTranslations = {
  home_section: {
    based_in: 'Based in',
    working_since: 'Working since',
    focus: 'Focus area',
    email: 'Contact email',
  },
  accessibility: {
    loading_portfolio: 'Loading portfolio',
    load_failure: 'Load failed',
    retry: 'Retry',
  },
};
const shellReleaseId = 'a'.repeat(16);
const shellEngine = 'b'.repeat(40);
const shellHints = [
  `rel="preload" href="main.dart.wasm?v=${shellReleaseId}" as="fetch" type="application/wasm" crossorigin fetchpriority="high"`,
  `rel="modulepreload" href="main.dart.mjs?v=${shellReleaseId}" crossorigin fetchpriority="high"`,
  `rel="preload" href="canvaskit/${shellEngine}/skwasm.wasm" as="fetch" type="application/wasm" crossorigin fetchpriority="high"`,
];

async function shellReleaseIssues(
  overrides = {},
  record = shellPortfolio,
  translations = shellTranslations,
) {
  const root = await mkdtemp(path.join(os.tmpdir(), 'release-shell-'));
  const values = [
    record.profile.display_name.primary,
    record.profile.display_name.accent,
    record.profile.role,
    record.profile.headline,
    record.profile.location,
    record.profile.since,
    ...record.profile.focus,
    ...Object.values(translations.home_section),
  ];
  const markup = `<div class="bootstrap-shell" aria-hidden="true" data-content-version="${portfolio.content_version}">${values.join(' | ')}</div>`;
  const files = {
    'index.html': `<!-- static-document:start --><div id="static-document"><h1>Example</h1><h2>About</h2><a href="#about">About</a><a href="https://example.com/profile"></a></div><!-- static-document:end -->
      <div aria-busy="true"><!-- bootstrap-content:start -->${markup}<!-- bootstrap-content:end --></div>
      ${shellPortfolio.content_version}<!-- release-preloads:start -->${shellHints.join('\n')}<!-- release-preloads:end -->`,
    'flutter_bootstrap.js': JSON.stringify({
      mainWasmPath: `main.dart.wasm?v=${shellReleaseId}`,
      engineRevision: shellEngine,
    }),
    'bootstrap_locale.js': await readFile('web/bootstrap_locale.js', 'utf8'),
    'bootstrap_locales.js': renderLocaleData({
      en: {
        title: record.site.title,
        markup,
        copy: {
          loadingPortfolio: translations.accessibility.loading_portfolio,
          loadFailure: translations.accessibility.load_failure,
          retry: translations.accessibility.retry,
        },
      },
    }),
    'version.json': JSON.stringify({
      commit: 'c'.repeat(40),
      content_version: portfolio.content_version,
      built_at: '2026-09-29T00:00:00.000Z',
    }),
    'assets/assets/i18n/en.json': JSON.stringify(translations),
  };
  try {
    for (const [file, transform] of Object.entries(overrides)) files[file] = transform(files[file]);
    await writeTree(root, files);
    return await verifyReleaseDocument(root, record, []);
  } finally {
    await rm(root, { recursive: true, force: true });
  }
}

test('accepts the complete external-locale critical shell', async () => {
  assert.deepEqual(await shellReleaseIssues(), []);
});

test('accepts raw locale title and accessibility copy containing HTML characters', async () => {
  const record = {
    ...shellPortfolio,
    site: { ...shellPortfolio.site, title: 'Research & Development' },
  };
  const translations = {
    ...shellTranslations,
    accessibility: {
      loading_portfolio: 'Loading & waiting',
      load_failure: 'Load <failed>',
      retry: 'Retry "again"',
    },
  };
  assert.deepEqual(await shellReleaseIssues({}, record, translations), []);
});

for (const value of ['2020', 'Testing']) {
  test(`rejects critical shell without ${value}`, async () => {
    const issues = await shellReleaseIssues({
      'index.html': (html) => html.replace(value, 'stale'),
    });
    assert(
      issues.some((issue) => issue.includes('shell is stale')),
      issues.join('\n'),
    );
  });
}

for (const value of [
  'Example portfolio',
  'Testing',
  'Based in',
  'Working since',
  'Focus area',
  'Contact email',
]) {
  test(`rejects locale data without ${value}`, async () => {
    const issues = await shellReleaseIssues({
      'bootstrap_locales.js': (script) => script.replace(value, 'stale'),
    });
    assert(
      issues.some((issue) => issue.includes('locale content')),
      issues.join('\n'),
    );
  });
}

for (const value of ['JSON.parse(stored)', 'document.documentElement.dir = locale.direction']) {
  test(`requires locale restoration step ${value}`, async () => {
    const issues = await shellReleaseIssues({
      'bootstrap_locale.js': (script) => script.replace(value, 'missing'),
    });
    assert(
      issues.some((issue) => issue.includes('locale selection')),
      issues.join('\n'),
    );
  });
}

for (const hint of shellHints) {
  const attributes = hint.match(
    /rel="[^"]+"|as="[^"]+"|type="[^"]+"|crossorigin|fetchpriority="[^"]+"/g,
  );
  for (const attribute of attributes) {
    test(`requires ${attribute} on ${hint.match(/href="([^"]+)/)[1]}`, async () => {
      const issues = await shellReleaseIssues({
        'index.html': (html) => html.replace(hint, hint.replace(attribute, '')),
      });
      assert(
        issues.some((issue) => issue.includes('preload')),
        issues.join('\n'),
      );
    });
  }
}

test('static document content cannot mask stale bootstrap shell content', async () => {
  const issues = await shellReleaseIssues({
    'index.html': (html) =>
      html.replace('Building software', 'stale').replace('</h1>', '</h1>Building software'),
  });
  assert(
    issues.some((issue) => issue.includes('shell is stale')),
    issues.join('\n'),
  );
});

for (const value of ['Example', 'Portfolio']) {
  test(`requires display name part ${value} in the bootstrap shell`, async () => {
    const issues = await shellReleaseIssues({
      'index.html': (html) =>
        html.replace(
          /<!-- bootstrap-content:start -->([\s\S]*?)<!-- bootstrap-content:end -->/,
          (block) => block.replace(value, 'stale'),
        ),
    });
    assert(
      issues.some((issue) => issue.includes('shell is stale')),
      issues.join('\n'),
    );
  });
}

test('requires the localized work action when work is present', async () => {
  const record = { ...shellPortfolio, systems: [{ name: 'Example work', summary: 'Work' }] };
  const issues = await shellReleaseIssues(
    {
      'index.html': (html) =>
        html.replace('<h2>About</h2>', '<h2>About</h2><h2>Work</h2><a href="#work">Work</a>'),
      'assets/assets/i18n/en.json': (json) => {
        const translations = JSON.parse(json);
        translations.home_section.view_work = 'View work';
        return JSON.stringify(translations);
      },
    },
    record,
  );
  assert.deepEqual(issues, ['critical shell is missing en locale content']);
});
