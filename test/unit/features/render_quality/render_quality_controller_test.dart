import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_web_portfolio/app/features/render_quality/application/render_quality_controller.dart';
import 'package:flutter_web_portfolio/app/features/render_quality/domain/render_quality.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  RenderQualityController buildController({
    int downgradeWindows = 2,
    int upgradeWindows = 3,
    int warmUpFrames = 0,
  }) => RenderQualityController(
    sampler: FrameBudgetSampler(windowSize: 4),
    pressureWindowsBeforeDowngrade: downgradeWindows,
    headroomWindowsBeforeUpgrade: upgradeWindows,
    warmUpFrameCount: warmUpFrames,
  );

  void recordWindow(RenderQualityController controller, Duration duration) {
    controller.recordFrameDurations(List.filled(4, duration));
  }

  group('FrameBudgetSampler', () {
    test('reports deterministic p95, maximum, and slow-frame ratio', () {
      final sampler = FrameBudgetSampler(windowSize: 4);

      expect(sampler.add(const Duration(milliseconds: 10)), isNull);
      expect(sampler.add(const Duration(milliseconds: 18)), isNull);
      expect(sampler.add(const Duration(milliseconds: 24)), isNull);
      final window = sampler.add(const Duration(milliseconds: 40));

      expect(window, isNotNull);
      expect(window!.sampleCount, 4);
      expect(window.p95, const Duration(milliseconds: 40));
      expect(window.maximum, const Duration(milliseconds: 40));
      expect(window.slowFrameRatio, 0.5);
    });
  });

  group('RenderQualityController', () {
    test('starts balanced for every device', () async {
      final controller = buildController();
      addTearDown(controller.close);

      expect(controller.state.quality, RenderQuality.balanced);
      expect(controller.state.reason, RenderQualityReason.startup);
      expect(controller.state.adaptationCount, 0);
    });

    test('downgrades only after consecutive pressure windows', () async {
      final controller = buildController();
      addTearDown(controller.close);

      recordWindow(controller, const Duration(milliseconds: 30));
      expect(controller.state.quality, RenderQuality.balanced);
      expect(controller.state.pressureWindows, 1);

      recordWindow(controller, const Duration(milliseconds: 30));
      expect(controller.state.quality, RenderQuality.essential);
      expect(controller.state.reason, RenderQualityReason.sustainedPressure);
      expect(controller.state.adaptationCount, 1);
    });

    test('upgrades only after a longer stable headroom streak', () async {
      final controller = buildController();
      addTearDown(controller.close);

      for (var index = 0; index < 2; index++) {
        recordWindow(controller, const Duration(milliseconds: 12));
      }
      expect(controller.state.quality, RenderQuality.balanced);

      recordWindow(controller, const Duration(milliseconds: 12));
      expect(controller.state.quality, RenderQuality.cinematic);
      expect(controller.state.reason, RenderQualityReason.sustainedHeadroom);
    });

    test('neutral timing resets pressure hysteresis', () async {
      final controller = buildController();
      addTearDown(controller.close);

      recordWindow(controller, const Duration(milliseconds: 30));
      expect(controller.state.pressureWindows, 1);

      recordWindow(controller, const Duration(milliseconds: 19));
      expect(controller.state.pressureWindows, 0);
      expect(controller.state.headroomWindows, 0);

      recordWindow(controller, const Duration(milliseconds: 30));
      expect(controller.state.quality, RenderQuality.balanced);
      expect(controller.state.pressureWindows, 1);
    });

    test('reduced motion is an absolute quality override', () async {
      final controller = buildController(upgradeWindows: 1);
      addTearDown(controller.close);

      recordWindow(controller, const Duration(milliseconds: 12));
      expect(controller.state.quality, RenderQuality.cinematic);

      controller.setReducedMotion(true);
      expect(controller.state.quality, RenderQuality.essential);
      expect(controller.state.reason, RenderQualityReason.reducedMotion);
      expect(controller.state.reducedMotion, isTrue);

      controller.setReducedMotion(false);
      expect(controller.state.quality, RenderQuality.cinematic);
      expect(controller.state.reason, RenderQualityReason.startup);
      expect(controller.state.reducedMotion, isFalse);
    });

    test('ignores warm-up frames before evaluating a window', () async {
      final controller = buildController(downgradeWindows: 1, warmUpFrames: 4);
      addTearDown(controller.close);

      recordWindow(controller, const Duration(milliseconds: 30));
      expect(controller.state.lastWindow, isNull);
      expect(controller.state.quality, RenderQuality.balanced);

      recordWindow(controller, const Duration(milliseconds: 30));
      expect(controller.state.quality, RenderQuality.essential);
    });
  });

  group('RenderQuality profiles', () {
    test('reduce decorative work without changing content semantics', () {
      expect(
        RenderQuality.essential.profile.targetFramesPerSecond,
        lessThan(RenderQuality.balanced.profile.targetFramesPerSecond),
      );
      expect(
        RenderQuality.balanced.profile.targetFramesPerSecond,
        lessThan(RenderQuality.cinematic.profile.targetFramesPerSecond),
      );
      expect(RenderQuality.essential.profile.drawGrain, isFalse);
      expect(RenderQuality.cinematic.profile.drawGrain, isTrue);
      expect(RenderQuality.essential.profile.trackPointer, isFalse);
    });
  });
}
