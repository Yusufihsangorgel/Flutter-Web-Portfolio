import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'dart:ui' show PointMode;

// Star field painter - twinkling and glowing stars
class StarFieldPainter extends CustomPainter {

  StarFieldPainter({required this.animController, this.scrollOffset = 0});
  final AnimationController animController;
  final double scrollOffset;

  static List<Star>? _cachedStars;
  static final _random = math.Random(42);

  @override
  void paint(Canvas canvas, Size size) {
    if (_cachedStars == null) {
      _initializeStars(size);
    }

    final realTime = animController.value * 7200;
    _drawStars(canvas, size, realTime);
  }

  void _initializeStars(Size size) {
    const starCount = 1000;
    _cachedStars = List.generate(starCount, (i) {
      final brightnessType = _random.nextInt(10);
      final isTwinkler = brightnessType < 2;
      final isVeryBright = brightnessType == 9;

      double starSize = _random.nextDouble() * 1.5 + 0.3;
      if (isVeryBright) starSize += 0.5;

      final movementAmplitude = starSize * 0.3;
      final movementSpeed = 0.00005 + _random.nextDouble() * 0.0001;

      final x = _random.nextDouble() * size.width;
      final y = _random.nextDouble() * size.height;

      // Unique phase per star so they twinkle at different times
      final phase = _random.nextDouble() * math.pi * 2;

      // Layer for parallax depth effect
      final layer = _random.nextDouble();

      return Star(
        x: x,
        y: y,
        size: starSize,
        isTwinkler: isTwinkler,
        isBright: isVeryBright,
        movementAmplitude: movementAmplitude,
        movementSpeed: movementSpeed,
        phase: phase,
        layer: layer,
      );
    });
  }

  void _drawStars(Canvas canvas, Size size, double time) {
    if (_cachedStars == null) return;

    for (var star in _cachedStars!) {
      double brightness = star.isBright ? 0.8 : 0.4;

      if (star.isTwinkler) {
        final twinkleSpeed = 0.05 + (star.size * 0.02);
        brightness *=
            0.3 + (math.sin(time * twinkleSpeed + star.phase) + 1) / 2 * 0.6;
      }

      final double x =
          star.x +
          math.sin(time * star.movementSpeed + star.phase) *
              star.movementAmplitude;
      double y =
          star.y +
          math.cos(time * star.movementSpeed + star.phase) *
              star.movementAmplitude;

      // Parallax: different layers scroll at different speeds
      final parallaxFactor = 0.1 + star.layer * 0.2;
      y -= scrollOffset * parallaxFactor;

      // Wrap stars that scroll off-screen
      y = y % size.height;

      final double starSize = star.size;

      final paint =
          Paint()
            ..color = Colors.white.withValues(alpha:brightness)
            ..strokeWidth = starSize
            ..strokeCap = StrokeCap.round;

      canvas.drawPoints(PointMode.points, [Offset(x, y)], paint);

      // Subtle glow for bright stars
      if (brightness > 0.6) {
        final glowPaint =
            Paint()
              ..color = Colors.white.withValues(alpha:brightness * 0.15)
              ..strokeWidth = starSize * 2.5
              ..strokeCap = StrokeCap.round;

        canvas.drawPoints(PointMode.points, [Offset(x, y)], glowPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant StarFieldPainter oldDelegate) => oldDelegate.animController.value != animController.value ||
        oldDelegate.scrollOffset != scrollOffset;
}

class Star {

  Star({
    required this.x,
    required this.y,
    required this.size,
    required this.isTwinkler,
    required this.isBright,
    required this.movementAmplitude,
    required this.movementSpeed,
    required this.phase,
    required this.layer,
  });
  final double x, y;
  final double size;
  final bool isTwinkler;
  final bool isBright;
  final double movementAmplitude;
  final double movementSpeed;
  final double phase;
  final double layer;
}
