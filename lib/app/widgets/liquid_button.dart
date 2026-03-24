import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_web_portfolio/app/core/constants/app_colors.dart';
import 'package:flutter_web_portfolio/app/core/constants/cinematic_curves.dart';
import 'package:flutter_web_portfolio/app/core/constants/durations.dart';
import 'package:google_fonts/google_fonts.dart';

// ─────────────────────────────────────────────────────────────────────────────
// LiquidButton
// ─────────────────────────────────────────────────────────────────────────────

/// Premium button with liquid/morphing border, fill animation, text swap,
/// magnetic pull, ripple burst, and spring-back.
class LiquidButton extends StatefulWidget {
  const LiquidButton({
    super.key,
    required this.text,
    required this.onTap,
    this.hoverText,
    this.icon,
    this.accentColor = AppColors.accent,
    this.minWidth = 180,
    this.height = 52,
    this.disabled = false,
  });

  final String text;
  final String? hoverText;
  final VoidCallback onTap;
  final IconData? icon;
  final Color accentColor;
  final double minWidth;
  final double height;
  final bool disabled;

  @override
  State<LiquidButton> createState() => _LiquidButtonState();
}

class _LiquidButtonState extends State<LiquidButton>
    with TickerProviderStateMixin {
  late final AnimationController _morphCtrl;
  late final AnimationController _fillCtrl;
  late final AnimationController _pressCtrl;
  late final AnimationController _rippleCtrl;

  bool _hovered = false;
  Offset _displacement = Offset.zero;
  Offset _rippleOrigin = Offset.zero;

  static const _magneticRadius = 120.0;
  static const _maxDisplacement = 6.0;

  @override
  void initState() {
    super.initState();
    _morphCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    );
    _fillCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _pressCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _rippleCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
  }

  @override
  void dispose() {
    _morphCtrl.dispose();
    _fillCtrl.dispose();
    _pressCtrl.dispose();
    _rippleCtrl.dispose();
    super.dispose();
  }

  void _onEnter(PointerEvent _) {
    if (widget.disabled) return;
    setState(() => _hovered = true);
    _morphCtrl.repeat();
    _fillCtrl.forward();
  }

  void _onExit(PointerEvent _) {
    setState(() {
      _hovered = false;
      _displacement = Offset.zero;
    });
    _morphCtrl.stop();
    _fillCtrl.reverse();
  }

  void _onHover(PointerEvent event) {
    if (widget.disabled) return;
    final pos = event.localPosition;
    final center = Offset(widget.minWidth / 2, widget.height / 2);
    final dx = pos.dx - center.dx;
    final dy = pos.dy - center.dy;
    final dist = Offset(dx, dy).distance;
    if (dist < _magneticRadius) {
      final factor = 1 - dist / _magneticRadius;
      final newDisp = Offset(
        dx * factor * _maxDisplacement / _magneticRadius,
        dy * factor * _maxDisplacement / _magneticRadius,
      );
      if ((_displacement - newDisp).distance > 1.5) {
        setState(() => _displacement = newDisp);
      }
    }
  }

  void _onTapDown(TapDownDetails d) {
    if (widget.disabled) return;
    _rippleOrigin = d.localPosition;
    _pressCtrl.forward();
    _rippleCtrl.forward(from: 0);
  }

  void _onTapUp(TapUpDetails _) {
    _pressCtrl.reverse();
    widget.onTap();
  }

  void _onTapCancel() {
    _pressCtrl.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final body = _buildBody(context);
    return widget.disabled ? Opacity(opacity: 0.4, child: body) : body;
  }

  Widget _buildBody(BuildContext context) {
    final effectiveHoverText = widget.hoverText ?? widget.text;

    return Semantics(
      button: true,
      label: widget.text,
      child: Shortcuts(
        shortcuts: const {
          SingleActivator(LogicalKeyboardKey.enter): ActivateIntent(),
          SingleActivator(LogicalKeyboardKey.space): ActivateIntent(),
        },
        child: Actions(
          actions: {
            ActivateIntent: CallbackAction<ActivateIntent>(
              onInvoke: (_) {
                if (!widget.disabled) widget.onTap();
                return null;
              },
            ),
          },
          child: Focus(
            child: MouseRegion(
              cursor: widget.disabled
                  ? SystemMouseCursors.forbidden
                  : SystemMouseCursors.click,
              onEnter: _onEnter,
              onHover: _onHover,
              onExit: _onExit,
              child: GestureDetector(
                onTapDown: _onTapDown,
                onTapUp: _onTapUp,
                onTapCancel: _onTapCancel,
                child: AnimatedBuilder(
                  animation: Listenable.merge(
                    [_morphCtrl, _fillCtrl, _pressCtrl, _rippleCtrl],
                  ),
                  builder: (context, child) {
                    final scale = 1.0 - _pressCtrl.value * 0.04;
                    return Transform.translate(
                      offset: _displacement,
                      child: Transform.scale(
                        scale: scale,
                        child: Container(
                          constraints:
                              BoxConstraints(minWidth: widget.minWidth),
                          height: widget.height,
                          child: CustomPaint(
                            painter: _LiquidBorderPainter(
                              morphPhase: _morphCtrl.value,
                              fillProgress: _fillCtrl.value,
                              accentColor: widget.accentColor,
                              hovered: _hovered,
                              rippleProgress: _rippleCtrl.value,
                              rippleOrigin: _rippleOrigin,
                            ),
                            child: _buildContent(effectiveHoverText),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(String hoverText) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (widget.icon != null) ...[
              Icon(
                widget.icon,
                size: 18,
                color: _hovered ? AppColors.white : widget.accentColor,
              ),
              const SizedBox(width: 10),
            ],
            ClipRect(
              child: AnimatedSwitcher(
                duration: AppDurations.medium,
                switchInCurve: CinematicCurves.dramaticEntrance,
                switchOutCurve: CinematicCurves.dramaticEntrance,
                transitionBuilder: (child, anim) {
                  final offsetIn = Tween<Offset>(
                    begin: const Offset(0, 0.6),
                    end: Offset.zero,
                  ).animate(anim);
                  return SlideTransition(
                    position: offsetIn,
                    child: FadeTransition(opacity: anim, child: child),
                  );
                },
                child: Text(
                  _hovered && widget.hoverText != null
                      ? hoverText
                      : widget.text,
                  key: ValueKey(
                    _hovered && widget.hoverText != null
                        ? hoverText
                        : widget.text,
                  ),
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.5,
                    color: _hovered ? AppColors.white : widget.accentColor,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
}

class _LiquidBorderPainter extends CustomPainter {
  _LiquidBorderPainter({
    required this.morphPhase,
    required this.fillProgress,
    required this.accentColor,
    required this.hovered,
    required this.rippleProgress,
    required this.rippleOrigin,
  });

  final double morphPhase;
  final double fillProgress;
  final Color accentColor;
  final bool hovered;
  final double rippleProgress;
  final Offset rippleOrigin;

  @override
  void paint(Canvas canvas, Size size) {
    // ── Fill from edges inward ──
    if (fillProgress > 0) {
      final fillPath = _buildOrganicPath(size, morphPhase, amplitude: 0);
      final fillPaint = Paint()
        ..color = accentColor.withValues(alpha: fillProgress * 0.85)
        ..style = PaintingStyle.fill;
      canvas
        ..save()
        ..clipPath(fillPath)
        ..drawRect(
          Rect.fromLTRB(-10, -10, size.width + 10, size.height + 10),
          fillPaint,
        )
        ..restore();
    }

    // ── Organic border ──
    final amplitude = hovered ? 4.0 : 0.0;
    final borderPath =
        _buildOrganicPath(size, morphPhase, amplitude: amplitude);
    final borderPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = hovered ? 2.0 : 1.5
      ..shader = ui.Gradient.linear(
        Offset.zero,
        Offset(size.width, size.height),
        [
          accentColor,
          accentColor.withValues(alpha: 0.5),
          accentColor,
        ],
        [0.0, 0.5, 1.0],
      );
    canvas.drawPath(borderPath, borderPaint);

    // ── Glow on hover ──
    if (hovered) {
      final glowPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6
        ..color = accentColor.withValues(alpha: 0.15)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
      canvas.drawPath(borderPath, glowPaint);
    }

    // ── Ripple burst ──
    if (rippleProgress > 0 && rippleProgress < 1) {
      final maxRadius =
          math.sqrt(size.width * size.width + size.height * size.height);
      final radius = rippleProgress * maxRadius;
      final ripplePaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3 * (1 - rippleProgress)
        ..color = accentColor.withValues(alpha: 0.5 * (1 - rippleProgress));
      canvas.drawCircle(rippleOrigin, radius, ripplePaint);
    }
  }

  Path _buildOrganicPath(
    Size size,
    double phase, {
    required double amplitude,
  }) {
    final w = size.width;
    final h = size.height;
    final r = h * 0.35;
    const tau = math.pi * 2;

    double wobble(double base, int seed) =>
        base + math.sin(phase * tau + seed * 1.7) * amplitude;

    return Path()
      // Start top-left after corner
      ..moveTo(r, wobble(0, 0))
      // Top edge
      ..cubicTo(
        w * 0.3, wobble(-amplitude * 0.6, 1),
        w * 0.7, wobble(amplitude * 0.6, 2),
        w - r, wobble(0, 3),
      )
      // Top-right corner
      ..quadraticBezierTo(w, 0, w, r + wobble(0, 4))
      // Right edge
      ..cubicTo(
        w + wobble(0, 5) * 0.5, h * 0.3,
        w + wobble(0, 6) * 0.5, h * 0.7,
        w, h - r + wobble(0, 7),
      )
      // Bottom-right corner
      ..quadraticBezierTo(w, h, w - r, h + wobble(0, 8))
      // Bottom edge
      ..cubicTo(
        w * 0.7, h + wobble(amplitude * 0.6, 9),
        w * 0.3, h + wobble(-amplitude * 0.6, 10),
        r, h + wobble(0, 11),
      )
      // Bottom-left corner
      ..quadraticBezierTo(0, h, 0, h - r + wobble(0, 12))
      // Left edge
      ..cubicTo(
        wobble(0, 13) * 0.5, h * 0.7,
        wobble(0, 14) * 0.5, h * 0.3,
        0, r + wobble(0, 15),
      )
      // Top-left corner
      ..quadraticBezierTo(0, 0, r, wobble(0, 0))
      ..close();
  }

  @override
  bool shouldRepaint(_LiquidBorderPainter old) =>
      old.morphPhase != morphPhase ||
      old.fillProgress != fillProgress ||
      old.hovered != hovered ||
      old.rippleProgress != rippleProgress;
}

// ─────────────────────────────────────────────────────────────────────────────
// GlowButton
// ─────────────────────────────────────────────────────────────────────────────

/// Pulsing neon glow border button. Hover intensifies; click flashes.
class GlowButton extends StatefulWidget {
  const GlowButton({
    super.key,
    required this.text,
    required this.onTap,
    this.icon,
    this.glowColor = AppColors.accent,
    this.minWidth = 160,
    this.height = 48,
    this.disabled = false,
  });

  final String text;
  final VoidCallback onTap;
  final IconData? icon;
  final Color glowColor;
  final double minWidth;
  final double height;
  final bool disabled;

  @override
  State<GlowButton> createState() => _GlowButtonState();
}

class _GlowButtonState extends State<GlowButton>
    with TickerProviderStateMixin {
  late final AnimationController _pulseCtrl;
  late final AnimationController _flashCtrl;

  bool _hovered = false;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
    _flashCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _flashCtrl.dispose();
    super.dispose();
  }

  void _handleTap() {
    if (widget.disabled) return;
    _flashCtrl.forward(from: 0).then((_) => _flashCtrl.reverse());
    widget.onTap();
  }

  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        label: widget.text,
        child: Shortcuts(
          shortcuts: const {
            SingleActivator(LogicalKeyboardKey.enter): ActivateIntent(),
            SingleActivator(LogicalKeyboardKey.space): ActivateIntent(),
          },
          child: Actions(
            actions: {
              ActivateIntent: CallbackAction<ActivateIntent>(
                onInvoke: (_) {
                  _handleTap();
                  return null;
                },
              ),
            },
            child: Focus(
              child: MouseRegion(
                cursor: widget.disabled
                    ? SystemMouseCursors.forbidden
                    : SystemMouseCursors.click,
                onEnter: (_) {
                  if (!widget.disabled) setState(() => _hovered = true);
                },
                onExit: (_) => setState(() => _hovered = false),
                child: GestureDetector(
                  onTap: _handleTap,
                  child: AnimatedBuilder(
                    animation: Listenable.merge([_pulseCtrl, _flashCtrl]),
                    builder: (context, _) {
                      final pulseVal = _pulseCtrl.value;
                      final flashVal = _flashCtrl.value;
                      final baseGlow = _hovered ? 0.5 : 0.2;
                      final glowAlpha =
                          (baseGlow + pulseVal * 0.3 + flashVal * 0.5)
                              .clamp(0.0, 1.0);
                      final blurRadius = (_hovered ? 18.0 : 8.0) +
                          pulseVal * 6 +
                          flashVal * 20;
                      final borderAlpha =
                          (0.6 + pulseVal * 0.4).clamp(0.0, 1.0);

                      return Opacity(
                        opacity: widget.disabled ? 0.4 : 1.0,
                        child: Container(
                          constraints:
                              BoxConstraints(minWidth: widget.minWidth),
                          height: widget.height,
                          decoration: BoxDecoration(
                            borderRadius:
                                BorderRadius.circular(widget.height / 2),
                            color: flashVal > 0
                                ? widget.glowColor
                                    .withValues(alpha: flashVal * 0.3)
                                : Colors.transparent,
                            border: Border.all(
                              color: widget.glowColor
                                  .withValues(alpha: borderAlpha),
                              width: _hovered ? 2.0 : 1.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: widget.glowColor
                                    .withValues(alpha: glowAlpha),
                                blurRadius: blurRadius,
                                spreadRadius: _hovered ? 2 : 0,
                              ),
                            ],
                          ),
                          alignment: Alignment.center,
                          child: Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 24),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (widget.icon != null) ...[
                                  Icon(
                                    widget.icon,
                                    size: 18,
                                    color: widget.glowColor,
                                  ),
                                  const SizedBox(width: 10),
                                ],
                                Text(
                                  widget.text,
                                  style: GoogleFonts.spaceGrotesk(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 1.5,
                                    color: widget.glowColor,
                                    shadows: [
                                      Shadow(
                                        color: widget.glowColor
                                            .withValues(alpha: 0.6),
                                        blurRadius: 6,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        ),
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// OutlineRevealButton
// ─────────────────────────────────────────────────────────────────────────────

/// Border draws itself on hover; text fades in after border completes.
/// On exit, border erases in reverse.
class OutlineRevealButton extends StatefulWidget {
  const OutlineRevealButton({
    super.key,
    required this.text,
    required this.onTap,
    this.icon,
    this.color = AppColors.accent,
    this.minWidth = 160,
    this.height = 48,
    this.disabled = false,
  });

  final String text;
  final VoidCallback onTap;
  final IconData? icon;
  final Color color;
  final double minWidth;
  final double height;
  final bool disabled;

  @override
  State<OutlineRevealButton> createState() => _OutlineRevealButtonState();
}

class _OutlineRevealButtonState extends State<OutlineRevealButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _onEnter(PointerEvent _) {
    if (!widget.disabled) _ctrl.forward();
  }

  void _onExit(PointerEvent _) {
    _ctrl.reverse();
  }

  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        label: widget.text,
        child: Shortcuts(
          shortcuts: const {
            SingleActivator(LogicalKeyboardKey.enter): ActivateIntent(),
            SingleActivator(LogicalKeyboardKey.space): ActivateIntent(),
          },
          child: Actions(
            actions: {
              ActivateIntent: CallbackAction<ActivateIntent>(
                onInvoke: (_) {
                  if (!widget.disabled) widget.onTap();
                  return null;
                },
              ),
            },
            child: Focus(
              child: MouseRegion(
                cursor: widget.disabled
                    ? SystemMouseCursors.forbidden
                    : SystemMouseCursors.click,
                onEnter: _onEnter,
                onExit: _onExit,
                child: GestureDetector(
                  onTap: widget.disabled ? null : widget.onTap,
                  child: AnimatedBuilder(
                    animation: _ctrl,
                    builder: (context, _) {
                      // Text fades in only after border is ~70 % drawn
                      final textOpacity =
                          ((_ctrl.value - 0.7) / 0.3).clamp(0.0, 1.0);
                      return Opacity(
                        opacity: widget.disabled ? 0.4 : 1.0,
                        child: Container(
                          constraints:
                              BoxConstraints(minWidth: widget.minWidth),
                          height: widget.height,
                          alignment: Alignment.center,
                          child: CustomPaint(
                            painter: _OutlineDrawPainter(
                              progress: _ctrl.value,
                              color: widget.color,
                              radius: widget.height / 2,
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                              ),
                              child: Opacity(
                                opacity: textOpacity,
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (widget.icon != null) ...[
                                      Icon(
                                        widget.icon,
                                        size: 18,
                                        color: widget.color,
                                      ),
                                      const SizedBox(width: 10),
                                    ],
                                    Text(
                                      widget.text,
                                      style: GoogleFonts.spaceGrotesk(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        letterSpacing: 1.5,
                                        color: widget.color,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        ),
      );
}

class _OutlineDrawPainter extends CustomPainter {
  _OutlineDrawPainter({
    required this.progress,
    required this.color,
    required this.radius,
  });

  final double progress;
  final Color color;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0) return;

    final rrect = RRect.fromLTRBR(
      0,
      0,
      size.width,
      size.height,
      Radius.circular(radius),
    );

    // Compute the full perimeter path
    final fullPath = Path()..addRRect(rrect);
    final metrics = fullPath.computeMetrics().first;
    final totalLength = metrics.length;
    final drawLength = totalLength * progress;
    final partialPath = metrics.extractPath(0, drawLength);

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..color = color
      ..strokeCap = StrokeCap.round;

    canvas.drawPath(partialPath, paint);

    // Subtle glow at the leading edge
    if (progress > 0 && progress < 1) {
      final tangent = metrics.getTangentForOffset(drawLength);
      if (tangent != null) {
        final dotPaint = Paint()
          ..color = color.withValues(alpha: 0.6)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
        canvas.drawCircle(tangent.position, 3, dotPaint);
      }
    }
  }

  @override
  bool shouldRepaint(_OutlineDrawPainter old) => old.progress != progress;
}

// ─────────────────────────────────────────────────────────────────────────────
// GradientShiftButton
// ─────────────────────────────────────────────────────────────────────────────

/// Animated gradient background that continuously shifts/rotates.
/// Hover speeds up the rotation. Gradient colors from scene palette.
class GradientShiftButton extends StatefulWidget {
  const GradientShiftButton({
    super.key,
    required this.text,
    required this.onTap,
    this.icon,
    this.gradientColors,
    this.minWidth = 160,
    this.height = 48,
    this.disabled = false,
  });

  final String text;
  final VoidCallback onTap;
  final IconData? icon;

  /// Two or more colors for the shifting gradient.
  /// Defaults to hero scene colors.
  final List<Color>? gradientColors;
  final double minWidth;
  final double height;
  final bool disabled;

  @override
  State<GradientShiftButton> createState() => _GradientShiftButtonState();
}

class _GradientShiftButtonState extends State<GradientShiftButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _rotCtrl;
  bool _hovered = false;
  bool _pressed = false;

  @override
  void initState() {
    super.initState();
    _rotCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    )..repeat();
  }

  @override
  void dispose() {
    _rotCtrl.dispose();
    super.dispose();
  }

  void _onEnter(PointerEvent _) {
    if (widget.disabled) return;
    setState(() => _hovered = true);
    // Speed up on hover
    _rotCtrl.duration = const Duration(milliseconds: 1200);
    _rotCtrl.repeat();
  }

  void _onExit(PointerEvent _) {
    setState(() => _hovered = false);
    // Slow back down
    _rotCtrl.duration = const Duration(milliseconds: 3000);
    _rotCtrl.repeat();
  }

  @override
  Widget build(BuildContext context) {
    final colors = widget.gradientColors ??
        const [
          AppColors.heroAccent,
          AppColors.projAccent,
          AppColors.expAccent,
          AppColors.aboutAccent,
        ];

    return Semantics(
      button: true,
      label: widget.text,
      child: Shortcuts(
        shortcuts: const {
          SingleActivator(LogicalKeyboardKey.enter): ActivateIntent(),
          SingleActivator(LogicalKeyboardKey.space): ActivateIntent(),
        },
        child: Actions(
          actions: {
            ActivateIntent: CallbackAction<ActivateIntent>(
              onInvoke: (_) {
                if (!widget.disabled) widget.onTap();
                return null;
              },
            ),
          },
          child: Focus(
            child: MouseRegion(
              cursor: widget.disabled
                  ? SystemMouseCursors.forbidden
                  : SystemMouseCursors.click,
              onEnter: _onEnter,
              onExit: _onExit,
              child: GestureDetector(
                onTapDown: (_) {
                  if (!widget.disabled) setState(() => _pressed = true);
                },
                onTapUp: (_) {
                  setState(() => _pressed = false);
                  if (!widget.disabled) widget.onTap();
                },
                onTapCancel: () => setState(() => _pressed = false),
                child: AnimatedBuilder(
                  animation: _rotCtrl,
                  builder: (context, _) {
                    final angle = _rotCtrl.value * math.pi * 2;
                    final scale = _pressed ? 0.96 : 1.0;

                    // Rotating gradient end-points
                    final begin = Alignment(
                      math.cos(angle),
                      math.sin(angle),
                    );
                    final end = Alignment(
                      math.cos(angle + math.pi),
                      math.sin(angle + math.pi),
                    );

                    return Opacity(
                      opacity: widget.disabled ? 0.4 : 1.0,
                      child: AnimatedScale(
                        scale: scale,
                        duration: AppDurations.microFast,
                        child: Container(
                          constraints:
                              BoxConstraints(minWidth: widget.minWidth),
                          height: widget.height,
                          decoration: BoxDecoration(
                            borderRadius:
                                BorderRadius.circular(widget.height / 2),
                            gradient: LinearGradient(
                              begin: begin,
                              end: end,
                              colors: colors,
                            ),
                            boxShadow: _hovered
                                ? [
                                    BoxShadow(
                                      color: colors.first
                                          .withValues(alpha: 0.35),
                                      blurRadius: 16,
                                      spreadRadius: 1,
                                    ),
                                  ]
                                : [],
                          ),
                          alignment: Alignment.center,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (widget.icon != null) ...[
                                  Icon(
                                    widget.icon,
                                    size: 18,
                                    color: AppColors.white,
                                  ),
                                  const SizedBox(width: 10),
                                ],
                                Text(
                                  widget.text,
                                  style: GoogleFonts.spaceGrotesk(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 1.5,
                                    color: AppColors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
