import 'dart:convert';
import 'dart:io';

import 'dart_metrics_engine.dart';

final class BaselineEntry {
  const BaselineEntry({
    required this.keyParts,
    required this.value,
    required this.reason,
  });

  factory BaselineEntry.fromJson(Object? value) {
    if (value is! Map<String, Object?>) {
      throw const FormatException('Baseline entries must be JSON objects.');
    }
    final path = value['path'];
    final identity = value['identity'];
    final metric = value['metric'];
    final measured = value['value'];
    final reason = value['reason'];
    if (path is! String ||
        identity is! String ||
        metric is! String ||
        measured is! int ||
        reason is! String ||
        reason.trim().isEmpty) {
      throw const FormatException(
        'Each baseline entry needs path, identity, metric, integer value, and reason.',
      );
    }
    return BaselineEntry(
      keyParts: MetricKey(path, identity, metric),
      value: measured,
      reason: reason,
    );
  }

  final MetricKey keyParts;
  final int value;
  final String reason;

  String get path => keyParts.path;
  String get identity => keyParts.identity;
  String get metric => keyParts.metric;

  String get key => '$path::$identity::$metric';

  Map<String, Object> toJson() => <String, Object>{
    'path': path,
    'identity': identity,
    'metric': metric,
    'value': value,
    'reason': reason,
  };
}

final class MetricKey {
  const MetricKey(this.path, this.identity, this.metric);

  final String path;
  final String identity;
  final String metric;
}

final class Baseline {
  const Baseline(this.entries);

  factory Baseline.read(File file) => Baseline.parse(file.readAsStringSync());

  factory Baseline.parse(String source) {
    final decoded = jsonDecode(source);
    if (decoded is! Map<String, Object?> || decoded['version'] != 1) {
      throw const FormatException(
        'Metrics baseline must have schema version 1.',
      );
    }
    final rawLimits = decoded['limits'];
    if (rawLimits is! Map<String, Object?>) {
      throw const FormatException('Metrics baseline must declare limits.');
    }
    _validateLimits(rawLimits);
    final rawEntries = decoded['entries'];
    if (rawEntries is! List<Object?>) {
      throw const FormatException('Metrics baseline entries must be a list.');
    }
    final entries = rawEntries.map(BaselineEntry.fromJson).toList();
    final keys = <String>{};
    for (final entry in entries) {
      if (!keys.add(entry.key)) {
        throw FormatException('Duplicate metrics baseline entry: ${entry.key}');
      }
    }
    return Baseline(entries);
  }

  final List<BaselineEntry> entries;

  void write(File file) {
    final sorted = [...entries]
      ..sort((left, right) => left.key.compareTo(right.key));
    final document = <String, Object>{
      'version': 1,
      'limits': metricLimits,
      'entries': sorted.map((entry) => entry.toJson()).toList(),
    };
    file.writeAsStringSync(
      '${const JsonEncoder.withIndent('  ').convert(document)}\n',
    );
  }
}

List<RatchetIssue> auditBaselineEvolution(
  Baseline current,
  Baseline historical,
) {
  final historicalByKey = <String, BaselineEntry>{
    for (final entry in historical.entries) entry.key: entry,
  };
  final issues = <RatchetIssue>[];
  for (final entry in current.entries) {
    final previous = historicalByKey[entry.key];
    if (previous == null) {
      issues.add(
        RatchetIssue(
          RatchetIssueKind.baselineGrowth,
          entry.key,
          'BASELINE_GROWTH ${entry.key}: new retained violation',
        ),
      );
    } else if (entry.value > previous.value) {
      issues.add(
        RatchetIssue(
          RatchetIssueKind.baselineGrowth,
          entry.key,
          'BASELINE_GROWTH ${entry.key}: ${previous.value} -> ${entry.value}',
        ),
      );
    }
  }
  issues.sort((left, right) => left.key.compareTo(right.key));
  return issues;
}

enum RatchetIssueKind { newViolation, worsened, stale, baselineGrowth }

final class RatchetIssue {
  const RatchetIssue(this.kind, this.key, this.message);

  final RatchetIssueKind kind;
  final String key;
  final String message;
}

final class RatchetAudit {
  const RatchetAudit({
    required this.violations,
    required this.retained,
    required this.issues,
  });

  final List<BaselineEntry> violations;
  final List<BaselineEntry> retained;
  final List<RatchetIssue> issues;

  bool get passes => issues.isEmpty;
}

RatchetAudit auditBaseline(
  List<CallableMetrics> measurements,
  Baseline baseline,
) {
  final violations = findViolations(measurements);
  final actualByKey = <String, BaselineEntry>{
    for (final entry in violations) entry.key: entry,
  };
  final baselineByKey = <String, BaselineEntry>{
    for (final entry in baseline.entries) entry.key: entry,
  };
  final issues = <RatchetIssue>[];
  final retained = <BaselineEntry>[];
  for (final actual in violations) {
    final previous = baselineByKey[actual.key];
    if (previous == null) {
      issues.add(
        RatchetIssue(
          RatchetIssueKind.newViolation,
          actual.key,
          'NEW ${actual.key}: ${actual.value}',
        ),
      );
    } else if (actual.value > previous.value) {
      issues.add(
        RatchetIssue(
          RatchetIssueKind.worsened,
          actual.key,
          'WORSENED ${actual.key}: ${previous.value} -> ${actual.value}',
        ),
      );
    } else if (actual.value < previous.value) {
      issues.add(
        RatchetIssue(
          RatchetIssueKind.stale,
          actual.key,
          'STALE ${actual.key}: lower ${previous.value} -> ${actual.value}',
        ),
      );
    } else {
      retained.add(previous);
    }
  }
  _addRemovedViolationIssues(baseline, actualByKey, issues);
  issues.sort((left, right) => left.key.compareTo(right.key));
  retained.sort((left, right) => left.key.compareTo(right.key));
  return RatchetAudit(
    violations: violations,
    retained: retained,
    issues: issues,
  );
}

void _addRemovedViolationIssues(
  Baseline baseline,
  Map<String, BaselineEntry> actualByKey,
  List<RatchetIssue> issues,
) {
  for (final previous in baseline.entries) {
    if (actualByKey.containsKey(previous.key)) continue;
    issues.add(
      RatchetIssue(
        RatchetIssueKind.stale,
        previous.key,
        'STALE ${previous.key}: violation was removed',
      ),
    );
  }
}

List<BaselineEntry> findViolations(List<CallableMetrics> measurements) {
  final violations = <BaselineEntry>[];
  for (final measurement in measurements) {
    for (final metric in measurement.measuredValues.entries) {
      if (metric.value <= measurement.limitFor(metric.key)) continue;
      violations.add(
        BaselineEntry(
          keyParts: MetricKey(
            measurement.path,
            measurement.identity,
            metric.key,
          ),
          value: metric.value,
          reason: _initialReason(metric.key),
        ),
      );
    }
  }
  violations.sort((left, right) => left.key.compareTo(right.key));
  return violations;
}

String _initialReason(String metric) =>
    'Existing $metric debt measured when the AST metrics gate was introduced; '
    'refactor this callable separately and shrink this entry.';

void _validateLimits(Map<String, Object?> actual) {
  if (actual.length != metricLimits.length) {
    throw const FormatException(
      'Metrics baseline limits do not match the tool.',
    );
  }
  for (final expected in metricLimits.entries) {
    if (actual[expected.key] != expected.value) {
      throw FormatException(
        'Metrics baseline limit ${expected.key} must be ${expected.value}.',
      );
    }
  }
}
