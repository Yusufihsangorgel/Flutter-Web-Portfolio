import 'package:adaptive_render_budget/src/adaptive_render_budget_config.dart';
import 'package:flutter/foundation.dart';

/// Tunable thresholds for [AdaptiveRenderBudgetController].
///
/// Defaults are conservative starting points, not device-performance claims.
/// Applications should validate them against profile or release telemetry.
@immutable
final class AdaptiveRenderBudgetPolicy {
  /// Creates a validated policy from grouped settings.
  ///
  /// Throws an [ArgumentError] when a value is out of range or the groups
  /// disagree: `minimumSamples <= probeSampleCount <= windowCapacity`,
  /// `rollbackMinimumSamples <= probeSampleCount`, recovery thresholds stay
  /// below their downgrade counterparts, and rollback thresholds stay above
  /// their recovery counterparts.
  factory AdaptiveRenderBudgetPolicy({
    AdaptiveRenderBudgetConfig config = const AdaptiveRenderBudgetConfig(),
  }) {
    _validateSampling(config.sampling);
    _validateThresholds(config.thresholds);
    _validateProbe(config.probe, config.sampling, config.thresholds);
    _validateTransition(config.transition);
    return AdaptiveRenderBudgetPolicy._(config);
  }

  const AdaptiveRenderBudgetPolicy._(this.config);

  /// Validated immutable settings used by this policy.
  final AdaptiveRenderBudgetConfig config;

  /// Number of recent frames retained.
  int get windowCapacity => config.sampling.windowCapacity;

  /// Frames required before normal downgrade or recovery decisions.
  int get minimumSamples => config.sampling.minimumSamples;

  /// New frames between policy evaluations.
  int get evaluationIntervalFrames => config.sampling.evaluationIntervalFrames;

  /// Load ratio counted as an overloaded frame.
  double get overloadThreshold => config.sampling.overloadThreshold;

  /// P95 load that contributes to a downgrade.
  double get downgradeP95Threshold => config.thresholds.downgradeP95Threshold;

  /// Overloaded-frame share that contributes to a downgrade.
  double get downgradeOverloadedFraction =>
      config.thresholds.downgradeOverloadedFraction;

  /// Maximum P95 load considered stable enough for an upward probe.
  double get recoveryP95Threshold => config.thresholds.recoveryP95Threshold;

  /// Maximum overloaded-frame share considered stable for a probe.
  double get recoveryOverloadedFraction =>
      config.thresholds.recoveryOverloadedFraction;

  /// Frames required to accept an upward probe.
  int get probeSampleCount => config.probe.probeSampleCount;

  /// Earliest point at which an unhealthy probe may roll back.
  int get rollbackMinimumSamples => config.probe.rollbackMinimumSamples;

  /// P95 load that immediately rejects a sufficiently sampled probe.
  double get rollbackP95Threshold => config.probe.rollbackP95Threshold;

  /// Overloaded-frame share that immediately rejects a probe.
  double get rollbackOverloadedFraction =>
      config.probe.rollbackOverloadedFraction;

  /// Minimum delay between quality transitions.
  Duration get cooldown => config.transition.cooldown;

  /// Relative refresh-rate change that resets accumulated evidence.
  double get refreshRateResetTolerance =>
      config.transition.refreshRateResetTolerance;

  static void _validateSampling(RenderBudgetSampling settings) {
    if (settings.windowCapacity <= 0) {
      throw ArgumentError.value(
        settings.windowCapacity,
        'windowCapacity',
        'must be greater than 0',
      );
    }
    if (settings.minimumSamples <= 0 ||
        settings.minimumSamples > settings.windowCapacity) {
      throw ArgumentError.value(
        settings.minimumSamples,
        'minimumSamples',
        'must be within 1..windowCapacity',
      );
    }
    if (settings.evaluationIntervalFrames <= 0 ||
        settings.evaluationIntervalFrames > settings.windowCapacity) {
      throw ArgumentError.value(
        settings.evaluationIntervalFrames,
        'evaluationIntervalFrames',
        'must be within 1..windowCapacity',
      );
    }
    _requirePositiveFinite(settings.overloadThreshold, 'overloadThreshold');
  }

  static void _validateThresholds(RenderBudgetThresholds settings) {
    _requirePositiveFinite(
      settings.downgradeP95Threshold,
      'downgradeP95Threshold',
    );
    _requireFraction(
      settings.downgradeOverloadedFraction,
      'downgradeOverloadedFraction',
    );
    _requirePositiveFinite(
      settings.recoveryP95Threshold,
      'recoveryP95Threshold',
    );
    if (settings.recoveryP95Threshold >= settings.downgradeP95Threshold) {
      throw ArgumentError.value(
        settings.recoveryP95Threshold,
        'recoveryP95Threshold',
        'must be lower than downgradeP95Threshold',
      );
    }
    _requireFraction(
      settings.recoveryOverloadedFraction,
      'recoveryOverloadedFraction',
    );
    if (settings.recoveryOverloadedFraction >=
        settings.downgradeOverloadedFraction) {
      throw ArgumentError.value(
        settings.recoveryOverloadedFraction,
        'recoveryOverloadedFraction',
        'must be lower than downgradeOverloadedFraction',
      );
    }
  }

  static void _validateProbe(
    RenderBudgetProbe probe,
    RenderBudgetSampling sampling,
    RenderBudgetThresholds thresholds,
  ) {
    if (probe.probeSampleCount < sampling.minimumSamples ||
        probe.probeSampleCount > sampling.windowCapacity) {
      throw ArgumentError.value(
        probe.probeSampleCount,
        'probeSampleCount',
        'must be within minimumSamples..windowCapacity',
      );
    }
    if (probe.rollbackMinimumSamples <= 0 ||
        probe.rollbackMinimumSamples > probe.probeSampleCount) {
      throw ArgumentError.value(
        probe.rollbackMinimumSamples,
        'rollbackMinimumSamples',
        'must be within 1..probeSampleCount',
      );
    }
    _requirePositiveFinite(probe.rollbackP95Threshold, 'rollbackP95Threshold');
    if (probe.rollbackP95Threshold <= thresholds.recoveryP95Threshold) {
      throw ArgumentError.value(
        probe.rollbackP95Threshold,
        'rollbackP95Threshold',
        'must be greater than recoveryP95Threshold',
      );
    }
    _requireFraction(
      probe.rollbackOverloadedFraction,
      'rollbackOverloadedFraction',
    );
    if (probe.rollbackOverloadedFraction <=
        thresholds.recoveryOverloadedFraction) {
      throw ArgumentError.value(
        probe.rollbackOverloadedFraction,
        'rollbackOverloadedFraction',
        'must be greater than recoveryOverloadedFraction',
      );
    }
  }

  static void _validateTransition(RenderBudgetTransitionSettings settings) {
    if (settings.cooldown.isNegative) {
      throw ArgumentError.value(
        settings.cooldown,
        'cooldown',
        'must not be negative',
      );
    }
    if (!settings.refreshRateResetTolerance.isFinite ||
        settings.refreshRateResetTolerance < 0) {
      throw ArgumentError.value(
        settings.refreshRateResetTolerance,
        'refreshRateResetTolerance',
        'must be finite and non-negative',
      );
    }
  }

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
