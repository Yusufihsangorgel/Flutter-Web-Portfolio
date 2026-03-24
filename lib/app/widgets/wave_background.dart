import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

// ==========================================================================
// 1. WaveBackground — Layered sine wave animation
// ==========================================================================

/// Renders layered sine waves at the bottom of a section with smooth
/// continuous animation. Each wave has independent amplitude, frequency,
/// phase, and speed. Waves respond subtly to the cursor x-position.
///
/// Wrap in a [SizedBox] or [Positioned.fill] to control size.
class WaveBackground extends StatefulWidget {
  const WaveBackground({
    super.key,
    this.waveCount = 4,
    this.colors,
    this.minAmplitude = 20.0,
    this.maxAmplitude = 50.0,
    this.baseSpeed = 0.3,
    this.height,
  });

  /// Number of overlapping waves (3-5 recommended).
  final int waveCount;

  /// One color per wave. Falls back to an accent-based palette when null.
  final List<Color>? colors;

  /// Minimum wave peak-to-trough amplitude in logical pixels.
  final double minAmplitude;

  /// Maximum wave peak-to-trough amplitude in logical pixels.
  final double maxAmplitude;

  /// Base animation speed multiplier.
  final double baseSpeed;

  /// Explicit height constraint. Uses all available height when null.
  final double? height;

  @override
  State<WaveBackground> createState() => _WaveBackgroundState();
}

class _WaveBackgroundState extends State<WaveBackground>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late final AnimationController _controller;
  double _mouseNormX = 0.0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 60),
    )..repeat();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.hidden ||
        state == AppLifecycleState.paused) {
      _controller.stop();
    } else if (state == AppLifecycleState.resumed) {
      _controller.repeat();
    }
  }

  void _onPointerEvent(PointerEvent event) {
    final w = context.size?.width ?? 1.0;
    _mouseNormX = (event.localPosition.dx / w - 0.5) * 2.0;
  }

  @override
  Widget build(BuildContext context) {
    final defaultColors = [
      const Color(0xFF06B6D4).withValues(alpha: 0.25),
      const Color(0xFF8B5CF6).withValues(alpha: 0.20),
      const Color(0xFF06B6D4).withValues(alpha: 0.15),
      const Color(0xFF8B5CF6).withValues(alpha: 0.10),
      const Color(0xFF06B6D4).withValues(alpha: 0.08),
    ];

    final effectiveColors = widget.colors ??
        defaultColors.take(widget.waveCount).toList();

    Widget painter = ExcludeSemantics(
      child: Listener(
        onPointerHover: _onPointerEvent,
        onPointerMove: _onPointerEvent,
        behavior: HitTestBehavior.translucent,
        child: RepaintBoundary(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (_, __) => CustomPaint(
              painter: _WavePainter(
                animValue: _controller.value,
                waveCount: widget.waveCount,
                colors: effectiveColors,
                minAmplitude: widget.minAmplitude,
                maxAmplitude: widget.maxAmplitude,
                baseSpeed: widget.baseSpeed,
                mouseNormX: _mouseNormX,
              ),
              size: Size.infinite,
            ),
          ),
        ),
      ),
    );

    if (widget.height != null) {
      painter = SizedBox(height: widget.height, child: painter);
    }
    return painter;
  }
}

class _WavePainter extends CustomPainter {
  _WavePainter({
    required this.animValue,
    required this.waveCount,
    required this.colors,
    required this.minAmplitude,
    required this.maxAmplitude,
    required this.baseSpeed,
    required this.mouseNormX,
  });

  final double animValue;
  final int waveCount;
  final List<Color> colors;
  final double minAmplitude;
  final double maxAmplitude;
  final double baseSpeed;
  final double mouseNormX;

  static final _paint = Paint()..style = PaintingStyle.fill;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;

    final t = animValue * math.pi * 2.0;

    for (var i = 0; i < waveCount; i++) {
      final progress = i / waveCount;
      final amplitude =
          minAmplitude + (maxAmplitude - minAmplitude) * (1.0 - progress);
      final frequency = 1.5 + i * 0.4;
      final phaseShift = i * math.pi * 0.6;
      final speed = baseSpeed * (0.7 + i * 0.15);
      final yBase = size.height * (0.55 + progress * 0.12);
      final mouseInfluence = mouseNormX * amplitude * 0.15;

      final path = Path()..moveTo(0, size.height);

      const step = 4.0;
      for (double x = 0; x <= size.width; x += step) {
        final normX = x / size.width;
        final y = yBase +
            math.sin(normX * frequency * math.pi * 2 + t * speed + phaseShift) *
                amplitude +
            math.sin(normX * frequency * 0.5 * math.pi * 2 +
                    t * speed * 0.6 +
                    phaseShift * 1.3) *
                amplitude *
                0.3 +
            mouseInfluence * math.sin(normX * math.pi);
        path.lineTo(x, y);
      }

      path
        ..lineTo(size.width, size.height)
        ..close();

      final color = i < colors.length ? colors[i] : colors.last;
      _paint.shader = ui.Gradient.linear(
        Offset(0, yBase - amplitude),
        Offset(0, size.height),
        [color, color.withValues(alpha: 0.0)],
        [0.0, 1.0],
      );
      canvas.drawPath(path, _paint);
    }
  }

  @override
  bool shouldRepaint(_WavePainter old) =>
      animValue != old.animValue || mouseNormX != old.mouseNormX;
}

// ==========================================================================
// 2. MeshGradientBackground — Animated mesh gradient with Lissajous curves
// ==========================================================================

/// Renders an organic animated mesh gradient using control points that
/// follow independent Lissajous curves. Creates smooth, ambient color
/// fields suitable as a section background.
class MeshGradientBackground extends StatefulWidget {
  const MeshGradientBackground({
    super.key,
    this.colors,
    this.pointCount = 5,
    this.speed = 0.15,
    this.opacity = 0.25,
    this.height,
  });

  /// Gradient colors for each control point. Falls back to a curated
  /// palette when null.
  final List<Color>? colors;

  /// Number of gradient control points (4-6 recommended).
  final int pointCount;

  /// Overall animation speed multiplier. Keep low for ambient effect.
  final double speed;

  /// Global opacity cap for the gradient blobs.
  final double opacity;

  /// Explicit height constraint.
  final double? height;

  @override
  State<MeshGradientBackground> createState() =>
      _MeshGradientBackgroundState();
}

class _MeshGradientBackgroundState extends State<MeshGradientBackground>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 120),
    )..repeat();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.hidden ||
        state == AppLifecycleState.paused) {
      _controller.stop();
    } else if (state == AppLifecycleState.resumed) {
      _controller.repeat();
    }
  }

  @override
  Widget build(BuildContext context) {
    final defaultColors = [
      const Color(0xFF1E0B3E),
      const Color(0xFF2D1055),
      const Color(0xFF0891B2),
      const Color(0xFF06B6D4),
      const Color(0xFF8B5CF6),
      const Color(0xFF451A03),
    ];

    final effectiveColors = widget.colors ??
        defaultColors.take(widget.pointCount).toList();

    Widget painter = ExcludeSemantics(
      child: RepaintBoundary(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (_, __) => CustomPaint(
            painter: _MeshGradientPainter(
              animValue: _controller.value,
              colors: effectiveColors,
              pointCount: widget.pointCount,
              speed: widget.speed,
              opacity: widget.opacity,
            ),
            size: Size.infinite,
          ),
        ),
      ),
    );

    if (widget.height != null) {
      painter = SizedBox(height: widget.height, child: painter);
    }
    return painter;
  }
}

class _MeshGradientPainter extends CustomPainter {
  _MeshGradientPainter({
    required this.animValue,
    required this.colors,
    required this.pointCount,
    required this.speed,
    required this.opacity,
  });

  final double animValue;
  final List<Color> colors;
  final int pointCount;
  final double speed;
  final double opacity;

  static final _blobPaint = Paint()..blendMode = BlendMode.screen;

  /// Lissajous parameter sets per point: (freqX, freqY, phaseX, phaseY).
  static const _lissajousParams = <(double, double, double, double)>[
    (1.0, 2.0, 0.0, 0.5),
    (3.0, 1.0, 1.2, 0.0),
    (2.0, 3.0, 0.8, 1.5),
    (1.0, 3.0, 2.0, 0.3),
    (2.0, 1.0, 0.5, 2.2),
    (3.0, 2.0, 1.8, 1.0),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;

    final t = animValue * math.pi * 2.0 * speed;
    final fullRect = Rect.fromLTWH(0, 0, size.width, size.height);

    for (var i = 0; i < pointCount; i++) {
      final params = _lissajousParams[i % _lissajousParams.length];
      final cx = size.width *
          (0.5 + 0.35 * math.sin(t * params.$1 + params.$3));
      final cy = size.height *
          (0.5 + 0.35 * math.cos(t * params.$2 + params.$4));
      final radius = size.width * (0.35 + 0.1 * math.sin(t * 0.5 + i));

      final color = i < colors.length ? colors[i] : colors.last;
      final effectiveColor = color.withValues(alpha: opacity);

      _blobPaint.shader = ui.Gradient.radial(
        Offset(cx, cy),
        radius,
        [effectiveColor, effectiveColor.withValues(alpha: 0.0)],
        [0.0, 1.0],
      );
      canvas.drawRect(fullRect, _blobPaint);
    }
  }

  @override
  bool shouldRepaint(_MeshGradientPainter old) => animValue != old.animValue;
}

// ==========================================================================
// 3. AuroraBackground — Northern lights shimmer effect
// ==========================================================================

/// Renders flowing aurora-like bands of color that wave and shimmer.
/// Multiple overlapping transparent gradient bands create a dreamy,
/// ethereal background effect.
class AuroraBackground extends StatefulWidget {
  const AuroraBackground({
    super.key,
    this.colors,
    this.bandCount = 5,
    this.speed = 0.2,
    this.opacity = 0.18,
    this.height,
  });

  /// Aurora band colors. Defaults to northern-lights greens/purples/blues.
  final List<Color>? colors;

  /// Number of aurora bands.
  final int bandCount;

  /// Animation speed multiplier.
  final double speed;

  /// Peak opacity for each band.
  final double opacity;

  /// Explicit height constraint.
  final double? height;

  @override
  State<AuroraBackground> createState() => _AuroraBackgroundState();
}

class _AuroraBackgroundState extends State<AuroraBackground>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 90),
    )..repeat();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.hidden ||
        state == AppLifecycleState.paused) {
      _controller.stop();
    } else if (state == AppLifecycleState.resumed) {
      _controller.repeat();
    }
  }

  @override
  Widget build(BuildContext context) {
    final defaultColors = [
      const Color(0xFF00E676), // green
      const Color(0xFF7C4DFF), // purple
      const Color(0xFF00B0FF), // blue
      const Color(0xFF69F0AE), // light green
      const Color(0xFFB388FF), // light purple
    ];

    final effectiveColors = widget.colors ??
        defaultColors.take(widget.bandCount).toList();

    Widget painter = ExcludeSemantics(
      child: RepaintBoundary(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (_, __) => CustomPaint(
            painter: _AuroraPainter(
              animValue: _controller.value,
              colors: effectiveColors,
              bandCount: widget.bandCount,
              speed: widget.speed,
              opacity: widget.opacity,
            ),
            size: Size.infinite,
          ),
        ),
      ),
    );

    if (widget.height != null) {
      painter = SizedBox(height: widget.height, child: painter);
    }
    return painter;
  }
}

class _AuroraPainter extends CustomPainter {
  _AuroraPainter({
    required this.animValue,
    required this.colors,
    required this.bandCount,
    required this.speed,
    required this.opacity,
  });

  final double animValue;
  final List<Color> colors;
  final int bandCount;
  final double speed;
  final double opacity;

  static final _bandPaint = Paint()..style = PaintingStyle.fill;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;

    final t = animValue * math.pi * 2.0;

    for (var i = 0; i < bandCount; i++) {
      final progress = i / bandCount;
      final baseY = size.height * (0.15 + progress * 0.55);
      final bandHeight = size.height * (0.15 + 0.08 * math.sin(t * speed + i));
      final phaseShift = i * math.pi * 0.7;
      final waveSpeed = speed * (0.8 + i * 0.1);

      final path = Path();

      // Top edge of the band — sine wave.
      const step = 4.0;
      final firstY = baseY +
          math.sin(phaseShift + t * waveSpeed) * bandHeight * 0.4 +
          math.sin(phaseShift * 1.3 + t * waveSpeed * 0.7) *
              bandHeight *
              0.2;
      path.moveTo(0, firstY);

      for (var x = step; x <= size.width; x += step) {
        final normX = x / size.width;
        final y = baseY +
            math.sin(normX * math.pi * 2.0 * (1.0 + i * 0.3) +
                    phaseShift +
                    t * waveSpeed) *
                bandHeight *
                0.4 +
            math.sin(normX * math.pi * 3.0 +
                    phaseShift * 1.3 +
                    t * waveSpeed * 0.7) *
                bandHeight *
                0.2;
        path.lineTo(x, y);
      }

      // Bottom edge — offset sine wave (slightly different frequency).
      for (var x = size.width; x >= 0; x -= step) {
        final normX = x / size.width;
        final y = baseY +
            bandHeight +
            math.sin(normX * math.pi * 2.0 * (1.2 + i * 0.25) +
                    phaseShift * 0.9 +
                    t * waveSpeed * 1.1) *
                bandHeight *
                0.3 +
            math.sin(normX * math.pi * 2.5 +
                    phaseShift * 1.1 +
                    t * waveSpeed * 0.5) *
                bandHeight *
                0.15;
        path.lineTo(x, y);
      }
      path.close();

      final color = i < colors.length ? colors[i] : colors.last;

      // Shimmer: pulse the opacity slightly over time.
      final shimmer =
          0.7 + 0.3 * math.sin(t * waveSpeed * 1.5 + i * 1.2);
      final effectiveOpacity = opacity * shimmer;

      _bandPaint.shader = ui.Gradient.linear(
        Offset(0, baseY),
        Offset(0, baseY + bandHeight),
        [
          color.withValues(alpha: effectiveOpacity),
          color.withValues(alpha: effectiveOpacity * 0.3),
        ],
        [0.0, 1.0],
      );

      canvas.drawPath(path, _bandPaint);
    }
  }

  @override
  bool shouldRepaint(_AuroraPainter old) => animValue != old.animValue;
}

// ==========================================================================
// 4. GridBackground — Perspective grid (Tron-like)
// ==========================================================================

/// Renders a receding perspective grid with optional forward scrolling,
/// glowing intersections, and mouse parallax on the vanishing point.
class GridBackground extends StatefulWidget {
  const GridBackground({
    super.key,
    this.lineColor,
    this.glowColor,
    this.horizontalLines = 20,
    this.verticalLines = 16,
    this.perspectiveDepth = 0.6,
    this.scrollSpeed = 0.0,
    this.mouseParallax = true,
    this.lineOpacity = 0.25,
    this.glowIntensity = 0.5,
    this.height,
  });

  /// Color for grid lines. Defaults to cyan.
  final Color? lineColor;

  /// Intersection glow color. Defaults to [lineColor].
  final Color? glowColor;

  /// Number of horizontal (depth) lines.
  final int horizontalLines;

  /// Number of vertical lines.
  final int verticalLines;

  /// Perspective foreshortening factor (0.0 = flat, 1.0 = extreme).
  final double perspectiveDepth;

  /// Forward scroll speed. 0.0 for a static grid.
  final double scrollSpeed;

  /// Whether the vanishing point reacts to mouse position.
  final bool mouseParallax;

  /// Base opacity for grid lines.
  final double lineOpacity;

  /// Brightness of intersection glow (0.0-1.0).
  final double glowIntensity;

  /// Explicit height constraint.
  final double? height;

  @override
  State<GridBackground> createState() => _GridBackgroundState();
}

class _GridBackgroundState extends State<GridBackground>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late final AnimationController _controller;
  Offset _mouseNorm = Offset.zero;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 30),
    )..repeat();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.hidden ||
        state == AppLifecycleState.paused) {
      _controller.stop();
    } else if (state == AppLifecycleState.resumed) {
      _controller.repeat();
    }
  }

  void _onPointerEvent(PointerEvent event) {
    if (!widget.mouseParallax) return;
    final sz = context.size;
    if (sz == null) return;
    _mouseNorm = Offset(
      (event.localPosition.dx / sz.width - 0.5) * 2.0,
      (event.localPosition.dy / sz.height - 0.5) * 2.0,
    );
  }

  @override
  Widget build(BuildContext context) {
    final lineColor = widget.lineColor ?? const Color(0xFF06B6D4);
    final glowColor = widget.glowColor ?? lineColor;

    Widget painter = ExcludeSemantics(
      child: Listener(
        onPointerHover: _onPointerEvent,
        onPointerMove: _onPointerEvent,
        behavior: HitTestBehavior.translucent,
        child: RepaintBoundary(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (_, __) => CustomPaint(
              painter: _GridPainter(
                animValue: _controller.value,
                lineColor: lineColor,
                glowColor: glowColor,
                horizontalLines: widget.horizontalLines,
                verticalLines: widget.verticalLines,
                perspectiveDepth: widget.perspectiveDepth,
                scrollSpeed: widget.scrollSpeed,
                mouseNorm: _mouseNorm,
                lineOpacity: widget.lineOpacity,
                glowIntensity: widget.glowIntensity,
              ),
              size: Size.infinite,
            ),
          ),
        ),
      ),
    );

    if (widget.height != null) {
      painter = SizedBox(height: widget.height, child: painter);
    }
    return painter;
  }
}

class _GridPainter extends CustomPainter {
  _GridPainter({
    required this.animValue,
    required this.lineColor,
    required this.glowColor,
    required this.horizontalLines,
    required this.verticalLines,
    required this.perspectiveDepth,
    required this.scrollSpeed,
    required this.mouseNorm,
    required this.lineOpacity,
    required this.glowIntensity,
  });

  final double animValue;
  final Color lineColor;
  final Color glowColor;
  final int horizontalLines;
  final int verticalLines;
  final double perspectiveDepth;
  final double scrollSpeed;
  final Offset mouseNorm;
  final double lineOpacity;
  final double glowIntensity;

  static final _linePaint = Paint()..style = PaintingStyle.stroke;
  static final _glowPaint = Paint();

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;

    // Vanishing point — centre by default, offset by mouse parallax.
    final vpX = size.width * 0.5 + mouseNorm.dx * size.width * 0.08;
    final vpY = size.height * 0.35 + mouseNorm.dy * size.height * 0.06;
    final vanishingPoint = Offset(vpX, vpY);

    // The bottom edge where the grid meets the viewer.
    final bottomY = size.height;
    final halfSpan = size.width * 0.8;

    // ----- Vertical lines (converge toward vanishing point) -----
    _linePaint.strokeWidth = 0.8;

    for (var i = 0; i <= verticalLines; i++) {
      final frac = i / verticalLines;
      final bottomX = (size.width * 0.5 - halfSpan) + frac * halfSpan * 2.0;

      // Fade lines more at edges.
      final edgeFade =
          1.0 - (frac - 0.5).abs() * 1.2;
      final alpha = (lineOpacity * edgeFade.clamp(0.15, 1.0));
      _linePaint.color = lineColor.withValues(alpha: alpha);
      canvas.drawLine(vanishingPoint, Offset(bottomX, bottomY), _linePaint);
    }

    // ----- Horizontal lines (perspective foreshortening) -----
    final scrollOffset = scrollSpeed > 0 ? animValue : 0.0;

    // Collect intersection points for glow pass.
    final intersections = <Offset>[];

    for (var i = 0; i <= horizontalLines; i++) {
      // Non-linear spacing: lines bunch up near the vanishing point.
      var rawT = i / horizontalLines + scrollOffset;
      rawT = rawT % 1.0;
      // Perspective foreshortening: power curve.
      final t = math.pow(rawT, 1.0 + perspectiveDepth * 2.0).toDouble();
      final y = vpY + (bottomY - vpY) * t;

      // Width at this depth — linearly interpolated between VP and bottom.
      final widthAtDepth = halfSpan * 2.0 * t;
      final leftX = size.width * 0.5 - widthAtDepth * 0.5;
      final rightX = size.width * 0.5 + widthAtDepth * 0.5;

      // Fade lines closer to vanishing point.
      final depthFade = t.clamp(0.05, 1.0);
      _linePaint.color =
          lineColor.withValues(alpha: lineOpacity * depthFade);
      _linePaint.strokeWidth = 0.5 + t * 0.5;
      canvas.drawLine(Offset(leftX, y), Offset(rightX, y), _linePaint);

      // Calculate intersections with vertical lines.
      if (glowIntensity > 0) {
        for (var j = 0; j <= verticalLines; j++) {
          final vFrac = j / verticalLines;
          final bottomVX =
              (size.width * 0.5 - halfSpan) + vFrac * halfSpan * 2.0;
          // Interpolate x along the vertical line at this depth.
          final ix = vpX + (bottomVX - vpX) * t;
          if (ix >= leftX && ix <= rightX) {
            intersections.add(Offset(ix, y));
          }
        }
      }
    }

    // ----- Intersection glow -----
    if (glowIntensity > 0 && intersections.isNotEmpty) {
      for (final pt in intersections) {
        // Distance from VP for depth-based sizing.
        final dFromVP = (pt - vanishingPoint).distance;
        final maxDist = (Offset(size.width * 0.5, bottomY) - vanishingPoint)
            .distance;
        final depthRatio = (dFromVP / maxDist).clamp(0.0, 1.0);
        final glowRadius = 2.0 + depthRatio * 4.0;
        final glowAlpha = glowIntensity * depthRatio * 0.4;

        _glowPaint.shader = ui.Gradient.radial(
          pt,
          glowRadius,
          [
            glowColor.withValues(alpha: glowAlpha),
            glowColor.withValues(alpha: 0.0),
          ],
        );
        canvas.drawCircle(pt, glowRadius, _glowPaint);
      }
    }
  }

  @override
  bool shouldRepaint(_GridPainter old) =>
      animValue != old.animValue ||
      mouseNorm != old.mouseNorm;
}
