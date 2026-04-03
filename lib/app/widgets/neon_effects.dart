import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_web_portfolio/app/core/constants/app_colors.dart';

// ─── NeonText ───────────────────────────────────────────────────────────────

/// Text with layered neon tube glow effect.
///
/// Multiple text shadows create the look of a real neon tube. Optionally
/// animates a subtle brightness pulse or a stochastic flicker.
class NeonText extends StatefulWidget {
  const NeonText({
    super.key,
    required this.text,
    this.style,
    this.glowColor,
    this.intensity = 1.0,
    this.blurRadius = 20.0,
    this.animated = true,
    this.flickering = false,
    this.textAlign,
    this.maxLines,
    this.overflow,
  });

  final String text;
  final TextStyle? style;

  /// Base glow color. Falls back to [AppColors.accent].
  final Color? glowColor;

  /// Overall glow strength multiplier (0.0 – 2.0 recommended).
  final double intensity;

  /// Outer blur radius for the largest shadow layer.
  final double blurRadius;

  /// Enable the breathing pulse animation.
  final bool animated;

  /// Enable stochastic neon-tube flicker (implies [animated]).
  final bool flickering;

  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;

  @override
  State<NeonText> createState() => _NeonTextState();
}

class _NeonTextState extends State<NeonText>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  final math.Random _rng = math.Random();
  bool _flickerListenerAdded = false;

  /// Current flicker opacity multiplier (1.0 = fully on).
  double _flickerValue = 1.0;

  @override
  void initState() {
    super.initState();
    final shouldAnimate = widget.animated || widget.flickering;
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );
    if (shouldAnimate) {
      _ctrl.repeat(reverse: true);
    }
    if (widget.flickering) {
      _ctrl.addListener(_updateFlicker);
      _flickerListenerAdded = true;
    }
  }

  void _updateFlicker() {
    // Occasionally dip brightness to simulate tube instability.
    if (_rng.nextDouble() < 0.06) {
      _flickerValue = 0.4 + _rng.nextDouble() * 0.3;
    } else {
      _flickerValue = 1.0;
    }
  }

  @override
  void dispose() {
    if (_flickerListenerAdded) {
      _ctrl.removeListener(_updateFlicker);
    }
    _ctrl.dispose();
    super.dispose();
  }

  List<Shadow> _buildShadows(Color color, double pulse) {
    final effectiveIntensity = widget.intensity * pulse * _flickerValue;
    return [
      // Inner core — tight white-ish glow
      Shadow(
        color: Color.lerp(color, Colors.white, 0.6)!
            .withValues(alpha: (0.9 * effectiveIntensity).clamp(0.0, 1.0)),
        blurRadius: widget.blurRadius * 0.15,
      ),
      // Mid glow
      Shadow(
        color:
            color.withValues(alpha: (0.7 * effectiveIntensity).clamp(0.0, 1.0)),
        blurRadius: widget.blurRadius * 0.5,
      ),
      // Outer glow
      Shadow(
        color:
            color.withValues(alpha: (0.4 * effectiveIntensity).clamp(0.0, 1.0)),
        blurRadius: widget.blurRadius,
      ),
      // Haze
      Shadow(
        color:
            color.withValues(alpha: (0.15 * effectiveIntensity).clamp(0.0, 1.0)),
        blurRadius: widget.blurRadius * 1.8,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.glowColor ?? AppColors.accent;
    final shouldAnimate = widget.animated || widget.flickering;

    if (!shouldAnimate) {
      return RepaintBoundary(
        child: Text(
          widget.text,
          style: (widget.style ?? const TextStyle()).copyWith(
            shadows: _buildShadows(color, 1.0),
          ),
          textAlign: widget.textAlign,
          maxLines: widget.maxLines,
          overflow: widget.overflow,
        ),
      );
    }

    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (_, __) {
          // Smooth sine-based pulse between 0.75 and 1.0
          final pulse =
              0.75 + 0.25 * math.sin(_ctrl.value * math.pi);
          return Text(
            widget.text,
            style: (widget.style ?? const TextStyle()).copyWith(
              shadows: _buildShadows(color, pulse),
            ),
            textAlign: widget.textAlign,
            maxLines: widget.maxLines,
            overflow: widget.overflow,
          );
        },
      ),
    );
  }
}

// ─── NeonLine ───────────────────────────────────────────────────────────────

/// Animated neon line / divider.
///
/// A light hotspot travels along the line while the whole line pulses gently.
class NeonLine extends StatefulWidget {
  const NeonLine({
    super.key,
    this.width,
    this.height,
    this.color,
    this.thickness = 2.0,
    this.direction = Axis.horizontal,
    this.animated = true,
    this.intensity = 1.0,
    this.blurRadius = 12.0,
    this.travelDuration = const Duration(milliseconds: 3000),
  });

  /// Explicit width. If null, expands to available space (horizontal).
  final double? width;

  /// Explicit height. If null, expands to available space (vertical).
  final double? height;

  final Color? color;
  final double thickness;
  final Axis direction;
  final bool animated;
  final double intensity;
  final double blurRadius;
  final Duration travelDuration;

  @override
  State<NeonLine> createState() => _NeonLineState();
}

class _NeonLineState extends State<NeonLine>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: widget.travelDuration);
    if (widget.animated) _ctrl.repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.color ?? AppColors.accent;
    final isHorizontal = widget.direction == Axis.horizontal;

    final sizedBox = SizedBox(
      width: isHorizontal ? (widget.width ?? double.infinity) : widget.thickness,
      height: isHorizontal ? widget.thickness : (widget.height ?? double.infinity),
    );

    return RepaintBoundary(
      child: widget.animated
          ? AnimatedBuilder(
              animation: _ctrl,
              builder: (_, __) => CustomPaint(
                painter: _NeonLinePainter(
                  color: color,
                  progress: _ctrl.value,
                  intensity: widget.intensity,
                  blurRadius: widget.blurRadius,
                  direction: widget.direction,
                ),
                child: sizedBox,
              ),
            )
          : CustomPaint(
              painter: _NeonLinePainter(
                color: color,
                progress: 0.5,
                intensity: widget.intensity,
                blurRadius: widget.blurRadius,
                direction: widget.direction,
                isStatic: true,
              ),
              child: sizedBox,
            ),
    );
  }
}

class _NeonLinePainter extends CustomPainter {
  _NeonLinePainter({
    required this.color,
    required this.progress,
    required this.intensity,
    required this.blurRadius,
    required this.direction,
    this.isStatic = false,
  });

  final Color color;
  final double progress;
  final double intensity;
  final double blurRadius;
  final Axis direction;
  final bool isStatic;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;

    final isHorizontal = direction == Axis.horizontal;
    final length = isHorizontal ? size.width : size.height;

    // Base line glow
    final basePaint = Paint()
      ..color = color.withValues(alpha: 0.25 * intensity)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, blurRadius * 0.5);
    if (isHorizontal) {
      canvas.drawLine(
        Offset(0, size.height / 2),
        Offset(size.width, size.height / 2),
        basePaint,
      );
    } else {
      canvas.drawLine(
        Offset(size.width / 2, 0),
        Offset(size.width / 2, size.height),
        basePaint,
      );
    }

    // Solid core line
    final corePaint = Paint()
      ..color = color.withValues(alpha: 0.5 * intensity)
      ..strokeWidth = 1.0;
    if (isHorizontal) {
      canvas.drawLine(
        Offset(0, size.height / 2),
        Offset(size.width, size.height / 2),
        corePaint,
      );
    } else {
      canvas.drawLine(
        Offset(size.width / 2, 0),
        Offset(size.width / 2, size.height),
        corePaint,
      );
    }

    if (isStatic) return;

    // Travelling light hotspot
    final hotspotPos = progress * length;
    final hotspotRadius = length * 0.15;

    final hotspotPaint = Paint()
      ..shader = (isHorizontal
              ? LinearGradient(
                  begin: Alignment(-1 + 2 * ((hotspotPos - hotspotRadius) / length).clamp(0.0, 1.0), 0),
                  end: Alignment(-1 + 2 * ((hotspotPos + hotspotRadius) / length).clamp(0.0, 1.0), 0),
                  colors: [
                    Colors.transparent,
                    color.withValues(alpha: 0.9 * intensity),
                    Color.lerp(color, Colors.white, 0.5)!
                        .withValues(alpha: intensity),
                    color.withValues(alpha: 0.9 * intensity),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.3, 0.5, 0.7, 1.0],
                )
              : LinearGradient(
                  begin: Alignment(0, -1 + 2 * ((hotspotPos - hotspotRadius) / length).clamp(0.0, 1.0)),
                  end: Alignment(0, -1 + 2 * ((hotspotPos + hotspotRadius) / length).clamp(0.0, 1.0)),
                  colors: [
                    Colors.transparent,
                    color.withValues(alpha: 0.9 * intensity),
                    Color.lerp(color, Colors.white, 0.5)!
                        .withValues(alpha: intensity),
                    color.withValues(alpha: 0.9 * intensity),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.3, 0.5, 0.7, 1.0],
                ))
          .createShader(Offset.zero & size);

    final hotspotGlowPaint = Paint()
      ..shader = hotspotPaint.shader
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, blurRadius);

    if (isHorizontal) {
      final start = Offset(0, size.height / 2);
      final end = Offset(size.width, size.height / 2);
      canvas
        ..drawLine(start, end, hotspotGlowPaint)
        ..drawLine(start, end, hotspotPaint);
    } else {
      final start = Offset(size.width / 2, 0);
      final end = Offset(size.width / 2, size.height);
      canvas
        ..drawLine(start, end, hotspotGlowPaint)
        ..drawLine(start, end, hotspotPaint);
    }
  }

  @override
  bool shouldRepaint(_NeonLinePainter old) =>
      progress != old.progress ||
      color != old.color ||
      intensity != old.intensity;
}

// ─── NeonBorder ─────────────────────────────────────────────────────────────

/// Container with a rotating gradient neon border.
///
/// Uses [CustomPainter] to sweep a conic gradient around the perimeter.
/// Glow intensifies on hover.
class NeonBorder extends StatefulWidget {
  const NeonBorder({
    super.key,
    required this.child,
    this.color,
    this.secondaryColor,
    this.borderRadius = 12.0,
    this.borderWidth = 2.0,
    this.animated = true,
    this.intensity = 1.0,
    this.blurRadius = 16.0,
    this.rotationDuration = const Duration(milliseconds: 4000),
    this.padding = EdgeInsets.zero,
  });

  final Widget child;
  final Color? color;

  /// Optional secondary color for the gradient sweep. Defaults to the primary
  /// color shifted in hue by 60°.
  final Color? secondaryColor;

  final double borderRadius;
  final double borderWidth;
  final bool animated;
  final double intensity;
  final double blurRadius;
  final Duration rotationDuration;
  final EdgeInsets padding;

  @override
  State<NeonBorder> createState() => _NeonBorderState();
}

class _NeonBorderState extends State<NeonBorder>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  final _hovered = ValueNotifier<bool>(false);

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: widget.rotationDuration);
    if (widget.animated) _ctrl.repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _hovered.dispose();
    super.dispose();
  }

  Color _deriveSecondary(Color primary) {
    final hsl = HSLColor.fromColor(primary);
    return hsl.withHue((hsl.hue + 60) % 360).toColor();
  }

  @override
  Widget build(BuildContext context) {
    final primary = widget.color ?? AppColors.accent;
    final secondary = widget.secondaryColor ?? _deriveSecondary(primary);

    return RepaintBoundary(
      child: MouseRegion(
        onEnter: (_) => _hovered.value = true,
        onExit: (_) => _hovered.value = false,
        child: ValueListenableBuilder<bool>(
          valueListenable: _hovered,
          builder: (_, hovered, child) => AnimatedBuilder(
            animation: _ctrl,
            builder: (_, __) => CustomPaint(
              painter: _NeonBorderPainter(
                primary: primary,
                secondary: secondary,
                angle: _ctrl.value * 2 * math.pi,
                borderRadius: widget.borderRadius,
                borderWidth: widget.borderWidth,
                intensity: widget.intensity * (hovered ? 1.5 : 1.0),
                blurRadius: widget.blurRadius * (hovered ? 1.3 : 1.0),
              ),
              child: Padding(
                padding: EdgeInsets.all(widget.borderWidth) + widget.padding,
                child: child,
              ),
            ),
          ),
          child: widget.child,
        ),
      ),
    );
  }
}

class _NeonBorderPainter extends CustomPainter {
  _NeonBorderPainter({
    required this.primary,
    required this.secondary,
    required this.angle,
    required this.borderRadius,
    required this.borderWidth,
    required this.intensity,
    required this.blurRadius,
  });

  final Color primary;
  final Color secondary;
  final double angle;
  final double borderRadius;
  final double borderWidth;
  final double intensity;
  final double blurRadius;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;

    final rect = Offset.zero & size;
    final rrect = RRect.fromRectAndRadius(
      rect.deflate(borderWidth / 2),
      Radius.circular(borderRadius),
    );

    // Build a sweep gradient rotated by [angle].
    final gradientColors = [
      primary.withValues(alpha: (0.9 * intensity).clamp(0.0, 1.0)),
      secondary.withValues(alpha: (0.6 * intensity).clamp(0.0, 1.0)),
      primary.withValues(alpha: (0.1 * intensity).clamp(0.0, 1.0)),
      secondary.withValues(alpha: (0.6 * intensity).clamp(0.0, 1.0)),
      primary.withValues(alpha: (0.9 * intensity).clamp(0.0, 1.0)),
    ];

    final shader = SweepGradient(
      startAngle: angle,
      endAngle: angle + 2 * math.pi,
      colors: gradientColors,
      stops: const [0.0, 0.25, 0.5, 0.75, 1.0],
      tileMode: TileMode.clamp,
      transform: GradientRotation(angle),
    ).createShader(rect);

    // Outer glow pass
    final glowPaint = Paint()
      ..shader = shader
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderWidth + 4
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, blurRadius);
    canvas.drawRRect(rrect, glowPaint);

    // Crisp border pass
    final borderPaint = Paint()
      ..shader = shader
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderWidth;
    canvas.drawRRect(rrect, borderPaint);
  }

  @override
  bool shouldRepaint(_NeonBorderPainter old) =>
      angle != old.angle ||
      intensity != old.intensity ||
      blurRadius != old.blurRadius ||
      primary != old.primary ||
      secondary != old.secondary;
}

// ─── NeonIcon ───────────────────────────────────────────────────────────────

/// Icon wrapped in layered shadow glow with optional pulse animation.
class NeonIcon extends StatefulWidget {
  const NeonIcon({
    super.key,
    required this.icon,
    this.size = 24.0,
    this.color,
    this.intensity = 1.0,
    this.blurRadius = 16.0,
    this.animated = true,
    this.pulseDuration = const Duration(milliseconds: 2000),
  });

  final IconData icon;
  final double size;
  final Color? color;
  final double intensity;
  final double blurRadius;
  final bool animated;
  final Duration pulseDuration;

  @override
  State<NeonIcon> createState() => _NeonIconState();
}

class _NeonIconState extends State<NeonIcon>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: widget.pulseDuration);
    if (widget.animated) _ctrl.repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.color ?? AppColors.accent;

    Widget buildIcon(double pulse) {
      final effectiveIntensity = widget.intensity * pulse;
      return Container(
        decoration: BoxDecoration(
          boxShadow: [
            // Inner core glow
            BoxShadow(
              color: Color.lerp(color, Colors.white, 0.4)!
                  .withValues(alpha: (0.6 * effectiveIntensity).clamp(0.0, 1.0)),
              blurRadius: widget.blurRadius * 0.3,
              spreadRadius: 0,
            ),
            // Mid glow
            BoxShadow(
              color: color.withValues(
                  alpha: (0.4 * effectiveIntensity).clamp(0.0, 1.0)),
              blurRadius: widget.blurRadius * 0.7,
              spreadRadius: 0,
            ),
            // Outer haze
            BoxShadow(
              color: color.withValues(
                  alpha: (0.15 * effectiveIntensity).clamp(0.0, 1.0)),
              blurRadius: widget.blurRadius,
              spreadRadius: 0,
            ),
          ],
        ),
        child: Icon(
          widget.icon,
          size: widget.size,
          color: Color.lerp(color, Colors.white, 0.3 * effectiveIntensity),
        ),
      );
    }

    if (!widget.animated) {
      return RepaintBoundary(child: buildIcon(1.0));
    }

    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (_, __) {
          final pulse = 0.7 + 0.3 * math.sin(_ctrl.value * math.pi);
          return buildIcon(pulse);
        },
      ),
    );
  }
}

// ─── NeonCard ───────────────────────────────────────────────────────────────

/// Dark card with neon-glow border accents.
///
/// On hover, an inner glow appears and the border brightens. Supports
/// top-only or full border mode.
class NeonCard extends StatefulWidget {
  const NeonCard({
    super.key,
    required this.child,
    this.color,
    this.borderRadius = 12.0,
    this.borderWidth = 2.0,
    this.fullBorder = false,
    this.animated = true,
    this.intensity = 1.0,
    this.blurRadius = 16.0,
    this.backgroundColor,
    this.padding = const EdgeInsets.all(24),
  });

  final Widget child;

  /// Accent neon color. Falls back to [AppColors.accent].
  final Color? color;

  final double borderRadius;
  final double borderWidth;

  /// If true, all four edges glow. Otherwise only the top edge.
  final bool fullBorder;

  final bool animated;
  final double intensity;
  final double blurRadius;
  final Color? backgroundColor;
  final EdgeInsets padding;

  @override
  State<NeonCard> createState() => _NeonCardState();
}

class _NeonCardState extends State<NeonCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  final _hovered = ValueNotifier<bool>(false);

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );
    if (widget.animated) _ctrl.repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _hovered.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accent = widget.color ?? AppColors.accent;
    final bg = widget.backgroundColor ??
        AppColors.backgroundLight.withValues(alpha: 0.45);

    return RepaintBoundary(
      child: MouseRegion(
        onEnter: (_) => _hovered.value = true,
        onExit: (_) => _hovered.value = false,
        child: ValueListenableBuilder<bool>(
          valueListenable: _hovered,
          builder: (_, hovered, child) {
            if (!widget.animated) {
              return _buildCard(accent, bg, 1.0, hovered, child!);
            }
            return AnimatedBuilder(
              animation: _ctrl,
              builder: (_, __) {
                final pulse =
                    0.8 + 0.2 * math.sin(_ctrl.value * math.pi);
                return _buildCard(accent, bg, pulse, hovered, child!);
              },
            );
          },
          child: Padding(
            padding: widget.padding,
            child: widget.child,
          ),
        ),
      ),
    );
  }

  Widget _buildCard(
    Color accent,
    Color bg,
    double pulse,
    bool hovered,
    Widget child,
  ) {
    final effectiveIntensity = widget.intensity * pulse;
    final hoverMultiplier = hovered ? 1.4 : 1.0;

    // Border decoration — top-only vs full
    final borderSide = BorderSide(
      color:
          accent.withValues(alpha: (0.7 * effectiveIntensity * hoverMultiplier).clamp(0.0, 1.0)),
      width: widget.borderWidth,
    );
    final transparentSide = BorderSide(
      color: Colors.white.withValues(alpha: 0.04),
      width: widget.borderWidth,
    );

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(widget.borderRadius),
        border: widget.fullBorder
            ? Border.all(
                color: accent.withValues(
                    alpha: (0.5 * effectiveIntensity * hoverMultiplier).clamp(0.0, 1.0)),
                width: widget.borderWidth,
              )
            : Border(
                top: borderSide,
                left: transparentSide,
                right: transparentSide,
                bottom: transparentSide,
              ),
        boxShadow: [
          // Neon glow under the card
          BoxShadow(
            color: accent.withValues(
                alpha: (0.12 * effectiveIntensity * hoverMultiplier).clamp(0.0, 1.0)),
            blurRadius: widget.blurRadius * hoverMultiplier,
            spreadRadius: 0,
            offset: const Offset(0, 2),
          ),
          // Inner glow on hover
          if (hovered)
            BoxShadow(
              color: accent.withValues(
                  alpha: (0.06 * effectiveIntensity).clamp(0.0, 1.0)),
              blurRadius: widget.blurRadius * 0.5,
              spreadRadius: -2,
              blurStyle: BlurStyle.inner,
            ),
        ],
      ),
      child: child,
    );
  }
}
