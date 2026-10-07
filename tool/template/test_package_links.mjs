import assert from 'node:assert/strict';
import { readFile } from 'node:fs/promises';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import test from 'node:test';

import { findTemplateRepository, rewritePubspecLinks } from './package_links.mjs';

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '../..');
const manifest = JSON.parse(await readFile(path.join(root, 'package.json'), 'utf8'));
const original = findTemplateRepository(manifest);
const replacement = 'https://github.com/example/portfolio';

test('rewrites only links to the original repository', () => {
  const input = `name: sample\nrepository: ${original}/tree/main/packages/sample\nhomepage: '${original}'\nissue_tracker: "${original}/issues"\ndocumentation: ${original}/wiki\n`;
  assert.equal(
    rewritePubspecLinks(input, original, replacement),
    `name: sample\nrepository: ${replacement}/tree/main/packages/sample\nhomepage: '${replacement}'\nissue_tracker: "${replacement}/issues"\ndocumentation: ${replacement}/wiki\n`,
  );
});

test('leaves unrelated repositories and fields unchanged', () => {
  const external = 'repository: https://github.com/example/other\n';
  const noFields = 'name: sample\ndescription: A sample package.\n';
  assert.equal(rewritePubspecLinks(external, original, replacement), external);
  assert.equal(rewritePubspecLinks(noFields, original, replacement), noFields);
  assert.equal(
    rewritePubspecLinks(`repository: ${original}-fork\n`, original, replacement),
    `repository: ${original}-fork\n`,
  );
});

test('reads the source repository from package.json', () => {
  assert.equal(
    findTemplateRepository({ repository: { url: 'git+https://github.com/a/b.git' } }),
    'https://github.com/a/b',
  );
  assert.throws(() => findTemplateRepository({}), /GitHub source repository/);
});
