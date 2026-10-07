import assert from 'node:assert/strict';
import { test } from 'node:test';

import { dartLiterals, jsonStrings } from './font_text_sources.mjs';
import {
  collectCoverage,
  codePoints,
  paintedCodePoints,
  sharedSubsetName,
  uncoveredCodePoints,
} from './subset_fonts.mjs';

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

test('painted code points drop control characters', () => {
  assert.deepEqual([...paintedCodePoints(['a\n\u0085 '])], [0x61, 0xa0]);
});

test('Dart literals decode escapes and skip comments', () => {
  const source = [
    "// 'ignored ─'",
    "/* outer /* 'nested' */ still a comment */",
    "const names = {'ar': '\\u0627\\u0644', 'x': \"\\u{1F600} it\\'s\"};",
    "final raw = r'\\u0041';",
    "final block = '''multi 'quoted' ·''';",
    "final url = 'https://example.com'; // trailing 'ignored'",
  ].join('\n');
  assert.deepEqual(dartLiterals(source), [
    'ar', 'ال', 'x', "😀 it's", '\\u0041', "multi 'quoted' ·", 'https://example.com',
  ]);
});

test('JSON strings include keys and nested values', () => {
  assert.deepEqual(jsonStrings({ a: ['b', { c: 'd' }], e: 1 }), ['a', 'b', 'c', 'd', 'e']);
});

test('a locale fails when no registered font paints one of its characters', () => {
  const text = { shared: ['العربية'], locales: new Map([['en', ['Hi']], ['ar', ['مرحبا']]]) };
  const latin = new Set(codePoints('Hi'));
  const arabicNames = new Set(codePoints('العربية'));
  const arabic = new Set(codePoints('العربيةمرحبا'));
  const fontsFor = (locale) => (locale === 'ar' ? [latin, arabicNames, arabic] : [latin, arabicNames]);
  assert.deepEqual(uncoveredCodePoints(text, fontsFor), []);
  assert.deepEqual(
    uncoveredCodePoints(text, (locale) => (locale === 'ar' ? [latin, arabic] : [latin])),
    [...new Set(codePoints('العربية'))].map((point) => ({ locale: 'en', point })),
  );
});

test('shared subsets sit next to the runtime script font', () => {
  assert.equal(
    sharedSubsetName('noto_sans_arabic/NotoSansArabic-Variable.ttf'),
    'noto_sans_arabic/NotoSansArabic-Shared.ttf',
  );
});
