import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/foundation.dart';

/// The portions of a Flutter frame that compete with the display frame budget.
///
/// Build and raster work are pipelined, so [criticalDuration] uses the slower
/// stage instead of adding both stages together.
@immutable
final class RenderFrameTiming {
  factory RenderFrameTiming({
    required Duration buildDuration,
    required Duration rasterDuration,
  }) {
    if (buildDuration.isNegative) {
      throw ArgumentError.value(
        buildDuration,
        'buildDuration',
        'must not be negative',
      );
    }
    if (rasterDuration.isNegative) {
      throw ArgumentError.value(
        rasterDuration,
        'rasterDuration',
        'must not be negative',
      );
    }
    return RenderFrameTiming._(
      buildDuration: buildDuration,
      rasterDuration: rasterDuration,
    );
  }

  const RenderFrameTiming._({
    required this.buildDuration,
    required this.rasterDuration,
  });

  /// Creates a package timing sample from an engine [FrameTiming].
  factory RenderFrameTiming.fromFlutter(FrameTiming timing) {
    return RenderFrameTiming(
      buildDuration: timing.buildDuration,
      rasterDuration: timing.rasterDuration,
    );
  }

  /// Time spent producing the layer tree on the UI thread.
  final Duration buildDuration;

  /// Time spent rasterizing the layer tree.
  final Duration rasterDuration;

  /// The stage that determines whether this frame fits the display cadence.
  Duration get criticalDuration {
    return Duration(
      microseconds: math.max(
        buildDuration.inMicroseconds,
        rasterDuration.inMicroseconds,
      ),
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is RenderFrameTiming &&
            buildDuration == other.buildDuration &&
            rasterDuration == other.rasterDuration;
  }

  @override
  int get hashCode => Object.hash(buildDuration, rasterDuration);

  @override
  String toString() {
    return 'RenderFrameTiming('
        'build: $buildDuration, raster: $rasterDuration)';
  }
}
