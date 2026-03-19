import 'package:flutter/material.dart';

class GalaxyRingsPainter extends CustomPainter {
  const GalaxyRingsPainter({required this.galaxySize});

  final double galaxySize;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    // Background glow
    final glowPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          Colors.blue[400]!.withValues(alpha: 0.15),
          Colors.blue[400]!.withValues(alpha: 0.05),
          Colors.transparent,
        ],
        stops: const [0.2, 0.6, 1.0],
      ).createShader(
        Rect.fromCircle(center: center, radius: galaxySize * 0.45),
      );

    canvas.drawCircle(center, galaxySize * 0.45, glowPaint);

    // Three orbit rings matching planet radii: 0.2, 0.29, 0.38
    final orbitRadii = [
      galaxySize * 0.2,
      galaxySize * 0.29,
      galaxySize * 0.38,
    ];

    for (int i = 0; i < orbitRadii.length; i++) {
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = i == 0 ? 1.5 : 1.0
        ..color = Colors.blue[400]!.withValues(alpha: 0.3 - i * 0.08);

      canvas.drawCircle(center, orbitRadii[i], paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
