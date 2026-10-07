import 'dart:convert';
import 'dart:io';

import 'dart_metrics_baseline.dart';
import 'dart_metrics_engine.dart';

const String _usage = '''
Usage: dart run tool/quality/dart_metrics.dart [options]

Measures every callable under lib/, test/, tool/, and packages/ except metric
fixtures. Identities use the file path plus the enclosing type/callable and
callable kind. Named callables do not depend on line numbers. Closures use a
lexical ordinal within their immediate callable, so unrelated line movement
does not rename them.

Options:
  --root PATH              Repository root (default: current directory).
  --baseline PATH          Baseline path (default: quality/metrics-baseline.json).
  --base-ref REVISION      Reject baseline growth against this Git revision.
  --json                   Print the complete measurement report as JSON.
  --create-baseline        Create the initial baseline; refuses to overwrite.
  --help                   Show this help.

Ratchet behavior: NEW and WORSENED violations fail. A lower or removed legacy
violation is STALE and also fails until the baseline is shrunk. Baseline entries
therefore preserve exact measured debt and can only be lowered or removed.
''';

void main(List<String> arguments) {
  try {
    final options = _parseOptions(arguments);
    if (options.help) {
      stdout.write(_usage);
      return;
    }
    final root = Directory(options.rootPath).absolute;
    final baselineFile = File(_resolve(root, options.baselinePath));
    final measurements = measureRepository(root);
    if (options.createBaseline) {
      _createBaseline(baselineFile, measurements);
      return;
    }
    final audit = auditBaseline(measurements, Baseline.read(baselineFile));
    final evolutionIssues = _auditHistoricalBaseline(root, options);
    if (options.json) {
      _printJson(measurements, audit, evolutionIssues);
    } else {
      _printHuman(measurements, audit, evolutionIssues);
    }
    if (!audit.passes || evolutionIssues.isNotEmpty) exitCode = 1;
  } on Object catch (error) {
    stderr.writeln('dart_metrics: $error');
    exitCode = 2;
  }
}

final class _Options {
  const _Options(this.values);

  final ({
    String rootPath,
    String baselinePath,
    String? baseRef,
    bool json,
    bool createBaseline,
    bool help,
  })
  values;

  String get rootPath => values.rootPath;
  String get baselinePath => values.baselinePath;
  String? get baseRef => values.baseRef;
  bool get json => values.json;
  bool get createBaseline => values.createBaseline;
  bool get help => values.help;
}

_Options _parseOptions(List<String> arguments) {
  var root = '.';
  var baseline = 'quality/metrics-baseline.json';
  String? baseRef;
  var json = false;
  var create = false;
  var help = false;
  for (var index = 0; index < arguments.length; index += 1) {
    final argument = arguments[index];
    if (argument == '--root' ||
        argument == '--baseline' ||
        argument == '--base-ref') {
      if (index + 1 >= arguments.length) {
        throw FormatException('Missing value for $argument.');
      }
      final value = arguments[index + 1];
      index += 1;
      if (argument == '--root') root = value;
      if (argument == '--baseline') baseline = value;
      if (argument == '--base-ref') baseRef = value;
    } else if (argument == '--json') {
      json = true;
    } else if (argument == '--create-baseline') {
      create = true;
    } else if (argument == '--help') {
      help = true;
    } else {
      throw FormatException('Unknown option: $argument');
    }
  }
  return _Options((
    rootPath: root,
    baselinePath: baseline,
    baseRef: baseRef,
    json: json,
    createBaseline: create,
    help: help,
  ));
}

void _createBaseline(File baselineFile, List<CallableMetrics> measurements) {
  if (baselineFile.existsSync()) {
    throw StateError('Refusing to overwrite ${baselineFile.path}.');
  }
  final violations = findViolations(measurements);
  baselineFile.parent.createSync(recursive: true);
  Baseline(violations).write(baselineFile);
  stdout.writeln(
    'Created ${baselineFile.path} with ${violations.length} retained violations.',
  );
}

void _printHuman(
  List<CallableMetrics> measurements,
  RatchetAudit audit,
  List<RatchetIssue> evolutionIssues,
) {
  for (final item in measurements) {
    stdout.writeln(
      '${item.path}:${item.startLine} ${item.identity} '
      'lines=${item.lines}/${item.lineLimit} '
      'parameters=${item.parameters}/${metricLimits['parameters']} '
      'nesting=${item.nesting}/${metricLimits['nesting']} '
      'complexity=${item.complexity}/${metricLimits['complexity']}',
    );
  }
  for (final issue in audit.issues) {
    stderr.writeln(issue.message);
  }
  for (final issue in evolutionIssues) {
    stderr.writeln(issue.message);
  }
  stdout.writeln(
    'Measured ${measurements.length} callables; '
    '${audit.violations.length} violations; '
    '${audit.retained.length} retained; '
    '${audit.issues.length + evolutionIssues.length} ratchet issues.',
  );
}

void _printJson(
  List<CallableMetrics> measurements,
  RatchetAudit audit,
  List<RatchetIssue> evolutionIssues,
) {
  final report = <String, Object>{
    'limits': metricLimits,
    'measurements': measurements.map((item) => item.toJson()).toList(),
    'violations': audit.violations.map((item) => item.toJson()).toList(),
    'issues': [...audit.issues, ...evolutionIssues]
        .map(
          (issue) => <String, Object>{
            'kind': issue.kind.name,
            'key': issue.key,
            'message': issue.message,
          },
        )
        .toList(),
  };
  stdout.writeln(const JsonEncoder.withIndent('  ').convert(report));
}

List<RatchetIssue> _auditHistoricalBaseline(Directory root, _Options options) {
  final reference = options.baseRef;
  if (reference == null || reference.isEmpty) return const <RatchetIssue>[];
  if (File(options.baselinePath).isAbsolute) {
    throw const FormatException('--baseline must be relative with --base-ref.');
  }
  final commitCheck = Process.runSync('git', <String>[
    'cat-file',
    '-e',
    '$reference^{commit}',
  ], workingDirectory: root.path);
  if (commitCheck.exitCode != 0) {
    throw FormatException('Invalid --base-ref: $reference');
  }
  final object = '$reference:${options.baselinePath}';
  final pathCheck = Process.runSync('git', <String>[
    'cat-file',
    '-e',
    object,
  ], workingDirectory: root.path);
  if (pathCheck.exitCode != 0) return const <RatchetIssue>[];
  final shown = Process.runSync('git', <String>[
    'show',
    object,
  ], workingDirectory: root.path);
  if (shown.exitCode != 0 || shown.stdout is! String) {
    throw StateError('Could not read metrics baseline at $reference.');
  }
  final historical = Baseline.parse(shown.stdout as String);
  final current = Baseline.read(File(_resolve(root, options.baselinePath)));
  return auditBaselineEvolution(current, historical);
}

String _resolve(Directory root, String path) {
  if (File(path).isAbsolute) return path;
  return '${root.path}${Platform.pathSeparator}$path';
}
