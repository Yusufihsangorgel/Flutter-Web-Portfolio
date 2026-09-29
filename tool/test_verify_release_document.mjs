import assert from 'node:assert/strict';
import { mkdtemp, readFile, rm, writeFile } from 'node:fs/promises';
import path from 'node:path';
import test from 'node:test';
import { gzipSync } from 'node:zlib';

import { precompressAssets } from './release/bundle_helpers.mjs';
import { renderReleaseIndex, renderLocaleData } from './release/render_release_index.mjs';
import { checkCompression, checkDocument, checkMetadata } from './release/verify_document.mjs';

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
  const root = await mkdtemp(path.resolve('tool/release', '.compression-test-'));
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
