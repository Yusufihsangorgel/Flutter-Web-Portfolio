import 'package:flutter/foundation.dart';

/// Tunable thresholds for [AdaptiveRenderBudgetController].
///
/// Defaults are conservative starting points, not device-performance claims.
/// Applications should validate them against profile or release telemetry.
@immutable
final class AdaptiveRenderBudgetPolicy {
  factory AdaptiveRenderBudgetPolicy({
    int windowCapacity = 90,
    int minimumSamples = 36,
    int evaluationIntervalFrames = 6,
    double overloadThreshold = 1,
    double downgradeP95Threshold = 1.08,
    double downgradeOverloadedFraction = 0.15,
    double recoveryP95Threshold = 0.78,
    double recoveryOverloadedFraction = 0.02,
    int probeSampleCount = 48,
    int rollbackMinimumSamples = 12,
    double rollbackP95Threshold = 1,
    double rollbackOverloadedFraction = 0.08,
    Duration cooldown = const Duration(seconds: 4),
    double refreshRateResetTolerance = 0.05,
  }) {
    if (windowCapacity <= 0) {
      throw ArgumentError.value(
        windowCapacity,
        'windowCapacity',
        'must be greater than 0',
      );
    }
    if (minimumSamples <= 0 || minimumSamples > windowCapacity) {
      throw ArgumentError.value(
        minimumSamples,
        'minimumSamples',
        'must be within 1..windowCapacity',
      );
    }
    if (evaluationIntervalFrames <= 0 ||
        evaluationIntervalFrames > windowCapacity) {
      throw ArgumentError.value(
        evaluationIntervalFrames,
        'evaluationIntervalFrames',
        'must be within 1..windowCapacity',
      );
    }
    _requirePositiveFinite(overloadThreshold, 'overloadThreshold');
    _requirePositiveFinite(downgradeP95Threshold, 'downgradeP95Threshold');
    _requireFraction(
      downgradeOverloadedFraction,
      'downgradeOverloadedFraction',
    );
    _requirePositiveFinite(recoveryP95Threshold, 'recoveryP95Threshold');
    if (recoveryP95Threshold >= downgradeP95Threshold) {
      throw ArgumentError.value(
        recoveryP95Threshold,
        'recoveryP95Threshold',
        'must be lower than downgradeP95Threshold',
      );
    }
    _requireFraction(recoveryOverloadedFraction, 'recoveryOverloadedFraction');
    if (recoveryOverloadedFraction >= downgradeOverloadedFraction) {
      throw ArgumentError.value(
        recoveryOverloadedFraction,
        'recoveryOverloadedFraction',
        'must be lower than downgradeOverloadedFraction',
      );
    }
    if (probeSampleCount < minimumSamples ||
        probeSampleCount > windowCapacity) {
      throw ArgumentError.value(
        probeSampleCount,
        'probeSampleCount',
        'must be within minimumSamples..windowCapacity',
      );
    }
    if (rollbackMinimumSamples <= 0 ||
        rollbackMinimumSamples > probeSampleCount) {
      throw ArgumentError.value(
        rollbackMinimumSamples,
        'rollbackMinimumSamples',
        'must be within 1..probeSampleCount',
      );
    }
    _requirePositiveFinite(rollbackP95Threshold, 'rollbackP95Threshold');
    if (rollbackP95Threshold <= recoveryP95Threshold) {
      throw ArgumentError.value(
        rollbackP95Threshold,
        'rollbackP95Threshold',
        'must be greater than recoveryP95Threshold',
      );
    }
    _requireFraction(rollbackOverloadedFraction, 'rollbackOverloadedFraction');
    if (rollbackOverloadedFraction <= recoveryOverloadedFraction) {
      throw ArgumentError.value(
        rollbackOverloadedFraction,
        'rollbackOverloadedFraction',
        'must be greater than recoveryOverloadedFraction',
      );
    }
    if (cooldown.isNegative) {
      throw ArgumentError.value(cooldown, 'cooldown', 'must not be negative');
    }
    if (!refreshRateResetTolerance.isFinite || refreshRateResetTolerance < 0) {
      throw ArgumentError.value(
        refreshRateResetTolerance,
        'refreshRateResetTolerance',
        'must be finite and non-negative',
      );
    }

    return AdaptiveRenderBudgetPolicy._(
      windowCapacity: windowCapacity,
      minimumSamples: minimumSamples,
      evaluationIntervalFrames: evaluationIntervalFrames,
      overloadThreshold: overloadThreshold,
      downgradeP95Threshold: downgradeP95Threshold,
      downgradeOverloadedFraction: downgradeOverloadedFraction,
      recoveryP95Threshold: recoveryP95Threshold,
      recoveryOverloadedFraction: recoveryOverloadedFraction,
      probeSampleCount: probeSampleCount,
      rollbackMinimumSamples: rollbackMinimumSamples,
      rollbackP95Threshold: rollbackP95Threshold,
      rollbackOverloadedFraction: rollbackOverloadedFraction,
      cooldown: cooldown,
      refreshRateResetTolerance: refreshRateResetTolerance,
    );
  }

  const AdaptiveRenderBudgetPolicy._({
    required this.windowCapacity,
    required this.minimumSamples,
    required this.evaluationIntervalFrames,
    required this.overloadThreshold,
    required this.downgradeP95Threshold,
    required this.downgradeOverloadedFraction,
    required this.recoveryP95Threshold,
    required this.recoveryOverloadedFraction,
    required this.probeSampleCount,
    required this.rollbackMinimumSamples,
    required this.rollbackP95Threshold,
    required this.rollbackOverloadedFraction,
    required this.cooldown,
    required this.refreshRateResetTolerance,
  });

  /// Number of recent frames retained.
  final int windowCapacity;

  /// Frames required before normal downgrade or recovery decisions.
  final int minimumSamples;

  /// New frames between policy evaluations.
  final int evaluationIntervalFrames;

  /// Load ratio counted as an overloaded frame.
  final double overloadThreshold;

  /// P95 load that contributes to a downgrade.
  final double downgradeP95Threshold;

  /// Overloaded-frame share that contributes to a downgrade.
  final double downgradeOverloadedFraction;

  /// Maximum P95 load considered stable enough for an upward probe.
  final double recoveryP95Threshold;

  /// Maximum overloaded-frame share considered stable for a probe.
  final double recoveryOverloadedFraction;

  /// Frames required to accept an upward probe.
  final int probeSampleCount;

  /// Earliest point at which an unhealthy probe may roll back.
  final int rollbackMinimumSamples;

  /// P95 load that immediately rejects a sufficiently sampled probe.
  final double rollbackP95Threshold;

  /// Overloaded-frame share that immediately rejects a probe.
  final double rollbackOverloadedFraction;

  /// Minimum delay between quality transitions.
  final Duration cooldown;

  /// Relative refresh-rate change that resets accumulated evidence.
  final double refreshRateResetTolerance;

  static void _requirePositiveFinite(double value, String name) {
    if (!value.isFinite || value <= 0) {
      throw ArgumentError.value(
        value,
        name,
        'must be finite and greater than 0',
      );
    }
  }

  static void _requireFraction(double value, String name) {
    if (!value.isFinite || value < 0 || value > 1) {
      throw ArgumentError.value(value, name, 'must be within 0..1');
    }
  }
}
