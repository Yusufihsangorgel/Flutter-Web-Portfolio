import { access, readFile } from 'node:fs/promises';
import path from 'node:path';
import process from 'node:process';
import { fileURLToPath } from 'node:url';

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const read = (relativePath) => readFile(path.join(root, relativePath), 'utf8');
const portfolio = JSON.parse(await read('assets/content/portfolio.json'));
const failures = [];

const conduct = await read('CODE_OF_CONDUCT.md');
const security = await read('SECURITY.md');
const issueConfig = await read('.github/ISSUE_TEMPLATE/config.yml');
const issueForms = await Promise.all([
  read('.github/ISSUE_TEMPLATE/bug.yml'),
  read('.github/ISSUE_TEMPLATE/feature.yml'),
]);

expect(conduct.includes(portfolio.profile.name), 'conduct contact uses the owner name');
expect(conduct.includes(portfolio.profile.email), 'conduct contact uses the owner email');
expect(security.includes(portfolio.profile.email), 'security contact uses the owner email');
expect(
  issueConfig.includes('blank_issues_enabled: false'),
  'blank issues are disabled',
);

for (const [index, form] of issueForms.entries()) {
  expect(/^name:\s+.+/m.test(form), `issue form ${index + 1} has a name`);
  expect(
    /^description:\s+.+/m.test(form),
    `issue form ${index + 1} has a description`,
  );
  expect(/^body:/m.test(form), `issue form ${index + 1} has a body`);
  const ids = [...form.matchAll(/^\s+id:\s+([a-z0-9_-]+)\s*$/gm)].map(
    (match) => match[1],
  );
  expect(ids.length > 0, `issue form ${index + 1} has field IDs`);
  expect(
    ids.length === new Set(ids).size,
    `issue form ${index + 1} has unique field IDs`,
  );
}

for (const retired of [
  '.github/ISSUE_TEMPLATE/bug_report.md',
  '.github/ISSUE_TEMPLATE/feature_request.md',
]) {
  try {
    await access(path.join(root, retired));
    failures.push(`${retired} should be replaced by an issue form`);
  } catch (error) {
    if (error?.code !== 'ENOENT') throw error;
  }
}

if (failures.length > 0) {
  for (const failure of failures) console.error(`- ${failure}`);
  process.exit(1);
}

console.log('Community contracts verified: conduct, security, and structured issue intake.');

function expect(condition, message) {
  if (!condition) failures.push(message);
}
