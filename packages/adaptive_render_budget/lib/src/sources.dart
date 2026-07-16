import 'dart:collection';
import 'dart:ui';

import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

import 'frame_timing_sample.dart';

typedef RenderFrameTimingCallback =
    void Function(List<RenderFrameTiming> timings);

/// Supplies batches of frame timing samples.
abstract interface class RenderFrameTimingSource {
  void addListener(RenderFrameTimingCallback listener);
  void removeListener(RenderFrameTimingCallback listener);
}

/// Adapts Flutter's scheduler timing callback into package timing samples.
final class SchedulerFrameTimingSource implements RenderFrameTimingSource {
  SchedulerFrameTimingSource({SchedulerBinding? binding})
    : _binding = binding ?? SchedulerBinding.instance;

  final SchedulerBinding _binding;
  final LinkedHashSet<RenderFrameTimingCallback> _listeners =
      LinkedHashSet<RenderFrameTimingCallback>.identity();
  bool _isAttached = false;
  bool _isDisposed = false;

  @override
  void addListener(RenderFrameTimingCallback listener) {
    if (_isDisposed) {
      throw StateError('SchedulerFrameTimingSource is disposed.');
    }
    if (!_listeners.add(listener)) {
      return;
    }
    if (!_isAttached) {
      _binding.addTimingsCallback(_handleFlutterTimings);
      _isAttached = true;
    }
  }

  @override
  void removeListener(RenderFrameTimingCallback listener) {
    if (_isDisposed || !_listeners.remove(listener)) {
      return;
    }
    if (_listeners.isEmpty && _isAttached) {
      _binding.removeTimingsCallback(_handleFlutterTimings);
      _isAttached = false;
    }
  }

  /// Detaches the scheduler callback and rejects future listeners.
  void dispose() {
    if (_isDisposed) {
      return;
    }
    if (_isAttached) {
      _binding.removeTimingsCallback(_handleFlutterTimings);
    }
    _listeners.clear();
    _isAttached = false;
    _isDisposed = true;
  }

  void _handleFlutterTimings(List<FrameTiming> timings) {
    if (_listeners.isEmpty || timings.isEmpty) {
      return;
    }
    final samples = List<RenderFrameTiming>.unmodifiable(
      timings.map(RenderFrameTiming.fromFlutter),
    );
    final listeners = List<RenderFrameTimingCallback>.of(_listeners);
    for (final listener in listeners) {
      if (_listeners.contains(listener)) {
        listener(samples);
      }
    }
  }
}

/// Observable source for the active display refresh rate.
abstract interface class RefreshRateSource implements Listenable {
  double get refreshRateHz;
}

/// An immutable refresh-rate source, useful when a display rate is known.
final class FixedRefreshRateSource implements RefreshRateSource {
  FixedRefreshRateSource(this.refreshRateHz) {
    _validateRefreshRate(refreshRateHz);
  }

  @override
  final double refreshRateHz;

  @override
  void addListener(VoidCallback listener) {}

  @override
  void removeListener(VoidCallback listener) {}
}

/// Tracks the display used by one [FlutterView].
///
/// The source observes framework metric changes and emits only when the
/// display-reported refresh rate changes.
final class DisplayRefreshRateSource extends ChangeNotifier
    with WidgetsBindingObserver
    implements RefreshRateSource {
  DisplayRefreshRateSource({
    required FlutterView view,
    WidgetsBinding? binding,
    double fallbackRefreshRateHz = 60,
  }) : _view = view,
       _binding = binding ?? WidgetsBinding.instance,
       _fallbackRefreshRateHz = fallbackRefreshRateHz,
       _refreshRateHz = _readRefreshRate(view, fallbackRefreshRateHz) {
    _validateRefreshRate(fallbackRefreshRateHz);
    _binding.addObserver(this);
  }

  final FlutterView _view;
  final WidgetsBinding _binding;
  final double _fallbackRefreshRateHz;
  double _refreshRateHz;
  bool _isDisposed = false;

  @override
  double get refreshRateHz => _refreshRateHz;

  @override
  void didChangeMetrics() {
    final next = _readRefreshRate(_view, _fallbackRefreshRateHz);
    if (next == _refreshRateHz) {
      return;
    }
    _refreshRateHz = next;
    notifyListeners();
  }

  @override
  void dispose() {
    if (_isDisposed) {
      return;
    }
    _binding.removeObserver(this);
    _isDisposed = true;
    super.dispose();
  }

  static double _readRefreshRate(FlutterView view, double fallback) {
    final reported = view.display.refreshRate;
    return reported.isFinite && reported > 0 ? reported : fallback;
  }
}

void _validateRefreshRate(double refreshRateHz) {
  if (!refreshRateHz.isFinite || refreshRateHz <= 0) {
    throw ArgumentError.value(
      refreshRateHz,
      'refreshRateHz',
      'must be finite and greater than 0',
    );
  }
}
