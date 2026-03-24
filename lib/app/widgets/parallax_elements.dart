import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

// ---------------------------------------------------------------------------
// FloatingOrbs — soft glowing circles that drift slowly
// ---------------------------------------------------------------------------

/// Renders soft, glowing circles that drift continuously across the canvas.
/// Size and density can be tuned per depth layer.
class FloatingOrbs extends StatefulWidget {
  const FloatingOrbs({
    super.key,
    this.orbCount = 6,
    this.color = const Color(0xFF06B6D4),
    this.opacity = 0.25,
    this.minRadius = 30.0,
    this.maxRadius = 120.0,
    this.driftSpeed = 0.3,
    this.seed = 0,
  });

  final int orbCount;
  final Color color;
  final double opacity;
  final double minRadius;
  final double maxRadius;
  final double driftSpeed;
  final int seed;

  @override
  State<FloatingOrbs> createState() => _FloatingOrbsState();
}

class _FloatingOrbsState extends State<FloatingOrbs>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 60),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => RepaintBoundary(
    child: AnimatedBuilder(
      animation: _controller,
      builder: (_, __) => CustomPaint(
        painter: _FloatingOrbsPainter(
          orbCount: widget.orbCount,
          color: widget.color,
          opacity: widget.opacity,
          minRadius: widget.minRadius,
          maxRadius: widget.maxRadius,
          driftSpeed: widget.driftSpeed,
          time: _controller.value,
          seed: widget.seed,
        ),
        size: Size.infinite,
      ),
    ),
  );
}

class _FloatingOrbsPainter extends CustomPainter {
  _FloatingOrbsPainter({
    required this.orbCount,
    required this.color,
    required this.opacity,
    required this.minRadius,
    required this.maxRadius,
    required this.driftSpeed,
    required this.time,
    required this.seed,
  });

  final int orbCount;
  final Color color;
  final double opacity;
  final double minRadius;
  final double maxRadius;
  final double driftSpeed;
  final double time;
  final int seed;

  static final _paint = Paint();

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;

    final rng = math.Random(seed);
    final t = time * math.pi * 2;

    for (var i = 0; i < orbCount; i++) {
      // Stable random parameters per orb.
      final baseX = rng.nextDouble();
      final baseY = rng.nextDouble();
      final radiusFrac = rng.nextDouble();
      final phaseX = rng.nextDouble() * math.pi * 2;
      final phaseY = rng.nextDouble() * math.pi * 2;
      final freqX = 0.3 + rng.nextDouble() * 0.5;
      final freqY = 0.2 + rng.nextDouble() * 0.4;

      final radius = minRadius + radiusFrac * (maxRadius - minRadius);
      final cx = size.width * (baseX + 0.08 * math.sin(t * freqX + phaseX));
      final cy = size.height * (baseY + 0.06 * math.cos(t * freqY + phaseY));

      _paint.shader = ui.Gradient.radial(
        Offset(cx, cy),
        radius,
        [
          color.withValues(alpha: opacity * 0.8),
          color.withValues(alpha: opacity * 0.2),
          color.withValues(alpha: 0),
        ],
        [0.0, 0.5, 1.0],
      );
      canvas.drawCircle(Offset(cx, cy), radius, _paint);
    }
  }

  @override
  bool shouldRepaint(_FloatingOrbsPainter old) =>
      time != old.time || color != old.color || opacity != old.opacity;
}

// ---------------------------------------------------------------------------
// GeometricShapes — rotating wireframe shapes with thin stroke
// ---------------------------------------------------------------------------

/// Renders slowly rotating wireframe geometric shapes (triangles, hexagons,
/// circles) with thin strokes for a premium cinematic look.
class GeometricShapes extends StatefulWidget {
  const GeometricShapes({
    super.key,
    this.shapeCount = 8,
    this.color = const Color(0xFF06B6D4),
    this.opacity = 0.15,
    this.strokeWidth = 0.8,
    this.minSize = 20.0,
    this.maxSize = 80.0,
    this.rotationSpeed = 0.4,
    this.seed = 0,
  });

  final int shapeCount;
  final Color color;
  final double opacity;
  final double strokeWidth;
  final double minSize;
  final double maxSize;
  final double rotationSpeed;
  final int seed;

  @override
  State<GeometricShapes> createState() => _GeometricShapesState();
}

class _GeometricShapesState extends State<GeometricShapes>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 40),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => RepaintBoundary(
    child: AnimatedBuilder(
      animation: _controller,
      builder: (_, __) => CustomPaint(
        painter: _GeometricShapesPainter(
          shapeCount: widget.shapeCount,
          color: widget.color,
          opacity: widget.opacity,
          strokeWidth: widget.strokeWidth,
          minSize: widget.minSize,
          maxSize: widget.maxSize,
          rotationSpeed: widget.rotationSpeed,
          time: _controller.value,
          seed: widget.seed,
        ),
        size: Size.infinite,
      ),
    ),
  );
}

class _GeometricShapesPainter extends CustomPainter {
  _GeometricShapesPainter({
    required this.shapeCount,
    required this.color,
    required this.opacity,
    required this.strokeWidth,
    required this.minSize,
    required this.maxSize,
    required this.rotationSpeed,
    required this.time,
    required this.seed,
  });

  final int shapeCount;
  final Color color;
  final double opacity;
  final double strokeWidth;
  final double minSize;
  final double maxSize;
  final double rotationSpeed;
  final double time;
  final int seed;

  static final _paint = Paint()..style = PaintingStyle.stroke;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;

    final rng = math.Random(seed);
    final t = time * math.pi * 2;

    _paint
      ..color = color.withValues(alpha: opacity)
      ..strokeWidth = strokeWidth;

    for (var i = 0; i < shapeCount; i++) {
      final cx = rng.nextDouble() * size.width;
      final cy = rng.nextDouble() * size.height;
      final shapeSize = minSize + rng.nextDouble() * (maxSize - minSize);
      final shapeType = rng.nextInt(3); // 0=triangle, 1=hexagon, 2=circle
      final rotDir = rng.nextBool() ? 1.0 : -1.0;
      final phase = rng.nextDouble() * math.pi * 2;
      final speed = (0.5 + rng.nextDouble() * 0.8) * rotationSpeed;

      // Slow drift.
      final driftX = 0.02 * math.sin(t * 0.3 + phase) * size.width;
      final driftY = 0.015 * math.cos(t * 0.25 + phase) * size.height;

      final angle = t * speed * rotDir + phase;

      canvas
        ..save()
        ..translate(cx + driftX, cy + driftY)
        ..rotate(angle);

      switch (shapeType) {
        case 0:
          _drawRegularPolygon(canvas, shapeSize / 2, 3);
        case 1:
          _drawRegularPolygon(canvas, shapeSize / 2, 6);
        case 2:
          canvas.drawCircle(Offset.zero, shapeSize / 2, _paint);
      }

      canvas.restore();
    }
  }

  void _drawRegularPolygon(Canvas canvas, double radius, int sides) {
    final path = Path();
    for (var i = 0; i <= sides; i++) {
      final angle = (i * 2 * math.pi / sides) - math.pi / 2;
      final x = radius * math.cos(angle);
      final y = radius * math.sin(angle);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    canvas.drawPath(path, _paint);
  }

  @override
  bool shouldRepaint(_GeometricShapesPainter old) =>
      time != old.time || color != old.color || opacity != old.opacity;
}

// ---------------------------------------------------------------------------
// GradientBlobs — large blurred gradient blobs for atmospheric depth
// ---------------------------------------------------------------------------

/// Renders large, softly blurred gradient blobs that drift slowly, creating
/// a cinematic atmospheric depth effect.
class GradientBlobs extends StatefulWidget {
  const GradientBlobs({
    super.key,
    this.blobCount = 3,
    this.colors = const [Color(0xFF1E0B3E), Color(0xFF0891B2)],
    this.opacity = 0.2,
    this.minRadius = 150.0,
    this.maxRadius = 400.0,
    this.seed = 0,
  });

  final int blobCount;
  final List<Color> colors;
  final double opacity;
  final double minRadius;
  final double maxRadius;
  final int seed;

  @override
  State<GradientBlobs> createState() => _GradientBlobsState();
}

class _GradientBlobsState extends State<GradientBlobs>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 50),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => RepaintBoundary(
    child: AnimatedBuilder(
      animation: _controller,
      builder: (_, __) => CustomPaint(
        painter: _GradientBlobsPainter(
          blobCount: widget.blobCount,
          colors: widget.colors,
          opacity: widget.opacity,
          minRadius: widget.minRadius,
          maxRadius: widget.maxRadius,
          time: _controller.value,
          seed: widget.seed,
        ),
        size: Size.infinite,
      ),
    ),
  );
}

class _GradientBlobsPainter extends CustomPainter {
  _GradientBlobsPainter({
    required this.blobCount,
    required this.colors,
    required this.opacity,
    required this.minRadius,
    required this.maxRadius,
    required this.time,
    required this.seed,
  });

  final int blobCount;
  final List<Color> colors;
  final double opacity;
  final double minRadius;
  final double maxRadius;
  final double time;
  final int seed;

  static final _paint = Paint()..blendMode = BlendMode.screen;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty || colors.isEmpty) return;

    final rng = math.Random(seed);
    final t = time * math.pi * 2;
    final fullRect = Rect.fromLTWH(0, 0, size.width, size.height);

    for (var i = 0; i < blobCount; i++) {
      final baseX = rng.nextDouble();
      final baseY = rng.nextDouble();
      final radiusFrac = rng.nextDouble();
      final phaseX = rng.nextDouble() * math.pi * 2;
      final phaseY = rng.nextDouble() * math.pi * 2;
      final freqX = 0.15 + rng.nextDouble() * 0.25;
      final freqY = 0.1 + rng.nextDouble() * 0.2;

      final radius = minRadius + radiusFrac * (maxRadius - minRadius);
      final cx = size.width * (baseX + 0.1 * math.sin(t * freqX + phaseX));
      final cy = size.height * (baseY + 0.08 * math.cos(t * freqY + phaseY));

      final blobColor = colors[i % colors.length];

      _paint.shader = ui.Gradient.radial(
        Offset(cx, cy),
        radius,
        [
          blobColor.withValues(alpha: opacity),
          blobColor.withValues(alpha: opacity * 0.3),
          blobColor.withValues(alpha: 0),
        ],
        [0.0, 0.4, 1.0],
      );
      canvas.drawRect(fullRect, _paint);
    }
  }

  @override
  bool shouldRepaint(_GradientBlobsPainter old) =>
      time != old.time ||
      opacity != old.opacity ||
      colors.length != old.colors.length;
}

// ---------------------------------------------------------------------------
// GridLines — subtle perspective grid receding into distance
// ---------------------------------------------------------------------------

/// Renders a subtle perspective grid that gives the impression of a floor
/// plane receding into the distance, with configurable vanishing point.
class GridLines extends StatefulWidget {
  const GridLines({
    super.key,
    this.color = const Color(0xFF06B6D4),
    this.opacity = 0.06,
    this.strokeWidth = 0.5,
    this.horizontalLines = 12,
    this.verticalLines = 16,
    this.perspectiveStrength = 0.6,
    this.driftSpeed = 0.15,
  });

  final Color color;
  final double opacity;
  final double strokeWidth;
  final int horizontalLines;
  final int verticalLines;
  final double perspectiveStrength;
  final double driftSpeed;

  @override
  State<GridLines> createState() => _GridLinesState();
}

class _GridLinesState extends State<GridLines>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 30),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => RepaintBoundary(
    child: AnimatedBuilder(
      animation: _controller,
      builder: (_, __) => CustomPaint(
        painter: _GridLinesPainter(
          color: widget.color,
          opacity: widget.opacity,
          strokeWidth: widget.strokeWidth,
          horizontalLines: widget.horizontalLines,
          verticalLines: widget.verticalLines,
          perspectiveStrength: widget.perspectiveStrength,
          time: _controller.value,
          driftSpeed: widget.driftSpeed,
        ),
        size: Size.infinite,
      ),
    ),
  );
}

class _GridLinesPainter extends CustomPainter {
  _GridLinesPainter({
    required this.color,
    required this.opacity,
    required this.strokeWidth,
    required this.horizontalLines,
    required this.verticalLines,
    required this.perspectiveStrength,
    required this.time,
    required this.driftSpeed,
  });

  final Color color;
  final double opacity;
  final double strokeWidth;
  final int horizontalLines;
  final int verticalLines;
  final double perspectiveStrength;
  final double time;
  final double driftSpeed;

  static final _paint = Paint()..style = PaintingStyle.stroke;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;

    _paint
      ..strokeWidth = strokeWidth
      ..color = color.withValues(alpha: opacity);

    final vanishX = size.width / 2;
    final vanishY = size.height * 0.35;
    final t = time * math.pi * 2 * driftSpeed;

    // Horizontal lines — exponentially spaced for perspective.
    for (var i = 0; i < horizontalLines; i++) {
      // Normalized position 0..1, exponentially distributed.
      final frac = math.pow((i + 1) / horizontalLines, 1.8).toDouble();
      final y = vanishY + (size.height - vanishY) * frac;

      // Lines narrow toward vanishing point.
      final narrowFactor = 1.0 - (1.0 - frac) * perspectiveStrength;
      final halfWidth = size.width / 2 * narrowFactor;
      final xOffset = math.sin(t + i * 0.3) * 3.0;

      // Fade by distance from viewer.
      _paint.color = color.withValues(alpha: opacity * frac);

      canvas.drawLine(
        Offset(vanishX - halfWidth + xOffset, y),
        Offset(vanishX + halfWidth + xOffset, y),
        _paint,
      );
    }

    // Vertical lines — converge toward vanishing point.
    for (var i = 0; i < verticalLines; i++) {
      final frac = i / (verticalLines - 1);
      final bottomX = size.width * frac;
      final topX = vanishX + (bottomX - vanishX) * (1.0 - perspectiveStrength);
      final yOffset = math.cos(t + i * 0.4) * 2.0;

      _paint.color = color.withValues(alpha: opacity * 0.6);

      canvas.drawLine(
        Offset(topX, vanishY + yOffset),
        Offset(bottomX, size.height),
        _paint,
      );
    }
  }

  @override
  bool shouldRepaint(_GridLinesPainter old) =>
      time != old.time || color != old.color || opacity != old.opacity;
}

// ---------------------------------------------------------------------------
// FloatingDots — small dots scattered across layers
// ---------------------------------------------------------------------------

/// Renders small dots scattered across the canvas at various densities.
/// Each dot drifts slowly and has a subtle glow.
class FloatingDots extends StatefulWidget {
  const FloatingDots({
    super.key,
    this.dotCount = 40,
    this.color = const Color(0xFF06B6D4),
    this.opacity = 0.3,
    this.minRadius = 0.5,
    this.maxRadius = 2.5,
    this.driftSpeed = 0.2,
    this.glowRadius = 6.0,
    this.seed = 0,
  });

  final int dotCount;
  final Color color;
  final double opacity;
  final double minRadius;
  final double maxRadius;
  final double driftSpeed;
  final double glowRadius;
  final int seed;

  @override
  State<FloatingDots> createState() => _FloatingDotsState();
}

class _FloatingDotsState extends State<FloatingDots>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 45),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => RepaintBoundary(
    child: AnimatedBuilder(
      animation: _controller,
      builder: (_, __) => CustomPaint(
        painter: _FloatingDotsPainter(
          dotCount: widget.dotCount,
          color: widget.color,
          opacity: widget.opacity,
          minRadius: widget.minRadius,
          maxRadius: widget.maxRadius,
          driftSpeed: widget.driftSpeed,
          glowRadius: widget.glowRadius,
          time: _controller.value,
          seed: widget.seed,
        ),
        size: Size.infinite,
      ),
    ),
  );
}

class _FloatingDotsPainter extends CustomPainter {
  _FloatingDotsPainter({
    required this.dotCount,
    required this.color,
    required this.opacity,
    required this.minRadius,
    required this.maxRadius,
    required this.driftSpeed,
    required this.glowRadius,
    required this.time,
    required this.seed,
  });

  final int dotCount;
  final Color color;
  final double opacity;
  final double minRadius;
  final double maxRadius;
  final double driftSpeed;
  final double glowRadius;
  final double time;
  final int seed;

  static final _dotPaint = Paint();
  static final _glowPaint = Paint();

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;

    final rng = math.Random(seed);
    final t = time * math.pi * 2;

    for (var i = 0; i < dotCount; i++) {
      final baseX = rng.nextDouble();
      final baseY = rng.nextDouble();
      final radiusFrac = rng.nextDouble();
      final phase = rng.nextDouble() * math.pi * 2;
      final freqX = 0.2 + rng.nextDouble() * 0.6;
      final freqY = 0.15 + rng.nextDouble() * 0.5;
      final dotOpacity = (0.3 + rng.nextDouble() * 0.7) * opacity;

      final radius = minRadius + radiusFrac * (maxRadius - minRadius);

      // Wrap-aware drift.
      final cx = (baseX + driftSpeed * 0.05 * math.sin(t * freqX + phase)) *
          size.width;
      final cy = (baseY + driftSpeed * 0.04 * math.cos(t * freqY + phase)) *
          size.height;

      // Core dot.
      _dotPaint.color = color.withValues(alpha: dotOpacity);
      canvas.drawCircle(Offset(cx, cy), radius, _dotPaint);

      // Glow for larger dots.
      if (radius > 1.5) {
        _glowPaint.shader = ui.Gradient.radial(
          Offset(cx, cy),
          glowRadius,
          [
            color.withValues(alpha: dotOpacity * 0.3),
            color.withValues(alpha: 0),
          ],
        );
        canvas.drawCircle(Offset(cx, cy), glowRadius, _glowPaint);
      }
    }
  }

  @override
  bool shouldRepaint(_FloatingDotsPainter old) =>
      time != old.time || color != old.color || opacity != old.opacity;
}
