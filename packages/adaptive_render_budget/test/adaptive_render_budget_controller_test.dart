import 'package:adaptive_render_budget/adaptive_render_budget.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/render_budget_fakes.dart';

void main() {
  group('AdaptiveRenderBudgetController', () {
    final fixture = _Fixture();

    setUp(fixture.reset);
    tearDown(fixture.dispose);

    _downgradeAndProbeTests(fixture);
    _rollbackTests(fixture);
    _ceilingAndPauseTests(fixture);
    _sourceAndDisposalTests(fixture);
  });
}

void _downgradeAndProbeTests(_Fixture fixture) {
  test('downgrades only after sustained load and honors cooldown', () {
    final controller = fixture.start();

    fixture.timingSource.emitRepeated(_slowFrame, 4);

    expect(controller.value.level, RenderBudgetLevel.reduced);
    expect(
      controller.value.lastTransition.cause,
      RenderBudgetTransitionCause.downgraded,
    );

    fixture.timingSource.emitRepeated(_slowFrame, 4);
    expect(controller.value.level, RenderBudgetLevel.reduced);

    fixture.clock.advance(const Duration(seconds: 10));
    fixture.timingSource.emitRepeated(_slowFrame, 1);
    expect(controller.value.level, RenderBudgetLevel.minimal);
  });

  test('probes upward and accepts a healthy tier', () {
    final controller = fixture.start(initialLevel: RenderBudgetLevel.reduced);

    fixture.timingSource.emitRepeated(_healthyFrame, 4);

    expect(controller.value.level, RenderBudgetLevel.full);
    expect(controller.value.phase, AdaptiveRenderBudgetPhase.probing);
    expect(
      controller.value.lastTransition.cause,
      RenderBudgetTransitionCause.probeStarted,
    );

    fixture.timingSource.emitRepeated(_healthyFrame, 4);

    expect(controller.value.level, RenderBudgetLevel.full);
    expect(controller.value.phase, AdaptiveRenderBudgetPhase.steady);
    expect(
      controller.value.lastTransition.cause,
      RenderBudgetTransitionCause.probeAccepted,
    );
  });
}

void _rollbackTests(_Fixture fixture) {
  test('rolls an unhealthy probe back to its verified tier', () {
    final controller = fixture.start(initialLevel: RenderBudgetLevel.reduced);
    fixture.timingSource
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
    final controller = fixture.start(initialLevel: RenderBudgetLevel.reduced);
    fixture.timingSource
      ..emitRepeated(_healthyFrame, 4)
      ..emitRepeated(_middlingFrame, 4);

    expect(controller.value.level, RenderBudgetLevel.reduced);
    expect(
      controller.value.lastTransition.cause,
      RenderBudgetTransitionCause.probeRolledBack,
    );
  });
}

void _ceilingAndPauseTests(_Fixture fixture) {
  test('clamps a lowered ceiling and probes after a raised ceiling', () {
    final controller = fixture.start()..setCeiling(RenderBudgetLevel.reduced);
    expect(controller.value.level, RenderBudgetLevel.reduced);
    expect(controller.value.ceiling, RenderBudgetLevel.reduced);
    expect(
      controller.value.lastTransition.cause,
      RenderBudgetTransitionCause.ceilingClamped,
    );

    controller.setCeiling(RenderBudgetLevel.full);
    expect(controller.value.level, RenderBudgetLevel.reduced);
    expect(controller.value.ceiling, RenderBudgetLevel.full);

    fixture.clock.advance(const Duration(seconds: 10));
    fixture.timingSource.emitRepeated(_healthyFrame, 4);
    expect(controller.value.level, RenderBudgetLevel.full);
    expect(controller.value.phase, AdaptiveRenderBudgetPhase.probing);
  });

  test('pause rolls back probes, detaches sources, and resume resets', () {
    final controller = fixture.start(initialLevel: RenderBudgetLevel.reduced);
    fixture.timingSource.emitRepeated(_healthyFrame, 4);
    expect(controller.value.phase, AdaptiveRenderBudgetPhase.probing);

    controller.pause();

    expect(controller.value.level, RenderBudgetLevel.reduced);
    expect(controller.value.phase, AdaptiveRenderBudgetPhase.paused);
    expect(fixture.timingSource.listenerCount, 0);
    expect(fixture.refreshRateSource.listenerCount, 0);
    fixture.timingSource.emitRepeated(_slowFrame, 8);
    expect(controller.statistics.sampleCount, 0);

    controller.resume();
    expect(controller.value.phase, AdaptiveRenderBudgetPhase.steady);
    expect(fixture.timingSource.listenerCount, 1);
    expect(fixture.refreshRateSource.listenerCount, 1);
    expect(controller.statistics.sampleCount, 0);
  });
}

void _sourceAndDisposalTests(_Fixture fixture) {
  test('material refresh-rate changes reset evidence and abort probes', () {
    final controller = fixture.start(initialLevel: RenderBudgetLevel.reduced);
    fixture.timingSource.emitRepeated(_healthyFrame, 4);
    expect(controller.value.phase, AdaptiveRenderBudgetPhase.probing);

    fixture.refreshRateSource.setRefreshRate(120);

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
    final controller = fixture.start();
    var notifications = 0;
    controller.addListener(() => notifications += 1);

    fixture.timingSource.emitRepeated(_healthyFrame, 3);
    expect(notifications, 0);

    fixture.timingSource.emitRepeated(_slowFrame, 1);
    expect(notifications, 0);
    expect(controller.statistics.sampleCount, 4);
  });

  test('dispose detaches sources and rejects lifecycle mutations', () {
    final controller = fixture.start()..dispose();

    expect(fixture.timingSource.listenerCount, 0);
    expect(fixture.refreshRateSource.listenerCount, 0);
    expect(controller.isDisposed, isTrue);
    expect(controller.pause, throwsStateError);
    expect(controller.resume, throwsStateError);
    expect(
      () => controller.setCeiling(RenderBudgetLevel.minimal),
      throwsStateError,
    );

    controller.dispose();
  });
}

final class _Fixture {
  late FakeTimingSource timingSource;
  late FakeRefreshRateSource refreshRateSource;
  late FakeClock clock;
  late AdaptiveRenderBudgetController controller;

  void reset() {
    timingSource = FakeTimingSource();
    refreshRateSource = FakeRefreshRateSource(60);
    clock = FakeClock();
  }

  void dispose() {
    if (!controller.isDisposed) {
      controller.dispose();
    }
    refreshRateSource.dispose();
  }

  AdaptiveRenderBudgetController start({
    RenderBudgetLevel initialLevel = RenderBudgetLevel.full,
  }) {
    controller = AdaptiveRenderBudgetController(
      timingSource: timingSource,
      refreshRateSource: refreshRateSource,
      clock: clock,
      policy: _testPolicy,
      initialLevel: initialLevel,
    );
    return controller;
  }
}

final _testPolicy = AdaptiveRenderBudgetPolicy(
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
    transition: RenderBudgetTransitionSettings(cooldown: Duration(seconds: 10)),
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
