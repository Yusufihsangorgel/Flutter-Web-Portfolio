import 'dart:collection';

import 'package:adaptive_render_budget/adaptive_render_budget.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_web_portfolio/app/features/render_quality/application/render_quality_controller.dart';
import 'package:flutter_web_portfolio/app/features/render_quality/domain/render_quality.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _FakeTimingSource timingSource;
  late _FakeRefreshRateSource refreshRateSource;
  late _FakeClock clock;
  late RenderQualityController controller;

  setUp(() {
    timingSource = _FakeTimingSource();
    refreshRateSource = _FakeRefreshRateSource(60);
    clock = _FakeClock();
    controller = RenderQualityController(
      timingSource: timingSource,
      refreshRateSource: refreshRateSource,
      clock: clock,
      policy: _testPolicy,
    );
  });

  tearDown(() async {
    await controller.close();
    refreshRateSource.dispose();
  });

  group('RenderQualityController', () {
    test('starts in the balanced tier for every display', () {
      expect(controller.state.quality, RenderQuality.balanced);
      expect(controller.state.reason, RenderQualityReason.startup);
      expect(controller.state.refreshRateHz, 60);
      expect(controller.state.adaptationCount, 0);
    });

    test('maps sustained normalized load to the essential tier', () {
      timingSource.emitRepeated(_slowFrame, 4);

      expect(controller.state.quality, RenderQuality.essential);
      expect(controller.state.reason, RenderQualityReason.sustainedPressure);
      expect(controller.state.adaptationCount, 1);
    });

    test('maps a verified upward probe to the full tier', () {
      timingSource.emitRepeated(_healthyFrame, 4);

      expect(controller.state.quality, RenderQuality.full);
      expect(controller.state.reason, RenderQualityReason.sustainedHeadroom);
      expect(controller.state.probing, isTrue);

      timingSource.emitRepeated(_healthyFrame, 4);

      expect(controller.state.quality, RenderQuality.full);
      expect(controller.state.probing, isFalse);
      expect(controller.state.adaptationCount, 1);
    });

    test('reduced motion pauses adaptation and restores the verified tier', () {
      controller.setReducedMotion(true);

      expect(controller.state.quality, RenderQuality.essential);
      expect(controller.state.reason, RenderQualityReason.reducedMotion);
      expect(controller.state.reducedMotion, isTrue);
      expect(controller.budgetState.isPaused, isTrue);

      timingSource.emitRepeated(_slowFrame, 8);
      expect(controller.budgetStatistics.sampleCount, 0);

      controller.setReducedMotion(false);

      expect(controller.state.quality, RenderQuality.balanced);
      expect(controller.state.reason, RenderQualityReason.startup);
      expect(controller.state.reducedMotion, isFalse);
      expect(controller.budgetState.isPaused, isFalse);
    });

    test('publishes material display refresh-rate changes', () {
      refreshRateSource.setRefreshRate(120);

      expect(controller.state.refreshRateHz, 120);
      expect(controller.state.reason, RenderQualityReason.refreshRateChanged);
    });

    test('close detaches the package core from its sources', () async {
      expect(timingSource.listenerCount, 1);
      expect(refreshRateSource.listenerCount, 1);

      await controller.close();

      expect(timingSource.listenerCount, 0);
      expect(refreshRateSource.listenerCount, 0);
    });
  });

  group('RenderQuality profiles', () {
    test('reduce decoration without changing content semantics', () {
      expect(RenderQuality.essential.profile.drawAmbientField, isFalse);
      expect(RenderQuality.balanced.profile.drawAmbientField, isTrue);
      expect(RenderQuality.full.profile.drawGrain, isTrue);
      expect(RenderQuality.essential.profile.trackPointer, isFalse);
      expect(RenderQuality.balanced.profile.trackPointer, isFalse);
      expect(RenderQuality.full.profile.trackPointer, isTrue);
    });
  });
}

final _testPolicy = AdaptiveRenderBudgetPolicy(
  windowCapacity: 8,
  minimumSamples: 4,
  evaluationIntervalFrames: 1,
  downgradeP95Threshold: 1.1,
  downgradeOverloadedFraction: 0.5,
  recoveryP95Threshold: 0.7,
  recoveryOverloadedFraction: 0,
  probeSampleCount: 4,
  rollbackMinimumSamples: 2,
  rollbackOverloadedFraction: 0.5,
  cooldown: Duration.zero,
);

final _healthyFrame = RenderFrameTiming(
  buildDuration: const Duration(milliseconds: 5),
  rasterDuration: const Duration(milliseconds: 4),
);

final _slowFrame = RenderFrameTiming(
  buildDuration: const Duration(milliseconds: 20),
  rasterDuration: const Duration(milliseconds: 18),
);

final class _FakeTimingSource implements RenderFrameTimingSource {
  final Set<RenderFrameTimingCallback> _listeners =
      LinkedHashSet<RenderFrameTimingCallback>.identity();

  int get listenerCount => _listeners.length;

  @override
  void addListener(RenderFrameTimingCallback listener) {
    _listeners.add(listener);
  }

  @override
  void removeListener(RenderFrameTimingCallback listener) {
    _listeners.remove(listener);
  }

  void emitRepeated(RenderFrameTiming timing, int count) {
    final batch = List<RenderFrameTiming>.filled(count, timing);
    for (final listener in List<RenderFrameTimingCallback>.of(_listeners)) {
      listener(batch);
    }
  }
}

final class _FakeRefreshRateSource extends ChangeNotifier
    implements RefreshRateSource {
  _FakeRefreshRateSource(this._refreshRateHz);

  double _refreshRateHz;
  int listenerCount = 0;

  @override
  double get refreshRateHz => _refreshRateHz;

  @override
  void addListener(VoidCallback listener) {
    listenerCount += 1;
    super.addListener(listener);
  }

  @override
  void removeListener(VoidCallback listener) {
    listenerCount -= 1;
    super.removeListener(listener);
  }

  void setRefreshRate(double value) {
    _refreshRateHz = value;
    notifyListeners();
  }
}

final class _FakeClock implements MonotonicClock {
  @override
  Duration elapsed = Duration.zero;
}
