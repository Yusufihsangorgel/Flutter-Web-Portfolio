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
  initialized,
  downgraded,
  probeStarted,
  probeAccepted,
  probeRolledBack,
  ceilingChanged,
  ceilingClamped,
  paused,
  resumed,
  refreshRateChanged,
}

/// One externally visible controller transition.
@immutable
final class RenderBudgetTransition {
  const RenderBudgetTransition({
    required this.cause,
    required this.previousLevel,
    required this.nextLevel,
    required this.at,
  });

  final RenderBudgetTransitionCause cause;
  final RenderBudgetLevel previousLevel;
  final RenderBudgetLevel nextLevel;
  final Duration at;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is RenderBudgetTransition &&
            cause == other.cause &&
            previousLevel == other.previousLevel &&
            nextLevel == other.nextLevel &&
            at == other.at;
  }

  @override
  int get hashCode => Object.hash(cause, previousLevel, nextLevel, at);

  @override
  String toString() {
    return 'RenderBudgetTransition('
        '$cause, $previousLevel -> $nextLevel, at: $at)';
  }
}

/// Immutable state exposed through the controller's [ValueListenable].
///
/// The controller notifies only for policy/configuration transitions, not for
/// every frame sample. Current telemetry remains available separately through
/// `controller.statistics`.
@immutable
final class AdaptiveRenderBudgetState {
  const AdaptiveRenderBudgetState({
    required this.level,
    required this.ceiling,
    required this.phase,
    required this.refreshRateHz,
    required this.cooldownUntil,
    required this.lastTransition,
    required this.revision,
  });

  final RenderBudgetLevel level;
  final RenderBudgetLevel ceiling;
  final AdaptiveRenderBudgetPhase phase;
  final double refreshRateHz;
  final Duration cooldownUntil;
  final RenderBudgetTransition lastTransition;

  /// Monotonically increasing number for externally visible transitions.
  final int revision;

  /// Whether the current quality is an unverified upward probe.
  bool get isProbing => phase == AdaptiveRenderBudgetPhase.probing;

  /// Whether frame collection is currently paused.
  bool get isPaused => phase == AdaptiveRenderBudgetPhase.paused;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is AdaptiveRenderBudgetState &&
            level == other.level &&
            ceiling == other.ceiling &&
            phase == other.phase &&
            refreshRateHz == other.refreshRateHz &&
            cooldownUntil == other.cooldownUntil &&
            lastTransition == other.lastTransition &&
            revision == other.revision;
  }

  @override
  int get hashCode {
    return Object.hash(
      level,
      ceiling,
      phase,
      refreshRateHz,
      cooldownUntil,
      lastTransition,
      revision,
    );
  }

  @override
  String toString() {
    return 'AdaptiveRenderBudgetState('
        'level: $level, ceiling: $ceiling, phase: $phase, '
        'refreshRateHz: $refreshRateHz, revision: $revision)';
  }
}
