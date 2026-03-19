import 'package:flutter/material.dart';

/// Custom painter that draws the galaxy rings background effect.
class GalaxyRingsPainter extends CustomPainter {
  final double galaxySize;

  const GalaxyRingsPainter({required this.galaxySize});

  @override
  void paint(Canvas canvas, Size size) {
    // Background glowing galaxy effect
    final Paint galaxyPaint =
        Paint()
          ..shader = RadialGradient(
            colors: [
              Colors.blue[400]!.withOpacity(0.2),
              Colors.blue[400]!.withOpacity(0.1),
              Colors.blue[400]!.withOpacity(0.05),
              Colors.transparent,
            ],
            stops: const [0.2, 0.5, 0.8, 1.0],
          ).createShader(
            Rect.fromCircle(
              center: Offset(size.width / 2, size.height / 2),
              radius: galaxySize / 2,
            ),
          );

    // Draw the galaxy
    canvas.drawCircle(
      Offset(size.width / 2, size.height / 2),
      galaxySize / 2,
      galaxyPaint,
    );

    // Orbits - the main orbit where skills reside is more prominent
    final double mainOrbitRadius = galaxySize * 0.35;
    final Paint mainOrbitPaint =
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0
          ..color = Colors.blue[400]!.withOpacity(0.5);

    canvas.drawCircle(
      Offset(size.width / 2, size.height / 2),
      mainOrbitRadius,
      mainOrbitPaint,
    );

    // Additional decorative rings
    for (int i = 0; i < 4; i++) {
      // Draw 4 different rings outside the main orbit
      double radius;
      if (i < 2) {
        // Inner rings
        radius = galaxySize * (0.15 + i * 0.1);
      } else {
        // Outer rings
        radius = galaxySize * (0.45 + (i - 2) * 0.08);
      }

      // Don't redraw the main orbit
      if ((radius - mainOrbitRadius).abs() < 0.01) continue;

      final Paint ringPaint =
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.0
            ..color = Colors.white.withOpacity(0.2);

      canvas.drawCircle(
        Offset(size.width / 2, size.height / 2),
        radius,
        ringPaint,
      );
    }

    // Star drawings removed - relies on CosmicBackground
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
