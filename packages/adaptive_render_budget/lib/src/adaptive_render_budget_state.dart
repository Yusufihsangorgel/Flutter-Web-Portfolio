import 'package:flutter/foundation.dart';

/// Ordered visual-complexity tiers controlled by the render budget.
enum RenderBudgetLevel {
  /// Essential visuals only.
  minimal,

  /// Reduced effects while preserving the core composition.
  reduced,

  /// Full intended visual treatment.
  full,
}

/// Current policy activity.
enum AdaptiveRenderBudgetPhase {
  /// Collecting evidence at a verified quality level.
  steady,

  /// Temporarily testing the next quality level.
  probing,

  /// Timing collection is detached and quality is held.
  paused,
}

/// Why the controller last changed externally visible state.
enum RenderBudgetTransitionCause {
  /// The initial tier was established.
  initialized,

  /// Sustained frame pressure lowered the tier.
  downgraded,

  /// A higher tier is being tested.
  probeStarted,

  /// The higher tier passed its probe.
  probeAccepted,

  /// The higher tier failed its probe.
  probeRolledBack,

  /// The maximum tier increased.
  ceilingChanged,

  /// The maximum tier forced a lower tier.
  ceilingClamped,

  /// Frame collection stopped.
  paused,

  /// Frame collection restarted.
  resumed,

  /// The reported refresh rate changed.
  refreshRateChanged,
}

/// One externally visible controller transition.
@immutable
final class RenderBudgetTransition {
  /// Describes one change in level at a monotonic time.
  const RenderBudgetTransition({
    required this.cause,
    required this.previousLevel,
    required this.nextLevel,
    required this.at,
  });

  /// Why this transition occurred.
  final RenderBudgetTransitionCause cause;

  /// The tier before the transition.
  final RenderBudgetLevel previousLevel;

  /// The tier after the transition.
  final RenderBudgetLevel nextLevel;

  /// Monotonic time of the transition.
  final Duration at;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RenderBudgetTransition &&
          cause == other.cause &&
          previousLevel == other.previousLevel &&
          nextLevel == other.nextLevel &&
          at == other.at;

  @override
  int get hashCode => Object.hash(cause, previousLevel, nextLevel, at);

  @override
  String toString() =>
      'RenderBudgetTransition('
      '$cause, $previousLevel -> $nextLevel, at: $at)';
}

/// Immutable state exposed through the controller's [ValueListenable].
///
/// The controller notifies only for policy/configuration transitions, not for
/// every frame sample. Current telemetry remains available separately through
/// `controller.statistics`.
@immutable
final class AdaptiveRenderBudgetState {
  /// Describes the current tier, phase, ceiling, and last transition.
  const AdaptiveRenderBudgetState({
    required this.level,
    required this.ceiling,
    required this.phase,
    required this.refreshRateHz,
    required this.cooldownUntil,
    required this.lastTransition,
    required this.revision,
  });

  /// Current rendering tier.
  final RenderBudgetLevel level;

  /// Highest allowed rendering tier.
  final RenderBudgetLevel ceiling;

  /// Current steady, probing, or paused phase.
  final AdaptiveRenderBudgetPhase phase;

  /// Rate currently used to normalize frame timings.
  final double refreshRateHz;

  /// Monotonic time before which tier changes are deferred.
  final Duration cooldownUntil;

  /// Most recent externally visible transition.
  final RenderBudgetTransition lastTransition;

  /// Monotonically increasing number for externally visible transitions.
  final int revision;

  /// Whether the current quality is an unverified upward probe.
  bool get isProbing => phase == AdaptiveRenderBudgetPhase.probing;

  /// Whether frame collection is currently paused.
  bool get isPaused => phase == AdaptiveRenderBudgetPhase.paused;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AdaptiveRenderBudgetState &&
          level == other.level &&
          ceiling == other.ceiling &&
          phase == other.phase &&
          refreshRateHz == other.refreshRateHz &&
          cooldownUntil == other.cooldownUntil &&
          lastTransition == other.lastTransition &&
          revision == other.revision;

  @override
  int get hashCode => Object.hash(
    level,
    ceiling,
    phase,
    refreshRateHz,
    cooldownUntil,
    lastTransition,
    revision,
  );

  @override
  String toString() =>
      'AdaptiveRenderBudgetState('
      'level: $level, ceiling: $ceiling, phase: $phase, '
      'refreshRateHz: $refreshRateHz, revision: $revision)';
}
