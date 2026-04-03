import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_web_portfolio/app/controllers/cursor_controller.dart';
import 'package:flutter_web_portfolio/app/core/constants/cinematic_curves.dart';
import 'package:flutter_web_portfolio/app/core/constants/durations.dart';

/// 3D tilt + glow + lift hover wrapper.
/// Max tilt: 2° — subtle but perceivable.
class CinematicHover extends StatefulWidget {
  const CinematicHover({
    super.key,
    required this.child,
    this.glowColor,
    this.maxTilt = 2.0,
    this.liftAmount = 4.0,
    this.glowOpacity = 0.15,
    this.glowBlur = 20.0,
  });

  final Widget child;
  final Color? glowColor;
  final double maxTilt;
  final double liftAmount;
  final double glowOpacity;
  final double glowBlur;

  @override
  State<CinematicHover> createState() => _CinematicHoverState();
}

class _CinematicHoverState extends State<CinematicHover>
    with SingleTickerProviderStateMixin {
  final _hovered = ValueNotifier<bool>(false);
  final _localPos = ValueNotifier<Offset>(Offset.zero);
  Size _size = Size.zero;

  late AnimationController _controller;
  late Animation<double> _liftAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: AppDurations.normal,
    );
    _liftAnim = Tween<double>(begin: 0, end: widget.liftAmount).animate(
      CurvedAnimation(parent: _controller, curve: CinematicCurves.hoverLift),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _hovered.dispose();
    _localPos.dispose();
    super.dispose();
  }

  void _onEnter(PointerEvent e) {
    _hovered.value = true;
    _controller.forward();
    Get.find<CursorController>().isHovering.value = true;
  }

  void _onExit(PointerEvent e) {
    _hovered.value = false;
    _localPos.value = Offset.zero;
    _controller.reverse();
    Get.find<CursorController>().isHovering.value = false;
  }

  void _onHover(PointerEvent e) {
    _localPos.value = e.localPosition;
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
      builder: (context, constraints) {
        _size = Size(constraints.maxWidth, constraints.maxHeight);

        return MouseRegion(
          onEnter: _onEnter,
          onExit: _onExit,
          onHover: _onHover,
          child: ValueListenableBuilder<Offset>(
            valueListenable: _localPos,
            builder: (context, localPos, _) =>
                ValueListenableBuilder<bool>(
                valueListenable: _hovered,
                builder: (context, hovered, __) {
                  // Calculate tilt angles (radians)
                  double tiltX = 0;
                  double tiltY = 0;
                  if (hovered && _size.width > 0 && _size.height > 0) {
                    final normalizedX =
                        (localPos.dx / _size.width - 0.5) * 2;
                    final normalizedY =
                        (localPos.dy / _size.height - 0.5) * 2;
                    tiltY =
                        normalizedX * widget.maxTilt * (math.pi / 180);
                    tiltX =
                        -normalizedY * widget.maxTilt * (math.pi / 180);
                  }

                  return AnimatedBuilder(
                    animation: _liftAnim,
                    builder: (_, child) {
                      final transform = Matrix4.identity()
                        ..setEntry(3, 2, 0.001) // perspective
                        ..rotateX(tiltX)
                        ..rotateY(tiltY);
                      transform.storage[13] -= _liftAnim.value;

                      return AnimatedContainer(
                        duration: AppDurations.veryFast,
                        transform: transform,
                        transformAlignment: Alignment.center,
                        decoration: BoxDecoration(
                          boxShadow: hovered
                              ? [
                                  BoxShadow(
                                    color: (widget.glowColor ?? Colors.white)
                                        .withValues(
                                            alpha: widget.glowOpacity),
                                    blurRadius: widget.glowBlur,
                                    spreadRadius: 0,
                                  ),
                                ]
                              : [],
                        ),
                        child: child,
                      );
                    },
                    child: widget.child,
                  );
                },
              ),
          ),
        );
      },
    );
}
