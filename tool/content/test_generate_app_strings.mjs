import assert from 'node:assert/strict';
import { execFileSync } from 'node:child_process';
import { mkdtempSync, readFileSync, rmSync, writeFileSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import test from 'node:test';
import { fileURLToPath } from 'node:url';
import { generateAppStrings } from './generate_app_strings.mjs';

const generator = fileURLToPath(new URL('./generate_app_strings.mjs', import.meta.url));

test('generates typed members and named placeholder arguments', () => {
  const output = generateAppStrings({
    nav: { home: 'Home' },
    action: { go_to: 'Go to {section}' },
  });
  assert.match(output, /String get navHome =>/);
  assert.match(output, /String actionGoTo\(\{required String section\}\)/);
  assert.match(
    output,
    /_interpolate\('action\.go_to', 'Go to \{section\}', \{'section': section\}\)/,
  );
  assert.match(output, /GENERATED — do not edit/);
});

test('names snake_case placeholders after a camelCase parameter', () => {
  const output = generateAppStrings({ greet: 'Hi {first_name}' });
  assert.match(output, /String greet\(\{required String firstName\}\)/);
  assert.match(output, /\{'first_name': firstName\}/);
});

test('orders members by key', () => {
  const output = generateAppStrings({ zeta: 'Z', alpha: 'A', mid: { one: 'M' } });
  const order = ['alpha', 'midOne', 'zeta'].map((name) => output.indexOf(`String get ${name}`));
  assert.deepEqual(
    order,
    [...order].sort((left, right) => left - right),
  );
  assert.ok(order.every((index) => index > 0));
});

test('rejects duplicate Dart names', () => {
  assert.throws(() => generateAppStrings({ a_b: 'One', a: { b: 'Two' } }), /Duplicate Dart member/);
});

test('rejects keys and placeholders that cannot be Dart names', () => {
  assert.throws(() => generateAppStrings({ class: 'One' }), /usable Dart name/);
  assert.throws(() => generateAppStrings({ '1st': 'One' }), /usable Dart name/);
  assert.throws(() => generateAppStrings({ a: 'Go {new}' }), /usable Dart name/);
  assert.throws(() => generateAppStrings({ a: '{x_y} {xY}' }), /share a Dart parameter name/);
});

test('escapes text Dart would interpret without adding needless escapes', () => {
  const output = generateAppStrings({
    a: { quote: 'Say "hi" to it\'s $5 \\ done', lines: 'x\ny\tz' },
  });
  assert.ok(output.includes(String.raw`'Say "hi" to it\'s \$5 \\ done'`));
  assert.ok(output.includes(String.raw`'x\ny\tz'`));
  assert.ok(!output.includes(String.raw`\"`));
});

test('emits the interpolation helper only when a placeholder exists', () => {
  assert.doesNotMatch(generateAppStrings({ nav: { home: 'Home' } }), /_interpolate/);
  assert.match(generateAppStrings({ nav: { go: 'Go {to}' } }), /String _interpolate/);
});

test('--check reports missing and stale output without rewriting it', () => {
  const directory = mkdtempSync(join(tmpdir(), 'app-strings-'));
  const source = join(directory, 'en.json');
  const output = join(directory, 'app_strings.g.dart');
  const args = [generator, '--source', source, '--output', output];
  const check = () => execFileSync(process.execPath, [...args, '--check'], { stdio: 'pipe' });
  try {
    writeFileSync(source, JSON.stringify({ nav: { home: 'Home' } }));
    assert.throws(check, /stale/);
    execFileSync(process.execPath, args);
    check();
    writeFileSync(source, JSON.stringify({ nav: { home: 'Welcome' } }));
    assert.throws(check, /stale/);
    assert.match(readFileSync(output, 'utf8'), /Home/);
  } finally {
    rmSync(directory, { recursive: true, force: true });
  }
});
