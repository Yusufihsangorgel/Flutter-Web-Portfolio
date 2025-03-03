import 'dart:math' as math;
import 'package:flutter/material.dart';

// Ay yüzeyi çizici - daha gerçekçi
class MoonSurfacePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final random = math.Random(42);
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Ay yüzeyi temel dokusu - hafif gri tonlama
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

    // Mare (koyu bölgeler) - ay denizleri
    _drawMare(canvas, size, random);

    // Kraterler - farklı boyutlarda
    _drawCraters(canvas, size, random);

    // Ay yüzeyindeki ince çizgiler (rilles) - tektonik çatlaklar
    _drawRilles(canvas, size, random);
  }

  // Ay denizleri (mare) çizimi
  void _drawMare(Canvas canvas, Size size, math.Random random) {
    // Mare pozisyonları - gerçek aya benzer şekilde
    final marePositions = [
      Offset(size.width * 0.3, size.height * 0.3), // Mare Serenitatis
      Offset(size.width * 0.7, size.height * 0.6), // Mare Imbrium
      Offset(size.width * 0.4, size.height * 0.7), // Mare Nubium
    ];

    for (var position in marePositions) {
      // Mare boyutu
      final mareSize = size.width * (0.2 + random.nextDouble() * 0.15);

      // Mare şekli - düzensiz
      final marePaint =
          Paint()
            ..color = const Color(0xFF9E9E9E).withOpacity(0.1)
            ..style = PaintingStyle.fill;

      canvas.drawCircle(position, mareSize, marePaint);

      // Mare kenarları - daha doğal geçiş
      final mareEdgePaint =
          Paint()
            ..color = const Color(0xFF9E9E9E).withOpacity(0.05)
            ..style = PaintingStyle.stroke
            ..strokeWidth = mareSize * 0.2;

      canvas.drawCircle(position, mareSize * 0.9, mareEdgePaint);
    }
  }

  // Kraterler çizimi
  void _drawCraters(Canvas canvas, Size size, math.Random random) {
    // Büyük kraterler - daha az sayıda
    final largeCraterCount = 5;
    for (int i = 0; i < largeCraterCount; i++) {
      final x = random.nextDouble() * size.width;
      final y = random.nextDouble() * size.height;
      final craterSize = 5.0 + random.nextDouble() * 8.0;

      _drawCrater(canvas, Offset(x, y), craterSize, random);
    }

    // Orta boy kraterler
    final mediumCraterCount = 12;
    for (int i = 0; i < mediumCraterCount; i++) {
      final x = random.nextDouble() * size.width;
      final y = random.nextDouble() * size.height;
      final craterSize = 2.0 + random.nextDouble() * 4.0;

      _drawCrater(canvas, Offset(x, y), craterSize, random);
    }

    // Küçük kraterler - daha çok sayıda
    final smallCraterCount = 25;
    for (int i = 0; i < smallCraterCount; i++) {
      final x = random.nextDouble() * size.width;
      final y = random.nextDouble() * size.height;
      final craterSize = 0.5 + random.nextDouble() * 1.5;

      _drawCrater(canvas, Offset(x, y), craterSize, random);
    }
  }

  // Tek bir krater çizimi
  void _drawCrater(
    Canvas canvas,
    Offset position,
    double size,
    math.Random random,
  ) {
    // Krater çukuru
    final craterPaint =
        Paint()
          ..color = const Color(0xFF9E9E9E).withOpacity(0.15)
          ..style = PaintingStyle.fill;

    canvas.drawCircle(position, size, craterPaint);

    // Krater kenarı - yükseltili kısım
    final rimPaint =
        Paint()
          ..color = Colors.white.withOpacity(0.1)
          ..style = PaintingStyle.stroke
          ..strokeWidth = size * 0.3;

    canvas.drawCircle(position, size * 0.85, rimPaint);

    // Krater gölgesi - ışık yönüne göre
    final shadowPaint =
        Paint()
          ..color = Colors.black.withOpacity(0.1)
          ..style = PaintingStyle.fill;

    // Işık soldan geliyorsa, sağ tarafta gölge olur
    final shadowOffset = Offset(size * 0.3, size * 0.3);
    canvas.drawCircle(position + shadowOffset, size * 0.5, shadowPaint);
  }

  // Ay yüzeyindeki ince çizgiler (rilles)
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
