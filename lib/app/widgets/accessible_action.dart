import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_web_portfolio/app/core/constants/app_colors.dart';

/// Accessibility role exposed by [AccessibleAction].
enum ActionSemanticRole { button, link }

/// Reusable action surface for pointer, keyboard, focus, and semantics input.
class AccessibleAction extends StatefulWidget {
  const AccessibleAction({
    super.key,
    required this.child,
    required this.onTap,
    this.onHoverChanged,
    this.onFocusChanged,
    this.focusNode,
    this.focusColor,
    this.showFocusRing = true,
    this.excludeFromSemantics = false,
    this.cursor = SystemMouseCursors.click,
    this.borderRadius = BorderRadius.zero,
    this.semanticLabel,
    this.semanticRole = ActionSemanticRole.button,
    this.linkUrl,
    this.selected,
    this.expanded,
  }) : assert(
         linkUrl == null || semanticRole == ActionSemanticRole.link,
         'linkUrl requires the link role',
       );

  final Widget child;
  final VoidCallback onTap;
  final ValueChanged<bool>? onHoverChanged;
  final ValueChanged<bool>? onFocusChanged;
  final FocusNode? focusNode;
  final Color? focusColor;
  final bool showFocusRing;
  final bool excludeFromSemantics;
  final MouseCursor cursor;
  final BorderRadius borderRadius;
  final String? semanticLabel;
  final ActionSemanticRole semanticRole;
  final Uri? linkUrl;
  final bool? selected;
  final bool? expanded;

  @override
  State<AccessibleAction> createState() => _AccessibleActionState();
}

class _AccessibleActionState extends State<AccessibleAction> {
  bool _focused = false;
  bool _pointerInteraction = false;
  bool _keyboardFocused = false;

  @override
  void initState() {
    super.initState();
    FocusManager.instance.addHighlightModeListener(_updateFocusRing);
  }

  @override
  void dispose() {
    FocusManager.instance.removeHighlightModeListener(_updateFocusRing);
    super.dispose();
  }

  void _updateFocusRing([FocusHighlightMode? _]) {
    final keyboardFocused =
        _focused &&
        !_pointerInteraction &&
        FocusManager.instance.highlightMode == FocusHighlightMode.traditional;
    if (_keyboardFocused == keyboardFocused) return;
    setState(() => _keyboardFocused = keyboardFocused);
  }

  void _handleKeyEvent(KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) return;
    _pointerInteraction = false;
    _updateFocusRing();
  }

  @override
  Widget build(BuildContext context) {
    final focusColor = widget.focusColor ?? AppColors.focusRing;

    Widget action = GestureDetector(
      onTap: widget.onTap,
      excludeFromSemantics: widget.excludeFromSemantics,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          widget.child,
          if (_keyboardFocused && widget.showFocusRing)
            Positioned(
              left: -4,
              top: -4,
              right: -4,
              bottom: -4,
              child: IgnorePointer(
                child: CustomPaint(
                  foregroundPainter: _ActionFocusRingPainter(
                    color: focusColor,
                    borderRadius: widget.borderRadius,
                  ),
                ),
              ),
            ),
        ],
      ),
    );

    final semanticLabel = widget.semanticLabel?.trim();
    final hasLabel = semanticLabel != null && semanticLabel.isNotEmpty;
    if (hasLabel || widget.linkUrl != null) {
      // Inside Focus, so its focusable and focused flags merge into this node.
      action = Semantics(
        button: widget.semanticRole == ActionSemanticRole.button,
        link: widget.semanticRole == ActionSemanticRole.link,
        linkUrl: widget.linkUrl,
        selected: widget.selected,
        expanded: widget.expanded,
        label: hasLabel ? semanticLabel : null,
        onTap: widget.onTap,
        excludeSemantics: hasLabel,
        child: action,
      );
    }

    return MouseRegion(
      cursor: widget.cursor,
      onEnter: (_) => widget.onHoverChanged?.call(true),
      onExit: (_) => widget.onHoverChanged?.call(false),
      child: Listener(
        onPointerDown: (_) {
          _pointerInteraction = true;
          _updateFocusRing();
        },
        child: Focus(
          focusNode: widget.focusNode,
          onFocusChange: (focused) {
            _focused = focused;
            if (!focused) _pointerInteraction = false;
            _updateFocusRing();
            widget.onFocusChanged?.call(focused);
          },
          onKeyEvent: (_, event) {
            _handleKeyEvent(event);
            final isEnter = event.logicalKey == LogicalKeyboardKey.enter;
            final isButtonSpace =
                widget.semanticRole == ActionSemanticRole.button &&
                event.logicalKey == LogicalKeyboardKey.space;
            if (event is KeyDownEvent && (isEnter || isButtonSpace)) {
              widget.onTap();
              return KeyEventResult.handled;
            }
            return KeyEventResult.ignored;
          },
          child: action,
        ),
      ),
    );
  }
}

final class _ActionFocusRingPainter extends CustomPainter {
  const _ActionFocusRingPainter({
    required this.color,
    required this.borderRadius,
  });

  final Color color;
  final BorderRadius borderRadius;

  @override
  void paint(Canvas canvas, Size size) {
    final bounds = Rect.fromLTWH(1, 1, size.width - 2, size.height - 2);
    canvas.drawRRect(
      borderRadius.toRRect(bounds),
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }

  @override
  bool shouldRepaint(_ActionFocusRingPainter oldDelegate) =>
      color != oldDelegate.color || borderRadius != oldDelegate.borderRadius;
}
