import 'package:flutter/animation.dart';

/// Shared easing curves for restrained interface motion.
final class MotionCurves {
  const MotionCurves._();

  /// Symmetric easing for progress changes and large transitions.
  static const standard = Cubic(0.65, 0.0, 0.35, 1.0);

  /// Fast response with a long deceleration for entering controls.
  static const emphasizedDecelerate = Cubic(0.22, 1.0, 0.36, 1.0);

  /// Low-latency deceleration for direct pointer feedback.
  static const quickOut = Cubic(0.0, 0.0, 0.2, 1.0);
}
