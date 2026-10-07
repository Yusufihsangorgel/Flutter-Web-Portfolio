import { mkdirSync, mkdtempSync, readFileSync, rmSync, writeFileSync } from 'node:fs';
import { spawnSync } from 'node:child_process';
import { tmpdir } from 'node:os';
import { fileURLToPath } from 'node:url';
import { dirname, join, resolve } from 'node:path';

const root = resolve(fileURLToPath(new URL('../..', import.meta.url)));
const defaultSource = resolve(root, 'assets/i18n/en.json');
const defaultOutput = resolve(root, 'lib/app/core/l10n/app_strings.g.dart');

const placeholderPattern = /\{([a-zA-Z_][a-zA-Z_0-9]*)\}/g;
const unusableNames = new Set([
  'assert',
  'break',
  'case',
  'catch',
  'class',
  'const',
  'continue',
  'default',
  'do',
  'else',
  'enum',
  'extends',
  'false',
  'final',
  'finally',
  'for',
  'if',
  'in',
  'is',
  'new',
  'null',
  'rethrow',
  'return',
  'super',
  'switch',
  'this',
  'throw',
  'true',
  'try',
  'var',
  'void',
  'while',
  'with',
  'hashCode',
  'lookup',
  'noSuchMethod',
  'runtimeType',
  'toString',
  'translations',
]);
const controlEscapes = { '\n': '\\n', '\r': '\\r', '\t': '\\t' };

const lookupSource = `  String lookup(String key, {String defaultValue = ''}) {
    Object? current = translations;
    for (final part in key.split('.')) {
      if (current is! Map<String, Object?> || !current.containsKey(part)) {
        return defaultValue;
      }
      current = current[part];
    }
    return current?.toString() ?? defaultValue;
  }
`;

const interpolationSource = `  String _interpolate(String key, String fallback, Map<String, String> values) =>
      lookup(key, defaultValue: fallback).replaceAllMapped(
        RegExp(r'\\{([a-zA-Z_][a-zA-Z_0-9]*)\\}'),
        (match) => values[match.group(1)] ?? match.group(0)!,
      );
`;

function flatten(document, prefix = '') {
  return Object.entries(document).flatMap(([key, value]) => {
    const path = prefix ? `${prefix}.${key}` : key;
    if (value !== null && typeof value === 'object' && !Array.isArray(value)) {
      return flatten(value, path);
    }
    if (typeof value !== 'string') throw new TypeError(`${path} must be text`);
    return [[path, value]];
  });
}

function identifier(path) {
  const parts = path.split(/[^a-zA-Z0-9]+/).filter(Boolean);
  return parts
    .map((part, index) =>
      index === 0 ? part.toLowerCase() : part[0].toUpperCase() + part.slice(1),
    )
    .join('');
}

function usableName(name, origin) {
  if (!/^[a-z][a-zA-Z0-9]*$/.test(name) || unusableNames.has(name)) {
    throw new Error(`${origin} does not map to a usable Dart name: "${name}"`);
  }
  return name;
}

function dartString(value) {
  const escaped = value
    .replace(/[\\'$]/g, (character) => `\\${character}`)
    .replace(
      /[\p{Cc}\p{Zl}\p{Zp}]/gu,
      (character) => controlEscapes[character] ?? `\\u{${character.codePointAt(0).toString(16)}}`,
    );
  return `'${escaped}'`;
}

function placeholders(text) {
  return [...new Set([...text.matchAll(placeholderPattern)].map((match) => match[1]))];
}

function parameterName(placeholder, path) {
  const name = /^[a-z][a-zA-Z0-9]*$/.test(placeholder) ? placeholder : identifier(placeholder);
  return usableName(name, `${path} placeholder {${placeholder}}`);
}

function member(path, fallback) {
  const name = usableName(identifier(path), path);
  const key = dartString(path);
  const text = dartString(fallback);
  const bindings = placeholders(fallback).map((placeholder) => [
    placeholder,
    parameterName(placeholder, path),
  ]);
  if (new Set(bindings.map(([, parameter]) => parameter)).size !== bindings.length) {
    throw new Error(`${path} has placeholders that share a Dart parameter name`);
  }
  if (bindings.length === 0)
    return `  String get ${name} => lookup(${key}, defaultValue: ${text});`;
  const parameters = bindings.map(([, parameter]) => `required String ${parameter}`).join(', ');
  const values = bindings
    .map(([placeholder, parameter]) => `${dartString(placeholder)}: ${parameter}`)
    .join(', ');
  return (
    `  String ${name}({${parameters}}) =>\n` + `    _interpolate(${key}, ${text}, {${values}});`
  );
}

function byPath([left], [right]) {
  return left < right ? -1 : left > right ? 1 : 0;
}

export function generateAppStrings(document) {
  const entries = flatten(document).sort(byPath);
  const claimed = new Map();
  for (const [path] of entries) {
    const name = usableName(identifier(path), path);
    if (claimed.has(name)) {
      throw new Error(`Duplicate Dart member: ${name} (${claimed.get(name)} and ${path})`);
    }
    claimed.set(name, path);
  }
  const needsInterpolation = entries.some(([, text]) => placeholders(text).length > 0);
  return (
    `// GENERATED — do not edit. Run: npm run generate:strings\n` +
    `final class AppStrings {\n` +
    `  const AppStrings(this.translations);\n\n` +
    `  final Map<String, Object?> translations;\n\n` +
    `${lookupSource}\n` +
    (needsInterpolation ? `${interpolationSource}\n` : '') +
    entries.map(([path, text]) => member(path, text)).join('\n\n') +
    `\n}\n`
  );
}

function formatted(source) {
  const manifest = readFileSync(resolve(root, 'pubspec.yaml'), 'utf8');
  const languageVersion = manifest.match(/\bsdk:\s*['"]>=([0-9]+\.[0-9]+)/)?.[1];
  if (!languageVersion) throw new Error('Cannot determine Dart language version');
  const directory = mkdtempSync(join(tmpdir(), 'app-strings-format-'));
  const file = join(directory, 'app_strings.g.dart');
  try {
    writeFileSync(file, source);
    const result = spawnSync(
      process.env.DART ?? 'dart',
      ['format', '--language-version', languageVersion, file],
      {
        encoding: 'utf8',
      },
    );
    if (result.status !== 0) {
      throw new Error(result.stderr || result.error?.message || 'Dart format failed');
    }
    return readFileSync(file, 'utf8');
  } finally {
    rmSync(directory, { recursive: true, force: true });
  }
}

function run() {
  const args = process.argv.slice(2);
  const check = args.includes('--check');
  const sourceIndex = args.indexOf('--source');
  const outputIndex = args.indexOf('--output');
  const source = sourceIndex < 0 ? defaultSource : args[sourceIndex + 1];
  const output = outputIndex < 0 ? defaultOutput : args[outputIndex + 1];
  if (!source || !output) throw new Error('Missing source or output path');
  const expected = formatted(generateAppStrings(JSON.parse(readFileSync(source, 'utf8'))));
  if (check) {
    let actual;
    try {
      actual = readFileSync(output, 'utf8');
    } catch {
      actual = null;
    }
    if (actual !== expected) throw new Error(`${output} is stale. Run: npm run generate:strings`);
    return;
  }
  mkdirSync(dirname(output), { recursive: true });
  writeFileSync(output, expected);
}

if (process.argv[1] && resolve(process.argv[1]) === fileURLToPath(import.meta.url)) {
  try {
    run();
  } catch (error) {
    console.error(error.message);
    process.exitCode = 1;
  }
}
