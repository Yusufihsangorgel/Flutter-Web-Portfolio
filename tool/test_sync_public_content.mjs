import assert from 'node:assert/strict';
import { readFile } from 'node:fs/promises';

import { renderLlmsTxt } from './render_llms_txt.mjs';

const sourcePortfolio = JSON.parse(
  await readFile(new URL('../assets/content/portfolio.json', import.meta.url), 'utf8'),
);

// Determinism: rendering the same document twice must produce byte-identical
// output, since `npm run verify:content` compares it against the committed
// file on every run.
const first = renderLlmsTxt(sourcePortfolio);
const second = renderLlmsTxt(sourcePortfolio);
assert.equal(first, second, 'renderLlmsTxt must be deterministic for the same input');

// Every catalogued package must be reachable, with its published version.
for (const pkg of sourcePortfolio.packages) {
  assert.ok(
    first.includes(`[${pkg.name}](${pkg.url})`),
    `llms.txt is missing the package link for ${pkg.name}`,
  );
  assert.ok(
    first.includes(`(v${pkg.version})`),
    `llms.txt is missing the version for ${pkg.name}`,
  );
}
assert.equal(
  (first.match(/^## Packages$/m) ?? []).length,
  1,
  'llms.txt must contain exactly one Packages section',
);
// Bounded to the next heading: a later section (e.g. Writing) must not be
// counted as part of the Packages list just because it comes after it.
const packageSection = (first.split('## Packages\n')[1] ?? '').split(/\n## /)[0];
assert.equal(
  packageSection.trim().split('\n').filter((line) => line.startsWith('- [')).length,
  sourcePortfolio.packages.length,
  'llms.txt must list every package exactly once, with none invented',
);

// Only merged contributions may appear; under-review or otherwise unmerged
// work must not be published as if it were accepted.
const fixture = {
  ...sourcePortfolio,
  systems: [],
  contributions: [
    {
      project: 'Example Project',
      status: 'merged',
      title: 'A merged and published change',
      url: 'https://github.com/example/project/pull/1',
    },
    {
      project: 'Example Project',
      status: 'under_review',
      title: 'A change still awaiting review',
      url: 'https://github.com/example/project/pull/2',
    },
  ],
  packages: [],
};
const fixtureOutput = renderLlmsTxt(fixture);
assert.ok(
  fixtureOutput.includes('[Example Project: A merged and published change](https://github.com/example/project/pull/1)'),
  'a merged contribution must be published',
);
assert.ok(
  !fixtureOutput.includes('A change still awaiting review'),
  'an unmerged contribution must not be published',
);

// Featured systems are only published when they carry a public URL; an
// unfeatured system, or a featured one with no URL, must not appear.
const systemsFixture = {
  ...sourcePortfolio,
  contributions: [],
  packages: [],
  systems: [
    {
      name: 'Public Featured System',
      featured: true,
      url: 'https://example.invalid/public-system',
      summary: 'A featured system with a public URL.',
    },
    {
      name: 'Unfeatured System',
      featured: false,
      url: 'https://example.invalid/unfeatured-system',
      summary: 'A system that is not featured.',
    },
    {
      name: 'Featured Without URL',
      featured: true,
      summary: 'A featured system without a public URL.',
    },
  ],
};
const systemsOutput = renderLlmsTxt(systemsFixture);
assert.ok(
  systemsOutput.includes('[Public Featured System](https://example.invalid/public-system)'),
  'a featured system with a public URL must be published',
);
assert.ok(
  !systemsOutput.includes('Unfeatured System'),
  'a system that is not featured must not be published',
);
assert.ok(
  !systemsOutput.includes('Featured Without URL'),
  'a featured system without a public URL must not be published',
);

// Every writing entry must be reachable, and the section is omitted
// entirely when there is nothing to publish.
for (const entry of sourcePortfolio.writing ?? []) {
  assert.ok(
    first.includes(`[${entry.title}](${entry.url})`),
    `llms.txt is missing the writing link for ${entry.title}`,
  );
}
const noWritingFixture = { ...sourcePortfolio, writing: [] };
assert.ok(
  !renderLlmsTxt(noWritingFixture).includes('## Writing'),
  'an empty writing list must omit the Writing section entirely',
);
const writingFixture = {
  ...sourcePortfolio,
  writing: [
    {
      title: 'A published piece',
      url: 'https://example.invalid/writing/a-published-piece',
      source: 'blog',
      date: '2026-01-01',
    },
  ],
};
const writingOutput = renderLlmsTxt(writingFixture);
assert.ok(writingOutput.includes('## Writing'));
assert.ok(
  writingOutput.includes(
    '[A published piece](https://example.invalid/writing/a-published-piece)',
  ),
  'a populated writing list must publish its entries as markdown links',
);

// The document opens with the llms.txt convention: an H1 with the person's
// name, then a one-line blockquote summary.
const lines = first.split('\n');
assert.equal(lines[0], `# ${sourcePortfolio.profile.name}`);
assert.equal(lines[1], '');
assert.ok(lines[2].startsWith('> '), 'the third line must be a blockquote summary');

// Structured-data parity: llms.txt must not publish more personal data than
// the head's JSON-LD Person record already exposes publicly.
const headSource = await readFile(new URL('../web/index.html', import.meta.url), 'utf8');
assert.ok(
  headSource.includes(sourcePortfolio.profile.email),
  'the fixture assumption that email is already public in structured data must hold',
);
for (const [, address] of first.matchAll(/mailto:([^)\s]+)/g)) {
  assert.ok(
    headSource.includes(address),
    `llms.txt publishes ${address}, which the structured data does not`,
  );
}
assert.ok(!first.includes('tel:'), 'llms.txt must not publish a phone link');

process.stdout.write('llms.txt renderer contracts passed.\n');
