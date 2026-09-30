/// A monotonic elapsed-time source.
abstract interface class MonotonicClock {
  /// Time elapsed since this clock's origin.
  Duration get elapsed;
}

/// Default monotonic clock backed by a running [Stopwatch].
final class StopwatchMonotonicClock implements MonotonicClock {
  /// Starts a stopwatch at construction.
  StopwatchMonotonicClock() : _stopwatch = Stopwatch()..start();

  final Stopwatch _stopwatch;

  @override
  Duration get elapsed => _stopwatch.elapsed;
}
