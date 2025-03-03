import 'dart:math' as math;
import 'package:flutter/material.dart';

// Roket üzerindeki ışık yansıması efekti
class RocketLightReflectionPainter extends CustomPainter {
  final double time;
  final double lightX;
  final double lightY;
  final bool isDragging;

  RocketLightReflectionPainter({
    required this.time,
    this.lightX = 0.0,
    this.lightY = 0.0,
    this.isDragging = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final width = size.width;
    final height = size.height;

    // Işık yansıması için paint
    final paint =
        Paint()
          ..style = PaintingStyle.fill
          ..strokeWidth = 1.0;

    // Roket gövdesi üzerindeki ışık yansıması
    final bodyReflectionPath = Path();
    bodyReflectionPath.moveTo(width * 0.4, height * 0.3);
    bodyReflectionPath.quadraticBezierTo(
      width * (0.5 + lightX * 0.2),
      height * (0.4 + lightY * 0.2),
      width * 0.6,
      height * 0.7,
    );
    bodyReflectionPath.close();

    // Sürükleme sırasında daha parlak yansıma
    final bodyGradient = LinearGradient(
      begin: Alignment(lightX, lightY),
      end: Alignment(-lightX, -lightY),
      colors: [
        Colors.white.withOpacity(isDragging ? 0.7 : 0.4),
        Colors.white.withOpacity(0.0),
      ],
    );

    final bodyReflectionPaint =
        Paint()
          ..shader = bodyGradient.createShader(
            Rect.fromLTWH(0, 0, width, height),
          );

    canvas.drawPath(bodyReflectionPath, bodyReflectionPaint);

    // Roket penceresi üzerindeki ışık yansıması
    final windowCenter = Offset(width * 0.35, height * 0.35);
    final windowRadius = width * 0.1;

    // Sürükleme sırasında daha parlak pencere yansıması
    final windowGradient = RadialGradient(
      center: Alignment(lightX * 0.5, lightY * 0.5),
      radius: 0.5,
      colors: [
        Colors.white.withOpacity(isDragging ? 0.9 : 0.7),
        Colors.white.withOpacity(isDragging ? 0.5 : 0.3),
        Colors.white.withOpacity(0.0),
      ],
      stops: const [0.0, 0.5, 1.0],
    );

    final windowReflectionPaint =
        Paint()
          ..shader = windowGradient.createShader(
            Rect.fromLTWH(
              windowCenter.dx - windowRadius,
              windowCenter.dy - windowRadius,
              windowRadius * 2,
              windowRadius * 2,
            ),
          );

    canvas.drawCircle(windowCenter, windowRadius * 0.7, windowReflectionPaint);

    // Sürükleme sırasında ekstra parıltı efektleri
    if (isDragging) {
      // Roket etrafında parıltı efekti
      final glowGradient = RadialGradient(
        center: const Alignment(0, 0),
        radius: 1.0,
        colors: [
          Colors.blue.withOpacity(0.3),
          Colors.blue.withOpacity(0.1),
          Colors.transparent,
        ],
        stops: const [0.0, 0.5, 1.0],
      );

      final glowPaint =
          Paint()
            ..shader = glowGradient.createShader(
              Rect.fromLTWH(0, 0, width, height),
            );

      canvas.drawRect(Rect.fromLTWH(0, 0, width, height), glowPaint);

      // Hız çizgileri
      final speedLinesPaint =
          Paint()
            ..color = Colors.white.withOpacity(0.4)
            ..strokeWidth = 1.0
            ..strokeCap = StrokeCap.round;

      final random = math.Random(42); // Sabit seed ile rastgele sayılar
      for (int i = 0; i < 5; i++) {
        final startX = width * (0.3 + random.nextDouble() * 0.4);
        final startY = height * (0.2 + random.nextDouble() * 0.6);
        final length = width * (0.1 + random.nextDouble() * 0.2);

        canvas.drawLine(
          Offset(startX, startY),
          Offset(startX - length, startY),
          speedLinesPaint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(RocketLightReflectionPainter oldDelegate) {
    return oldDelegate.time != time ||
        oldDelegate.lightX != lightX ||
        oldDelegate.lightY != lightY ||
        oldDelegate.isDragging != isDragging;
  }
}
