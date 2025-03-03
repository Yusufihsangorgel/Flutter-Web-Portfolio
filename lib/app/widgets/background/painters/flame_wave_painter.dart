import 'dart:math' as math;
import 'package:flutter/material.dart';

// Alev dalgalanma efekti çizici
class FlameWavePainter extends CustomPainter {
  final double time;
  final double flameWidth;
  final double flameHeight;

  FlameWavePainter({
    required this.time,
    required this.flameWidth,
    required this.flameHeight,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path();

    // Alevin dalgalı kenarları için
    final waveCount = 8; // Daha fazla dalga
    final amplitude = flameWidth * 0.3; // Daha belirgin dalgalar

    // Başlangıç noktası
    path.moveTo(0, 0);

    // Sol kenar - dalgalı
    for (int i = 0; i < waveCount; i++) {
      final y = i * (flameHeight / waveCount);
      final nextY = (i + 1) * (flameHeight / waveCount);
      final controlY = (y + nextY) / 2;

      // Zaman ile değişen dalga - çoklu frekans daha gerçekçi görünüm
      final waveOffset =
          math.sin(time * math.pi * 8 + i * 0.8) * amplitude * 0.7 +
          math.sin(time * math.pi * 15 + i * 1.5) * amplitude * 0.3;

      // Bezier eğrisi ile dalgalı kenar
      path.quadraticBezierTo(waveOffset.toDouble(), controlY, 0, nextY);
    }

    // Alt kenar
    path.lineTo(flameWidth, flameHeight);

    // Sağ kenar - dalgalı
    for (int i = waveCount - 1; i >= 0; i--) {
      final y = i * (flameHeight / waveCount);
      final nextY = (i > 0) ? (i - 1) * (flameHeight / waveCount) : 0;
      final controlY = (y + nextY) / 2;

      // Zaman ile değişen dalga - sol kenardan farklı faz
      final waveOffset =
          math.sin(time * math.pi * 8 + i + math.pi) * amplitude * 0.7 +
          math.sin(time * math.pi * 18 + i * 1.2 + math.pi / 2) *
              amplitude *
              0.3;

      // Bezier eğrisi ile dalgalı kenar
      path.quadraticBezierTo(
        (flameWidth + waveOffset).toDouble(),
        controlY,
        flameWidth.toDouble(),
        nextY.toDouble(),
      );
    }

    path.close();

    // Alev gradyanı - daha parlak ve çeşitli renkler
    final gradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        Colors.white.withOpacity(0.8),
        Colors.yellow.withOpacity(0.7),
        Colors.amber.withOpacity(0.6),
        Colors.orange.withOpacity(0.4),
        Colors.deepOrange.withOpacity(0.2),
        Colors.transparent,
      ],
      stops: const [0.0, 0.15, 0.3, 0.5, 0.7, 1.0],
    ).createShader(Rect.fromLTWH(0, 0, flameWidth, flameHeight));

    // Alev çizimi
    final paint =
        Paint()
          ..shader = gradient
          ..style = PaintingStyle.fill
          ..blendMode = BlendMode.screen;

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(FlameWavePainter oldDelegate) {
    return oldDelegate.time != time ||
        oldDelegate.flameWidth != flameWidth ||
        oldDelegate.flameHeight != flameHeight;
  }
}
