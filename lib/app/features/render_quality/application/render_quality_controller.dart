import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:flutter_web_portfolio/app/features/render_quality/domain/render_quality.dart';

enum RenderQualityReason {
  startup,
  sustainedPressure,
  sustainedHeadroom,
  reducedMotion,
}

@immutable
final class RenderQualityState {
  const RenderQualityState({
    this.quality = RenderQuality.balanced,
    this.reason = RenderQualityReason.startup,
    this.lastWindow,
    this.pressureWindows = 0,
    this.headroomWindows = 0,
    this.reducedMotion = false,
    this.adaptationCount = 0,
  });

  final RenderQuality quality;
  final RenderQualityReason reason;
  final FrameBudgetWindow? lastWindow;
  final int pressureWindows;
  final int headroomWindows;
  final bool reducedMotion;
  final int adaptationCount;

  RenderQualityState copyWith({
    RenderQuality? quality,
    RenderQualityReason? reason,
    FrameBudgetWindow? lastWindow,
    int? pressureWindows,
    int? headroomWindows,
    bool? reducedMotion,
    int? adaptationCount,
  }) => RenderQualityState(
    quality: quality ?? this.quality,
    reason: reason ?? this.reason,
    lastWindow: lastWindow ?? this.lastWindow,
    pressureWindows: pressureWindows ?? this.pressureWindows,
    headroomWindows: headroomWindows ?? this.headroomWindows,
    reducedMotion: reducedMotion ?? this.reducedMotion,
    adaptationCount: adaptationCount ?? this.adaptationCount,
  );
}

/// Adapts decorative render work from observed frame timings.
///
/// The controller starts in [RenderQuality.balanced] on every device. It does
/// not classify visitors by user agent, screen size, or device model. A tier is
/// lowered only after consecutive over-budget windows and raised only after a
/// longer stable period, preventing visible quality oscillation.
final class RenderQualityController extends Cubit<RenderQualityState> {
  RenderQualityController({
    FrameBudgetSampler? sampler,
    this.overBudgetP95 = const Duration(milliseconds: 24),
    this.headroomP95 = const Duration(milliseconds: 18),
    this.maximumSlowFrameRatio = 0.15,
    this.maximumHeadroomSlowFrameRatio = 0.02,
    this.pressureWindowsBeforeDowngrade = 3,
    this.headroomWindowsBeforeUpgrade = 8,
    this.warmUpFrameCount = 120,
  }) : _sampler = sampler ?? FrameBudgetSampler(),
       _warmUpFramesRemaining = warmUpFrameCount,
       assert(pressureWindowsBeforeDowngrade > 0),
       assert(headroomWindowsBeforeUpgrade > 0),
       assert(warmUpFrameCount >= 0),
       super(const RenderQualityState());

  final FrameBudgetSampler _sampler;
  final Duration overBudgetP95;
  final Duration headroomP95;
  final double maximumSlowFrameRatio;
  final double maximumHeadroomSlowFrameRatio;
  final int pressureWindowsBeforeDowngrade;
  final int headroomWindowsBeforeUpgrade;
  final int warmUpFrameCount;

  bool _monitoring = false;
  int _warmUpFramesRemaining;
  RenderQuality _qualityBeforeReducedMotion = RenderQuality.balanced;
  late final void Function(List<FrameTiming>) _timingsCallback = _handleTimings;

  void startMonitoring() {
    if (_monitoring) return;
    SchedulerBinding.instance.addTimingsCallback(_timingsCallback);
    _monitoring = true;
  }

  void setReducedMotion(bool reducedMotion) {
    if (state.reducedMotion == reducedMotion) return;
    _sampler.reset();
    _warmUpFramesRemaining = warmUpFrameCount;
    if (reducedMotion) {
      _qualityBeforeReducedMotion = state.quality;
      emit(
        state.copyWith(
          quality: RenderQuality.essential,
          reason: RenderQualityReason.reducedMotion,
          pressureWindows: 0,
          headroomWindows: 0,
          reducedMotion: true,
        ),
      );
      return;
    }

    emit(
      state.copyWith(
        quality: _qualityBeforeReducedMotion,
        reason: RenderQualityReason.startup,
        pressureWindows: 0,
        headroomWindows: 0,
        reducedMotion: false,
      ),
    );
  }

  @visibleForTesting
  void recordFrameDurations(Iterable<Duration> durations) {
    for (final duration in durations) {
      if (_warmUpFramesRemaining > 0) {
        _warmUpFramesRemaining--;
        continue;
      }
      final window = _sampler.add(duration);
      if (window != null) _evaluate(window);
    }
  }

  void _handleTimings(List<FrameTiming> timings) {
    recordFrameDurations(timings.map((timing) => timing.totalSpan));
  }

  void _evaluate(FrameBudgetWindow window) {
    if (state.reducedMotion) {
      emit(state.copyWith(lastWindow: window));
      return;
    }

    final isUnderPressure =
        window.p95 > overBudgetP95 ||
        window.slowFrameRatio > maximumSlowFrameRatio;
    final hasHeadroom =
        window.p95 <= headroomP95 &&
        window.slowFrameRatio <= maximumHeadroomSlowFrameRatio;

    if (isUnderPressure) {
      final pressureWindows = state.pressureWindows + 1;
      if (pressureWindows >= pressureWindowsBeforeDowngrade &&
          state.quality != RenderQuality.essential) {
        emit(
          state.copyWith(
            quality: state.quality.lower,
            reason: RenderQualityReason.sustainedPressure,
            lastWindow: window,
            pressureWindows: 0,
            headroomWindows: 0,
            adaptationCount: state.adaptationCount + 1,
          ),
        );
      } else {
        emit(
          state.copyWith(
            lastWindow: window,
            pressureWindows: pressureWindows,
            headroomWindows: 0,
          ),
        );
      }
      return;
    }

    if (hasHeadroom) {
      final headroomWindows = state.headroomWindows + 1;
      if (headroomWindows >= headroomWindowsBeforeUpgrade &&
          state.quality != RenderQuality.cinematic) {
        emit(
          state.copyWith(
            quality: state.quality.higher,
            reason: RenderQualityReason.sustainedHeadroom,
            lastWindow: window,
            pressureWindows: 0,
            headroomWindows: 0,
            adaptationCount: state.adaptationCount + 1,
          ),
        );
      } else {
        emit(
          state.copyWith(
            lastWindow: window,
            pressureWindows: 0,
            headroomWindows: headroomWindows,
          ),
        );
      }
      return;
    }

    emit(
      state.copyWith(
        lastWindow: window,
        pressureWindows: 0,
        headroomWindows: 0,
      ),
    );
  }

  @override
  Future<void> close() async {
    if (_monitoring) {
      SchedulerBinding.instance.removeTimingsCallback(_timingsCallback);
      _monitoring = false;
    }
    await super.close();
  }
}
