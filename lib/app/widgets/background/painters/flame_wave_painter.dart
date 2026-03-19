import 'dart:math' as math;
import 'package:flutter/material.dart';

// Flame wave effect painter
class FlameWavePainter extends CustomPainter {

  FlameWavePainter({
    required this.time,
    required this.flameWidth,
    required this.flameHeight,
  });
  final double time;
  final double flameWidth;
  final double flameHeight;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path();

    const waveCount = 8;
    final amplitude = flameWidth * 0.3;

    path.moveTo(0, 0);

    // Left edge - wavy, multi-frequency for realism
    for (int i = 0; i < waveCount; i++) {
      final y = i * (flameHeight / waveCount);
      final nextY = (i + 1) * (flameHeight / waveCount);
      final controlY = (y + nextY) / 2;

      final waveOffset =
          math.sin(time * math.pi * 8 + i * 0.8) * amplitude * 0.7 +
          math.sin(time * math.pi * 15 + i * 1.5) * amplitude * 0.3;

      path.quadraticBezierTo(waveOffset.toDouble(), controlY, 0, nextY);
    }

    path.lineTo(flameWidth, flameHeight);

    // Right edge - wavy, phase-shifted from left
    for (int i = waveCount - 1; i >= 0; i--) {
      final y = i * (flameHeight / waveCount);
      final nextY = (i > 0) ? (i - 1) * (flameHeight / waveCount) : 0;
      final controlY = (y + nextY) / 2;

      final waveOffset =
          math.sin(time * math.pi * 8 + i + math.pi) * amplitude * 0.7 +
          math.sin(time * math.pi * 18 + i * 1.2 + math.pi / 2) *
              amplitude *
              0.3;

      path.quadraticBezierTo(
        (flameWidth + waveOffset).toDouble(),
        controlY,
        flameWidth.toDouble(),
        nextY.toDouble(),
      );
    }

    path.close();

    final gradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        Colors.white.withValues(alpha:0.8),
        Colors.yellow.withValues(alpha:0.7),
        Colors.amber.withValues(alpha:0.6),
        Colors.orange.withValues(alpha:0.4),
        Colors.deepOrange.withValues(alpha:0.2),
        Colors.transparent,
      ],
      stops: const [0.0, 0.15, 0.3, 0.5, 0.7, 1.0],
    ).createShader(Rect.fromLTWH(0, 0, flameWidth, flameHeight));

    final paint =
        Paint()
          ..shader = gradient
          ..style = PaintingStyle.fill
          ..blendMode = BlendMode.screen;

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(FlameWavePainter oldDelegate) => oldDelegate.time != time ||
        oldDelegate.flameWidth != flameWidth ||
        oldDelegate.flameHeight != flameHeight;
}
