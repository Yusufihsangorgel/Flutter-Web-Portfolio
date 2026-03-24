import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:flutter_web_portfolio/app/core/constants/cinematic_curves.dart';

// ─────────────────────────────────────────────────────────────────────────────
// AnimatedSectionDivider — scroll-triggered decorative line between sections
// ─────────────────────────────────────────────────────────────────────────────

/// Visual style for [AnimatedSectionDivider].
enum DividerStyle {
  /// Simple gradient line.
  gradient,

  /// Dotted line with animated dot opacity.
  dotted,

  /// Sinusoidal wave line.
  wave,

  /// Two parallel lines with an accent-colored gap between them.
  doubleLine,
}

/// A horizontal divider that "draws" itself when scrolled into view.
///
/// Supports four visual styles via [DividerStyle] and an optional center
/// decoration (diamond, dot, or custom icon).
class AnimatedSectionDivider extends StatefulWidget {
  const AnimatedSectionDivider({
    super.key,
    this.style = DividerStyle.gradient,
    this.accent,
    this.thickness = 1.5,
    this.maxWidth = 600,
    this.centerIcon,
    this.centerDot = false,
    this.centerDiamond = false,
    this.padding = const EdgeInsets.symmetric(vertical: 48),
  });

  /// Visual style of the divider line.
  final DividerStyle style;

  /// Accent color used for the line and glow. Falls back to the current
  /// theme's primary color if unset.
  final Color? accent;

  /// Stroke thickness of the line. Defaults to 1.5.
  final double thickness;

  /// Maximum width the line expands to. Defaults to 600.
  final double maxWidth;

  /// Optional icon widget rendered at the center of the line.
  final IconData? centerIcon;

  /// When true, a small circle dot is rendered at the center.
  final bool centerDot;

  /// When true, a diamond shape is rendered at the center.
  final bool centerDiamond;

  /// Outer padding around the divider.
  final EdgeInsetsGeometry padding;

  @override
  State<AnimatedSectionDivider> createState() => _AnimatedSectionDividerState();
}

class _AnimatedSectionDividerState extends State<AnimatedSectionDivider>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _progress;

  bool _triggered = false;
  ScrollPosition? _scrollPosition;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _progress = CurvedAnimation(
      parent: _controller,
      curve: CinematicCurves.textReveal,
    );

    WidgetsBinding.instance.addPostFrameCallback((_) => _checkVisibility());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _scrollPosition?.removeListener(_checkVisibility);
    _scrollPosition = Scrollable.maybeOf(context)?.position;
    _scrollPosition?.addListener(_checkVisibility);
  }

  @override
  void dispose() {
    _scrollPosition?.removeListener(_checkVisibility);
    _controller.dispose();
    super.dispose();
  }

  void _checkVisibility() {
    if (_triggered || !mounted) return;
    final box = context.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return;

    final pos = box.localToGlobal(Offset.zero);
    final screenH = MediaQuery.sizeOf(context).height;

    if (pos.dy < screenH * 0.9 && pos.dy > -box.size.height) {
      _triggered = true;
      _scrollPosition?.removeListener(_checkVisibility);
      _controller.forward();
    }
  }

  Color get _accent =>
      widget.accent ?? Theme.of(context).colorScheme.primary;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: widget.padding,
      child: Center(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (_, __) {
            final p = _progress.value;
            final currentWidth = widget.maxWidth * p;

            return SizedBox(
              width: currentWidth,
              child: _buildDividerContent(p, currentWidth),
            );
          },
        ),
      ),
    );
  }

  Widget _buildDividerContent(double progress, double width) {
    final hasCenterDecor =
        widget.centerIcon != null ||
        widget.centerDot ||
        widget.centerDiamond;

    if (!hasCenterDecor) {
      return _buildLine(progress, width);
    }

    // Split into left half, center decoration, right half.
    return Row(
      children: [
        Expanded(child: _buildLine(progress, width / 2)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: _buildCenterDecor(progress),
        ),
        Expanded(child: _buildLine(progress, width / 2)),
      ],
    );
  }

  Widget _buildLine(double progress, double width) {
    switch (widget.style) {
      case DividerStyle.gradient:
        return _GradientLine(
          accent: _accent,
          thickness: widget.thickness,
          progress: progress,
        );
      case DividerStyle.dotted:
        return _DottedLine(
          accent: _accent,
          thickness: widget.thickness,
          progress: progress,
        );
      case DividerStyle.wave:
        return _WaveLine(
          accent: _accent,
          thickness: widget.thickness,
          progress: progress,
        );
      case DividerStyle.doubleLine:
        return _DoubleLine(
          accent: _accent,
          thickness: widget.thickness,
          progress: progress,
        );
    }
  }

  Widget _buildCenterDecor(double progress) {
    final opacity = (progress * 3 - 1).clamp(0.0, 1.0); // fade in at ~33%
    final scale = Curves.elasticOut.transform(
      (progress * 2 - 0.5).clamp(0.0, 1.0),
    );

    Widget decor;

    if (widget.centerIcon != null) {
      decor = Icon(widget.centerIcon, color: _accent, size: 18);
    } else if (widget.centerDiamond) {
      decor = Transform.rotate(
        angle: math.pi / 4,
        child: Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: _accent,
            boxShadow: [
              BoxShadow(
                color: _accent.withValues(alpha: 0.5 * opacity),
                blurRadius: 8,
              ),
            ],
          ),
        ),
      );
    } else {
      // centerDot
      decor = Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(
          color: _accent,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: _accent.withValues(alpha: 0.5 * opacity),
              blurRadius: 8,
            ),
          ],
        ),
      );
    }

    return Opacity(
      opacity: opacity,
      child: Transform.scale(scale: scale, child: decor),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Line style widgets
// ─────────────────────────────────────────────────────────────────────────────

class _GradientLine extends StatelessWidget {
  const _GradientLine({
    required this.accent,
    required this.thickness,
    required this.progress,
  });

  final Color accent;
  final double thickness;
  final double progress;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: thickness,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            accent.withValues(alpha: 0),
            accent.withValues(alpha: 0.8 * progress),
            accent.withValues(alpha: 0.8 * progress),
            accent.withValues(alpha: 0),
          ],
          stops: const [0.0, 0.3, 0.7, 1.0],
        ),
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: 0.4 * progress),
            blurRadius: 6,
            spreadRadius: 0,
          ),
        ],
      ),
    );
  }
}

class _DottedLine extends StatelessWidget {
  const _DottedLine({
    required this.accent,
    required this.thickness,
    required this.progress,
  });

  final Color accent;
  final double thickness;
  final double progress;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(double.infinity, thickness + 4),
      painter: _DottedLinePainter(
        color: accent,
        thickness: thickness,
        progress: progress,
      ),
    );
  }
}

class _DottedLinePainter extends CustomPainter {
  _DottedLinePainter({
    required this.color,
    required this.thickness,
    required this.progress,
  });

  final Color color;
  final double thickness;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final dotRadius = thickness;
    final spacing = dotRadius * 4;
    final dotCount = (size.width / spacing).floor();
    final cy = size.height / 2;

    for (var i = 0; i < dotCount; i++) {
      // Stagger dot appearance across progress
      final dotProgress =
          ((progress * dotCount - i) / 1).clamp(0.0, 1.0);
      if (dotProgress <= 0) continue;

      paint.color = color.withValues(alpha: 0.7 * dotProgress);
      final cx = spacing / 2 + i * spacing;
      canvas.drawCircle(Offset(cx, cy), dotRadius * dotProgress, paint);
    }
  }

  @override
  bool shouldRepaint(_DottedLinePainter old) =>
      old.progress != progress || old.color != color;
}

class _WaveLine extends StatelessWidget {
  const _WaveLine({
    required this.accent,
    required this.thickness,
    required this.progress,
  });

  final Color accent;
  final double thickness;
  final double progress;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(double.infinity, 20),
      painter: _WaveLinePainter(
        color: accent,
        thickness: thickness,
        progress: progress,
      ),
    );
  }
}

class _WaveLinePainter extends CustomPainter {
  _WaveLinePainter({
    required this.color,
    required this.thickness,
    required this.progress,
  });

  final Color color;
  final double thickness;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0) return;

    final paint =
        Paint()
          ..color = color.withValues(alpha: 0.7 * progress)
          ..strokeWidth = thickness
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round;

    // Glow layer
    final glowPaint =
        Paint()
          ..color = color.withValues(alpha: 0.2 * progress)
          ..strokeWidth = thickness + 4
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);

    final drawWidth = size.width * progress;
    final amplitude = 4.0;
    final wavelength = 30.0;
    final cy = size.height / 2;

    final path = Path();
    path.moveTo(0, cy);

    for (var x = 0.0; x <= drawWidth; x += 1) {
      final y = cy + math.sin(x / wavelength * 2 * math.pi) * amplitude;
      path.lineTo(x, y);
    }

    canvas.drawPath(path, glowPaint);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_WaveLinePainter old) =>
      old.progress != progress || old.color != color;
}

class _DoubleLine extends StatelessWidget {
  const _DoubleLine({
    required this.accent,
    required this.thickness,
    required this.progress,
  });

  final Color accent;
  final double thickness;
  final double progress;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: thickness * 2 + 4,
      child: Column(
        children: [
          Container(
            height: thickness,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  accent.withValues(alpha: 0),
                  accent.withValues(alpha: 0.4 * progress),
                  accent.withValues(alpha: 0),
                ],
              ),
            ),
          ),
          SizedBox(
            height: 4,
            child: Container(
              margin: EdgeInsets.symmetric(
                horizontal: (1 - progress) * 40,
              ),
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.15 * progress),
                boxShadow: [
                  BoxShadow(
                    color: accent.withValues(alpha: 0.2 * progress),
                    blurRadius: 4,
                  ),
                ],
              ),
            ),
          ),
          Container(
            height: thickness,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  accent.withValues(alpha: 0),
                  accent.withValues(alpha: 0.4 * progress),
                  accent.withValues(alpha: 0),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
