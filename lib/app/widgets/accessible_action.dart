import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
    this.focusColor,
    this.showFocusRing = true,
    this.cursor = SystemMouseCursors.click,
    this.borderRadius = BorderRadius.zero,
    this.semanticLabel,
    this.semanticRole = ActionSemanticRole.button,
    this.selected,
    this.expanded,
  });

  final Widget child;
  final VoidCallback onTap;
  final ValueChanged<bool>? onHoverChanged;
  final ValueChanged<bool>? onFocusChanged;
  final Color? focusColor;
  final bool showFocusRing;
  final MouseCursor cursor;
  final BorderRadius borderRadius;
  final String? semanticLabel;
  final ActionSemanticRole semanticRole;
  final bool? selected;
  final bool? expanded;

  @override
  State<AccessibleAction> createState() => _AccessibleActionState();
}

class _AccessibleActionState extends State<AccessibleAction> {
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final focusColor = widget.focusColor ?? Colors.white.withValues(alpha: 0.4);

    final control = FocusableActionDetector(
      mouseCursor: widget.cursor,
      onShowHoverHighlight: widget.onHoverChanged,
      onShowFocusHighlight: (focused) {
        if (_focused != focused) setState(() => _focused = focused);
        widget.onFocusChanged?.call(focused);
      },
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
        onTap: widget.onTap,
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

    final semanticLabel = widget.semanticLabel?.trim();
    if (semanticLabel == null || semanticLabel.isEmpty) return control;

    return Semantics(
      button: widget.semanticRole == ActionSemanticRole.button,
      link: widget.semanticRole == ActionSemanticRole.link,
      selected: widget.selected,
      expanded: widget.expanded,
      focusable: true,
      label: semanticLabel,
      onTap: widget.onTap,
      excludeSemantics: true,
      child: control,
    );
  }
}
