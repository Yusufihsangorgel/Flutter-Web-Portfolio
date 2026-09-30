import assert from 'node:assert/strict';
import { readFile } from 'node:fs/promises';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import test from 'node:test';

import { renderStarterReadme } from './starter_readme.mjs';
import {
  collectTemplateIdentityMarkers,
  findTemplateIdentityResidue,
} from './template_identity_markers.mjs';

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const template = JSON.parse(await readFile(path.join(root, 'assets/content/portfolio.json')));
const markers = [
  'portfolio-ci',
  'portfolio-template',
  'portfolio-demo',
  'portfolio-onboarding',
  'portfolio-record-intro',
  'portfolio-record',
];

test('starter README contains only the new identity and ordered sync markers', () => {
  const readme = renderStarterReadme({
    name: 'Ada Lovelace',
    site: 'https://example.com',
    repository: 'example/portfolio',
  });
  let previousEnd = -1;
  for (const marker of markers) {
    const start = `<!-- ${marker}:start -->`;
    const end = `<!-- ${marker}:end -->`;
    const startAt = readme.indexOf(start);
    const endAt = readme.indexOf(end);
    assert.ok(startAt > previousEnd && endAt > startAt, marker);
    assert.equal(readme.split(start).length, 2, `${marker} start count`);
    assert.equal(readme.split(end).length, 2, `${marker} end count`);
    assert.match(readme.slice(startAt, endAt), /^<!-- [^\n]+ -->\n\n$/);
    previousEnd = endAt;
  }
  assert.match(readme, /Ada Lovelace/);
  assert.match(readme, /https:\/\/example\.com/);
  assert.match(readme, /docs\/CUSTOMIZE\.md/);
  assert.doesNotMatch(readme, /home-desktop\.jpg|docs\/readme\//);
  assert.deepEqual(findTemplateIdentityResidue(readme, collectTemplateIdentityMarkers(template)), []);
});
