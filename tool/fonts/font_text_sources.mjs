import { readdir, readFile } from 'node:fs/promises';
import { basename, join, resolve } from 'node:path';

const catalogDirectories = ['assets/i18n', 'assets/content/locales'];
const simpleEscapes = { n: '\n', r: '\r', t: '\t', b: '\b', f: '\f', v: '\v' };

/**
 * Text the app can paint: `shared` appears in every locale (the content record and Dart string
 * literals such as language names); `locales` maps each catalog's locale to its own strings.
 */
export async function collectPaintableText(root) {
  const portfolio = jsonStrings(await readJson(resolve(root, 'assets/content/portfolio.json')));
  const literals = [];
  for (const file of await dartFiles(resolve(root, 'lib'))) {
    literals.push(...dartLiterals(await readFile(file, 'utf8')));
  }
  const locales = new Map();
  for (const directory of catalogDirectories) {
    for (const entry of (await readdir(resolve(root, directory))).sort()) {
      if (!entry.endsWith('.json')) continue;
      const locale = basename(entry, '.json');
      const values = jsonStrings(await readJson(resolve(root, directory, entry)));
      locales.set(locale, [...(locales.get(locale) ?? []), ...withUpperCase(values)]);
    }
  }
  return { shared: withUpperCase([...portfolio, ...literals]), locales };
}

/** Every key and string value in a decoded JSON document. */
export function jsonStrings(value) {
  if (typeof value === 'string') return [value];
  if (Array.isArray(value)) return value.flatMap(jsonStrings);
  if (value && typeof value === 'object') {
    return Object.entries(value).flatMap(([key, item]) => [key, ...jsonStrings(item)]);
  }
  return [];
}

/** The decoded bodies of the string literals in Dart source; comments are skipped. */
export function dartLiterals(source) {
  const literals = [];
  let index = 0;
  while (index < source.length) {
    if (source.startsWith('//', index)) {
      const end = source.indexOf('\n', index);
      index = end === -1 ? source.length : end;
    } else if (source.startsWith('/*', index)) {
      index = blockCommentEnd(source, index);
    } else if (source[index] === "'" || source[index] === '"') {
      const literal = readLiteral(source, index);
      literals.push(literal.text);
      index = literal.end;
    } else {
      index += 1;
    }
  }
  return literals;
}

// The UI upper-cases labels at paint time.
function withUpperCase(values) {
  return values.flatMap((value) => [value, value.toUpperCase()]);
}

async function readJson(path) {
  return JSON.parse(await readFile(path, 'utf8'));
}

async function dartFiles(directory) {
  const entries = await readdir(directory, { recursive: true, withFileTypes: true });
  return entries
    .filter((entry) => entry.isFile() && entry.name.endsWith('.dart'))
    .map((entry) => join(entry.parentPath, entry.name))
    .sort();
}

function blockCommentEnd(source, start) {
  let depth = 0;
  let index = start;
  while (index < source.length) {
    if (source.startsWith('/*', index)) {
      depth += 1;
      index += 2;
    } else if (source.startsWith('*/', index)) {
      depth -= 1;
      index += 2;
      if (depth === 0) return index;
    } else {
      index += 1;
    }
  }
  return index;
}

function readLiteral(source, start) {
  const raw = source[start - 1] === 'r' && !/[\w$]/.test(source[start - 2] ?? '');
  const triple = source[start].repeat(3);
  const quote = source.startsWith(triple, start) ? triple : source[start];
  let index = start + quote.length;
  while (index < source.length && !source.startsWith(quote, index)) {
    index += !raw && source[index] === '\\' ? 2 : 1;
  }
  const body = source.slice(start + quote.length, index);
  return { text: raw ? body : decodeEscapes(body), end: index + quote.length };
}

function decodeEscapes(body) {
  return body.replace(
    /\\(?:u\{([0-9a-fA-F]+)\}|u([0-9a-fA-F]{4})|x([0-9a-fA-F]{2})|([\s\S]))/g,
    (_, ...groups) => {
      const [braced, short, hex, other] = groups;
      const code = braced ?? short ?? hex;
      if (code) return String.fromCodePoint(Number.parseInt(code, 16));
      return simpleEscapes[other] ?? other;
    },
  );
}
