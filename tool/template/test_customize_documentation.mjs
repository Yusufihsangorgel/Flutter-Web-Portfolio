import assert from 'node:assert/strict';
import { readFile } from 'node:fs/promises';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const projectRoot = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '../..');
const document = await readFile(path.join(projectRoot, 'docs/CUSTOMIZE.md'), 'utf8');
const sectionStart = document.indexOf('For automation or a reproducible team setup:');
assert.ok(sectionStart !== -1, 'The automation setup section must be present.');

const sectionEnd = document.indexOf('\n## ', sectionStart);
assert.ok(sectionEnd !== -1, 'The automation setup section must end at a heading.');
const section = document.slice(sectionStart, sectionEnd);
const sectionFences = section.match(/^```[^\n]*$/gm) ?? [];
assert.ok(
  sectionFences.length === 2 && sectionFences[0] === '```bash' && sectionFences[1] === '```',
  'The setup section must contain exactly one Bash fence pair.',
);
const commandBlocks = [...section.matchAll(/```bash\n([\s\S]*?)\n```/g)];
assert.ok(commandBlocks.length === 1, 'The setup section must contain one Bash command.');

const command = commandBlocks[0][1];
const commandLines = command.split('\n');
assert.ok(
  commandLines[0].trimEnd() === 'npm run portfolio:init -- \\',
  'The example must use the existing initializer command.',
);

const requiredVariables = new Map([
  ['--name', 'PORTFOLIO_NAME'],
  ['--role', 'PORTFOLIO_ROLE'],
  ['--email', 'PORTFOLIO_EMAIL'],
  ['--site', 'PORTFOLIO_SITE'],
  ['--location', 'PORTFOLIO_LOCATION'],
  ['--focus', 'PORTFOLIO_FOCUS'],
]);
const argumentLines = commandLines.slice(1);
const guardedArgument =
  /^\s*(--[a-z0-9-]+)\s+"(\$\{([A-Z][A-Z0-9_]*):\?Set ([A-Z][A-Z0-9_]*)\})"(?:\s+\\)?\s*$/;
const seenOptions = new Set();
for (const [index, line] of argumentLines.entries()) {
  const match = line.match(guardedArgument);
  assert.ok(match, 'Each argument must use a guarded environment expansion.');

  const [, option, , variable, guardVariable] = match;
  const expectedVariable = requiredVariables.get(option);
  assert.ok(expectedVariable, 'The example must not add an unreviewed initializer option.');
  assert.ok(
    variable === expectedVariable && guardVariable === expectedVariable,
    'Each option must require its matching environment variable.',
  );
  assert.ok(!seenOptions.has(option), 'Each required option must appear once.');
  seenOptions.add(option);

  const hasContinuation = line.trimEnd().endsWith('\\');
  const shouldContinue = index < argumentLines.length - 1;
  assert.ok(
    hasContinuation === shouldContinue,
    'Shell continuations must match the command layout.',
  );
}
assert.ok(
  argumentLines.length === requiredVariables.size,
  'The example must contain only the required profile arguments.',
);
for (const option of requiredVariables.keys()) {
  assert.ok(seenOptions.has(option), 'The example must preserve every required profile option.');
}
assert.ok(!command.includes('@'), 'The command must not contain a fixed email address.');
assert.ok(!/https?:\/\//i.test(command), 'The command must not contain a fixed URL.');

const normalizedSection = section.replace(/\s+/g, ' ').toLowerCase();
assert.ok(
  normalizedSection.includes('at least three comma-separated items'),
  'The guide must preserve the initializer focus-area input contract.',
);
assert.ok(
  normalizedSection.includes('`--github` is optional'),
  'The guide must identify the GitHub link as optional.',
);
assert.ok(
  normalizedSection.includes('omit `--github`'),
  'The guide must explain how to omit the link.',
);
const githubExamples = [
  ...section.matchAll(/`--github\s+"(\$\{([A-Z][A-Z0-9_]*):\?Set ([A-Z][A-Z0-9_]*)\})"`/g),
];
assert.ok(githubExamples.length === 1, 'An optional GitHub link must use a guarded variable.');
assert.ok(
  githubExamples[0][2] === 'PORTFOLIO_GITHUB_URL' &&
    githubExamples[0][3] === 'PORTFOLIO_GITHUB_URL',
  'The optional GitHub link must require its own environment value.',
);
assert.ok(
  normalizedSection.includes('`--force` is optional'),
  'The guide must identify force as optional.',
);
assert.ok(
  normalizedSection.includes('if the output file already exists'),
  'The guide must condition overwrite guidance on an existing file.',
);
assert.ok(
  normalizedSection.includes('interactive run asks for confirmation'),
  'The guide must describe interactive overwrite confirmation.',
);
assert.ok(
  normalizedSection.includes('non-interactive run refuses to overwrite'),
  'The guide must describe non-interactive overwrite refusal.',
);
assert.ok(
  normalizedSection.includes('add `--force` only when replacing the existing file is intentional'),
  'The guide must reserve force for intentional replacement.',
);

process.stdout.write('Customization documentation command structure is guarded.\n');
