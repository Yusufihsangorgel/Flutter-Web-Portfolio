import assert from 'node:assert/strict';
import { spawnSync } from 'node:child_process';
import { mkdir, mkdtemp, readFile, rm } from 'node:fs/promises';
import path from 'node:path';
import { test } from 'node:test';
import { fileURLToPath } from 'node:url';

import { formatDate, formatPeriod, renderResumeHtml } from './render_resume_html.mjs';

const root = fileURLToPath(new URL('../../', import.meta.url));
const record = JSON.parse(await readFile(path.join(root, 'assets/content/portfolio.json'), 'utf8'));

test('every experience entry retains its order, facts and normalized dates', () => {
  const html = renderResumeHtml(record);
  let previous = -1;
  for (const entry of record.experience) {
    const position = html.indexOf(entry.company);
    assert.ok(position > previous, entry.company);
    previous = position;
    assert.ok(html.includes(entry.role));
    assert.ok(html.includes(formatPeriod(entry.period)));
    assert.ok(html.includes(entry.summary));
  }
  assert.ok(html.includes(record.profile.name));
  assert.ok(html.includes(record.profile.summary));
});

test('empty and missing optional sections are omitted, without owner-specific defaults', () => {
  for (const optional of [{}, { experience: [], education: [], contributions: [], packages: [], writing: [] }]) {
    const html = renderResumeHtml({ profile: { name: 'Example' }, ...optional });
    assert.doesNotMatch(html, /<h2>|undefined|null/);
    assert.ok(html.includes('<h1>Example</h1>'));
    assert.ok(!html.includes(record.profile.name));
    assert.ok(!html.includes(record.profile.email));
  }
});

test('rendering is pure and uses semantic text with offline A4 and Letter print CSS', () => {
  const original = structuredClone(record);
  const html = renderResumeHtml(record);
  assert.equal(html, renderResumeHtml(record));
  assert.deepEqual(record, original);
  assert.match(html, /<main>.*<header><h1>/s);
  assert.match(html, /<h2>Experience<\/h2><ul><li><h3>/);
  assert.match(html, /@page \{ size: A4;/);
  assert.match(renderResumeHtml(record, { paper: 'letter' }), /@page \{ size: Letter;/);
  assert.doesNotMatch(html, /<table|<img|<script|<iframe|@import|url\(/i);
  assert.throws(() => renderResumeHtml(record, { paper: 'legal' }));
});

test('all links are visible absolute HTTPS URLs drawn from the record', () => {
  const html = renderResumeHtml(record);
  const source = JSON.stringify(record);
  const links = [...html.matchAll(/<a href="([^"]+)">([^<]+)<\/a>/g)];
  assert.ok(links.length > 0);
  for (const [, href, visible] of links) {
    assert.equal(new URL(href).protocol, 'https:');
    assert.equal(href, visible);
    assert.ok(source.includes(href.replaceAll('&amp;', '&')));
  }
  for (const url of ['http://example.com', '/relative', 'javascript:alert(1)', 'https://private@example.com']) {
    assert.throws(() => renderResumeHtml({ profile: { name: 'Example', links: [{ url }] } }));
  }
});

test('dates are consistent and invalid calendar dates fail', () => {
  assert.equal(formatDate('2024-02-29'), 'February 29, 2024');
  assert.equal(formatDate('2026-09-24'), 'September 24, 2026');
  assert.equal(formatPeriod(' March 2021 – Present '), 'March 2021 — Present');
  assert.equal(formatPeriod('2021 - 2025'), '2021 — 2025');
  for (const value of ['2025-02-29', '2026-13-01', '2026-9-1', 'not-a-date']) assert.throws(() => formatDate(value));
});

test('content is escaped and selections use only authored fields', () => {
  const html = renderResumeHtml({
    profile: { name: 'Example <&>', role: '<script>role</script>', email: 'resume@example.com' },
    contributions: [{ project: 'Project', title: '<b>Change</b>', date: '2026-09-24', status: 'open', url: 'https://example.com/change?a=1&b=2' }],
  });
  assert.match(html, /Example &lt;&amp;&gt;/);
  assert.doesNotMatch(html, /<script>|<b>Change/);
  assert.match(html, /September 24, 2026 · open/);
  assert.match(html, /https:\/\/example.com\/change\?a=1&amp;b=2/);
  assert.throws(() => renderResumeHtml({ profile: {} }), /profile name/);
});

test('the actual initializer custom-output record renders without demo identity', async () => {
  await mkdir(path.join(root, 'build'), { recursive: true });
  const temporary = await mkdtemp(path.join(root, 'build/resume-init-'));
  try {
    const output = path.join(temporary, 'portfolio.json');
    const result = spawnSync(process.execPath, [
      path.join(root, 'tool/init_portfolio.mjs'), '--name', 'Example', '--role', 'Engineer',
      '--email', 'resume@example.com', '--site', 'https://example.com', '--location', 'Example',
      '--focus', 'Software, Testing, Delivery', '--output', output,
    ], { cwd: root, encoding: 'utf8', input: '' });
    assert.equal(result.status, 0, result.stderr);
    const clone = JSON.parse(await readFile(output, 'utf8'));
    const html = renderResumeHtml(clone);
    assert.ok(html.includes(clone.profile.name));
    assert.ok(html.includes(clone.profile.email));
    assert.doesNotMatch(html, /<h2>/);
    assert.ok(!html.includes(record.profile.name));
    assert.ok(!html.includes(record.profile.email));
  } finally {
    await rm(temporary, { recursive: true, force: true });
  }
});

test('long experience records retain all text instead of hiding overflow', () => {
  const summary = 'Complete authored text. '.repeat(200);
  const html = renderResumeHtml({ profile: { name: 'Example' }, experience: [{ company: 'Example', role: 'Engineer', period: '2021 — Present', summary }] });
  assert.ok(html.includes(summary));
});

test('selection follows authored featured flags and caps in source order', () => {
  const packages = Array.from({ length: 6 }, (_, index) => ({ name: `Package ${index}`, featured: index > 0, url: `https://example.com/package/${index}` }));
  const selected = renderResumeHtml({ profile: { name: 'Example' }, packages });
  assert.ok(!selected.includes('<h3>Package 0</h3>'));
  [1, 2, 3].forEach((index) => assert.ok(selected.includes(`<h3>Package ${index}</h3>`)));
  [4, 5].forEach((index) => assert.ok(!selected.includes(`<h3>Package ${index}</h3>`)));
  const fallback = renderResumeHtml({ profile: { name: 'Example' }, packages: packages.map((entry) => ({ ...entry, featured: false })) });
  [0, 1, 2].forEach((index) => assert.ok(fallback.includes(`<h3>Package ${index}</h3>`)));
});
