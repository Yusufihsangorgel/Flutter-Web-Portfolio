import 'package:flutter/material.dart';

/// Wraps any widget with a magnetic hover effect.
///
/// When the cursor enters the detection zone, the child translates toward
/// the pointer position using spring-like animation, creating a "magnetic
/// pull" feel. On exit, the widget springs back to center.
///
/// Usage:
/// ```dart
/// MagneticHover(
///   magnetStrength: 0.3,
///   child: ElevatedButton(...),
/// )
/// ```
class MagneticHover extends StatefulWidget {
  const MagneticHover({
    super.key,
    required this.child,
    this.magnetStrength = 0.3,
    this.resetDuration = const Duration(milliseconds: 600),
    this.resetCurve = Curves.elasticOut,
    this.enabled = true,
  });

  /// The widget to apply the magnetic effect to.
  final Widget child;

  /// How strongly the child is pulled toward the cursor (0.0–1.0).
  /// 0.3 is subtle, 0.6 is noticeable, 1.0 is aggressive.
  final double magnetStrength;

  /// Duration of the spring-back animation on hover exit.
  final Duration resetDuration;

  /// Curve for the spring-back animation.
  final Curve resetCurve;

  /// Whether the magnetic effect is active.
  final bool enabled;

  @override
  State<MagneticHover> createState() => _MagneticHoverState();
}

class _MagneticHoverState extends State<MagneticHover>
    with SingleTickerProviderStateMixin {
  Offset _offset = Offset.zero;
  bool _isHovering = false;

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) return widget.child;

    return MouseRegion(
      onHover: (event) {
        if (!widget.enabled) return;
        final box = context.findRenderObject() as RenderBox?;
        if (box == null) return;
        final size = box.size;
        final center = Offset(size.width / 2, size.height / 2);
        final local = event.localPosition;
        final dx = (local.dx - center.dx) * widget.magnetStrength;
        final dy = (local.dy - center.dy) * widget.magnetStrength;
        setState(() {
          _isHovering = true;
          _offset = Offset(dx, dy);
        });
      },
      onExit: (_) {
        setState(() {
          _isHovering = false;
          _offset = Offset.zero;
        });
      },
      child: AnimatedContainer(
        duration: _isHovering
            ? const Duration(milliseconds: 100)
            : widget.resetDuration,
        curve: _isHovering ? Curves.easeOut : widget.resetCurve,
        transform: Matrix4.translationValues(_offset.dx, _offset.dy, 0),
        child: widget.child,
      ),
    );
  }
}
