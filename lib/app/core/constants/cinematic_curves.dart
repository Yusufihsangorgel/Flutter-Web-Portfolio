import 'package:flutter/animation.dart';

/// Easing curves tuned for cinematic micro-interactions.
final class CinematicCurves {
  const CinematicCurves._();

  /// Smooth cinematic ease — replaces springy Flutter defaults
  static const easeInOutCinematic = Cubic(0.65, 0.0, 0.35, 1.0);

  /// Dramatic entrance — slow start, powerful finish
  static const dramaticEntrance = Cubic(0.22, 1.0, 0.36, 1.0);

  /// Soft deceleration for reveals
  static const revealDecel = Cubic(0.0, 0.0, 0.2, 1.0);

  /// Magnetic pull — used for magnetic button attraction
  static const magneticPull = Cubic(0.25, 0.46, 0.45, 0.94);

  /// Scene crossfade timing
  static const sceneFade = Cubic(0.4, 0.0, 0.6, 1.0);

  /// Text reveal sweep
  static const textReveal = Cubic(0.77, 0.0, 0.175, 1.0);

  /// Hover lift — quick out
  static const hoverLift = Cubic(0.0, 0.0, 0.2, 1.0);

  /// Particle drift
  static const particleDrift = Cubic(0.37, 0.0, 0.63, 1.0);
}
