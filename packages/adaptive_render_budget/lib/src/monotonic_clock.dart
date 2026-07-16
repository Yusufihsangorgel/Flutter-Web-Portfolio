/// A monotonic elapsed-time source.
abstract interface class MonotonicClock {
  Duration get elapsed;
}

/// Default monotonic clock backed by a running [Stopwatch].
final class StopwatchMonotonicClock implements MonotonicClock {
  StopwatchMonotonicClock() : _stopwatch = Stopwatch()..start();

  final Stopwatch _stopwatch;

  @override
  Duration get elapsed => _stopwatch.elapsed;
}
