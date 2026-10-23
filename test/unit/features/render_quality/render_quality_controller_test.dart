import 'package:adaptive_render_budget/adaptive_render_budget.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_web_portfolio/app/features/render_quality/application/render_quality_controller.dart';
import 'package:flutter_web_portfolio/app/features/render_quality/domain/render_quality.dart';

import '../../../../packages/adaptive_render_budget/test/support/render_budget_fakes.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final fixture = _Fixture();

  setUp(fixture.start);
  tearDown(fixture.close);

  group('RenderQualityController', () {
    _startupTests(fixture);
    _adaptationTests(fixture);
    _reducedMotionAndCloseTests(fixture);
  });
}

void _startupTests(_Fixture fixture) {
  test('default wiring observes display metrics and closes cleanly', () async {
    final binding = TestWidgetsFlutterBinding.instance;
    final display = binding.platformDispatcher.views.first.display;
    addTearDown(display.resetRefreshRate);
    display.refreshRate = 120;
    final defaultController = RenderQualityController();

    expect(defaultController.state.refreshRateHz, 120);
    display.refreshRate = 90;
    expect(defaultController.state.refreshRateHz, 90);
    await defaultController.close();
    display.refreshRate = 60;
    expect(defaultController.state.refreshRateHz, 90);
  });

  test('starts in the balanced tier for every display', () {
    final controller = fixture.controller;
    expect(controller.state.quality, RenderQuality.balanced);
    expect(controller.state.reason, RenderQualityReason.startup);
    expect(controller.state.refreshRateHz, 60);
    expect(controller.state.adaptationCount, 0);
  });
}

void _adaptationTests(_Fixture fixture) {
  test('maps sustained normalized load to the essential tier', () {
    final controller = fixture.controller;
    fixture.timingSource.emitRepeated(_slowFrame, 4);

    expect(controller.state.quality, RenderQuality.essential);
    expect(controller.state.reason, RenderQualityReason.sustainedPressure);
    expect(controller.state.adaptationCount, 1);
  });

  test('maps a verified upward probe to the full tier', () {
    final controller = fixture.controller;
    fixture.timingSource.emitRepeated(_healthyFrame, 4);

    expect(controller.state.quality, RenderQuality.full);
    expect(controller.state.reason, RenderQualityReason.sustainedHeadroom);
    expect(controller.state.probing, isTrue);

    fixture.timingSource.emitRepeated(_healthyFrame, 4);

    expect(controller.state.quality, RenderQuality.full);
    expect(controller.state.probing, isFalse);
    expect(controller.state.adaptationCount, 1);
  });
}

void _reducedMotionAndCloseTests(_Fixture fixture) {
  test('reduced motion pauses adaptation and restores the verified tier', () {
    final controller = fixture.controller..setReducedMotion(true);

    expect(controller.state.quality, RenderQuality.essential);
    expect(controller.state.reason, RenderQualityReason.reducedMotion);
    expect(controller.state.reducedMotion, isTrue);
    expect(controller.budgetState.isPaused, isTrue);

    fixture.timingSource.emitRepeated(_slowFrame, 8);
    expect(controller.budgetStatistics.sampleCount, 0);

    controller.setReducedMotion(false);

    expect(controller.state.quality, RenderQuality.balanced);
    expect(controller.state.reason, RenderQualityReason.startup);
    expect(controller.state.reducedMotion, isFalse);
    expect(controller.budgetState.isPaused, isFalse);
  });

  test('publishes material display refresh-rate changes', () {
    final controller = fixture.controller;
    fixture.refreshRateSource.setRefreshRate(120);

    expect(controller.state.refreshRateHz, 120);
    expect(controller.state.reason, RenderQualityReason.refreshRateChanged);
  });

  test('close detaches the package core from its sources', () async {
    expect(fixture.timingSource.listenerCount, 1);
    expect(fixture.refreshRateSource.listenerCount, 1);

    await fixture.controller.close();

    expect(fixture.timingSource.listenerCount, 0);
    expect(fixture.refreshRateSource.listenerCount, 0);
  });
}

final class _Fixture {
  late FakeTimingSource timingSource;
  late FakeRefreshRateSource refreshRateSource;
  late RenderQualityController controller;

  void start() {
    timingSource = FakeTimingSource();
    refreshRateSource = FakeRefreshRateSource(60);
    controller = RenderQualityController(
      timingSource: timingSource,
      refreshRateSource: refreshRateSource,
      clock: FakeClock(),
      policy: _testPolicy,
    );
  }

  Future<void> close() async {
    await controller.close();
    refreshRateSource.dispose();
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
    transition: RenderBudgetTransitionSettings(cooldown: Duration.zero),
  ),
);

final _healthyFrame = RenderFrameTiming(
  buildDuration: const Duration(milliseconds: 5),
  rasterDuration: const Duration(milliseconds: 4),
);

final _slowFrame = RenderFrameTiming(
  buildDuration: const Duration(milliseconds: 20),
  rasterDuration: const Duration(milliseconds: 18),
);
