import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:flutter_web_portfolio/app/controllers/cursor_controller.dart';
import 'package:flutter_web_portfolio/app/core/constants/cinematic_curves.dart';
import 'package:flutter_web_portfolio/app/core/constants/durations.dart';

/// Button that gets magnetically attracted to cursor within proximity.
/// Cursor within [magneticRadius] px = button shifts toward it.
class MagneticButton extends StatefulWidget {
  const MagneticButton({
    super.key,
    required this.child,
    required this.onTap,
    this.magneticRadius = 100.0,
    this.maxDisplacement = 8.0,
  });

  final Widget child;
  final VoidCallback onTap;
  final double magneticRadius;
  final double maxDisplacement;

  @override
  State<MagneticButton> createState() => _MagneticButtonState();
}

class _MagneticButtonState extends State<MagneticButton> {
  Offset _displacement = Offset.zero;
  Size _cachedSize = Size.zero;

  void _onHover(PointerEvent event) {
    if (_cachedSize == Size.zero) return;

    final center = Offset(_cachedSize.width / 2, _cachedSize.height / 2);
    final localPos = event.localPosition;
    final dx = localPos.dx - center.dx;
    final dy = localPos.dy - center.dy;
    final distance = Offset(dx, dy).distance;

    if (distance < widget.magneticRadius) {
      final factor = (1 - distance / widget.magneticRadius);
      final newDisplacement = Offset(
        dx * factor * widget.maxDisplacement / widget.magneticRadius,
        dy * factor * widget.maxDisplacement / widget.magneticRadius,
      );
      if ((_displacement - newDisplacement).distance > 2.0) {
        setState(() => _displacement = newDisplacement);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cursorCtrl = Get.find<CursorController>();

    return Semantics(
      button: true,
      child: LayoutBuilder(
      builder: (context, constraints) {
        _cachedSize = Size(constraints.maxWidth, constraints.maxHeight);

        return Shortcuts(
          shortcuts: const {
            SingleActivator(LogicalKeyboardKey.enter): ActivateIntent(),
            SingleActivator(LogicalKeyboardKey.space): ActivateIntent(),
          },
          child: Actions(
            actions: {
              ActivateIntent: CallbackAction<ActivateIntent>(
                onInvoke: (_) { widget.onTap(); return null; },
              ),
            },
            child: Focus(
              child: MouseRegion(
                onEnter: (_) {
                  cursorCtrl.isHovering.value = true;
                },
                onHover: _onHover,
                onExit: (_) {
                  setState(() => _displacement = Offset.zero);
                  cursorCtrl.isHovering.value = false;
                },
                cursor: SystemMouseCursors.click,
                child: GestureDetector(
                  onTap: widget.onTap,
                  child: AnimatedContainer(
                    duration: AppDurations.fast,
                    curve: CinematicCurves.magneticPull,
                    transform: Matrix4.translationValues(_displacement.dx, _displacement.dy, 0),
                    child: widget.child,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    ),
    );
  }
}
