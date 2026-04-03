import 'package:flutter/material.dart';
import 'package:flutter_web_portfolio/app/core/constants/app_colors.dart';
import 'package:flutter_web_portfolio/app/widgets/cinematic_hover.dart';

/// Card with mouse-following border glow effect.
/// On hover, a glow follows the cursor along the card border.
class BorderLightCard extends StatefulWidget {
  const BorderLightCard({
    super.key,
    required this.child,
    this.glowColor,
    this.borderRadius = 8.0,
    this.padding = const EdgeInsets.all(28),
    this.backgroundColor,
  });

  final Widget child;
  final Color? glowColor;
  final double borderRadius;
  final EdgeInsets padding;
  final Color? backgroundColor;

  @override
  State<BorderLightCard> createState() => _BorderLightCardState();
}

class _BorderLightCardState extends State<BorderLightCard> {
  final _mousePos = ValueNotifier<Offset>(Offset.zero);
  final _hovered = ValueNotifier<bool>(false);

  @override
  void dispose() {
    _mousePos.dispose();
    _hovered.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accent = widget.glowColor ?? AppColors.heroAccent;

    return CinematicHover(
      glowColor: accent,
      glowOpacity: 0.08,
      child: MouseRegion(
        onEnter: (_) => _hovered.value = true,
        onHover: (e) => _mousePos.value = e.localPosition,
        onExit: (_) {
          _hovered.value = false;
          _mousePos.value = Offset.zero;
        },
        child: ValueListenableBuilder<Offset>(
          valueListenable: _mousePos,
          builder: (context, mousePos, child) =>
              ValueListenableBuilder<bool>(
            valueListenable: _hovered,
            builder: (context, hovered, _) => CustomPaint(
              foregroundPainter: hovered
                  ? _BorderGlowPainter(
                      mousePos: mousePos,
                      glowColor: accent,
                      borderRadius: widget.borderRadius,
                    )
                  : null,
              child: child,
            ),
          ),
          child: Container(
            padding: widget.padding,
            decoration: BoxDecoration(
              color: widget.backgroundColor ??
                  AppColors.backgroundLight.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(widget.borderRadius),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.05),
                width: 1,
              ),
            ),
            child: widget.child,
          ),
        ),
      ),
    );
  }
}

class _BorderGlowPainter extends CustomPainter {
  _BorderGlowPainter({
    required this.mousePos,
    required this.glowColor,
    required this.borderRadius,
  });

  final Offset mousePos;
  final Color glowColor;
  final double borderRadius;

  static final _paint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.5;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;

    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final rrect = RRect.fromRectAndRadius(rect, Radius.circular(borderRadius));

    _paint.shader = RadialGradient(
      center: Alignment(
        (mousePos.dx / size.width) * 2 - 1,
        (mousePos.dy / size.height) * 2 - 1,
      ),
      radius: 0.5,
      colors: [
        glowColor.withValues(alpha: 0.3),
        glowColor.withValues(alpha: 0.05),
        Colors.transparent,
      ],
      stops: const [0.0, 0.4, 1.0],
    ).createShader(rect);

    canvas.drawRRect(rrect, _paint);
  }

  @override
  bool shouldRepaint(_BorderGlowPainter old) => mousePos != old.mousePos;
}
