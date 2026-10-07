import assert from 'node:assert/strict';
import { mkdir, mkdtemp, readFile, rm, writeFile } from 'node:fs/promises';
import os from 'node:os';
import path from 'node:path';
import test from 'node:test';
import { gzipSync } from 'node:zlib';

import { precompressAssets, resolveReleaseCommit } from './bundle_helpers.mjs';
import { renderNotFoundPage } from './not_found_page.mjs';
import { renderReleaseIndex, renderLocaleData } from './render_release_index.mjs';
import { checkCompression, checkDocument, checkMetadata } from './verify_document.mjs';
import { verifyStatic404Release } from './verify_static_404.mjs';

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

test('checks headings and every evidence link', () => {
  const html =
    '<!-- static-document:start --><div id="static-document"><h1>Example</h1><a href="#about">About</a><h2>About</h2><a href="https://example.com/profile"></a></div><!-- static-document:end -->';
  assert.deepEqual(checkDocument(html, portfolio), []);
  assert(
    checkDocument(html.replace('<h1>Example</h1>', ''), portfolio).some((issue) =>
      issue.includes('h1'),
    ),
  );
  assert(
    checkDocument(html.replace('https://example.com/profile', '#missing'), portfolio).some(
      (issue) => issue.includes('evidence'),
    ),
  );
  assert(
    checkDocument(`${html}<script>alert(1)</script>`, portfolio).some((issue) =>
      issue.includes('inline'),
    ),
  );
});

test('checks deterministic gzip siblings for large assets', () => {
  const bytes = Buffer.from('x'.repeat(1025));
  const file = { name: 'index.html', bytes, compressed: gzipSync(bytes, { level: 9 }) };
  assert.deepEqual(checkCompression([file]), []);
  assert(
    checkCompression([{ ...file, compressed: null }]).some((issue) =>
      issue.includes('index.html.gz'),
    ),
  );
  assert(
    checkCompression([{ ...file, compressed: gzipSync(Buffer.from('wrong')) }]).some((issue) =>
      issue.includes('index.html.gz'),
    ),
  );
});

test('precompresses eligible assets with reproducible bytes', async () => {
  const root = await mkdtemp(path.join(os.tmpdir(), 'compression-test-'));
  try {
    const source = Buffer.from('renderer'.repeat(300));
    await writeFile(path.join(root, 'skwasm.wasm'), source);
    await writeFile(path.join(root, 'small.js'), 'short');
    await writeFile(path.join(root, 'image.png'), source);
    assert.equal(await precompressAssets(root), 1);
    const compressed = await readFile(path.join(root, 'skwasm.wasm.gz'));
    assert(compressed.equals(gzipSync(source, { level: 9 })));
    assert.deepEqual([...compressed.subarray(3, 8)], [0, 0, 0, 0, 0]);
    assert.equal(compressed[8], 2);
    assert.equal(await precompressAssets(root), 1);
    assert((await readFile(path.join(root, 'skwasm.wasm.gz'))).equals(compressed));
  } finally {
    await rm(root, { recursive: true, force: true });
  }
});

test('checks release metadata fields', () => {
  const valid = {
    version: '1',
    commit: 'a'.repeat(40),
    content_version: '1.2.3',
    built_at: '2026-09-29T00:00:00.000Z',
  };
  assert.deepEqual(checkMetadata(valid, portfolio), []);
  assert(checkMetadata({ ...valid, content_version: 'old' }, portfolio).length > 0);
  assert(checkMetadata({ ...valid, commit: '' }, portfolio).length > 0);
});

test('resolves the built commit from a provider variable before git', () => {
  const first = 'a'.repeat(40);
  const second = 'b'.repeat(40);
  const noGit = () => {
    throw new Error('not a git checkout');
  };
  assert.equal(resolveReleaseCommit({ GITHUB_SHA: first, COMMIT_REF: second }, noGit), first);
  for (const name of ['VERCEL_GIT_COMMIT_SHA', 'COMMIT_REF', 'CF_PAGES_COMMIT_SHA']) {
    assert.equal(resolveReleaseCommit({ [name]: second }, noGit), second);
  }
  assert.equal(
    resolveReleaseCommit({}, () => first),
    first,
  );
  assert.throws(() => resolveReleaseCommit({}, noGit), /needs the built commit/);
});

test('inserts the document and shell at source markers without duplicate ids', () => {
  const source =
    '<!-- static-document:start --><!-- static-document:end --><div><!-- bootstrap-content:start --><!-- bootstrap-content:end --></div>';
  const output = renderReleaseIndex(
    source,
    '<div class="bootstrap-shell"></div>',
    '<div id="static-document"></div>',
  );
  assert.equal((output.match(/id="static-document"/g) ?? []).length, 1);
  assert.match(output, /\n<div id="static-document"><\/div>\n/);
  assert.match(output, /\n<div class="bootstrap-shell"><\/div>\n/);
  assert.throws(() => renderReleaseIndex('no markers', '', ''), /markers/);
});

test('emits parseable locale data without an HTML script boundary', () => {
  const title = '</script><SCRIPT>alert(1)</Script ><!-- & -->';
  const script = renderLocaleData({ en: { title } });
  assert(script.endsWith('\n'));
  // No markup character survives, so no tag in any letter case can end the script element.
  for (const character of ['<', '>', '&'])
    assert(!script.includes(character), `${character} leaked`);
  const json = script.match(/^window\.__portfolioBootstrapLocales = ([\s\S]*);\n$/)?.[1];
  assert.equal(JSON.parse(json).en.title, title);
});

const nginx =
  'server {\n  location / { try_files $uri $uri/ =404; }\n  error_page 404 /404.html;\n}\n';
const securityText = 'Contact: https://example.invalid/security';
const validSource = {
  'nginx/default.conf': nginx,
  Dockerfile:
    'COPY nginx/default.conf /etc/nginx/conf.d/default.conf\nCOPY build/web /usr/share/nginx/html\n',
  'web/_redirects': "# Unknown paths use each host's 404 response.\n",
  'web/404.html': notFoundPage('/'),
  'web/.well-known/security.txt': securityText,
};
const validRelease = {
  'index.html': '<base href="/">',
  '404.html': notFoundPage('/'),
  '.well-known/security.txt': securityText,
};
const projectSiteRelease = {
  'index.html': '<base href="/portfolio/">',
  '404.html': notFoundPage('/portfolio/'),
};
const nginxFailure = 'Nginx must return 404';

function notFoundPage(base) {
  return `<base href="${base}"><h1>Not Found</h1><a href="./">Home</a>`;
}

// [name, source overrides, release overrides, expected issue fragment or null]; a null file is not written.
/** @type {Array<[string, Record<string, string | null>, Record<string, string | null>, string | null]>} */
const static404Cases = [
  ['accepts the static 404 contract', {}, {}, null],
  ['requires 404.html in the release', {}, { '404.html': null }, '404.html is missing'],
  ['accepts a 404 page on a project site base', {}, projectSiteRelease, null],
  [
    'rejects a root base on a project site',
    {},
    { 'index.html': projectSiteRelease['index.html'] },
    '404.html is stale',
  ],
  [
    'requires the source 404 base',
    { 'web/404.html': '<h1>Not Found</h1>' },
    {},
    '404.html cannot be checked',
  ],
  [
    'requires a release base href',
    {},
    { 'index.html': '<title>No base</title>' },
    '404.html cannot be checked',
  ],
  [
    'rejects an unsafe release base href',
    {},
    { 'index.html': '<base href="/a/../b/">' },
    '404.html cannot be checked',
  ],
  [
    'requires security.txt in the release',
    {},
    { '.well-known/security.txt': null },
    'security.txt is missing',
  ],
  [
    'rejects a stale security.txt',
    {},
    { '.well-known/security.txt': 'stale' },
    'security.txt is stale',
  ],
  [
    'rejects an index fallback in try_files',
    { 'nginx/default.conf': nginx.replace('=404', '/index.html') },
    {},
    nginxFailure,
  ],
  [
    'rejects a server-level catch-all rewrite',
    {
      'nginx/default.conf': nginx.replace('  location /', '  rewrite ^ /index.html;\n  location /'),
    },
    {},
    nginxFailure,
  ],
  [
    'rejects a rewrite beside error_page',
    { 'nginx/default.conf': nginx.replace('error_page', 'rewrite ^ /index.html; error_page') },
    {},
    nginxFailure,
  ],
  [
    'rejects a success override',
    { 'nginx/default.conf': nginx.replace('=404;', '=404; return 200;') },
    {},
    nginxFailure,
  ],
  [
    'rejects error_page 404 to the index',
    {
      'nginx/default.conf': nginx.replace(
        '  error_page',
        '  error_page 404 /index.html;\n  error_page',
      ),
    },
    {},
    nginxFailure,
  ],
  [
    'rejects error_page 404 = to the index',
    {
      'nginx/default.conf': nginx.replace(
        '  error_page',
        '  error_page 404 = /index.html;\n  error_page',
      ),
    },
    {},
    nginxFailure,
  ],
  [
    'allows a narrow rewrite in another location',
    {
      'nginx/default.conf': nginx.replace(
        '  error_page',
        '  location /old { rewrite ^ /index.html; }\n  error_page',
      ),
    },
    {},
    null,
  ],
  [
    'allows a narrow error_page in another location',
    {
      'nginx/default.conf': nginx.replace(
        '  error_page',
        '  location /old { error_page 404 /index.html; }\n  error_page',
      ),
    },
    {},
    null,
  ],
  [
    'allows a narrow rewrite in a quoted regex location',
    {
      'nginx/default.conf': nginx.replace(
        '  error_page',
        '  location ~ "^/old{1,2}$" { rewrite ^ /index.html; }\n  error_page',
      ),
    },
    {},
    null,
  ],
  [
    'ignores commented directives',
    {
      'nginx/default.conf': nginx.replace(
        '  error_page',
        '  # rewrite ^ /index.html;\n  error_page',
      ),
    },
    {},
    null,
  ],
  [
    'rejects an index fallback in _redirects',
    { 'web/_redirects': '/*  /index.html  200\n' },
    {},
    '_redirects contains an index fallback',
  ],
  [
    'requires the Nginx copy in the Dockerfile',
    { Dockerfile: 'COPY build/web /usr/share/nginx/html\n' },
    {},
    'Dockerfile does not package',
  ],
  [
    'requires the release copy in the Dockerfile',
    { Dockerfile: 'COPY nginx/default.conf /etc/nginx/conf.d/default.conf\n' },
    {},
    'Dockerfile does not package',
  ],
];

async function writeTree(root, files) {
  for (const [relative, content] of Object.entries(files)) {
    if (content === null) continue;
    const target = path.join(root, relative);
    await mkdir(path.dirname(target), { recursive: true });
    await writeFile(target, content);
  }
}

for (const [name, sourceOverrides, releaseOverrides, expected] of static404Cases) {
  test(`static 404 contract: ${name}`, async () => {
    const root = await mkdtemp(path.join(os.tmpdir(), 'static-404-'));
    const sourceRoot = path.join(root, 'source');
    const webRoot = path.join(root, 'release');
    try {
      await writeTree(sourceRoot, { ...validSource, ...sourceOverrides });
      await writeTree(webRoot, { ...validRelease, ...releaseOverrides });
      const issues = await verifyStatic404Release({ sourceRoot, webRoot });
      if (expected === null) assert.deepEqual(issues, []);
      else
        assert(
          issues.some((issue) => issue.includes(expected)),
          issues.join('\n') || 'no issues reported',
        );
    } finally {
      await rm(root, { recursive: true, force: true });
    }
  });
}

test('the 404 home link resolves to the site root at a domain root and on a project site', async () => {
  const source = await readFile('web/404.html', 'utf8');
  for (const base of ['/', '/portfolio/']) {
    const page = renderNotFoundPage(source, base);
    const declared = page.match(/<base href="([^"]*)">/)?.[1];
    const link = page.match(/<a href="([^"]*)">Return to the home page<\/a>/)?.[1];
    assert.ok(declared && link, '404.html must keep its base and home link');
    const missing = new URL(`${base}deep/missing/path`, 'https://example.com');
    assert.equal(new URL(link, new URL(declared, missing)).href, `https://example.com${base}`);
  }
});

test('checks an adversarial Nginx location in linear time', async () => {
  const root = await mkdtemp(path.join(os.tmpdir(), 'static-404-redos-'));
  try {
    const adversarial = nginx.replace(
      '  error_page',
      `  location ${'""'.repeat(50_000)}\n  error_page`,
    );
    await writeTree(path.join(root, 'source'), {
      ...validSource,
      'nginx/default.conf': adversarial,
    });
    await writeTree(path.join(root, 'release'), validRelease);
    const started = performance.now();
    const issues = await verifyStatic404Release({
      sourceRoot: path.join(root, 'source'),
      webRoot: path.join(root, 'release'),
    });
    assert(performance.now() - started < 1000, 'the Nginx check must not backtrack');
    assert.deepEqual(issues, []);
  } finally {
    await rm(root, { recursive: true, force: true });
  }
});
