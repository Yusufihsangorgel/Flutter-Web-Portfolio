import 'dart:math' as math;
import 'package:flutter/material.dart';

// Deep space painter - distant galaxies and nebulae with slow drift
class DeepSpacePainter extends CustomPainter {
  final double time;

  static List<Nebula>? _cachedNebulas;
  static final _random = math.Random(42);

  DeepSpacePainter({required this.time});

  @override
  void paint(Canvas canvas, Size size) {
    if (_cachedNebulas == null) {
      _initializeNebulas(size);
    }

    final realTime = time * 10000;
    _drawNebulas(canvas, size, realTime);
  }

  void _initializeNebulas(Size size) {
    const nebulaCount = 3;
    _cachedNebulas = List.generate(nebulaCount, (i) {
      final x = _random.nextDouble() * size.width;
      final y = _random.nextDouble() * size.height * 0.8;
      final nebulaSize = 30.0 + _random.nextDouble() * 40.0;

      List<Color> colors;
      final colorType = _random.nextInt(3);

      switch (colorType) {
        case 0: // Purple/blue nebula
          colors = [
            const Color(0xFF9C27B0).withOpacity(0.01),
            const Color(0xFF3F51B5).withOpacity(0.008),
            const Color(0xFF673AB7).withOpacity(0.005),
            Colors.transparent,
          ];
          break;
        case 1: // Pink/red nebula
          colors = [
            const Color(0xFFE91E63).withOpacity(0.01),
            const Color(0xFFF44336).withOpacity(0.008),
            const Color(0xFFFF9800).withOpacity(0.005),
            Colors.transparent,
          ];
          break;
        default: // Teal/green nebula
          colors = [
            const Color(0xFF009688).withOpacity(0.01),
            const Color(0xFF4CAF50).withOpacity(0.008),
            const Color(0xFF00BCD4).withOpacity(0.005),
            Colors.transparent,
          ];
      }

      final movementSpeed = 0.00002 + _random.nextDouble() * 0.00005;
      final movementAmplitude = 15.0 + _random.nextDouble() * 10.0;
      final innerSpeed = 0.0001 + _random.nextDouble() * 0.0002;
      final innerAmplitude = 0.05 + _random.nextDouble() * 0.1;
      final phase = _random.nextDouble() * math.pi * 2;

      return Nebula(
        x: x,
        y: y,
        size: nebulaSize,
        colors: colors,
        movementSpeed: movementSpeed,
        movementAmplitude: movementAmplitude,
        innerSpeed: innerSpeed,
        innerAmplitude: innerAmplitude,
        phase: phase,
      );
    });

    // Smaller background galaxies for depth
    _cachedNebulas!.addAll(
      List.generate(12, (i) {
        final x = _random.nextDouble() * size.width;
        final y = _random.nextDouble() * size.height * 0.9;
        final nebulaSize = 10.0 + _random.nextDouble() * 20.0;

        final colors = [
          Colors.white.withOpacity(0.008),
          Colors.white.withOpacity(0.005),
          Colors.transparent,
        ];

        final movementSpeed = 0.00001 + _random.nextDouble() * 0.00002;
        final movementAmplitude = 3.0 + _random.nextDouble() * 5.0;
        final innerSpeed = 0.00005 + _random.nextDouble() * 0.0001;
        final innerAmplitude = 0.02 + _random.nextDouble() * 0.05;
        final phase = _random.nextDouble() * math.pi * 2;

        return Nebula(
          x: x,
          y: y,
          size: nebulaSize,
          colors: colors,
          movementSpeed: movementSpeed,
          movementAmplitude: movementAmplitude,
          innerSpeed: innerSpeed,
          innerAmplitude: innerAmplitude,
          phase: phase,
          isDistant: true,
        );
      }),
    );
  }

  void _drawNebulas(Canvas canvas, Size size, double time) {
    if (_cachedNebulas == null) return;

    for (var nebula in _cachedNebulas!) {
      final xOffset =
          math.sin(time * nebula.movementSpeed + nebula.phase) *
          nebula.movementAmplitude;
      final yOffset =
          math.cos(time * nebula.movementSpeed * 0.7 + nebula.phase) *
          nebula.movementAmplitude *
          0.5;

      final x = nebula.x + xOffset;
      final y = nebula.y + yOffset;

      // Inner shape shift - nebula center drifts slightly over time
      final centerOffsetX =
          math.sin(time * nebula.innerSpeed + nebula.phase) *
          nebula.innerAmplitude;
      final centerOffsetY =
          math.cos(time * nebula.innerSpeed * 1.1 + nebula.phase) *
          nebula.innerAmplitude;

      final radiusModulation =
          1.0 + math.sin(time * nebula.innerSpeed * 0.5) * 0.05;

      final gradient = RadialGradient(
        center: Alignment(centerOffsetX, centerOffsetY),
        radius: radiusModulation,
        colors: nebula.colors,
        stops:
            nebula.isDistant
                ? [0.0, 0.5, 1.0]
                : [0.0, 0.3, 0.6, 1.0],
      ).createShader(
        Rect.fromCircle(center: Offset(x, y), radius: nebula.size),
      );

      final paint =
          Paint()
            ..shader = gradient
            ..style = PaintingStyle.fill
            ..blendMode = BlendMode.screen;

      canvas.drawCircle(Offset(x, y), nebula.size, paint);
    }
  }

  @override
  bool shouldRepaint(DeepSpacePainter oldDelegate) {
    return oldDelegate.time != time;
  }
}

class Nebula {
  final double x, y;
  final double size;
  final List<Color> colors;
  final double movementSpeed;
  final double movementAmplitude;
  final double innerSpeed;
  final double innerAmplitude;
  final double phase;
  final bool isDistant;

  Nebula({
    required this.x,
    required this.y,
    required this.size,
    required this.colors,
    required this.movementSpeed,
    required this.movementAmplitude,
    required this.innerSpeed,
    required this.innerAmplitude,
    required this.phase,
    this.isDistant = false,
  });
}
