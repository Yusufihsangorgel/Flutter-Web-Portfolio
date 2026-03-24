import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';


/// Animated aurora gradient background inspired by the northern lights.
///
/// Renders multiple layered radial gradients with slow, drifting motion.
/// Designed for dark mode hero sections and ambient backgrounds.
///
/// Drop into a [Stack] behind your content:
/// ```dart
/// Stack(
///   children: [
///     const AuroraBackground(),
///     // … your content …
///   ],
/// )
/// ```
class AuroraBackground extends StatefulWidget {
  const AuroraBackground({
    super.key,
    this.speed = 0.3,
    this.colors,
    this.blurSigma = 80.0,
    this.opacity = 0.4,
  });

  /// Animation speed multiplier. Lower = more serene.
  final double speed;

  /// Custom aurora colors. Defaults to cyan/magenta/purple tones.
  final List<Color>? colors;

  /// Gaussian blur applied to the gradient blobs.
  final double blurSigma;

  /// Overall opacity of the aurora effect.
  final double opacity;

  @override
  State<AuroraBackground> createState() => _AuroraBackgroundState();
}

class _AuroraBackgroundState extends State<AuroraBackground>
    with SingleTickerProviderStateMixin {
  late Ticker _ticker;
  double _elapsed = 0.0;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker((elapsed) {
      setState(() => _elapsed = elapsed.inMilliseconds / 1000.0);
    })..start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: IgnorePointer(
        child: Opacity(
          opacity: widget.opacity,
          child: CustomPaint(
            painter: _AuroraPainter(
              elapsed: _elapsed,
              speed: widget.speed,
              colors: widget.colors ?? _defaultColors,
              blurSigma: widget.blurSigma,
            ),
            size: Size.infinite,
          ),
        ),
      ),
    );
  }

  static const _defaultColors = [
    Color(0xFF00D4FF), // cyan
    Color(0xFF7B2FBE), // purple
    Color(0xFFFF006E), // magenta
    Color(0xFF00FFB2), // teal green
    Color(0xFF4169E1), // royal blue
  ];
}

class _AuroraPainter extends CustomPainter {
  _AuroraPainter({
    required this.elapsed,
    required this.speed,
    required this.colors,
    required this.blurSigma,
  });

  final double elapsed;
  final double speed;
  final List<Color> colors;
  final double blurSigma;

  @override
  void paint(Canvas canvas, Size size) {
    final t = elapsed * speed;

    // Draw 4-5 drifting gradient blobs
    for (int i = 0; i < colors.length; i++) {
      final phase = i * math.pi * 2 / colors.length;
      final cx = size.width * (0.3 + 0.4 * math.sin(t * 0.3 + phase));
      final cy = size.height * (0.2 + 0.3 * math.cos(t * 0.2 + phase * 1.3));
      final radius = size.width * (0.3 + 0.1 * math.sin(t * 0.5 + phase));

      final paint = Paint()
        ..shader = ui.Gradient.radial(
          Offset(cx, cy),
          radius,
          [
            colors[i].withValues(alpha: 0.6),
            colors[i].withValues(alpha: 0.0),
          ],
          [0.0, 1.0],
        )
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, blurSigma);

      canvas.drawCircle(Offset(cx, cy), radius, paint);
    }
  }

  @override
  bool shouldRepaint(_AuroraPainter old) => elapsed != old.elapsed;
}
