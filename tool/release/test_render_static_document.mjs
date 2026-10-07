import assert from 'node:assert/strict';
import test from 'node:test';

import { renderStaticDocument, evidenceUrls } from './render_static_document.mjs';

const fixture = {
  profile: {
    name: 'Ada <Lovelace>',
    role: 'Engineer & writer',
    summary: 'A < B & C',
    background: 'Builds "tools"',
    email: 'ada@example.com',
    links: [{ label: 'Profile', url: 'https://example.com/?a=1&b=2' }],
  },
  experience: [{ company: 'Example', role: 'Developer', summary: 'Built apps' }],
  contributions: [
    {
      title: 'PR',
      project: 'Project',
      url: 'https://example.com/pr',
      issue_url: 'https://example.com/issue',
    },
  ],
  systems: [
    {
      name: 'Work',
      summary: 'System',
      url: 'https://example.com/work',
      evidence: [{ label: 'Proof', url: 'https://example.com/proof' }],
    },
  ],
  packages: [
    {
      name: 'Package',
      description: 'Library',
      url: 'https://example.com/package',
      repository: 'https://example.com/repo',
    },
  ],
  writing: [{ title: 'Article', url: 'https://example.com/article' }],
  writing_sources: [{ label: 'Archive', profile_url: 'https://example.com/archive' }],
  sources: [{ label: 'Source', url: 'https://example.com/source' }],
};

test('escapes text and attributes while rendering one heading per chapter', () => {
  const html = renderStaticDocument(fixture);
  assert.match(html, /<h1>Ada &lt;Lovelace&gt;<\/h1>/);
  assert.match(html, /A &lt; B &amp; C/);
  assert.match(html, /href="https:\/\/example.com\/\?a=1&amp;b=2"/);
  assert.doesNotMatch(html, /Ada <Lovelace>|A < B|href="https:\/\/example.com\/\?a=1&b=2"/);
  assert.equal((html.match(/<h1>/g) ?? []).length, 1);
  assert.equal((html.match(/<h2>/g) ?? []).length, 6);
});

test('omits optional chapters with empty arrays', () => {
  const empty = { ...fixture, contributions: [], systems: [], packages: [], writing: [] };
  const html = renderStaticDocument(empty);
  assert.equal((html.match(/<h2>/g) ?? []).length, 2);
  assert.doesNotMatch(html, /Open Source|<h2>Work<\/h2>|Packages|Writing/);
});

test('renders one anchor for each evidence URL', () => {
  const html = renderStaticDocument(fixture);
  const urls = evidenceUrls(fixture);
  assert.equal((html.match(/data-evidence-link=/g) ?? []).length, urls.length);
  for (const url of urls) {
    assert(html.includes(`href="${url.replaceAll('&', '&amp;')}"`));
  }
  assert.match(html, /href="mailto:ada@example.com"/);
});

test('rejects unsafe link schemes', () => {
  const unsafe = { ...fixture, writing: [{ title: 'Bad', url: 'javascript:alert(1)' }] };
  assert.throws(() => renderStaticDocument(unsafe), /Unsafe URL/);
});
