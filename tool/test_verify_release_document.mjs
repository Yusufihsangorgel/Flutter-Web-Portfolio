import assert from 'node:assert/strict';
import { mkdir, mkdtemp, readFile, rm, writeFile } from 'node:fs/promises';
import os from 'node:os';
import path from 'node:path';
import test from 'node:test';
import { gzipSync } from 'node:zlib';

import { precompressAssets } from './release/bundle_helpers.mjs';
import { renderReleaseIndex, renderLocaleData } from './release/render_release_index.mjs';
import { checkCompression, checkDocument, checkMetadata } from './release/verify_document.mjs';
import { verifyStatic404Release } from './release/verify_static_404.mjs';

const portfolio = {
  content_version: '1.2.3',
  profile: { name: 'Example', role: 'Engineer', summary: 'About', links: [{ url: 'https://example.com/profile' }] },
  experience: [], contributions: [], systems: [], packages: [], writing: [],
};

test('checks headings and every evidence link', () => {
  const html = '<!-- static-document:start --><div id="static-document"><h1>Example</h1><a href="#about">About</a><h2>About</h2><a href="https://example.com/profile"></a></div><!-- static-document:end -->';
  assert.deepEqual(checkDocument(html, portfolio), []);
  assert(checkDocument(html.replace('<h1>Example</h1>', ''), portfolio).some((issue) => issue.includes('h1')));
  assert(checkDocument(html.replace('https://example.com/profile', '#missing'), portfolio).some((issue) => issue.includes('evidence')));
  assert(checkDocument(`${html}<script>alert(1)</script>`, portfolio).some((issue) => issue.includes('inline')));
});

test('checks deterministic gzip siblings for large assets', () => {
  const bytes = Buffer.from('x'.repeat(1025));
  const file = { name: 'index.html', bytes, compressed: gzipSync(bytes, { level: 9, mtime: 0 }) };
  assert.deepEqual(checkCompression([file]), []);
  assert(checkCompression([{ ...file, compressed: null }]).some((issue) => issue.includes('index.html.gz')));
  assert(checkCompression([{ ...file, compressed: gzipSync(Buffer.from('wrong')) }]).some((issue) => issue.includes('index.html.gz')));
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
    assert(compressed.equals(gzipSync(source, { level: 9, mtime: 0 })));
    assert.deepEqual([...compressed.subarray(3, 8)], [0, 0, 0, 0, 0]);
    assert.equal(compressed[8], 2);
    assert.equal(await precompressAssets(root), 1);
    assert((await readFile(path.join(root, 'skwasm.wasm.gz'))).equals(compressed));
  } finally {
    await rm(root, { recursive: true, force: true });
  }
});

test('checks release metadata fields', () => {
  const valid = { version: '1', commit: 'a'.repeat(40), content_version: '1.2.3', built_at: '2026-09-29T00:00:00.000Z' };
  assert.deepEqual(checkMetadata(valid, portfolio), []);
  assert(checkMetadata({ ...valid, content_version: 'old' }, portfolio).length > 0);
  assert(checkMetadata({ ...valid, commit: '' }, portfolio).length > 0);
});

test('inserts the document and shell at source markers without duplicate ids', () => {
  const source = '<!-- static-document:start --><!-- static-document:end --><div><!-- bootstrap-content:start --><!-- bootstrap-content:end --></div>';
  const output = renderReleaseIndex(source, '<div class="bootstrap-shell"></div>', '<div id="static-document"></div>');
  assert.equal((output.match(/id="static-document"/g) ?? []).length, 1);
  assert.match(output, /\n<div id="static-document"><\/div>\n/);
  assert.match(output, /\n<div class="bootstrap-shell"><\/div>\n/);
  assert.throws(() => renderReleaseIndex('no markers', '', ''), /markers/);
});

test('emits parseable locale data without an HTML script boundary', () => {
  const script = renderLocaleData({ en: { title: '</script><script>alert(1)</script>' } });
  assert(script.endsWith('\n'));
  assert.doesNotMatch(script, /<script>/);
  const json = script.match(/^window\.__portfolioBootstrapLocales = ([\s\S]*);\n$/)?.[1];
  assert.equal(JSON.parse(json).en.title, '</script><script>alert(1)</script>');
});

const nginx = 'server {\n  location / { try_files $uri $uri/ =404; }\n  error_page 404 /404.html;\n}\n';
const securityText = 'Contact: https://example.invalid/security';
const validSource = {
  'nginx/default.conf': nginx,
  Dockerfile: 'COPY nginx/default.conf /etc/nginx/conf.d/default.conf\nCOPY build/web /usr/share/nginx/html\n',
  'web/_redirects': "# Unknown paths use each host's 404 response.\n",
  'web/404.html': '<h1>Not Found</h1>',
  'web/.well-known/security.txt': securityText,
};
const validRelease = { '404.html': '<h1>Not Found</h1>', '.well-known/security.txt': securityText };
const nginxFailure = 'Nginx must return 404';

// [name, source overrides, release overrides, expected issue fragment or null]; a null file is not written.
const static404Cases = [
  ['accepts the static 404 contract', {}, {}, null],
  ['requires 404.html in the release', {}, { '404.html': null }, '404.html is missing'],
  ['requires security.txt in the release', {}, { '.well-known/security.txt': null }, 'security.txt is missing'],
  ['rejects a stale security.txt', {}, { '.well-known/security.txt': 'stale' }, 'security.txt is stale'],
  ['rejects an index fallback in try_files', { 'nginx/default.conf': nginx.replace('=404', '/index.html') }, {}, nginxFailure],
  ['rejects a server-level catch-all rewrite', { 'nginx/default.conf': nginx.replace('  location /', '  rewrite ^ /index.html;\n  location /') }, {}, nginxFailure],
  ['rejects a rewrite beside error_page', { 'nginx/default.conf': nginx.replace('error_page', 'rewrite ^ /index.html; error_page') }, {}, nginxFailure],
  ['rejects a success override', { 'nginx/default.conf': nginx.replace('=404;', '=404; return 200;') }, {}, nginxFailure],
  ['rejects error_page 404 to the index', { 'nginx/default.conf': nginx.replace('  error_page', '  error_page 404 /index.html;\n  error_page') }, {}, nginxFailure],
  ['rejects error_page 404 = to the index', { 'nginx/default.conf': nginx.replace('  error_page', '  error_page 404 = /index.html;\n  error_page') }, {}, nginxFailure],
  ['allows a narrow rewrite in another location', { 'nginx/default.conf': nginx.replace('  error_page', '  location /old { rewrite ^ /index.html; }\n  error_page') }, {}, null],
  ['allows a narrow error_page in another location', { 'nginx/default.conf': nginx.replace('  error_page', '  location /old { error_page 404 /index.html; }\n  error_page') }, {}, null],
  ['ignores commented directives', { 'nginx/default.conf': nginx.replace('  error_page', '  # rewrite ^ /index.html;\n  error_page') }, {}, null],
  ['rejects an index fallback in _redirects', { 'web/_redirects': '/*  /index.html  200\n' }, {}, '_redirects contains an index fallback'],
  ['requires the Nginx copy in the Dockerfile', { Dockerfile: 'COPY build/web /usr/share/nginx/html\n' }, {}, 'Dockerfile does not package'],
  ['requires the release copy in the Dockerfile', { Dockerfile: 'COPY nginx/default.conf /etc/nginx/conf.d/default.conf\n' }, {}, 'Dockerfile does not package'],
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
      else assert(issues.some((issue) => issue.includes(expected)), issues.join('\n') || 'no issues reported');
    } finally {
      await rm(root, { recursive: true, force: true });
    }
  });
}
