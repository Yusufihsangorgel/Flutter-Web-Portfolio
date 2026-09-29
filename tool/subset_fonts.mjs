import { readFile, writeFile } from 'node:fs/promises';
import { fileURLToPath } from 'node:url';
import { resolve } from 'node:path';
import subsetFont from 'subset-font';

const root = resolve(fileURLToPath(new URL('..', import.meta.url)));
const locales = ['en', 'tr', 'de', 'fr', 'es'];
const contentLocales = locales.filter((locale) => locale !== 'en');
const inputs = [
  ...locales.map((locale) => `assets/i18n/${locale}.json`),
  'assets/content/portfolio.json',
  ...contentLocales.map((locale) => `assets/content/locales/${locale}.json`),
];
const fonts = [
  'inter/Inter-Variable.ttf',
  'space_grotesk/SpaceGrotesk-Variable.ttf',
  'jetbrains_mono/JetBrainsMono-Variable.ttf',
];
const ranges = [
  [0x20, 0x7e],
  [0xa0, 0xff],
  [0x100, 0x17f],
  [0x2000, 0x206f],
];
const uiArrows = '←↑→↓↗';

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
      if (glyph && ((glyph + delta) & 0xffff)) output.add(point);
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

function fontCodePoints(font) {
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

async function expectedCoverage() {
  const values = await Promise.all(inputs.map((path) => readFile(resolve(root, path), 'utf8')));
  const authored = new Set(values.flatMap((value) => [...codePoints(value)]));
  for (const point of authored) {
    if (point < 0x20 || (point >= 0x7f && point < 0xa0)) authored.delete(point);
  }
  return { coverage: collectCoverage(values), authored };
}

async function processFont(name, coverage, check) {
  const source = await readFile(resolve(root, 'tool/font_sources', name));
  const targetPath = resolve(root, 'assets/fonts', name);
  const sourceCoverage = fontCodePoints(source);
  const requested = new Set([...coverage].filter((point) => sourceCoverage.has(point)));
  const text = String.fromCodePoint(...requested);
  const output = Buffer.from(await subsetFont(source, text, {
    targetFormat: 'truetype',
    keepFeatures: [
      'ccmp', 'locl', 'rlig', 'liga', 'clig', 'calt',
      'kern', 'mark', 'mkmk',
    ],
  }));
  const outputCoverage = fontCodePoints(output);
  for (const point of requested) {
    if (!outputCoverage.has(point)) throw new Error(`${name} is missing U+${point.toString(16)}`);
  }
  if (axes(source).join(',') !== axes(output).join(',')) {
    throw new Error(`${name} lost a variation axis`);
  }
  if (check) {
    const current = await readFile(targetPath);
    if (!current.equals(output)) throw new Error(`${name} subset is stale`);
  } else {
    await writeFile(targetPath, output);
  }
  process.stdout.write(`${name}: ${output.length} bytes, ${requested.size} glyphs\n`);
}

async function main() {
  const check = process.argv.includes('--check');
  const { coverage, authored } = await expectedCoverage();
  const available = new Set();
  for (const name of fonts) {
    const source = await readFile(resolve(root, 'tool/font_sources', name));
    for (const point of fontCodePoints(source)) available.add(point);
  }
  for (const point of authored) {
    if (!available.has(point)) throw new Error(`Used code point U+${point.toString(16)} is missing`);
  }
  for (const name of fonts) await processFont(name, coverage, check);
}

if (process.argv[1] && resolve(process.argv[1]) === fileURLToPath(import.meta.url)) {
  main().catch((error) => {
    process.stderr.write(`${error.message}\n`);
    process.exitCode = 1;
  });
}
