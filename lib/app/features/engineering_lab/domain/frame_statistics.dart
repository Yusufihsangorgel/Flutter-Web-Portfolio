import 'package:flutter/foundation.dart';

/// Immutable summary of a real frame-timing sample.
@immutable
final class FrameStatistics {
  const FrameStatistics({
    required this.sampleCount,
    required this.medianMilliseconds,
    required this.p95Milliseconds,
  });

  const FrameStatistics.empty()
    : sampleCount = 0,
      medianMilliseconds = 0,
      p95Milliseconds = 0;

  factory FrameStatistics.fromDurations(Iterable<Duration> durations) {
    final samples =
        durations
            .map((duration) => duration.inMicroseconds / 1000)
            .where((milliseconds) => milliseconds >= 0)
            .toList()
          ..sort();

    if (samples.isEmpty) return const FrameStatistics.empty();

    return FrameStatistics(
      sampleCount: samples.length,
      medianMilliseconds: _percentile(samples, 0.50),
      p95Milliseconds: _percentile(samples, 0.95),
    );
  }

  final int sampleCount;
  final double medianMilliseconds;
  final double p95Milliseconds;

  bool get hasSamples => sampleCount > 0;

  static double _percentile(List<double> sortedSamples, double percentile) {
    final index = ((sortedSamples.length - 1) * percentile).round();
    return sortedSamples[index];
  }
}
