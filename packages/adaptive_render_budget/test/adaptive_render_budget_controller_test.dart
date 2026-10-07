import 'package:adaptive_render_budget/adaptive_render_budget.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/render_budget_fakes.dart';

void main() {
  group('AdaptiveRenderBudgetController', () {
    late FakeTimingSource timingSource;
    late FakeRefreshRateSource refreshRateSource;
    late FakeClock clock;
    late AdaptiveRenderBudgetController controller;

    setUp(() {
      timingSource = FakeTimingSource();
      refreshRateSource = FakeRefreshRateSource(60);
      clock = FakeClock();
    });

    tearDown(() {
      if (!controller.isDisposed) {
        controller.dispose();
      }
      refreshRateSource.dispose();
    });

    test('downgrades only after sustained load and honors cooldown', () {
      controller = _controller(
        timingSource: timingSource,
        refreshRateSource: refreshRateSource,
        clock: clock,
      );

      timingSource.emitRepeated(_slowFrame, 4);

      expect(controller.value.level, RenderBudgetLevel.reduced);
      expect(
        controller.value.lastTransition.cause,
        RenderBudgetTransitionCause.downgraded,
      );

      timingSource.emitRepeated(_slowFrame, 4);
      expect(controller.value.level, RenderBudgetLevel.reduced);

      clock.advance(const Duration(seconds: 10));
      timingSource.emitRepeated(_slowFrame, 1);
      expect(controller.value.level, RenderBudgetLevel.minimal);
    });

    test('probes upward and accepts a healthy tier', () {
      controller = _controller(
        timingSource: timingSource,
        refreshRateSource: refreshRateSource,
        clock: clock,
        initialLevel: RenderBudgetLevel.reduced,
      );

      timingSource.emitRepeated(_healthyFrame, 4);

      expect(controller.value.level, RenderBudgetLevel.full);
      expect(controller.value.phase, AdaptiveRenderBudgetPhase.probing);
      expect(
        controller.value.lastTransition.cause,
        RenderBudgetTransitionCause.probeStarted,
      );

      timingSource.emitRepeated(_healthyFrame, 4);

      expect(controller.value.level, RenderBudgetLevel.full);
      expect(controller.value.phase, AdaptiveRenderBudgetPhase.steady);
      expect(
        controller.value.lastTransition.cause,
        RenderBudgetTransitionCause.probeAccepted,
      );
    });

    test('rolls an unhealthy probe back to its verified tier', () {
      controller = _controller(
        timingSource: timingSource,
        refreshRateSource: refreshRateSource,
        clock: clock,
        initialLevel: RenderBudgetLevel.reduced,
      );
      timingSource
        ..emitRepeated(_healthyFrame, 4)
        ..emitRepeated(_slowFrame, 2);

      expect(controller.value.level, RenderBudgetLevel.reduced);
      expect(controller.value.phase, AdaptiveRenderBudgetPhase.steady);
      expect(
        controller.value.lastTransition.cause,
        RenderBudgetTransitionCause.probeRolledBack,
      );
    });

    test('rolls an inconclusive completed probe back', () {
      controller = _controller(
        timingSource: timingSource,
        refreshRateSource: refreshRateSource,
        clock: clock,
        initialLevel: RenderBudgetLevel.reduced,
      );
      timingSource
        ..emitRepeated(_healthyFrame, 4)
        ..emitRepeated(_middlingFrame, 4);

      expect(controller.value.level, RenderBudgetLevel.reduced);
      expect(
        controller.value.lastTransition.cause,
        RenderBudgetTransitionCause.probeRolledBack,
      );
    });

    test('clamps a lowered ceiling and probes after a raised ceiling', () {
      controller = _controller(
        timingSource: timingSource,
        refreshRateSource: refreshRateSource,
        clock: clock,
      )..setCeiling(RenderBudgetLevel.reduced);
      expect(controller.value.level, RenderBudgetLevel.reduced);
      expect(controller.value.ceiling, RenderBudgetLevel.reduced);
      expect(
        controller.value.lastTransition.cause,
        RenderBudgetTransitionCause.ceilingClamped,
      );

      controller.setCeiling(RenderBudgetLevel.full);
      expect(controller.value.level, RenderBudgetLevel.reduced);
      expect(controller.value.ceiling, RenderBudgetLevel.full);

      clock.advance(const Duration(seconds: 10));
      timingSource.emitRepeated(_healthyFrame, 4);
      expect(controller.value.level, RenderBudgetLevel.full);
      expect(controller.value.phase, AdaptiveRenderBudgetPhase.probing);
    });

    test('pause rolls back probes, detaches sources, and resume resets', () {
      controller = _controller(
        timingSource: timingSource,
        refreshRateSource: refreshRateSource,
        clock: clock,
        initialLevel: RenderBudgetLevel.reduced,
      );
      timingSource.emitRepeated(_healthyFrame, 4);
      expect(controller.value.phase, AdaptiveRenderBudgetPhase.probing);

      controller.pause();

      expect(controller.value.level, RenderBudgetLevel.reduced);
      expect(controller.value.phase, AdaptiveRenderBudgetPhase.paused);
      expect(timingSource.listenerCount, 0);
      expect(refreshRateSource.listenerCount, 0);
      timingSource.emitRepeated(_slowFrame, 8);
      expect(controller.statistics.sampleCount, 0);

      controller.resume();
      expect(controller.value.phase, AdaptiveRenderBudgetPhase.steady);
      expect(timingSource.listenerCount, 1);
      expect(refreshRateSource.listenerCount, 1);
      expect(controller.statistics.sampleCount, 0);
    });

    test('material refresh-rate changes reset evidence and abort probes', () {
      controller = _controller(
        timingSource: timingSource,
        refreshRateSource: refreshRateSource,
        clock: clock,
        initialLevel: RenderBudgetLevel.reduced,
      );
      timingSource.emitRepeated(_healthyFrame, 4);
      expect(controller.value.phase, AdaptiveRenderBudgetPhase.probing);

      refreshRateSource.setRefreshRate(120);

      expect(controller.value.refreshRateHz, 120);
      expect(controller.value.level, RenderBudgetLevel.reduced);
      expect(controller.value.phase, AdaptiveRenderBudgetPhase.steady);
      expect(controller.statistics.sampleCount, 0);
      expect(
        controller.value.lastTransition.cause,
        RenderBudgetTransitionCause.refreshRateChanged,
      );
    });

    test('does not notify render listeners for telemetry-only frames', () {
      controller = _controller(
        timingSource: timingSource,
        refreshRateSource: refreshRateSource,
        clock: clock,
      );
      var notifications = 0;
      controller.addListener(() => notifications += 1);

      timingSource.emitRepeated(_healthyFrame, 3);
      expect(notifications, 0);

      timingSource.emitRepeated(_slowFrame, 1);
      expect(notifications, 0);
      expect(controller.statistics.sampleCount, 4);
    });

    test('dispose detaches sources and rejects lifecycle mutations', () {
      controller = _controller(
        timingSource: timingSource,
        refreshRateSource: refreshRateSource,
        clock: clock,
      )..dispose();

      expect(timingSource.listenerCount, 0);
      expect(refreshRateSource.listenerCount, 0);
      expect(controller.isDisposed, isTrue);
      expect(controller.pause, throwsStateError);
      expect(controller.resume, throwsStateError);
      expect(
        () => controller.setCeiling(RenderBudgetLevel.minimal),
        throwsStateError,
      );

      controller.dispose();
    });
  });
}

AdaptiveRenderBudgetController _controller({
  required FakeTimingSource timingSource,
  required FakeRefreshRateSource refreshRateSource,
  required FakeClock clock,
  RenderBudgetLevel initialLevel = RenderBudgetLevel.full,
}) => AdaptiveRenderBudgetController(
  timingSource: timingSource,
  refreshRateSource: refreshRateSource,
  clock: clock,
  initialLevel: initialLevel,
  policy: AdaptiveRenderBudgetPolicy(
    config: const AdaptiveRenderBudgetConfig(
      sampling: RenderBudgetSampling(
        windowCapacity: 8,
        minimumSamples: 4,
        evaluationIntervalFrames: 1,
      ),
      thresholds: RenderBudgetThresholds(
        downgradeP95Threshold: 1.1,
        downgradeOverloadedFraction: 0.5,
        recoveryP95Threshold: 0.7,
        recoveryOverloadedFraction: 0,
      ),
      probe: RenderBudgetProbe(
        probeSampleCount: 4,
        rollbackMinimumSamples: 2,
        rollbackOverloadedFraction: 0.5,
      ),
      transition: RenderBudgetTransitionSettings(
        cooldown: Duration(seconds: 10),
      ),
    ),
  ),
);

final _healthyFrame = RenderFrameTiming(
  buildDuration: const Duration(milliseconds: 5),
  rasterDuration: const Duration(milliseconds: 4),
);

final _middlingFrame = RenderFrameTiming(
  buildDuration: const Duration(milliseconds: 14),
  rasterDuration: const Duration(milliseconds: 10),
);

final _slowFrame = RenderFrameTiming(
  buildDuration: const Duration(milliseconds: 20),
  rasterDuration: const Duration(milliseconds: 18),
);
