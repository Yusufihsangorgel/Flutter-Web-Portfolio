import 'dart:math' as math;

import 'package:flutter/foundation.dart';

import 'adaptive_render_budget_policy.dart';
import 'adaptive_render_budget_state.dart';
import 'frame_load_window.dart';
import 'frame_timing_sample.dart';
import 'monotonic_clock.dart';
import 'sources.dart';

/// Adapts an application's rendering tier to sustained frame pressure.
///
/// The controller is deliberately independent of BLoC and widget lifecycle
/// APIs. Rendering code can consume it with [ValueListenableBuilder], while
/// tests can inject deterministic timing, refresh-rate, and clock sources.
final class AdaptiveRenderBudgetController extends ChangeNotifier
    implements ValueListenable<AdaptiveRenderBudgetState> {
  factory AdaptiveRenderBudgetController({
    required RenderFrameTimingSource timingSource,
    required RefreshRateSource refreshRateSource,
    AdaptiveRenderBudgetPolicy? policy,
    RenderBudgetLevel initialLevel = RenderBudgetLevel.full,
    RenderBudgetLevel ceiling = RenderBudgetLevel.full,
    MonotonicClock? clock,
  }) {
    final resolvedPolicy = policy ?? AdaptiveRenderBudgetPolicy();
    return AdaptiveRenderBudgetController._(
      timingSource: timingSource,
      refreshRateSource: refreshRateSource,
      policy: resolvedPolicy,
      initialLevel: initialLevel,
      ceiling: ceiling,
      clock: clock ?? StopwatchMonotonicClock(),
    );
  }

  AdaptiveRenderBudgetController._({
    required this._timingSource,
    required this._refreshRateSource,
    required this._policy,
    required RenderBudgetLevel initialLevel,
    required RenderBudgetLevel ceiling,
    required this._clock,
  }) : _window = FrameLoadWindow(capacity: _policy.windowCapacity) {
    _validateRefreshRate(_refreshRateSource.refreshRateHz);
    final now = _clock.elapsed;
    final safeInitialLevel = _lowerOf(initialLevel, ceiling);
    _value = AdaptiveRenderBudgetState(
      level: safeInitialLevel,
      ceiling: ceiling,
      phase: AdaptiveRenderBudgetPhase.steady,
      refreshRateHz: _refreshRateSource.refreshRateHz,
      cooldownUntil: now,
      lastTransition: RenderBudgetTransition(
        cause: RenderBudgetTransitionCause.initialized,
        previousLevel: safeInitialLevel,
        nextLevel: safeInitialLevel,
        at: now,
      ),
      revision: 0,
    );
    _attachSources();
  }

  final RenderFrameTimingSource _timingSource;
  final RefreshRateSource _refreshRateSource;
  final AdaptiveRenderBudgetPolicy _policy;
  final MonotonicClock _clock;
  final FrameLoadWindow _window;

  late AdaptiveRenderBudgetState _value;
  late final RenderFrameTimingCallback _timingsListener = _handleTimings;
  late final VoidCallback _refreshRateListener = _handleRefreshRateChanged;
  RenderBudgetLevel? _probeFallbackLevel;
  int _framesSinceEvaluation = 0;
  bool _sourcesAttached = false;
  bool _isDisposed = false;

  @override
  AdaptiveRenderBudgetState get value => _value;

  /// The policy used for all decisions.
  AdaptiveRenderBudgetPolicy get policy => _policy;

  /// Current rolling telemetry without frame-by-frame notifications.
  FrameLoadStatistics get statistics {
    return _window.statistics(overloadThreshold: _policy.overloadThreshold);
  }

  /// Whether [dispose] has permanently detached the controller.
  bool get isDisposed => _isDisposed;

  /// Changes the maximum render tier.
  ///
  /// Lowering the ceiling clamps immediately. Raising it keeps the current
  /// verified tier; the next tier is entered only through a successful probe.
  void setCeiling(RenderBudgetLevel ceiling) {
    _checkNotDisposed();
    if (ceiling == _value.ceiling) {
      return;
    }

    final now = _clock.elapsed;
    final clampedLevel = _lowerOf(_value.level, ceiling);
    final didClamp = clampedLevel != _value.level;
    if (didClamp) {
      _probeFallbackLevel = null;
      _resetEvidence();
    }

    _publish(
      cause: didClamp
          ? RenderBudgetTransitionCause.ceilingClamped
          : RenderBudgetTransitionCause.ceilingChanged,
      level: clampedLevel,
      ceiling: ceiling,
      phase: didClamp && !_value.isPaused
          ? AdaptiveRenderBudgetPhase.steady
          : _value.phase,
      cooldownUntil: didClamp ? now + _policy.cooldown : _value.cooldownUntil,
      at: now,
    );
  }

  /// Detaches timing and refresh-rate listeners while holding a safe tier.
  ///
  /// An in-flight upward probe is rolled back before pausing.
  void pause() {
    _checkNotDisposed();
    if (_value.isPaused) {
      return;
    }

    final now = _clock.elapsed;
    final heldLevel = _probeFallbackLevel ?? _value.level;
    _probeFallbackLevel = null;
    _detachSources();
    _resetEvidence();
    _publish(
      cause: RenderBudgetTransitionCause.paused,
      level: heldLevel,
      phase: AdaptiveRenderBudgetPhase.paused,
      cooldownUntil: now + _policy.cooldown,
      at: now,
    );
  }

  /// Reattaches sources and begins with an empty evidence window.
  void resume() {
    _checkNotDisposed();
    if (!_value.isPaused) {
      return;
    }

    final now = _clock.elapsed;
    final refreshRateHz = _validRefreshRateOr(
      _refreshRateSource.refreshRateHz,
      fallback: _value.refreshRateHz,
    );
    _resetEvidence();
    _attachSources();
    _publish(
      cause: RenderBudgetTransitionCause.resumed,
      level: _value.level,
      phase: AdaptiveRenderBudgetPhase.steady,
      refreshRateHz: refreshRateHz,
      cooldownUntil: now + _policy.cooldown,
      at: now,
    );
  }

  @override
  void dispose() {
    if (_isDisposed) {
      return;
    }
    _detachSources();
    _window.clear();
    _isDisposed = true;
    super.dispose();
  }

  void _attachSources() {
    if (_sourcesAttached) {
      return;
    }
    _timingSource.addListener(_timingsListener);
    try {
      _refreshRateSource.addListener(_refreshRateListener);
    } on Object {
      _timingSource.removeListener(_timingsListener);
      rethrow;
    }
    _sourcesAttached = true;
  }

  void _detachSources() {
    if (!_sourcesAttached) {
      return;
    }
    _timingSource.removeListener(_timingsListener);
    _refreshRateSource.removeListener(_refreshRateListener);
    _sourcesAttached = false;
  }

  void _handleTimings(List<RenderFrameTiming> timings) {
    if (_isDisposed || _value.isPaused || timings.isEmpty) {
      return;
    }

    for (final timing in timings) {
      _window.add(timing, refreshRateHz: _value.refreshRateHz);
      _framesSinceEvaluation += 1;
    }
    if (_framesSinceEvaluation < _policy.evaluationIntervalFrames) {
      return;
    }
    _framesSinceEvaluation = 0;
    _evaluatePolicy();
  }

  void _evaluatePolicy() {
    final stats = statistics;
    if (_value.isProbing) {
      _evaluateProbe(stats);
      return;
    }
    if (stats.sampleCount < _policy.minimumSamples) {
      return;
    }

    final now = _clock.elapsed;
    if (now < _value.cooldownUntil) {
      return;
    }

    final shouldDowngrade =
        stats.p95 >= _policy.downgradeP95Threshold &&
        stats.overloadedFraction >= _policy.downgradeOverloadedFraction;
    if (shouldDowngrade) {
      if (_value.level != RenderBudgetLevel.minimal) {
        final next = RenderBudgetLevel.values[_value.level.index - 1];
        _resetEvidence();
        _publish(
          cause: RenderBudgetTransitionCause.downgraded,
          level: next,
          phase: AdaptiveRenderBudgetPhase.steady,
          cooldownUntil: now + _policy.cooldown,
          at: now,
        );
      }
      return;
    }

    final isRecovered =
        stats.p95 <= _policy.recoveryP95Threshold &&
        stats.overloadedFraction <= _policy.recoveryOverloadedFraction;
    if (isRecovered && _value.level.index < _value.ceiling.index) {
      final next = RenderBudgetLevel.values[_value.level.index + 1];
      _probeFallbackLevel = _value.level;
      _resetEvidence();
      _publish(
        cause: RenderBudgetTransitionCause.probeStarted,
        level: next,
        phase: AdaptiveRenderBudgetPhase.probing,
        cooldownUntil: now,
        at: now,
      );
    }
  }

  void _evaluateProbe(FrameLoadStatistics stats) {
    if (stats.sampleCount < _policy.rollbackMinimumSamples) {
      return;
    }

    final isUnhealthy =
        stats.p95 >= _policy.rollbackP95Threshold ||
        stats.overloadedFraction >= _policy.rollbackOverloadedFraction;
    if (isUnhealthy) {
      _rollbackProbe();
      return;
    }
    if (stats.sampleCount < _policy.probeSampleCount) {
      return;
    }

    final isRecovered =
        stats.p95 <= _policy.recoveryP95Threshold &&
        stats.overloadedFraction <= _policy.recoveryOverloadedFraction;
    if (!isRecovered) {
      _rollbackProbe();
      return;
    }

    final now = _clock.elapsed;
    _probeFallbackLevel = null;
    _resetEvidence();
    _publish(
      cause: RenderBudgetTransitionCause.probeAccepted,
      level: _value.level,
      phase: AdaptiveRenderBudgetPhase.steady,
      cooldownUntil: now + _policy.cooldown,
      at: now,
    );
  }

  void _rollbackProbe() {
    final fallback = _probeFallbackLevel;
    if (fallback == null) {
      throw StateError('A probing state must have a fallback level.');
    }
    final now = _clock.elapsed;
    _probeFallbackLevel = null;
    _resetEvidence();
    _publish(
      cause: RenderBudgetTransitionCause.probeRolledBack,
      level: fallback,
      phase: AdaptiveRenderBudgetPhase.steady,
      cooldownUntil: now + _policy.cooldown,
      at: now,
    );
  }

  void _handleRefreshRateChanged() {
    if (_isDisposed || _value.isPaused) {
      return;
    }
    final next = _refreshRateSource.refreshRateHz;
    if (!next.isFinite || next <= 0 || next == _value.refreshRateHz) {
      return;
    }

    final now = _clock.elapsed;
    final relativeChange =
        (next - _value.refreshRateHz).abs() / _value.refreshRateHz;
    final isMaterial = relativeChange >= _policy.refreshRateResetTolerance;
    var level = _value.level;
    var phase = _value.phase;
    var cooldownUntil = _value.cooldownUntil;
    if (isMaterial) {
      level = _probeFallbackLevel ?? level;
      _probeFallbackLevel = null;
      phase = AdaptiveRenderBudgetPhase.steady;
      cooldownUntil = now + _policy.cooldown;
      _resetEvidence();
    }

    _publish(
      cause: RenderBudgetTransitionCause.refreshRateChanged,
      level: level,
      phase: phase,
      refreshRateHz: next,
      cooldownUntil: cooldownUntil,
      at: now,
    );
  }

  void _resetEvidence() {
    _window.clear();
    _framesSinceEvaluation = 0;
  }

  void _publish({
    required RenderBudgetTransitionCause cause,
    required RenderBudgetLevel level,
    required AdaptiveRenderBudgetPhase phase,
    required Duration cooldownUntil,
    required Duration at,
    RenderBudgetLevel? ceiling,
    double? refreshRateHz,
  }) {
    final previous = _value;
    _value = AdaptiveRenderBudgetState(
      level: level,
      ceiling: ceiling ?? previous.ceiling,
      phase: phase,
      refreshRateHz: refreshRateHz ?? previous.refreshRateHz,
      cooldownUntil: cooldownUntil,
      lastTransition: RenderBudgetTransition(
        cause: cause,
        previousLevel: previous.level,
        nextLevel: level,
        at: at,
      ),
      revision: previous.revision + 1,
    );
    notifyListeners();
  }

  void _checkNotDisposed() {
    if (_isDisposed) {
      throw StateError('AdaptiveRenderBudgetController is disposed.');
    }
  }

  static RenderBudgetLevel _lowerOf(
    RenderBudgetLevel first,
    RenderBudgetLevel second,
  ) {
    return RenderBudgetLevel.values[math.min(first.index, second.index)];
  }

  static double _validRefreshRateOr(double value, {required double fallback}) {
    return value.isFinite && value > 0 ? value : fallback;
  }

  static void _validateRefreshRate(double refreshRateHz) {
    if (!refreshRateHz.isFinite || refreshRateHz <= 0) {
      throw ArgumentError.value(
        refreshRateHz,
        'refreshRateHz',
        'must be finite and greater than 0',
      );
    }
  }
}
