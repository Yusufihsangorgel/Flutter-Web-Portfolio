import 'dart:collection';
import 'dart:developer' as dev;

import 'package:flutter/scheduler.dart';
import 'package:get/get.dart';

/// Quality level that determines which visual effects are active.
enum QualityLevel {
  /// All effects enabled: particles, shaders, complex animations, cursor trail.
  high,

  /// Reduced effects: simplified particles, lighter animations.
  medium,

  /// Minimal effects: no particles, no shaders, basic animations, no cursor trail.
  low,
}

/// Monitors frame performance and adaptively adjusts visual quality.
///
/// Tracks FPS via [SchedulerBinding.addTimingsCallback], computes rolling
/// averages, and exposes a reactive [qualityLevel] that widgets can observe
/// to scale their rendering cost.
///
/// Register as a GetX service in your bindings:
/// ```dart
/// Get.put(PerformanceMonitor(), permanent: true);
/// ```
class PerformanceMonitor extends GetxController {
  // ---------------------------------------------------------------------------
  // Configuration
  // ---------------------------------------------------------------------------

  /// FPS threshold below which quality is reduced.
  static const double _degradeThreshold = 30.0;

  /// FPS threshold above which quality is restored.
  static const double _recoverThreshold = 45.0;

  /// Number of consecutive low/high samples required before changing quality,
  /// preventing flicker from momentary spikes.
  static const int _hysteresisFrames = 10;

  /// Maximum number of frame durations kept for the rolling average.
  static const int _sampleWindowSize = 120;

  // ---------------------------------------------------------------------------
  // Observable state
  // ---------------------------------------------------------------------------

  /// Current instantaneous FPS (smoothed over recent frames).
  final currentFps = 0.0.obs;

  /// Rolling average FPS across [_sampleWindowSize] frames.
  final averageFps = 60.0.obs;

  /// Total number of frames that exceeded the budget (16.67 ms at 60 Hz).
  final droppedFrames = 0.obs;

  /// Adaptive quality level driven by FPS measurements.
  final qualityLevel = QualityLevel.high.obs;

  // ---------------------------------------------------------------------------
  // Convenience getters for widgets
  // ---------------------------------------------------------------------------

  /// Whether particle systems should be rendered.
  bool get particlesEnabled => qualityLevel.value != QualityLevel.low;

  /// Whether shader effects should be rendered.
  bool get shadersEnabled => qualityLevel.value == QualityLevel.high;

  /// Whether cursor trail effects should be rendered.
  bool get cursorTrailEnabled => qualityLevel.value != QualityLevel.low;

  /// Whether complex animations (parallax, 3D transforms) should be active.
  bool get complexAnimationsEnabled =>
      qualityLevel.value != QualityLevel.low;

  // ---------------------------------------------------------------------------
  // Internal state
  // ---------------------------------------------------------------------------

  final Queue<double> _frameDurations = Queue<double>();
  int _consecutiveLowFrames = 0;
  int _consecutiveHighFrames = 0;
  bool _isMonitoring = false;
  TimingsCallback? _timingsCallback;

  // ---------------------------------------------------------------------------
  // Lifecycle
  // ---------------------------------------------------------------------------

  @override
  void onInit() {
    super.onInit();
    _startMonitoring();
  }

  @override
  void onClose() {
    _stopMonitoring();
    super.onClose();
  }

  // ---------------------------------------------------------------------------
  // Public API
  // ---------------------------------------------------------------------------

  /// Force a specific quality level, disabling adaptive adjustments until
  /// [resetToAdaptive] is called.
  void forceQuality(QualityLevel level) {
    _stopMonitoring();
    qualityLevel.value = level;
  }

  /// Resume adaptive quality based on live FPS measurements.
  void resetToAdaptive() {
    if (!_isMonitoring) {
      _startMonitoring();
    }
  }

  // ---------------------------------------------------------------------------
  // Monitoring
  // ---------------------------------------------------------------------------

  void _startMonitoring() {
    if (_isMonitoring) return;
    _isMonitoring = true;

    _timingsCallback = _onTimings;
    try {
      SchedulerBinding.instance.addTimingsCallback(_timingsCallback!);
    } catch (e) {
      dev.log(
        'Failed to register timings callback',
        name: 'PerformanceMonitor',
        error: e,
      );
      _isMonitoring = false;
    }
  }

  void _stopMonitoring() {
    if (!_isMonitoring || _timingsCallback == null) return;
    _isMonitoring = false;

    try {
      SchedulerBinding.instance.removeTimingsCallback(_timingsCallback!);
    } catch (e) {
      dev.log(
        'Failed to remove timings callback',
        name: 'PerformanceMonitor',
        error: e,
      );
    }
    _timingsCallback = null;
  }

  void _onTimings(List<FrameTiming> timings) {
    for (final timing in timings) {
      final frameDurationMs =
          timing.totalSpan.inMicroseconds / Duration.microsecondsPerMillisecond;

      _frameDurations.addLast(frameDurationMs);
      if (_frameDurations.length > _sampleWindowSize) {
        _frameDurations.removeFirst();
      }

      // A frame is "dropped" when it exceeds the 60 Hz budget (≈16.67 ms).
      if (frameDurationMs > 16.67) {
        droppedFrames.value++;
      }
    }

    _updateMetrics();
  }

  void _updateMetrics() {
    if (_frameDurations.isEmpty) return;

    // Current FPS: based on last few frames for responsiveness.
    final recentCount = _frameDurations.length.clamp(1, 10);
    final recentSamples = _frameDurations.toList().sublist(
          _frameDurations.length - recentCount,
        );
    final recentAvgMs =
        recentSamples.reduce((a, b) => a + b) / recentSamples.length;
    currentFps.value =
        recentAvgMs > 0 ? (1000.0 / recentAvgMs).clamp(0.0, 120.0) : 60.0;

    // Rolling average FPS.
    final totalMs = _frameDurations.reduce((a, b) => a + b);
    final avgMs = totalMs / _frameDurations.length;
    averageFps.value =
        avgMs > 0 ? (1000.0 / avgMs).clamp(0.0, 120.0) : 60.0;

    _evaluateQuality();
  }

  void _evaluateQuality() {
    final fps = averageFps.value;
    final current = qualityLevel.value;

    if (fps < _degradeThreshold) {
      _consecutiveHighFrames = 0;
      _consecutiveLowFrames++;

      if (_consecutiveLowFrames >= _hysteresisFrames) {
        final next = _degradeLevel(current);
        if (next != current) {
          qualityLevel.value = next;
          _consecutiveLowFrames = 0;
          dev.log(
            'Quality degraded: $current → $next (avg FPS: ${fps.toStringAsFixed(1)})',
            name: 'PerformanceMonitor',
          );
        }
      }
    } else if (fps > _recoverThreshold) {
      _consecutiveLowFrames = 0;
      _consecutiveHighFrames++;

      if (_consecutiveHighFrames >= _hysteresisFrames) {
        final next = _upgradeLevel(current);
        if (next != current) {
          qualityLevel.value = next;
          _consecutiveHighFrames = 0;
          dev.log(
            'Quality upgraded: $current → $next (avg FPS: ${fps.toStringAsFixed(1)})',
            name: 'PerformanceMonitor',
          );
        }
      }
    } else {
      // FPS is between thresholds — hold steady.
      _consecutiveLowFrames = 0;
      _consecutiveHighFrames = 0;
    }
  }

  QualityLevel _degradeLevel(QualityLevel current) => switch (current) {
        QualityLevel.high => QualityLevel.medium,
        QualityLevel.medium => QualityLevel.low,
        QualityLevel.low => QualityLevel.low,
      };

  QualityLevel _upgradeLevel(QualityLevel current) => switch (current) {
        QualityLevel.low => QualityLevel.medium,
        QualityLevel.medium => QualityLevel.high,
        QualityLevel.high => QualityLevel.high,
      };
}
