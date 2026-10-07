import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_web_portfolio/app/core/constants/app_colors.dart';
import 'package:flutter_web_portfolio/app/core/constants/durations.dart';
import 'package:flutter_web_portfolio/app/widgets/accessible_action.dart';

/// Keyboard bypass link that is revealed only while it holds focus.
///
/// Paint it above the page chrome; while hidden it lets pointer input through
/// but stays in the semantics tree.
class SkipToContentLink extends StatefulWidget {
  const SkipToContentLink({
    super.key,
    required this.label,
    required this.focusNode,
    required this.onActivate,
  });

  final String label;
  final FocusNode focusNode;
  final VoidCallback onActivate;

  @override
  State<SkipToContentLink> createState() => _SkipToContentLinkState();
}

class _SkipToContentLinkState extends State<SkipToContentLink> {
  bool _visible = false;

  void _handleFocusChange(bool focused) {
    if (_visible != focused) setState(() => _visible = focused);
  }

  @override
  Widget build(BuildContext context) => _PointerPassThrough(
    passThrough: !_visible,
    child: AccessibleAction(
      focusNode: widget.focusNode,
      onFocusChanged: _handleFocusChange,
      onTap: widget.onActivate,
      semanticLabel: widget.label,
      showFocusRing: false,
      cursor: _visible ? SystemMouseCursors.click : MouseCursor.defer,
      child: AnimatedOpacity(
        opacity: _visible ? 1.0 : 0.0,
        duration: AppDurations.fast,
        child: AnimatedContainer(
          duration: AppDurations.fast,
          transform: Matrix4.translationValues(0, _visible ? 0 : -48, 0),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.accent,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            widget.label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w600,
              decoration: TextDecoration.none,
            ),
          ),
        ),
      ),
    ),
  );
}

/// Skips hit testing without blocking semantics actions, unlike IgnorePointer.
class _PointerPassThrough extends SingleChildRenderObjectWidget {
  const _PointerPassThrough({required this.passThrough, super.child});

  final bool passThrough;

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderPointerPassThrough(passThrough);

  @override
  void updateRenderObject(
    BuildContext context,
    _RenderPointerPassThrough renderObject,
  ) => renderObject.passThrough = passThrough;
}

class _RenderPointerPassThrough extends RenderProxyBox {
  _RenderPointerPassThrough(this.passThrough);

  bool passThrough;

  @override
  bool hitTest(BoxHitTestResult result, {required Offset position}) =>
      !passThrough && super.hitTest(result, position: position);
}
