import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_web_portfolio/app/controllers/theme_controller.dart';
import 'package:flutter_web_portfolio/app/widgets/mouse_effects.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class SectionWrapper extends StatelessWidget {
  const SectionWrapper({
    super.key,
    required this.child,
    required this.sectionKey,
    required this.sectionId,
    this.backgroundColor,
    this.padding = const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
    this.noBackground = false,
    this.minHeight,
  });

  final Widget child;
  final GlobalKey sectionKey;
  final String sectionId;
  final Color? backgroundColor;
  final EdgeInsetsGeometry padding;
  final bool noBackground;
  final double? minHeight;

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Container(
      key: sectionKey,
      constraints: BoxConstraints(
        minHeight: minHeight ?? screenHeight * 0.7,
      ),
      color: Colors.transparent,
      padding: padding,
      child: child,
    );
  }
}

class AnimatedCardWrapper extends StatelessWidget {
  const AnimatedCardWrapper({
    super.key,
    required this.child,
    this.elevation = 5,
    this.borderRadius = const BorderRadius.all(Radius.circular(16)),
    this.backgroundColor,
    this.hoverScale = 1.03,
    this.duration = const Duration(milliseconds: 200),
    this.margin = const EdgeInsets.all(8),
    this.padding = const EdgeInsets.all(16),
  });

  final Widget child;
  final double elevation;
  final BorderRadius borderRadius;
  final Color? backgroundColor;
  final double hoverScale;
  final Duration duration;
  final EdgeInsetsGeometry margin;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final bgColor = backgroundColor ?? const Color(0xFF001628).withValues(alpha: 0.7);

    if (!kIsWeb) {
      return Card(
        margin: margin,
        elevation: elevation,
        shape: RoundedRectangleBorder(borderRadius: borderRadius),
        color: bgColor,
        child: Padding(padding: padding, child: child),
      );
    }

    return HoverAnimatedWidget(
      hoverScale: hoverScale,
      duration: duration,
      child: Card(
        margin: margin,
        elevation: elevation,
        shape: RoundedRectangleBorder(borderRadius: borderRadius),
        color: bgColor,
        child: Padding(padding: padding, child: child),
      ),
    );
  }
}

class AnimatedButtonWrapper extends StatelessWidget {
  const AnimatedButtonWrapper({
    super.key,
    required this.child,
    required this.onTap,
    this.hoverScale = 1.05,
    this.hoverColor,
    this.borderRadius = const BorderRadius.all(Radius.circular(8)),
    this.duration = const Duration(milliseconds: 150),
  });

  final Widget child;
  final VoidCallback onTap;
  final double hoverScale;
  final Color? hoverColor;
  final BorderRadius borderRadius;
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    final themeController = Get.find<ThemeController>();
    final effectiveHoverColor =
        hoverColor ?? themeController.primaryColor.withValues(alpha: 0.1);

    if (!kIsWeb) {
      return Material(
        color: Colors.transparent,
        child: InkWell(onTap: onTap, borderRadius: borderRadius, child: child),
      );
    }

    return HoverAnimatedWidget(
      hoverScale: hoverScale,
      hoverColor: effectiveHoverColor,
      borderRadius: borderRadius,
      duration: duration,
      child: Material(
        color: Colors.transparent,
        child: InkWell(onTap: onTap, borderRadius: borderRadius, child: child),
      ),
    );
  }
}
