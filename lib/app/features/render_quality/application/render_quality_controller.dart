import 'package:adaptive_render_budget/adaptive_render_budget.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:flutter_web_portfolio/app/features/render_quality/domain/render_quality.dart';

enum RenderQualityReason {
  startup,
  sustainedPressure,
  sustainedHeadroom,
  refreshRateChanged,
  reducedMotion,
}

@immutable
final class RenderQualityState {
  const RenderQualityState({
    this.quality = RenderQuality.balanced,
    this.reason = RenderQualityReason.startup,
    this.reducedMotion = false,
    this.adaptationCount = 0,
    this.refreshRateHz = 60,
    this.probing = false,
  });

  final RenderQuality quality;
  final RenderQualityReason reason;
  final bool reducedMotion;
  final int adaptationCount;
  final double refreshRateHz;
  final bool probing;

  RenderQualityState copyWith({
    RenderQuality? quality,
    RenderQualityReason? reason,
    bool? reducedMotion,
    int? adaptationCount,
    double? refreshRateHz,
    bool? probing,
  }) => RenderQualityState(
    quality: quality ?? this.quality,
    reason: reason ?? this.reason,
    reducedMotion: reducedMotion ?? this.reducedMotion,
    adaptationCount: adaptationCount ?? this.adaptationCount,
    refreshRateHz: refreshRateHz ?? this.refreshRateHz,
    probing: probing ?? this.probing,
  );
}

/// Maps the reusable render-budget core into portfolio visual tiers.
///
/// Frame load is normalized to the active display refresh rate. The wrapper
/// preserves the app's BLoC boundary and reduced-motion contract while the
/// package owns sustained-load decisions, cooldowns, and upward probes.
final class RenderQualityController extends Cubit<RenderQualityState> {
  factory RenderQualityController({
    RenderFrameTimingSource? timingSource,
    RefreshRateSource? refreshRateSource,
    AdaptiveRenderBudgetPolicy? policy,
    MonotonicClock? clock,
  }) {
    if ((timingSource == null) != (refreshRateSource == null)) {
      throw ArgumentError(
        'timingSource and refreshRateSource must be supplied together.',
      );
    }

    VoidCallback? disposeSources;
    final RenderFrameTimingSource resolvedTiming;
    final RefreshRateSource resolvedRefreshRate;
    if (timingSource == null) {
      final views = PlatformDispatcher.instance.views;
      if (views.isEmpty) {
        throw StateError('A FlutterView is required for render budgeting.');
      }
      final schedulerSource = SchedulerFrameTimingSource();
      final displaySource = DisplayRefreshRateSource(view: views.first);
      resolvedTiming = schedulerSource;
      resolvedRefreshRate = displaySource;
      disposeSources = () {
        schedulerSource.dispose();
        displaySource.dispose();
      };
    } else {
      resolvedTiming = timingSource;
      resolvedRefreshRate = refreshRateSource!;
    }

    final budget = AdaptiveRenderBudgetController(
      timingSource: resolvedTiming,
      refreshRateSource: resolvedRefreshRate,
      policy: policy,
      clock: clock,
      initialLevel: RenderBudgetLevel.reduced,
    );
    return RenderQualityController._(
      budget: budget,
      disposeSources: disposeSources,
    );
  }

  RenderQualityController._({
    required AdaptiveRenderBudgetController budget,
    required this._disposeSources,
  }) : _budget = budget,
       super(
         RenderQualityState(
           quality: _qualityFor(budget.value.level),
           refreshRateHz: budget.value.refreshRateHz,
           probing: budget.value.isProbing,
         ),
       ) {
    _budget.addListener(_handleBudgetChanged);
  }

  final AdaptiveRenderBudgetController _budget;
  final VoidCallback? _disposeSources;
  bool _reducedMotion = false;
  bool _isClosed = false;

  AdaptiveRenderBudgetState get budgetState => _budget.value;
  FrameLoadStatistics get budgetStatistics => _budget.statistics;

  void setReducedMotion(bool reducedMotion) {
    if (_reducedMotion == reducedMotion) return;
    _reducedMotion = reducedMotion;
    if (reducedMotion) {
      _budget.pause();
      return;
    }
    _budget.resume();
  }

  void _handleBudgetChanged() {
    final budget = _budget.value;
    final quality = _reducedMotion
        ? RenderQuality.essential
        : _qualityFor(budget.level);
    final reason = _reducedMotion
        ? RenderQualityReason.reducedMotion
        : _reasonFor(budget.lastTransition.cause);
    final adapted = !_reducedMotion && quality != state.quality;
    emit(
      RenderQualityState(
        quality: quality,
        reason: reason,
        reducedMotion: _reducedMotion,
        adaptationCount: state.adaptationCount + (adapted ? 1 : 0),
        refreshRateHz: budget.refreshRateHz,
        probing: !_reducedMotion && budget.isProbing,
      ),
    );
  }

  @override
  Future<void> close() async {
    if (_isClosed) return;
    _isClosed = true;
    _budget
      ..removeListener(_handleBudgetChanged)
      ..dispose();
    _disposeSources?.call();
    await super.close();
  }

  static RenderQuality _qualityFor(RenderBudgetLevel level) => switch (level) {
    RenderBudgetLevel.minimal => RenderQuality.essential,
    RenderBudgetLevel.reduced => RenderQuality.balanced,
    RenderBudgetLevel.full => RenderQuality.full,
  };

  static RenderQualityReason _reasonFor(RenderBudgetTransitionCause cause) =>
      switch (cause) {
        RenderBudgetTransitionCause.downgraded ||
        RenderBudgetTransitionCause.probeRolledBack ||
        RenderBudgetTransitionCause.ceilingClamped =>
          RenderQualityReason.sustainedPressure,
        RenderBudgetTransitionCause.probeStarted ||
        RenderBudgetTransitionCause.probeAccepted =>
          RenderQualityReason.sustainedHeadroom,
        RenderBudgetTransitionCause.refreshRateChanged =>
          RenderQualityReason.refreshRateChanged,
        _ => RenderQualityReason.startup,
      };
}
