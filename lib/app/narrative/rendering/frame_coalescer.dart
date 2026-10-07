import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';

/// Queues updates and notifies listeners at most once per frame.
abstract class FrameCoalescer extends ChangeNotifier {
  bool _pending = false;
  bool _disposed = false;

  void scheduleFrameUpdate(bool Function() flush) {
    if (_disposed || _pending) return;
    _pending = true;
    SchedulerBinding.instance.scheduleFrameCallback((_) {
      if (_disposed) return;
      _pending = false;
      if (flush()) notifyListeners();
    });
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
