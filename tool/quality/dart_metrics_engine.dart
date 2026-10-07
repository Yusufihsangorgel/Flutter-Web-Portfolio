import 'dart:io';

import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/source/line_info.dart';

import 'dart_metrics_flow.dart';

const Map<String, int> metricLimits = <String, int>{
  'lines': 60,
  'buildLines': 100,
  'parameters': 4,
  'nesting': 4,
  'complexity': 15,
};

/// One syntactic callable measured without resolving imports or types.
///
/// Lines include the declaration from its first token through its final token.
/// A method named exactly `build` uses the 100-line limit; all other callables
/// use 60. Parameters are formal parameter nodes. Nesting counts `if`, loops,
/// `switch`, switch expressions, and `catch`; an `else if` stays at its parent's
/// depth. Complexity starts at one and adds `if`, loops, `catch`, conditional
/// expressions, non-default switch cases, switch-expression cases, `&&`, and
/// `||`. Nested callables are measured separately and never contribute to an
/// outer callable's nesting or complexity.
final class CallableMetrics {
  const CallableMetrics({required this.location, required this.values});

  final CallableLocation location;
  final MetricValues values;

  String get path => location.path;
  String get identity => location.identity;
  int get startLine => location.startLine;
  int get endLine => location.endLine;
  int get lines => values.lines;
  int get lineLimit => values.lineLimit;
  int get parameters => values.parameters;
  int get nesting => values.nesting;
  int get complexity => values.complexity;

  Map<String, int> get measuredValues => <String, int>{
    lineLimit == metricLimits['buildLines'] ? 'buildLines' : 'lines': lines,
    'parameters': parameters,
    'nesting': nesting,
    'complexity': complexity,
  };

  int limitFor(String metric) {
    if (metric == 'lines' || metric == 'buildLines') return lineLimit;
    return metricLimits[metric]!;
  }

  Map<String, Object> toJson() => <String, Object>{
    'path': path,
    'identity': identity,
    'startLine': startLine,
    'endLine': endLine,
    ...values.toJson(),
  };
}

final class CallableLocation {
  const CallableLocation({
    required this.path,
    required this.identity,
    required this.startLine,
    required this.endLine,
  });

  final String path;
  final String identity;
  final int startLine;
  final int endLine;
}

final class MetricValues {
  const MetricValues(this.data);

  final ({
    int lines,
    int lineLimit,
    int parameters,
    int nesting,
    int complexity,
  })
  data;

  int get lines => data.lines;
  int get lineLimit => data.lineLimit;
  int get parameters => data.parameters;
  int get nesting => data.nesting;
  int get complexity => data.complexity;

  Map<String, Object> toJson() => <String, Object>{
    'lines': lines,
    'lineLimit': lineLimit,
    'parameters': parameters,
    'nesting': nesting,
    'complexity': complexity,
  };
}

List<CallableMetrics> measureSource(String source, String path) {
  final parsed = parseString(
    content: source,
    path: path,
    throwIfDiagnostics: false,
  );
  if (parsed.errors.isNotEmpty) {
    final messages = parsed.errors.map((error) => error.toString()).join('\n');
    throw FormatException(
      'Cannot measure invalid Dart source $path:\n$messages',
    );
  }
  final collector = _CallableCollector(path, parsed.lineInfo);
  parsed.unit.accept(collector);
  collector.measurements.sort(_compareMeasurements);
  return collector.measurements;
}

List<CallableMetrics> measureRepository(Directory root) {
  final files = collectDartFiles(root);
  final measurements = <CallableMetrics>[];
  for (final file in files) {
    final path = _relativePath(root, file);
    measurements.addAll(measureSource(file.readAsStringSync(), path));
  }
  measurements.sort(_compareMeasurements);
  return measurements;
}

List<File> collectDartFiles(Directory root) {
  const roots = <String>['lib', 'test', 'tool', 'packages'];
  final files = <File>[];
  for (final name in roots) {
    final directory = Directory('${root.path}${Platform.pathSeparator}$name');
    if (!directory.existsSync()) continue;
    for (final entity in directory.listSync(
      recursive: true,
      followLinks: false,
    )) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      final relative = _relativePath(root, entity);
      if (relative.startsWith('tool/quality/fixtures/dart_metrics/')) continue;
      if (_containsGeneratedDirectory(relative)) continue;
      files.add(entity);
    }
  }
  files.sort((left, right) => left.path.compareTo(right.path));
  return files;
}

bool _containsGeneratedDirectory(String path) {
  const excluded = <String>{
    '.dart_tool',
    '.hosted-cache',
    '.pub-cache',
    'build',
  };
  final segments = path.split('/');
  return segments.any(excluded.contains);
}

int _compareMeasurements(CallableMetrics left, CallableMetrics right) {
  final pathOrder = left.path.compareTo(right.path);
  if (pathOrder != 0) return pathOrder;
  return left.identity.compareTo(right.identity);
}

String _relativePath(Directory root, File file) {
  final prefix = '${root.absolute.path}${Platform.pathSeparator}';
  return file.absolute.path.substring(prefix.length).replaceAll('\\', '/');
}

final class _CallableCollector extends RecursiveAstVisitor<void> {
  _CallableCollector(this.path, this.lineInfo);

  final String path;
  final LineInfo lineInfo;
  final List<CallableMetrics> measurements = <CallableMetrics>[];
  final List<String> _callableStack = <String>[];
  final Map<String, int> _identityCounts = <String, int>{};
  final Map<String, int> _closureCounts = <String, int>{};

  @override
  void visitConstructorDeclaration(ConstructorDeclaration node) {
    final type = _enclosingType(node);
    final suffix = node.name?.lexeme ?? 'new';
    final identity = _unique('$type.constructor:$suffix');
    _record(
      _CallableInput(
        (offset: node.offset, end: node.end),
        <AstNode>[node.parameters, ...node.initializers, node.body],
        _parameterCount(node.parameters),
        _CallableLabel(identity, false),
      ),
    );
  }

  @override
  void visitFunctionDeclaration(FunctionDeclaration node) {
    final kind = node.isGetter
        ? 'getter'
        : node.isSetter
        ? 'setter'
        : 'function';
    final prefix = _callableStack.isEmpty
        ? ''
        : '${_callableStack.last}/local:';
    final identity = _unique('$prefix$kind:${node.name.lexeme}');
    final expression = node.functionExpression;
    _record(
      _CallableInput(
        (offset: node.offset, end: node.end),
        <AstNode>[?expression.parameters, expression.body],
        _parameterCount(expression.parameters),
        _CallableLabel(identity, false),
      ),
    );
  }

  @override
  void visitFunctionExpression(FunctionExpression node) {
    final owner = _callableStack.isEmpty ? 'unit' : _callableStack.last;
    final ordinal = (_closureCounts[owner] ?? 0) + 1;
    _closureCounts[owner] = ordinal;
    final identity = _unique('$owner/closure:$ordinal');
    _record(
      _CallableInput(
        (offset: node.offset, end: node.end),
        <AstNode>[?node.parameters, node.body],
        _parameterCount(node.parameters),
        _CallableLabel(identity, false),
      ),
    );
  }

  @override
  void visitMethodDeclaration(MethodDeclaration node) {
    final kind = node.isGetter
        ? 'getter'
        : node.isSetter
        ? 'setter'
        : node.isOperator
        ? 'operator'
        : 'method';
    final identity = _unique(
      '${_enclosingType(node)}.$kind:${node.name.lexeme}',
    );
    _record(
      _CallableInput(
        (offset: node.offset, end: node.end),
        <AstNode>[?node.parameters, node.body],
        _parameterCount(node.parameters),
        _CallableLabel(
          identity,
          node.name.lexeme == 'build' && !node.isGetter && !node.isSetter,
        ),
      ),
    );
  }

  @override
  void visitPrimaryConstructorDeclaration(PrimaryConstructorDeclaration node) {
    final body = node.body;
    final suffix = node.constructorName?.name.lexeme ?? 'new';
    final identity = _unique('${_enclosingType(node)}.constructor:$suffix');
    _record(
      _CallableInput(
        (offset: node.offset, end: body?.end ?? node.end),
        <AstNode>[
          node.formalParameters,
          if (body != null) ...body.initializers,
          if (body != null) body.body,
        ],
        _parameterCount(node.formalParameters),
        _CallableLabel(identity, false),
      ),
    );
  }

  @override
  void visitPrimaryConstructorBody(PrimaryConstructorBody node) {}

  void _record(_CallableInput input) {
    final startLine = lineInfo.getLocation(input.range.offset).lineNumber;
    final endOffset = input.range.end > input.range.offset
        ? input.range.end - 1
        : input.range.end;
    final endLine = lineInfo.getLocation(endOffset).lineNumber;
    final flow = FlowMetricsVisitor();
    for (final root in input.executableRoots) {
      root.accept(flow);
    }
    measurements.add(
      CallableMetrics(
        location: CallableLocation(
          path: path,
          identity: input.label.identity,
          startLine: startLine,
          endLine: endLine,
        ),
        values: MetricValues((
          lines: endLine - startLine + 1,
          lineLimit: input.label.isBuild
              ? metricLimits['buildLines']!
              : metricLimits['lines']!,
          parameters: input.parameters,
          nesting: flow.maxDepth,
          complexity: flow.complexity,
        )),
      ),
    );
    _callableStack.add(input.label.identity);
    for (final root in input.executableRoots) {
      root.accept(this);
    }
    _callableStack.removeLast();
  }

  String _unique(String base) {
    final count = (_identityCounts[base] ?? 0) + 1;
    _identityCounts[base] = count;
    return count == 1 ? base : '$base#$count';
  }
}

final class _CallableLabel {
  const _CallableLabel(this.identity, this.isBuild);

  final String identity;
  final bool isBuild;
}

final class _CallableInput {
  const _CallableInput(
    this.range,
    this.executableRoots,
    this.parameters,
    this.label,
  );

  final ({int offset, int end}) range;
  final List<AstNode> executableRoots;
  final int parameters;
  final _CallableLabel label;
}

String _enclosingType(AstNode node) {
  var current = node.parent;
  while (current != null) {
    if (current is ClassDeclaration) {
      return 'class:${current.namePart.typeName.lexeme}';
    }
    if (current is EnumDeclaration) {
      return 'enum:${current.namePart.typeName.lexeme}';
    }
    if (current is MixinDeclaration) return 'mixin:${current.name.lexeme}';
    if (current is ExtensionTypeDeclaration) {
      return 'extensionType:${current.namePart.typeName.lexeme}';
    }
    if (current is ExtensionDeclaration) {
      final name =
          current.name?.lexeme ??
          'on:${current.onClause?.extendedType.toSource()}';
      return 'extension:$name';
    }
    current = current.parent;
  }
  return 'unit';
}

int _parameterCount(FormalParameterList? parameters) =>
    parameters?.parameterFragments.length ?? 0;
