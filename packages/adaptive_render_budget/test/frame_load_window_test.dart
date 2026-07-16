import 'dart:ui';

import 'package:adaptive_render_budget/adaptive_render_budget.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('FrameLoadWindow', () {
    test('normalizes identical work against the display refresh rate', () {
      final timing = RenderFrameTiming(
        buildDuration: const Duration(milliseconds: 8),
        rasterDuration: const Duration(milliseconds: 5),
      );

      final at60Hz = FrameLoadWindow.normalizedLoad(timing, refreshRateHz: 60);
      final at120Hz = FrameLoadWindow.normalizedLoad(
        timing,
        refreshRateHz: 120,
      );

      expect(at60Hz, closeTo(0.48, 0.001));
      expect(at120Hz, closeTo(0.96, 0.001));
    });

    test('uses the slower pipelined stage as critical work', () {
      final timing = RenderFrameTiming(
        buildDuration: const Duration(milliseconds: 3),
        rasterDuration: const Duration(milliseconds: 10),
      );

      expect(
        FrameLoadWindow.normalizedLoad(timing, refreshRateHz: 100),
        closeTo(1, 0.001),
      );
    });

    test('evicts the oldest sample without growing beyond capacity', () {
      final window = FrameLoadWindow(capacity: 3);
      window
        ..add(_timing(4), refreshRateHz: 100)
        ..add(_timing(6), refreshRateHz: 100)
        ..add(_timing(8), refreshRateHz: 100)
        ..add(_timing(10), refreshRateHz: 100);

      final stats = window.statistics(overloadThreshold: 0.75);
      expect(stats.sampleCount, 3);
      expect(stats.mean, closeTo(0.8, 0.001));
      expect(stats.p95, closeTo(1, 0.001));
      expect(stats.maximum, closeTo(1, 0.001));
      expect(stats.overloadedFraction, closeTo(2 / 3, 0.001));
    });

    test('clear retains capacity while dropping accumulated evidence', () {
      final window = FrameLoadWindow(capacity: 2)
        ..add(_timing(10), refreshRateHz: 100);

      window.clear();

      expect(window.length, 0);
      expect(
        window.statistics(overloadThreshold: 1),
        FrameLoadStatistics.empty,
      );
      window.add(_timing(5), refreshRateHz: 100);
      expect(window.length, 1);
    });

    test('rejects invalid refresh rates and thresholds', () {
      final timing = _timing(5);
      final window = FrameLoadWindow(capacity: 2);

      expect(
        () => FrameLoadWindow.normalizedLoad(timing, refreshRateHz: double.nan),
        throwsArgumentError,
      );
      expect(
        () => window.statistics(overloadThreshold: 0),
        throwsArgumentError,
      );
      expect(() => FrameLoadWindow(capacity: 0), throwsArgumentError);
    });
  });

  group('RenderFrameTiming', () {
    test('maps Flutter frame timings without retaining engine objects', () {
      final flutterTiming = FrameTiming(
        vsyncStart: 0,
        buildStart: 100,
        buildFinish: 5100,
        rasterStart: 6000,
        rasterFinish: 13000,
        rasterFinishWallTime: 13000,
      );

      final timing = RenderFrameTiming.fromFlutter(flutterTiming);

      expect(timing.buildDuration, const Duration(milliseconds: 5));
      expect(timing.rasterDuration, const Duration(milliseconds: 7));
      expect(timing.criticalDuration, const Duration(milliseconds: 7));
    });

    test('rejects negative stage durations', () {
      expect(
        () => RenderFrameTiming(
          buildDuration: const Duration(microseconds: -1),
          rasterDuration: Duration.zero,
        ),
        throwsArgumentError,
      );
    });
  });
}

RenderFrameTiming _timing(int milliseconds) {
  return RenderFrameTiming(
    buildDuration: Duration(milliseconds: milliseconds),
    rasterDuration: const Duration(milliseconds: 1),
  );
}
