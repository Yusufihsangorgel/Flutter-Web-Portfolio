import 'package:flutter/material.dart';
import 'package:flutter_web_portfolio/app/widgets/custom_cursor.dart';

/// Wraps content with the custom cursor overlay (web only).
class MouseInteractionWrapper extends StatelessWidget {
  const MouseInteractionWrapper({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => CustomCursor(child: child);
}
