import 'package:web/web.dart' as web;

bool get isCrossOriginIsolated => web.window.crossOriginIsolated;

int? get logicalProcessorCount {
  final count = web.window.navigator.hardwareConcurrency;
  return count > 0 ? count : null;
}
