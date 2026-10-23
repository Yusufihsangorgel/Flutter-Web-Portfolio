import assert from 'node:assert/strict';
import { spawnSync } from 'node:child_process';
import { mkdtempSync, mkdirSync, readFileSync, rmSync, writeFileSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import test from 'node:test';
import { fileURLToPath } from 'node:url';
import { parseDartDirectives } from './dart_directives.mjs';

const verifier = fileURLToPath(new URL('./verify_dart_reachability.mjs', import.meta.url));
const sharedFixtures = JSON.parse(
  readFileSync(new URL('../../quality/fixtures/dart_directives.json', import.meta.url), 'utf8'),
).cases;

function checkFixture(mainSource, includeDependency = true) {
  const root = mkdtempSync(join(tmpdir(), 'dart-reachability-'));
  try {
    const lib = join(root, 'lib');
    mkdirSync(lib);
    writeFileSync(join(lib, 'main.dart'), mainSource);
    if (includeDependency) writeFileSync(join(lib, 'dependency.dart'), 'const value = 1;\n');
    return spawnSync(process.execPath, [verifier], { cwd: root, encoding: 'utf8' });
  } finally {
    rmSync(root, { recursive: true, force: true });
  }
}

test('shared Dart directive fixtures agree on URI branches and line numbers', () => {
  assert.ok(sharedFixtures.length >= 15);
  for (const fixture of sharedFixtures) {
    if ('error' in fixture) {
      assert.throws(
        () => parseDartDirectives(fixture.source, 'lib/main.dart'),
        new RegExp(`main\\.dart:${fixture.error}:`),
        fixture.name,
      );
    } else {
      assert.deepEqual(
        parseDartDirectives(fixture.source, 'lib/main.dart'),
        fixture.directives,
        fixture.name,
      );
    }
  }
});

test('a part URI equal to of is not the part of keyword', () => {
  for (const literal of ["'of'", 'r"""of"""']) {
    assert.deepEqual(parseDartDirectives(`part ${literal};`, 'lib/main.dart'), [
      { kind: 'part', uri: 'of', line: 1 },
    ]);
    assert.deepEqual(parseDartDirectives(`part of ${literal};`, 'lib/main.dart'), [
      { kind: 'part of', uri: 'of', line: 1 },
    ]);
  }
});

test('a named dotted part of declaration creates no URI edge', () => {
  const source = 'part of library.name;\n';
  assert.deepEqual(parseDartDirectives(source, 'lib/main.dart'), []);
  const result = checkFixture(source, false);
  assert.equal(result.status, 0, result.stderr);
  assert.match(result.stdout, /1\/1 files reachable/);
});

test('a named part of terminator leaves the following import visible', () => {
  const result = checkFixture("part of library.name;\nimport 'dependency.dart';\n");
  assert.equal(result.status, 0, result.stderr);
  assert.match(result.stdout, /2\/2 files reachable/);
});

test('malformed named part of syntax fails closed even in a one-file graph', () => {
  for (const fixture of sharedFixtures.filter(
    (item) => item.name.startsWith('named-part-of-') && 'error' in item,
  )) {
    const result = checkFixture(fixture.source, false);
    assert.equal(result.status, 1, fixture.name);
    assert.match(
      result.stderr,
      new RegExp(`lib/main\\.dart:${fixture.error}: unsupported named part of directive`),
      fixture.name,
    );
  }
});

test('declaration boundaries preserve import and part reachability', () => {
  for (const declaration of [
    'library library.import;',
    'void part() {}',
    'part<T>() {}',
    'final value = of(part);',
    'final value = () { return part; };',
    'final value = <int>[part];',
    'final value = {part};',
    '@prefix.import<List<int>>.named(of(part)) void of() {}',
  ]) {
    for (const directive of ['import', 'export', 'part', 'part of']) {
      const result = checkFixture(`${declaration}\n${directive} 'dependency.dart';\n`);
      assert.equal(result.status, 0, `${declaration}: ${result.stderr}`);
      assert.match(result.stdout, /2\/2 files reachable/);
    }
  }
});

test('reserved keywords cannot be library name segments', () => {
  const reserved = (
    'assert break case catch class const continue default do else enum extends ' +
    'false final finally for if in is new null rethrow return super switch this ' +
    'throw true try var void while with'
  ).split(' ');
  for (const word of reserved) {
    for (const directive of ['library', 'part of']) {
      assert.throws(
        () => parseDartDirectives(`${directive} name.${word};`, 'lib/main.dart'),
        /main\.dart:1:/,
      );
    }
  }
});

test('second same-line part remains reachable after an import', () => {
  const result = checkFixture("import 'dart:core'; part 'dependency.dart';\n");
  assert.equal(result.status, 0, result.stderr);
  assert.match(result.stdout, /2\/2 files reachable/);
});

test('CR-only line comment ends before a real import', () => {
  assert.deepEqual(parseDartDirectives("// hidden\rimport 'dependency.dart';\r", 'lib/main.dart'), [
    { kind: 'import', uri: 'dependency.dart', line: 2 },
  ]);
});

test('part identifier inside a method is not a directive', () => {
  assert.deepEqual(
    parseDartDirectives(
      "class Example { void split() { for (final part in ['a']) {} } }\nimport 'dependency.dart';\n",
      'lib/main.dart',
    ),
    [{ kind: 'import', uri: 'dependency.dart', line: 2 }],
  );
});

test('multiline import reaches the second Dart source', () => {
  const result = checkFixture("import\n  'dependency.dart';\n");
  assert.equal(result.status, 0, result.stderr);
  assert.match(result.stdout, /2\/2 files reachable/);
});

test('a missing internal import is rejected even with multiline syntax', () => {
  const result = checkFixture("import\n  'missing.dart';\n");
  assert.equal(result.status, 1);
  assert.match(result.stderr, /Internal Dart dependency not found: missing\.dart/);
});

test('single-line and conditional imports remain reachable', () => {
  for (const source of [
    "import 'dependency.dart';\n",
    "import 'dart:core' if (dart.library.html) 'dependency.dart';\n",
  ]) {
    const result = checkFixture(source);
    assert.equal(result.status, 0, result.stderr);
    assert.match(result.stdout, /2\/2 files reachable/);
  }
});

test('comments between import and URI still reach the dependency', () => {
  for (const source of [
    "import /* separator */ 'dependency.dart';\n",
    "import // separator\n  'dependency.dart';\n",
  ]) {
    const result = checkFixture(source);
    assert.equal(result.status, 0, result.stderr);
    assert.match(result.stdout, /2\/2 files reachable/);
  }
});

test('an inline comment cannot add a missing conditional dependency', () => {
  const result = checkFixture(
    "import 'dependency.dart' // if (dart.library.html) 'missing.dart'\n;\n",
  );
  assert.equal(result.status, 0, result.stderr);
  assert.match(result.stdout, /2\/2 files reachable/);
});

test('comment markers inside a quoted URI remain intact', () => {
  const result = checkFixture("import './/dependency.dart';\n");
  assert.equal(result.status, 0, result.stderr);
  assert.match(result.stdout, /2\/2 files reachable/);
});

test('nested block comments hide missing imports until the outer close', () => {
  const result = checkFixture(
    "/* outer\n  /* inner */\n  import 'missing.dart';\n*/\nimport 'dependency.dart';\n",
  );
  assert.equal(result.status, 0, result.stderr);
  assert.match(result.stdout, /2\/2 files reachable/);
});

test('triple-quoted import and part URIs reach the second Dart source', () => {
  for (const source of ["import '''dependency.dart''';\n", 'part """dependency.dart""";\n']) {
    const result = checkFixture(source);
    assert.equal(result.status, 0, result.stderr);
    assert.match(result.stdout, /2\/2 files reachable/);
  }
});

test('a multiline string cannot fake a dependency or a comment', () => {
  const result = checkFixture(
    "import 'dependency.dart';\nconst fake = '''\nimport 'missing.dart';\n''';\nconst marker = \"\"\"/* not a comment */\"\"\";\n",
  );
  assert.equal(result.status, 0, result.stderr);
  assert.match(result.stdout, /2\/2 files reachable/);
});

test('a raw URI prefix still reaches the dependency', () => {
  const result = checkFixture('part r"""dependency.dart""";\n');
  assert.equal(result.status, 0, result.stderr);
  assert.match(result.stdout, /2\/2 files reachable/);
});

test('a truly unreachable second Dart source is rejected', () => {
  const result = checkFixture("// import 'dependency.dart';\nconst value = 'dependency.dart';\n");
  assert.equal(result.status, 1);
  assert.match(result.stderr, /Unreachable Dart sources detected:[\s\S]*lib\/dependency\.dart/);
});

test('metadata interpolation with an inner same-quote string leaves the real import visible', () => {
  const source = "@Note('${'inner'}')\nimport 'dependency.dart';\n";
  const result = checkFixture(source);
  assert.equal(result.status, 0, result.stderr);
  assert.match(result.stdout, /2\/2 files reachable/);
});

test('a conditional URI containing a semicolon is parsed as one string', () => {
  const result = checkFixture(
    "import 'dart:core' if (dart.library.html) 'missing;source.dart' if (dart.library.io) 'dependency.dart';\n",
  );
  assert.equal(result.status, 1);
  assert.match(result.stderr, /Internal Dart dependency not found: missing;source\.dart/);
});

test('part of URI and part URI both preserve graph reachability', () => {
  for (const source of ["part 'dependency.dart';\n", "part of 'dependency.dart';\n"]) {
    const result = checkFixture(source);
    assert.equal(result.status, 0, result.stderr);
    assert.match(result.stdout, /2\/2 files reachable/);
  }
});

test('unsupported and unterminated URI syntax fails closed with a source location', () => {
  for (const source of [
    "import '${uri}.dart';\n",
    "import 'dependency\\x2edart';\n",
    'import /* never closed',
    "import 'unterminated",
    "import 'dart:core' if (dart.library.html) foo;\n",
  ]) {
    const result = checkFixture(source);
    assert.equal(result.status, 1, source);
    assert.match(result.stderr, /main\.dart:1:/, source);
  }
});

test('directive output retains kind, URI, and literal line across conditional and part forms', () => {
  const source = [
    "@Note('${'inner'}')",
    "import 'dart:core' if (dart.library.html)",
    "  'dependency.dart';",
    "export r'''also.dart''';",
    "part of 'parent.dart';",
    "part 'child.dart';",
    'part of library.name;',
  ].join('\n');
  assert.deepEqual(parseDartDirectives(source, 'lib/main.dart'), [
    { kind: 'import', uri: 'dart:core', line: 2 },
    { kind: 'import', uri: 'dependency.dart', line: 3 },
    { kind: 'export', uri: 'also.dart', line: 4 },
    { kind: 'part of', uri: 'parent.dart', line: 5 },
    { kind: 'part', uri: 'child.dart', line: 6 },
  ]);
});

test('nested interpolation cannot create a false import or hide a later one', () => {
  const source =
    "@Note('${{'key': 'import \\u0027missing.dart\\u0027;'}}')\nimport 'dependency.dart';\n";
  const result = checkFixture(source);
  assert.equal(result.status, 0, result.stderr);
  assert.match(result.stdout, /2\/2 files reachable/);
});
