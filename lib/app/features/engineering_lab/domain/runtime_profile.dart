import 'package:flutter/foundation.dart';
import 'package:flutter_web_portfolio/app/features/engineering_lab/infrastructure/runtime_probe.dart'
    as runtime_probe;

/// Facts about the build that is executing in the visitor's browser.
@immutable
final class RuntimeProfile {
  const RuntimeProfile({
    required this.runtime,
    required this.renderer,
    required this.artifact,
    required this.crossOriginIsolated,
    required this.logicalProcessors,
  });

  factory RuntimeProfile.current() => RuntimeProfile(
    runtime: kIsWasm
        ? 'Dart WebAssembly'
        : kIsWeb
        ? 'Dart JavaScript'
        : 'Native Dart',
    renderer: kIsWasm
        ? 'SkWasm'
        : kIsWeb
        ? 'CanvasKit'
        : 'Platform renderer',
    artifact: kIsWasm
        ? 'main.dart.wasm'
        : kIsWeb
        ? 'main.dart.js'
        : 'native executable',
    crossOriginIsolated: runtime_probe.isCrossOriginIsolated,
    logicalProcessors: runtime_probe.logicalProcessorCount,
  );

  final String runtime;
  final String renderer;
  final String artifact;
  final bool crossOriginIsolated;
  final int? logicalProcessors;
}
