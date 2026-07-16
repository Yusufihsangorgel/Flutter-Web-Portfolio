import 'dart:ui';

import 'package:adaptive_render_budget/adaptive_render_budget.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('FixedRefreshRateSource exposes a validated immutable rate', () {
    final source = FixedRefreshRateSource(120);
    var notifications = 0;

    source.addListener(() => notifications += 1);

    expect(source.refreshRateHz, 120);
    expect(notifications, 0);
    expect(() => FixedRefreshRateSource(0), throwsArgumentError);
  });

  test('SchedulerFrameTimingSource maps and detaches scheduler timings', () {
    final binding = TestWidgetsFlutterBinding.instance;
    final source = SchedulerFrameTimingSource(binding: binding);
    final received = <RenderFrameTiming>[];

    void listener(List<RenderFrameTiming> timings) {
      received.addAll(timings);
    }

    source.addListener(listener);
    binding.platformDispatcher.onReportTimings?.call(<FrameTiming>[
      FrameTiming(
        vsyncStart: 0,
        buildStart: 100,
        buildFinish: 4100,
        rasterStart: 5000,
        rasterFinish: 11000,
        rasterFinishWallTime: 11000,
      ),
    ]);

    expect(received, hasLength(1));
    expect(received.single.buildDuration, const Duration(milliseconds: 4));
    expect(received.single.rasterDuration, const Duration(milliseconds: 6));

    source.removeListener(listener);
    binding.platformDispatcher.onReportTimings?.call(<FrameTiming>[
      FrameTiming(
        vsyncStart: 0,
        buildStart: 0,
        buildFinish: 1000,
        rasterStart: 1000,
        rasterFinish: 2000,
        rasterFinishWallTime: 2000,
      ),
    ]);
    expect(received, hasLength(1));

    source.dispose();
    source.dispose();
    expect(() => source.addListener(listener), throwsStateError);
  });
}
