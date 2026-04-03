import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:flutter_web_portfolio/app/controllers/sound_controller.dart';

/// Focusable interaction wrapper — keyboard nav, hover, tap, focus ring.
/// Replaces raw MouseRegion + GestureDetector with accessibility baked in.
class CinematicFocusable extends StatefulWidget {
  const CinematicFocusable({
    super.key,
    required this.child,
    required this.onTap,
    this.onHoverChanged,
    this.focusColor,
    this.showFocusRing = true,
    this.cursor = SystemMouseCursors.click,
    this.borderRadius = BorderRadius.zero,
  });

  final Widget child;
  final VoidCallback onTap;
  final ValueChanged<bool>? onHoverChanged;
  final Color? focusColor;
  final bool showFocusRing;
  final MouseCursor cursor;
  final BorderRadius borderRadius;

  @override
  State<CinematicFocusable> createState() => _CinematicFocusableState();
}

class _CinematicFocusableState extends State<CinematicFocusable> {
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final focusColor = widget.focusColor ??
        Colors.white.withValues(alpha: 0.4);

    return FocusableActionDetector(
      mouseCursor: widget.cursor,
      onShowHoverHighlight: (hovered) {
        if (hovered && Get.isRegistered<SoundController>()) {
          Get.find<SoundController>().playHover();
        }
        widget.onHoverChanged?.call(hovered);
      },
      onShowFocusHighlight: (focused) => setState(() => _focused = focused),
      actions: {
        ActivateIntent: CallbackAction<ActivateIntent>(
          onInvoke: (_) {
            widget.onTap();
            return null;
          },
        ),
      },
      shortcuts: const {
        SingleActivator(LogicalKeyboardKey.enter): ActivateIntent(),
        SingleActivator(LogicalKeyboardKey.space): ActivateIntent(),
      },
      child: GestureDetector(
        onTap: () {
          if (Get.isRegistered<SoundController>()) {
            Get.find<SoundController>().playClick();
          }
          widget.onTap();
        },
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: widget.borderRadius,
            border: (_focused && widget.showFocusRing)
                ? Border.all(color: focusColor, width: 1)
                : null,
          ),
          child: widget.child,
        ),
      ),
    );
  }
}
