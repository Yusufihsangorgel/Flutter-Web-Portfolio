import 'package:flutter/foundation.dart';

/// How frames are retained and how often the window is evaluated.
@immutable
final class RenderBudgetSampling {
  /// Creates sampling settings; omitted fields keep their defaults.
  const RenderBudgetSampling({
    this.windowCapacity = 90,
    this.minimumSamples = 36,
    this.evaluationIntervalFrames = 6,
    this.overloadThreshold = 1,
  });

  /// Number of recent frames retained. Defaults to 90.
  final int windowCapacity;

  /// Frames required before a downgrade or recovery is considered. Defaults
  /// to 36.
  final int minimumSamples;

  /// New frames between policy evaluations. Defaults to 6.
  final int evaluationIntervalFrames;

  /// Normalized load at or above which a frame counts as overloaded. Defaults
  /// to 1, one full display interval.
  final double overloadThreshold;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RenderBudgetSampling &&
          windowCapacity == other.windowCapacity &&
          minimumSamples == other.minimumSamples &&
          evaluationIntervalFrames == other.evaluationIntervalFrames &&
          overloadThreshold == other.overloadThreshold;

  @override
  int get hashCode => Object.hash(
    windowCapacity,
    minimumSamples,
    evaluationIntervalFrames,
    overloadThreshold,
  );
}

/// Load levels that lower the tier and that allow an upward probe.
@immutable
final class RenderBudgetThresholds {
  /// Creates threshold settings; omitted fields keep their defaults.
  const RenderBudgetThresholds({
    this.downgradeP95Threshold = 1.08,
    this.downgradeOverloadedFraction = 0.15,
    this.recoveryP95Threshold = 0.78,
    this.recoveryOverloadedFraction = 0.02,
  });

  /// P95 load that contributes to a downgrade. Defaults to 1.08.
  final double downgradeP95Threshold;

  /// Overloaded-frame share that contributes to a downgrade. Defaults to 0.15.
  final double downgradeOverloadedFraction;

  /// Highest P95 load considered stable enough for an upward probe. Must stay
  /// below [downgradeP95Threshold]. Defaults to 0.78.
  final double recoveryP95Threshold;

  /// Highest overloaded-frame share considered stable for an upward probe.
  /// Must stay below [downgradeOverloadedFraction]. Defaults to 0.02.
  final double recoveryOverloadedFraction;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RenderBudgetThresholds &&
          downgradeP95Threshold == other.downgradeP95Threshold &&
          downgradeOverloadedFraction == other.downgradeOverloadedFraction &&
          recoveryP95Threshold == other.recoveryP95Threshold &&
          recoveryOverloadedFraction == other.recoveryOverloadedFraction;

  @override
  int get hashCode => Object.hash(
    downgradeP95Threshold,
    downgradeOverloadedFraction,
    recoveryP95Threshold,
    recoveryOverloadedFraction,
  );
}

/// When an upward probe is accepted or rolled back.
@immutable
final class RenderBudgetProbe {
  /// Creates probe settings; omitted fields keep their defaults.
  const RenderBudgetProbe({
    this.probeSampleCount = 48,
    this.rollbackMinimumSamples = 12,
    this.rollbackP95Threshold = 1,
    this.rollbackOverloadedFraction = 0.08,
  });

  /// Frames required to accept a probe. Defaults to 48.
  final int probeSampleCount;

  /// Earliest frame count at which an unhealthy probe may roll back. Defaults
  /// to 12.
  final int rollbackMinimumSamples;

  /// P95 load that rejects a sufficiently sampled probe. Defaults to 1.
  final double rollbackP95Threshold;

  /// Overloaded-frame share that rejects a probe. Defaults to 0.08.
  final double rollbackOverloadedFraction;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RenderBudgetProbe &&
          probeSampleCount == other.probeSampleCount &&
          rollbackMinimumSamples == other.rollbackMinimumSamples &&
          rollbackP95Threshold == other.rollbackP95Threshold &&
          rollbackOverloadedFraction == other.rollbackOverloadedFraction;

  @override
  int get hashCode => Object.hash(
    probeSampleCount,
    rollbackMinimumSamples,
    rollbackP95Threshold,
    rollbackOverloadedFraction,
  );
}

/// Timing that separates quality transitions and refresh-rate resets.
@immutable
final class RenderBudgetTransitionSettings {
  /// Creates transition settings; omitted fields keep their defaults.
  const RenderBudgetTransitionSettings({
    this.cooldown = const Duration(seconds: 4),
    this.refreshRateResetTolerance = 0.05,
  });

  /// Minimum delay between quality transitions. Defaults to 4 seconds.
  final Duration cooldown;

  /// Relative refresh-rate change that discards accumulated evidence. Defaults
  /// to 0.05.
  final double refreshRateResetTolerance;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RenderBudgetTransitionSettings &&
          cooldown == other.cooldown &&
          refreshRateResetTolerance == other.refreshRateResetTolerance;

  @override
  int get hashCode => Object.hash(cooldown, refreshRateResetTolerance);
}

/// Immutable settings validated by [AdaptiveRenderBudgetPolicy].
///
/// Each group can be overridden on its own; omitted groups and fields keep the
/// documented defaults.
@immutable
final class AdaptiveRenderBudgetConfig {
  /// Creates settings from named groups.
  const AdaptiveRenderBudgetConfig({
    this.sampling = const RenderBudgetSampling(),
    this.thresholds = const RenderBudgetThresholds(),
    this.probe = const RenderBudgetProbe(),
    this.transition = const RenderBudgetTransitionSettings(),
  });

  /// Frame retention and evaluation cadence.
  final RenderBudgetSampling sampling;

  /// Downgrade and recovery load levels.
  final RenderBudgetThresholds thresholds;

  /// Acceptance and rollback rules for an upward probe.
  final RenderBudgetProbe probe;

  /// Cooldown and refresh-rate reset settings.
  final RenderBudgetTransitionSettings transition;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AdaptiveRenderBudgetConfig &&
          sampling == other.sampling &&
          thresholds == other.thresholds &&
          probe == other.probe &&
          transition == other.transition;

  @override
  int get hashCode => Object.hash(sampling, thresholds, probe, transition);
}
