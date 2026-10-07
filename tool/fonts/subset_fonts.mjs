import { readFile, writeFile } from 'node:fs/promises';
import { fileURLToPath } from 'node:url';
import { resolve } from 'node:path';
import subsetFont from 'subset-font';

import { collectPaintableText } from './font_text_sources.mjs';

const root = resolve(fileURLToPath(new URL('../..', import.meta.url)));
const latinFonts = [
  'inter/Inter-Variable.ttf',
  'space_grotesk/SpaceGrotesk-Variable.ttf',
  'jetbrains_mono/JetBrainsMono-Variable.ttf',
];
// Loaded at runtime for their own locale; other locales get the "-Shared" subset of these fonts.
export const scriptFonts = new Map([
  ['ar', 'noto_sans_arabic/NotoSansArabic-Variable.ttf'],
  ['hi', 'noto_sans_devanagari/NotoSansDevanagari-Variable.ttf'],
]);
const ranges = [
  [0x20, 0x7e],
  [0xa0, 0xff],
  [0x100, 0x17f],
  [0x2000, 0x206f],
];
const uiArrows = '←↑→↓↗';
// Only these layout features survive in the Latin subsets: add a tag before the UI uses a FontFeature for it.
const latinFeatures = ['ccmp', 'locl', 'rlig', 'liga', 'clig', 'calt', 'kern', 'mark', 'mkmk'];

export function* codePoints(value) {
  for (const character of value) yield character.codePointAt(0);
}

export function collectCoverage(values) {
  const coverage = new Set(codePoints(uiArrows));
  for (const [start, end] of ranges) {
    for (let point = start; point <= end; point += 1) coverage.add(point);
  }
  for (const value of values) {
    for (const point of codePoints(value)) coverage.add(point);
  }
  return coverage;
}

/** Code points that reach the text engine; control characters never do. */
export function paintedCodePoints(values) {
  const points = new Set();
  for (const value of values) {
    for (const point of codePoints(value)) {
      if (point >= 0x20 && (point < 0x7f || point >= 0xa0)) points.add(point);
    }
  }
  return points;
}

/** Each code point a locale paints that none of the fonts it has registered covers. */
export function uncoveredCodePoints(text, fontsFor) {
  const failures = [];
  for (const [locale, values] of text.locales) {
    const fonts = fontsFor(locale);
    for (const point of paintedCodePoints([...text.shared, ...values])) {
      if (!fonts.some((font) => font.has(point))) failures.push({ locale, point });
    }
  }
  return failures;
}

export function sharedSubsetName(name) {
  return name.replace(/-Variable\.ttf$/, '-Shared.ttf');
}

function table(font, tag) {
  const count = font.readUInt16BE(4);
  for (let index = 0; index < count; index += 1) {
    const entry = 12 + index * 16;
    if (font.toString('ascii', entry, entry + 4) !== tag) continue;
    const offset = font.readUInt32BE(entry + 8);
    const length = font.readUInt32BE(entry + 12);
    return font.subarray(offset, offset + length);
  }
  return undefined;
}

function cmap4(font, offset, output) {
  const segments = font.readUInt16BE(offset + 6) / 2;
  const endCodes = offset + 14;
  const startCodes = endCodes + segments * 2 + 2;
  const deltas = startCodes + segments * 2;
  const rangesOffset = deltas + segments * 2;
  for (let index = 0; index < segments; index += 1) {
    const start = font.readUInt16BE(startCodes + index * 2);
    const end = font.readUInt16BE(endCodes + index * 2);
    const range = font.readUInt16BE(rangesOffset + index * 2);
    const delta = font.readInt16BE(deltas + index * 2);
    for (let point = start; point <= end && point !== 0xffff; point += 1) {
      const address = rangesOffset + index * 2 + range + (point - start) * 2;
      const glyph = range ? font.readUInt16BE(address) : point;
      if (glyph && (glyph + delta) & 0xffff) output.add(point);
    }
  }
}

function cmap12(font, offset, output) {
  const groups = font.readUInt32BE(offset + 12);
  for (let index = 0; index < groups; index += 1) {
    const group = offset + 16 + index * 12;
    const start = font.readUInt32BE(group);
    const end = font.readUInt32BE(group + 4);
    const glyph = font.readUInt32BE(group + 8);
    for (let point = start; point <= end; point += 1) {
      if (glyph + point - start) output.add(point);
    }
  }
}

export function fontCodePoints(font) {
  const cmap = table(font, 'cmap');
  if (!cmap) throw new Error('Font has no cmap table');
  const result = new Set();
  const records = cmap.readUInt16BE(2);
  for (let index = 0; index < records; index += 1) {
    const offset = cmap.readUInt32BE(4 + index * 8 + 4);
    const format = cmap.readUInt16BE(offset);
    if (format === 4) cmap4(cmap, offset, result);
    if (format === 12) cmap12(cmap, offset, result);
  }
  return result;
}

function axes(font) {
  const fvar = table(font, 'fvar');
  if (!fvar) throw new Error('Variable font lost its fvar table');
  const axisOffset = fvar.readUInt16BE(4);
  const count = fvar.readUInt16BE(8);
  const size = fvar.readUInt16BE(10);
  return Array.from({ length: count }, (_, index) =>
    fvar.subarray(axisOffset + index * size, axisOffset + index * size + 16).toString('hex'),
  );
}

async function subset(name, source, points, options = {}) {
  const output = Buffer.from(
    await subsetFont(source, String.fromCodePoint(...points), {
      targetFormat: 'truetype',
      ...options,
    }),
  );
  const coverage = fontCodePoints(output);
  for (const point of points) {
    if (!coverage.has(point)) throw new Error(`${name} is missing U+${point.toString(16)}`);
  }
  if (axes(source).join(',') !== axes(output).join(',')) {
    throw new Error(`${name} lost a variation axis`);
  }
  return { name, output, coverage };
}

async function emit({ name, output, coverage }, check) {
  const targetPath = resolve(root, 'assets/fonts', name);
  if (check) {
    const current = await readFile(targetPath).catch(() => Buffer.alloc(0));
    if (!current.equals(output))
      throw new Error(`${name} subset is stale; run npm run fonts:subset`);
  } else {
    await writeFile(targetPath, output);
  }
  process.stdout.write(`${name}: ${output.length} bytes, ${coverage.size} code points\n`);
}

async function latinSubsets(text) {
  const coverage = collectCoverage([...text.shared, ...[...text.locales.values()].flat()]);
  const results = [];
  for (const name of latinFonts) {
    const source = await readFile(resolve(root, 'tool/font_sources', name));
    const available = fontCodePoints(source);
    const points = [...coverage].filter((point) => available.has(point));
    results.push(await subset(name, source, points, { keepFeatures: latinFeatures }));
  }
  return results;
}

// Script glyphs every locale paints (language names) come from small eager subsets of the script fonts.
async function scriptSubsets(text, latin) {
  const needed = [...paintedCodePoints(text.shared)].filter(
    (point) => !latin.some((result) => result.coverage.has(point)),
  );
  const full = new Map();
  const shared = [];
  for (const [locale, name] of scriptFonts) {
    const source = await readFile(resolve(root, 'assets/fonts', name));
    const available = fontCodePoints(source);
    full.set(locale, available);
    const points = needed.filter((point) => available.has(point));
    shared.push(await subset(sharedSubsetName(name), source, points));
  }
  return { full, shared };
}

function describe({ locale, point }) {
  const character = String.fromCodePoint(point);
  return `${locale} paints U+${point.toString(16).toUpperCase()} (${character}), which no bundled font covers`;
}

async function main() {
  const check = process.argv.includes('--check');
  const text = await collectPaintableText(root);
  const latin = await latinSubsets(text);
  const { full, shared } = await scriptSubsets(text, latin);
  for (const result of [...latin, ...shared]) await emit(result, check);
  const eager = [...latin, ...shared].map((result) => result.coverage);
  const failures = uncoveredCodePoints(text, (locale) =>
    full.has(locale) ? [...eager, full.get(locale)] : eager,
  );
  if (failures.length > 0) throw new Error(failures.map(describe).join('\n'));
}

if (process.argv[1] && resolve(process.argv[1]) === fileURLToPath(import.meta.url)) {
  main().catch((error) => {
    process.stderr.write(`${error.message}\n`);
    process.exitCode = 1;
  });
}
