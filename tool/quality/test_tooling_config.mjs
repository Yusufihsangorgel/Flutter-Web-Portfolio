import assert from 'node:assert/strict';
import test from 'node:test';

import { ESLint } from 'eslint';

const lint = new ESLint();

async function ruleIds(source) {
  const [result] = await lint.lintText(source, {
    filePath: 'tool/quality/calibration.mjs',
  });
  return result.messages.map((message) => message.ruleId);
}

test('the recommended rules reject undefined names', async () => {
  assert((await ruleIds('export const value = missing;')).includes('no-undef'));
});

test('the recommended rules reject unreachable code', async () => {
  assert(
    (await ruleIds('export function value() { return 1; return 2; }')).includes('no-unreachable'),
  );
});

test('the custom limits coexist with the recommended rules', async () => {
  const source = 'export function value(a, b, c, d, e) { return [a, b, c, d, e]; }';
  assert((await ruleIds(source)).includes('max-params'));
  assert.deepEqual(await ruleIds('export const value = 1;'), []);
});
