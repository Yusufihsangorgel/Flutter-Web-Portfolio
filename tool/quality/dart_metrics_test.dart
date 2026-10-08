import 'dart:io';

import 'dart_metrics.dart' as cli;
import 'dart_metrics_baseline.dart';
import 'dart_metrics_engine.dart';

const _shrinkRoot = 'tool/quality/fixtures/dart_metrics/shrink';
const _staleBaseline = '$_shrinkRoot/stale_baseline.json';
const _shrunkBaseline = '$_shrinkRoot/shrunk_baseline.json';

// A fixed past timestamp reveals whether a temporary baseline was rewritten.
final _untouched = DateTime.utc(2001);

var _checks = 0;

void main() {
  _testFixtureMeasurements();
  _testCollectionControlMeasurements();
  _testStableIdentities();
  _testPrimaryConstructor();
  _testSourceRatchet();
  _testBaselineEvolution();
  _testBaselineValidation();
  _testShrinkRemoval();
  _testShrinkLowering();
  _testShrinkRefusesIncrease();
  _testShrinkRefusesNewViolation();
  _testShrinkRewriteKeepsOrderAndReasons();
  _testShrinkWithoutStaleEntriesDoesNotWrite();
  _testShrinkIsIdempotent();
  _testShrinkOptions();
  _testGeneratedDirectoriesExcluded();
  stdout.writeln('dart_metrics_test: $_checks checks passed');
}

void _testFixtureMeasurements() {
  final fixture = File(
    'tool/quality/fixtures/dart_metrics/callables.dart',
  ).readAsStringSync();
  final measured = measureSource(fixture, 'fixture.dart');
  final byIdentity = <String, CallableMetrics>{
    for (final item in measured) item.identity: item,
  };
  _expectMetric(byIdentity, 'function:lineBoundary', 'lines', 60);
  _expectMetric(byIdentity, 'function:lineViolation', 'lines', 61);
  _expectMetric(byIdentity, 'class:BuildBoundaries.method:build', 'lines', 100);
  _expectMetric(byIdentity, 'class:BuildViolation.method:build', 'lines', 101);
  _expectMetric(byIdentity, 'function:parameterBoundary', 'parameters', 4);
  _expectMetric(byIdentity, 'function:parameterViolation', 'parameters', 5);
  _expectMetric(byIdentity, 'function:nestingBoundary', 'nesting', 4);
  _expectMetric(byIdentity, 'function:nestingViolation', 'nesting', 5);
  _expectMetric(byIdentity, 'function:complexityBoundary', 'complexity', 15);
  _expectMetric(byIdentity, 'function:complexityViolation', 'complexity', 16);
  _expectIdentityMeasurements(byIdentity);
}

void _testCollectionControlMeasurements() {
  final fixture = File(
    'tool/quality/fixtures/dart_metrics/collection_control.dart',
  ).readAsStringSync();
  final measured = measureSource(fixture, 'collection_control.dart');
  final byIdentity = <String, CallableMetrics>{
    for (final item in measured) item.identity: item,
  };
  _expectMetric(
    byIdentity,
    'function:collectionControlPassing',
    'complexity',
    3,
  );
  _expectMetric(byIdentity, 'function:collectionControlPassing', 'nesting', 1);
  _expectMetric(
    byIdentity,
    'function:collectionComplexityBoundary',
    'complexity',
    15,
  );
  _expectMetric(
    byIdentity,
    'function:collectionComplexityViolation',
    'complexity',
    16,
  );
  _expectCollectionNesting(byIdentity);
  _expectMetric(byIdentity, 'function:collectionElseIf', 'complexity', 3);
  _expectMetric(byIdentity, 'function:collectionElseIf', 'nesting', 1);
  _expectMetric(
    byIdentity,
    'function:collectionClosureIsolation',
    'complexity',
    1,
  );
  _expectMetric(
    byIdentity,
    'function:collectionClosureIsolation/closure:1',
    'complexity',
    3,
  );
}

void _expectCollectionNesting(Map<String, CallableMetrics> byIdentity) {
  _expectMetric(byIdentity, 'function:collectionNestingBoundary', 'nesting', 4);
  _expectMetric(
    byIdentity,
    'function:collectionNestingViolation',
    'nesting',
    5,
  );
  _expectMetric(
    byIdentity,
    'function:collectionIfNestingBoundary',
    'nesting',
    4,
  );
  _expectMetric(
    byIdentity,
    'function:collectionIfNestingViolation',
    'nesting',
    5,
  );
}

void _expectIdentityMeasurements(Map<String, CallableMetrics> byIdentity) {
  final build = byIdentity['class:BuildBoundaries.method:build']!;
  _expect(build.measuredValues.containsKey('buildLines'), 'buildLines missing');
  _expect(
    !build.measuredValues.containsKey('lines'),
    'build reported as lines',
  );
  final method = byIdentity['class:IdentityFixture.method:closures']!;
  _expect(
    method.complexity == 1,
    'nested closure leaked into method complexity',
  );
  _expect(
    byIdentity.containsKey('class:IdentityFixture.constructor:new'),
    'constructor missing',
  );
  _expect(
    byIdentity.containsKey('class:IdentityFixture.constructor:named'),
    'named constructor missing',
  );
  _expect(
    byIdentity.containsKey('class:IdentityFixture.getter:value'),
    'getter missing',
  );
  _expect(
    byIdentity.containsKey('class:IdentityFixture.setter:value'),
    'setter missing',
  );
  final firstClosure =
      byIdentity['class:IdentityFixture.method:closures/closure:1'];
  _expect(firstClosure?.complexity == 2, 'closure complexity was not isolated');
  _expect(
    byIdentity.containsKey('class:IdentityFixture.method:closures/closure:2'),
    'second closure identity missing',
  );
  final initializer =
      byIdentity['class:ConstructorInitializerFixture.constructor:new'];
  _expect(
    initializer?.complexity == 2,
    'constructor initializer was not measured',
  );
  final initializerClosure =
      byIdentity['class:ConstructorInitializerFixture.constructor:new/closure:1'];
  _expect(
    initializerClosure?.complexity == 2,
    'initializer closure missing or leaked',
  );
}

void _testStableIdentities() {
  const source = '''
class Example {
  Example.named();
  int get value => 1;
  set value(int next) {}
  void run() {
    final callback = () => 1;
    callback();
  }
}
''';
  final original = measureSource(source, 'same.dart');
  final shifted = measureSource('\n\n$source', 'same.dart');
  final originalIdentities = original.map((item) => item.identity).toList();
  final shiftedIdentities = shifted.map((item) => item.identity).toList();
  _expect(
    _sameStrings(originalIdentities, shiftedIdentities),
    'line movement changed callable identities',
  );
}

void _testPrimaryConstructor() {
  const source = '''
class Primary(final int value) {
  this : assert(value >= 0) {
    if (value == 0) return;
    final callback = () {
      if (value > 1) return value;
      return 1;
    };
    callback();
  }
}
''';
  final measured = measureSource(source, 'primary.dart');
  final primary = measured.singleWhere(
    (item) => item.identity == 'class:Primary.constructor:new',
  );
  _expect(primary.parameters == 1, 'primary constructor parameters missing');
  _expect(primary.complexity == 2, 'primary constructor body missing');
  const closureIdentity = 'class:Primary.constructor:new/closure:1';
  final closures = measured.where((item) => item.identity == closureIdentity);
  _expect(closures.length == 1, 'primary constructor closure was duplicated');
  _expect(closures.single.complexity == 2, 'primary closure flow was missed');
  _expect(
    measured.every((item) => !item.identity.startsWith('unit/closure:')),
    'primary closure leaked into the compilation unit',
  );
}

void _testSourceRatchet() {
  final boundary = _metric(parameters: 4);
  final violation = _metric(parameters: 5);
  final worse = _metric(parameters: 6);
  final entry = _entry(5);
  _expect(
    auditBaseline(<CallableMetrics>[boundary], const Baseline([])).passes,
    'boundary failed',
  );
  final newAudit = auditBaseline(<CallableMetrics>[
    violation,
  ], const Baseline([]));
  _expect(
    _hasKind(newAudit.issues, RatchetIssueKind.newViolation),
    'NEW not rejected',
  );
  final retained = auditBaseline(<CallableMetrics>[
    violation,
  ], Baseline(<BaselineEntry>[entry]));
  _expect(
    retained.passes && retained.retained.length == 1,
    'exact debt not retained',
  );
  final worsened = auditBaseline(<CallableMetrics>[
    worse,
  ], Baseline(<BaselineEntry>[entry]));
  _expect(
    _hasKind(worsened.issues, RatchetIssueKind.worsened),
    'worsening not rejected',
  );
  final staleLower = auditBaseline(<CallableMetrics>[
    violation,
  ], Baseline(<BaselineEntry>[_entry(6)]));
  _expect(
    _hasKind(staleLower.issues, RatchetIssueKind.stale),
    'lower debt not stale',
  );
  final staleRemoved = auditBaseline(
    const <CallableMetrics>[],
    Baseline(<BaselineEntry>[entry]),
  );
  _expect(
    _hasKind(staleRemoved.issues, RatchetIssueKind.stale),
    'removed debt not stale',
  );
}

void _testBaselineEvolution() {
  final old = Baseline(<BaselineEntry>[_entry(6)]);
  final added = Baseline(<BaselineEntry>[
    _entry(6),
    _entry(5, identity: 'function:other'),
  ]);
  final increased = Baseline(<BaselineEntry>[_entry(7)]);
  final lowered = Baseline(<BaselineEntry>[_entry(5)]);
  _expect(
    auditBaselineEvolution(lowered, old).isEmpty,
    'lowered baseline rejected',
  );
  _expect(
    auditBaselineEvolution(const Baseline([]), old).isEmpty,
    'removal rejected',
  );
  _expect(
    _hasKind(
      auditBaselineEvolution(added, old),
      RatchetIssueKind.baselineGrowth,
    ),
    'added baseline key accepted',
  );
  _expect(
    _hasKind(
      auditBaselineEvolution(increased, old),
      RatchetIssueKind.baselineGrowth,
    ),
    'increased baseline value accepted',
  );
}

void _testBaselineValidation() {
  const invalid = '''
{"version":1,"limits":{"lines":60,"buildLines":100,"parameters":4,"nesting":4,"complexity":15},"entries":[{"path":"a.dart","identity":"function:a","metric":"parameters","value":5,"reason":""}]}
''';
  var rejected = false;
  try {
    Baseline.parse(invalid);
  } on FormatException {
    rejected = true;
  }
  _expect(rejected, 'empty baseline reason accepted');
}

void _testShrinkRemoval() {
  final measured = <CallableMetrics>[_metric(parameters: 4)];
  final baseline = Baseline(<BaselineEntry>[
    _entry(5),
    _entry(5, identity: 'function:gone'),
  ]);
  final shrink = shrinkBaseline(measured, baseline);
  _expect(shrink.removed == 2, 'resolved and vanished entries were kept');
  _expect(shrink.baseline.entries.isEmpty, 'removed entries remain listed');
  _expect(!shrink.refused && shrink.lowered == 0, 'removal was misreported');
}

void _testShrinkLowering() {
  final measured = <CallableMetrics>[_metric(parameters: 5)];
  final baseline = Baseline(<BaselineEntry>[_entry(7)]);
  final shrink = shrinkBaseline(measured, baseline);
  final lowered = shrink.baseline.entries.single;
  _expect(shrink.lowered == 1 && shrink.removed == 0, 'decrease not lowered');
  _expect(lowered.value == 5, 'lowered value differs from the measurement');
  _expect(lowered.reason == _entry(7).reason, 'lowering replaced the reason');
}

void _testShrinkRefusesIncrease() {
  final stale = Baseline.parse(_read(_staleBaseline));
  final retained = stale.entries.first;
  _expect(retained.identity == 'function:retained', 'fixture order changed');
  final increased = Baseline(<BaselineEntry>[
    BaselineEntry(
      keyParts: retained.keyParts,
      value: retained.value - 1,
      reason: retained.reason,
    ),
    ...stale.entries.skip(1),
  ]);
  _expectRefusedWithoutWrite(increased, RatchetIssueKind.worsened);
}

void _testShrinkRefusesNewViolation() {
  final stale = Baseline.parse(_read(_staleBaseline));
  final missing = Baseline(stale.entries.skip(1).toList());
  _expectRefusedWithoutWrite(missing, RatchetIssueKind.newViolation);
}

void _testShrinkRewriteKeepsOrderAndReasons() {
  final run = _shrinkCopy(_read(_staleBaseline));
  _expect(run.written, 'stale baseline was not rewritten');
  _expect(
    run.shrink.removed == 2 && run.shrink.lowered == 1,
    'rewrite reported wrong removed or lowered counts',
  );
  _expect(
    run.content == _read(_shrunkBaseline),
    'rewrite changed entry order, reasons, or formatting',
  );
  final measured = measureRepository(Directory(_shrinkRoot));
  _expect(
    auditBaseline(measured, Baseline.parse(run.content)).passes,
    'rewritten baseline still fails the ratchet',
  );
}

void _testShrinkWithoutStaleEntriesDoesNotWrite() {
  final source = _read(_shrunkBaseline);
  final run = _shrinkCopy(source);
  _expect(
    !run.shrink.changed && !run.shrink.refused,
    'a clean baseline reported changes or a refusal',
  );
  _expect(!run.written && run.content == source, 'clean baseline rewritten');
}

void _testShrinkIsIdempotent() {
  final first = _shrinkCopy(_read(_staleBaseline));
  final second = _shrinkCopy(first.content);
  _expect(first.written, 'the first shrink did not rewrite the baseline');
  _expect(!second.shrink.changed, 'a second shrink found more stale entries');
  _expect(!second.written, 'a second shrink rewrote the baseline');
  _expect(second.content == first.content, 'a second shrink changed content');
}

void _testShrinkOptions() {
  final options = cli.parseMetricsOptions(<String>[
    '--root',
    _shrinkRoot,
    '--baseline',
    'custom.json',
    '--shrink-baseline',
  ]);
  _expect(options.shrinkBaseline, '--shrink-baseline was not parsed');
  _expect(options.rootPath == _shrinkRoot, '--root was not kept');
  _expect(options.baselinePath == 'custom.json', '--baseline was not kept');
  _expectOptionsRejected(<String>['--shrink-baseline', '--create-baseline']);
  _expectOptionsRejected(<String>['--base-ref', 'HEAD', '--shrink-baseline']);
}

void _testGeneratedDirectoriesExcluded() {
  final root = Directory.systemTemp.createTempSync('dart_metrics_test_');
  try {
    final keptPath = '${root.path}/lib/kept.dart';
    File(keptPath)
      ..createSync(recursive: true)
      ..writeAsStringSync('void kept() {}\n');
    final legitimateCache = File('${root.path}/lib/cache/kept.dart')
      ..createSync(recursive: true)
      ..writeAsStringSync('void cachedSource() {}\n');
    for (final directory in <String>['build', '.dart_tool']) {
      File('${root.path}/packages/sample/$directory/ignored.dart')
        ..createSync(recursive: true)
        ..writeAsStringSync('void ignored() {}\n');
    }
    final paths = collectDartFiles(root).map((file) => file.path).toList();
    _expect(paths.length == 2, 'generated package directories were scanned');
    _expect(paths.contains(keptPath), 'the source file was excluded');
    _expect(
      paths.contains(legitimateCache.path),
      'lib/cache source was excluded',
    );
  } finally {
    root.deleteSync(recursive: true);
  }
}

CallableMetrics _metric({required int parameters}) => CallableMetrics(
  location: const CallableLocation(
    path: 'sample.dart',
    identity: 'function:sample',
    startLine: 1,
    endLine: 1,
  ),
  values: MetricValues((
    lines: 1,
    lineLimit: 60,
    parameters: parameters,
    nesting: 0,
    complexity: 1,
  )),
);

BaselineEntry _entry(int value, {String identity = 'function:sample'}) =>
    BaselineEntry(
      keyParts: MetricKey('sample.dart', identity, 'parameters'),
      value: value,
      reason: 'Existing parameter debt has a focused refactor target.',
    );

typedef _ShrinkRun = ({BaselineShrink shrink, String content, bool written});

_ShrinkRun _shrinkCopy(String source) {
  final temp = Directory.systemTemp.createTempSync('dart_metrics_shrink_');
  try {
    final file = File('${temp.path}/metrics-baseline.json')
      ..writeAsStringSync(source)
      ..setLastModifiedSync(_untouched);
    final measured = measureRepository(Directory(_shrinkRoot));
    final shrink = shrinkBaselineFile(measured, file);
    return (
      shrink: shrink,
      content: file.readAsStringSync(),
      written: !file.lastModifiedSync().isAtSameMomentAs(_untouched),
    );
  } finally {
    temp.deleteSync(recursive: true);
  }
}

void _expectRefusedWithoutWrite(Baseline baseline, RatchetIssueKind kind) {
  final source = baseline.encode();
  final run = _shrinkCopy(source);
  _expect(run.shrink.changed, '${kind.name} case had nothing to shrink');
  _expect(
    _hasKind(run.shrink.blockingIssues, kind),
    '${kind.name} did not block the shrink',
  );
  _expect(
    !run.written && run.content == source,
    '${kind.name} refusal rewrote the baseline',
  );
}

void _expectOptionsRejected(List<String> arguments) {
  var message = '';
  try {
    cli.parseMetricsOptions(arguments);
  } on FormatException catch (error) {
    message = error.message;
  }
  _expect(
    message.contains('cannot be combined'),
    'conflicting options accepted: $arguments',
  );
}

String _read(String path) => File(path).readAsStringSync();

void _expectMetric(
  Map<String, CallableMetrics> byIdentity,
  String identity,
  String metric,
  int expected,
) {
  final item = byIdentity[identity];
  _expect(item != null, 'missing $identity');
  final actual = switch (metric) {
    'lines' => item!.lines,
    'parameters' => item!.parameters,
    'nesting' => item!.nesting,
    'complexity' => item!.complexity,
    _ => throw ArgumentError.value(metric),
  };
  _expect(
    actual == expected,
    '$identity $metric: expected $expected, got $actual',
  );
}

bool _hasKind(List<RatchetIssue> issues, RatchetIssueKind kind) =>
    issues.any((issue) => issue.kind == kind);

bool _sameStrings(List<String> left, List<String> right) {
  if (left.length != right.length) return false;
  for (var index = 0; index < left.length; index += 1) {
    if (left[index] != right[index]) return false;
  }
  return true;
}

void _expect(bool condition, String message) {
  _checks += 1;
  if (!condition) throw StateError(message);
}
