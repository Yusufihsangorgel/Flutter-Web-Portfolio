import 'package:flutter/foundation.dart';

/// Visual fidelity tiers for the restrained ambient background.
///
/// Every tier preserves the same content, section geometry, and semantics. Only
/// decorative work changes, so adaptation never changes the information
/// architecture of the portfolio.
enum RenderQuality {
  essential(
    RenderQualityProfile(
      targetFramesPerSecond: 15,
      verticalGridLines: 0,
      horizontalGridLines: 0,
      planeCount: 0,
      drawConnections: false,
      drawRegistrationMarks: false,
      drawGrain: false,
      trackPointer: false,
    ),
  ),
  balanced(
    RenderQualityProfile(
      targetFramesPerSecond: 30,
      verticalGridLines: 0,
      horizontalGridLines: 0,
      planeCount: 0,
      drawConnections: false,
      drawRegistrationMarks: false,
      drawGrain: false,
      trackPointer: true,
    ),
  ),
  cinematic(
    RenderQualityProfile(
      targetFramesPerSecond: 60,
      verticalGridLines: 0,
      horizontalGridLines: 0,
      planeCount: 0,
      drawConnections: false,
      drawRegistrationMarks: false,
      drawGrain: true,
      trackPointer: true,
    ),
  );

  const RenderQuality(this.profile);

  final RenderQualityProfile profile;

  RenderQuality get lower => switch (this) {
    RenderQuality.cinematic => RenderQuality.balanced,
    RenderQuality.balanced => RenderQuality.essential,
    RenderQuality.essential => RenderQuality.essential,
  };

  RenderQuality get higher => switch (this) {
    RenderQuality.essential => RenderQuality.balanced,
    RenderQuality.balanced => RenderQuality.cinematic,
    RenderQuality.cinematic => RenderQuality.cinematic,
  };
}

@immutable
final class RenderQualityProfile {
  const RenderQualityProfile({
    required this.targetFramesPerSecond,
    required this.verticalGridLines,
    required this.horizontalGridLines,
    required this.planeCount,
    required this.drawConnections,
    required this.drawRegistrationMarks,
    required this.drawGrain,
    required this.trackPointer,
  });

  final int targetFramesPerSecond;
  final int verticalGridLines;
  final int horizontalGridLines;
  final int planeCount;
  final bool drawConnections;
  final bool drawRegistrationMarks;
  final bool drawGrain;
  final bool trackPointer;
}

@immutable
final class FrameBudgetWindow {
  const FrameBudgetWindow({
    required this.sampleCount,
    required this.p95,
    required this.maximum,
    required this.slowFrameRatio,
  });

  final int sampleCount;
  final Duration p95;
  final Duration maximum;
  final double slowFrameRatio;
}

/// Collects fixed-size windows so quality decisions are deterministic and
/// independently testable from Flutter's frame scheduler.
final class FrameBudgetSampler {
  FrameBudgetSampler({
    this.windowSize = 90,
    this.slowFrameThreshold = const Duration(milliseconds: 20),
  }) : assert(windowSize > 0);

  final int windowSize;
  final Duration slowFrameThreshold;
  final List<int> _samples = [];

  FrameBudgetWindow? add(Duration duration) {
    _samples.add(duration.inMicroseconds);
    if (_samples.length < windowSize) return null;

    final sorted = List<int>.of(_samples)..sort();
    final p95Index = ((sorted.length - 1) * 0.95).ceil();
    final slowThreshold = slowFrameThreshold.inMicroseconds;
    final slowFrames = sorted.where((sample) => sample > slowThreshold).length;
    final window = FrameBudgetWindow(
      sampleCount: sorted.length,
      p95: Duration(microseconds: sorted[p95Index]),
      maximum: Duration(microseconds: sorted.last),
      slowFrameRatio: slowFrames / sorted.length,
    );
    _samples.clear();
    return window;
  }

  void reset() => _samples.clear();
}
