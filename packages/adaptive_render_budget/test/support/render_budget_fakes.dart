import 'dart:collection';

import 'package:adaptive_render_budget/adaptive_render_budget.dart';
import 'package:flutter/foundation.dart';

final class FakeTimingSource implements RenderFrameTimingSource {
  final _listeners = LinkedHashSet<RenderFrameTimingCallback>.identity();

  int get listenerCount => _listeners.length;

  @override
  void addListener(RenderFrameTimingCallback listener) =>
      _listeners.add(listener);

  @override
  void removeListener(RenderFrameTimingCallback listener) =>
      _listeners.remove(listener);

  void emitRepeated(RenderFrameTiming timing, int count) {
    final batch = List<RenderFrameTiming>.filled(count, timing);
    for (final listener in List<RenderFrameTimingCallback>.of(_listeners)) {
      listener(batch);
    }
  }
}

final class FakeRefreshRateSource extends ChangeNotifier
    implements RefreshRateSource {
  FakeRefreshRateSource(this._refreshRateHz);

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

final class FakeClock implements MonotonicClock {
  @override
  Duration elapsed = Duration.zero;

  void advance(Duration duration) => elapsed += duration;
}
