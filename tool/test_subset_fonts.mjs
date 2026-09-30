import assert from 'node:assert/strict';
import { test } from 'node:test';

import { collectCoverage, codePoints } from './subset_fonts.mjs';

test('coverage includes the required ranges and authored text', () => {
  const coverage = collectCoverage(['Aİé–→', '😀']);
  for (const point of [0x20, 0x7e, 0xa0, 0xff, 0x100, 0x17f, 0x2013, 0x2192]) {
    assert.ok(coverage.has(point), `Missing U+${point.toString(16)}`);
  }
  assert.ok(coverage.has(0x1f600));
  assert.ok(!coverage.has(0x80));
});

test('code point extraction keeps astral characters intact', () => {
  assert.deepEqual([...codePoints('A😀')], [0x41, 0x1f600]);
});
