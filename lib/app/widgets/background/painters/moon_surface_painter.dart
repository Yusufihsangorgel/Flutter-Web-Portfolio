import 'dart:math' as math;
import 'package:flutter/material.dart';

// Moon surface painter - realistic crater and mare rendering
class MoonSurfacePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final random = math.Random(42);
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    final baseSurfacePaint =
        Paint()
          ..shader = RadialGradient(
            center: const Alignment(-0.3, -0.3),
            radius: 1.0,
            colors: [
              Colors.white.withOpacity(0.05),
              Colors.grey[300]!.withOpacity(0.03),
              Colors.grey[400]!.withOpacity(0.02),
              Colors.transparent,
            ],
            stops: const [0.0, 0.3, 0.7, 1.0],
          ).createShader(Rect.fromCircle(center: center, radius: radius));

    canvas.drawCircle(center, radius, baseSurfacePaint);

    // Mare (dark regions) - lunar seas
    _drawMare(canvas, size, random);
    _drawCraters(canvas, size, random);
    // Rilles - tectonic surface fractures
    _drawRilles(canvas, size, random);
  }

  void _drawMare(Canvas canvas, Size size, math.Random random) {
    // Mare positions modeled after real lunar features
    final marePositions = [
      Offset(size.width * 0.3, size.height * 0.3),
      Offset(size.width * 0.7, size.height * 0.6),
      Offset(size.width * 0.4, size.height * 0.7),
    ];

    for (var position in marePositions) {
      final mareSize = size.width * (0.2 + random.nextDouble() * 0.15);

      final marePaint =
          Paint()
            ..color = const Color(0xFF9E9E9E).withOpacity(0.1)
            ..style = PaintingStyle.fill;

      canvas.drawCircle(position, mareSize, marePaint);

      final mareEdgePaint =
          Paint()
            ..color = const Color(0xFF9E9E9E).withOpacity(0.05)
            ..style = PaintingStyle.stroke
            ..strokeWidth = mareSize * 0.2;

      canvas.drawCircle(position, mareSize * 0.9, mareEdgePaint);
    }
  }

  void _drawCraters(Canvas canvas, Size size, math.Random random) {
    final largeCraterCount = 5;
    for (int i = 0; i < largeCraterCount; i++) {
      final x = random.nextDouble() * size.width;
      final y = random.nextDouble() * size.height;
      final craterSize = 5.0 + random.nextDouble() * 8.0;
      _drawCrater(canvas, Offset(x, y), craterSize, random);
    }

    final mediumCraterCount = 12;
    for (int i = 0; i < mediumCraterCount; i++) {
      final x = random.nextDouble() * size.width;
      final y = random.nextDouble() * size.height;
      final craterSize = 2.0 + random.nextDouble() * 4.0;
      _drawCrater(canvas, Offset(x, y), craterSize, random);
    }

    final smallCraterCount = 25;
    for (int i = 0; i < smallCraterCount; i++) {
      final x = random.nextDouble() * size.width;
      final y = random.nextDouble() * size.height;
      final craterSize = 0.5 + random.nextDouble() * 1.5;
      _drawCrater(canvas, Offset(x, y), craterSize, random);
    }
  }

  void _drawCrater(
    Canvas canvas,
    Offset position,
    double size,
    math.Random random,
  ) {
    final craterPaint =
        Paint()
          ..color = const Color(0xFF9E9E9E).withOpacity(0.15)
          ..style = PaintingStyle.fill;

    canvas.drawCircle(position, size, craterPaint);

    // Raised crater rim
    final rimPaint =
        Paint()
          ..color = Colors.white.withOpacity(0.1)
          ..style = PaintingStyle.stroke
          ..strokeWidth = size * 0.3;

    canvas.drawCircle(position, size * 0.85, rimPaint);

    // Shadow cast by the rim based on light direction
    final shadowPaint =
        Paint()
          ..color = Colors.black.withOpacity(0.1)
          ..style = PaintingStyle.fill;

    final shadowOffset = Offset(size * 0.3, size * 0.3);
    canvas.drawCircle(position + shadowOffset, size * 0.5, shadowPaint);
  }

  void _drawRilles(Canvas canvas, Size size, math.Random random) {
    final rilleCount = 3;

    for (int i = 0; i < rilleCount; i++) {
      final startX = random.nextDouble() * size.width;
      final startY = random.nextDouble() * size.height;
      final length = 10.0 + random.nextDouble() * 20.0;
      final angle = random.nextDouble() * math.pi * 2;

      final endX = startX + math.cos(angle) * length;
      final endY = startY + math.sin(angle) * length;

      final rillePaint =
          Paint()
            ..color = const Color(0xFF9E9E9E).withOpacity(0.1)
            ..strokeWidth = 0.5
            ..style = PaintingStyle.stroke;

      canvas.drawLine(Offset(startX, startY), Offset(endX, endY), rillePaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
