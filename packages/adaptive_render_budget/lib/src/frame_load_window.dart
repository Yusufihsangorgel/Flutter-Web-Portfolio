import 'dart:math' as math;

import 'package:flutter/foundation.dart';

import 'frame_timing_sample.dart';

/// A read-only summary of normalized load samples.
@immutable
final class FrameLoadStatistics {
  const FrameLoadStatistics({
    required this.sampleCount,
    required this.mean,
    required this.p95,
    required this.maximum,
    required this.overloadedFraction,
  });

  /// Empty statistics returned before any frame has been recorded.
  static const empty = FrameLoadStatistics(
    sampleCount: 0,
    mean: 0,
    p95: 0,
    maximum: 0,
    overloadedFraction: 0,
  );

  /// Number of samples currently represented.
  final int sampleCount;

  /// Arithmetic mean of the normalized frame loads.
  final double mean;

  /// Nearest-rank 95th percentile of the normalized frame loads.
  final double p95;

  /// Largest normalized frame load.
  final double maximum;

  /// Fraction of samples at or above the requested overload threshold.
  final double overloadedFraction;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is FrameLoadStatistics &&
            sampleCount == other.sampleCount &&
            mean == other.mean &&
            p95 == other.p95 &&
            maximum == other.maximum &&
            overloadedFraction == other.overloadedFraction;
  }

  @override
  int get hashCode {
    return Object.hash(sampleCount, mean, p95, maximum, overloadedFraction);
  }

  @override
  String toString() {
    return 'FrameLoadStatistics('
        'samples: $sampleCount, mean: $mean, p95: $p95, '
        'maximum: $maximum, overloaded: $overloadedFraction)';
  }
}

/// A fixed-capacity rolling window of refresh-rate-normalized frame load.
///
/// A load of `1.0` means the slower of the build and raster stages consumed
/// one full display interval. The same 8 ms frame therefore has a load near
/// `0.48` at 60 Hz and `0.96` at 120 Hz.
final class FrameLoadWindow {
  FrameLoadWindow({required int capacity})
    : capacity = _validatedCapacity(capacity),
      _loads = Float64List(_validatedCapacity(capacity));

  /// Maximum number of recent samples retained.
  final int capacity;

  final Float64List _loads;
  int _length = 0;
  int _nextIndex = 0;

  /// Number of samples currently retained.
  int get length => _length;

  /// Whether no samples are currently retained.
  bool get isEmpty => _length == 0;

  /// Adds one frame, normalized against [refreshRateHz].
  double add(RenderFrameTiming timing, {required double refreshRateHz}) {
    final load = normalizedLoad(timing, refreshRateHz: refreshRateHz);
    _loads[_nextIndex] = load;
    _nextIndex = (_nextIndex + 1) % capacity;
    if (_length < capacity) {
      _length += 1;
    }
    return load;
  }

  /// Removes every retained sample without reallocating the backing buffer.
  void clear() {
    _length = 0;
    _nextIndex = 0;
  }

  /// Returns a load summary using [overloadThreshold] for the overloaded share.
  FrameLoadStatistics statistics({required double overloadThreshold}) {
    _validatePositiveFinite(overloadThreshold, name: 'overloadThreshold');
    if (_length == 0) {
      return FrameLoadStatistics.empty;
    }

    final sorted = _orderedLoads()..sort();
    var sum = 0.0;
    var overloaded = 0;
    for (final load in sorted) {
      sum += load;
      if (load >= overloadThreshold) {
        overloaded += 1;
      }
    }

    final percentileIndex = math.max(0, (0.95 * sorted.length).ceil() - 1);
    return FrameLoadStatistics(
      sampleCount: sorted.length,
      mean: sum / sorted.length,
      p95: sorted[percentileIndex],
      maximum: sorted.last,
      overloadedFraction: overloaded / sorted.length,
    );
  }

  /// Converts one frame into a ratio of the current display interval.
  static double normalizedLoad(
    RenderFrameTiming timing, {
    required double refreshRateHz,
  }) {
    _validatePositiveFinite(refreshRateHz, name: 'refreshRateHz');
    final budgetMicroseconds = Duration.microsecondsPerSecond / refreshRateHz;
    return timing.criticalDuration.inMicroseconds / budgetMicroseconds;
  }

  List<double> _orderedLoads() {
    if (_length < capacity) {
      return List<double>.generate(_length, (index) => _loads[index]);
    }

    return List<double>.generate(
      _length,
      (index) => _loads[(_nextIndex + index) % capacity],
    );
  }

  static void _validatePositiveFinite(double value, {required String name}) {
    if (!value.isFinite || value <= 0) {
      throw ArgumentError.value(
        value,
        name,
        'must be finite and greater than 0',
      );
    }
  }

  static int _validatedCapacity(int capacity) {
    if (capacity <= 0) {
      throw ArgumentError.value(capacity, 'capacity', 'must be greater than 0');
    }
    return capacity;
  }
}
