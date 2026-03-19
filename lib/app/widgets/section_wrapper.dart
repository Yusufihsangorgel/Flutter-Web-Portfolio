import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_web_portfolio/app/controllers/theme_controller.dart';
import 'package:flutter_web_portfolio/app/controllers/shared_background_controller.dart';
import 'package:flutter_web_portfolio/app/widgets/mouse_effects.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

/// Widget that wraps sections with hover animations and cosmic background
class SectionWrapper extends StatefulWidget {
  final Widget child;
  final GlobalKey sectionKey;
  final String sectionId;
  final Color? backgroundColor;
  final bool useHoverLight;
  final EdgeInsetsGeometry padding;
  final bool noBackground;
  final double? minHeight;

  const SectionWrapper({
    super.key,
    required this.child,
    required this.sectionKey,
    required this.sectionId,
    this.backgroundColor,
    this.useHoverLight = true,
    this.padding = const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
    this.noBackground = false,
    this.minHeight,
  });

  @override
  State<SectionWrapper> createState() => _SectionWrapperState();
}

class _SectionWrapperState extends State<SectionWrapper>
    with SingleTickerProviderStateMixin {
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    if (widget.sectionId == 'home' &&
        !SharedBackgroundController.isInitialized) {
      SharedBackgroundController.init(this);
    }
  }

  void _updateMousePosition(PointerEvent event) {
    if (widget.sectionId == 'home') {
      SharedBackgroundController.updateMousePosition(event.localPosition);
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeController = Get.find<ThemeController>();
    final screenHeight = MediaQuery.of(context).size.height;

    return MouseRegion(
      onHover: (event) {
        _updateMousePosition(event);
        if (!_isHovered) {
          setState(() {
            _isHovered = true;
          });
        }
      },
      onExit: (_) {
        if (_isHovered) {
          setState(() {
            _isHovered = false;
          });
        }
      },
      child: Container(
        key: widget.sectionKey,
        margin: EdgeInsets.zero,
        constraints: BoxConstraints(
          minHeight:
              widget.minHeight ??
              (widget.sectionId == 'home'
                  ? screenHeight - 80
                  : (widget.sectionId == 'about'
                      ? screenHeight - 80
                      : screenHeight * 0.7)),
        ),
        color: Colors.transparent,
        child: Stack(
          children: [
            if (!widget.noBackground)
              AnimatedOpacity(
                opacity: _isHovered ? 0.5 : 0.0,
                duration: const Duration(milliseconds: 600),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: Alignment.center,
                      radius: 1.0,
                      colors: [
                        themeController.primaryColor.withOpacity(0.05),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
            Padding(
              padding:
                  widget.sectionId == 'home'
                      ? const EdgeInsets.only(bottom: 0)
                      : (widget.sectionId == 'about'
                          ? const EdgeInsets.only(top: 0)
                          : widget.padding),
              child: widget.child,
            ),
          ],
        ),
      ),
    );
  }
}

/// Adds hover animation to card-style widgets
class AnimatedCardWrapper extends StatelessWidget {
  final Widget child;
  final double elevation;
  final BorderRadius borderRadius;
  final Color? backgroundColor;
  final double hoverScale;
  final Duration duration;
  final EdgeInsetsGeometry margin;
  final EdgeInsetsGeometry padding;

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

  @override
  Widget build(BuildContext context) {
    final themeController = Get.find<ThemeController>();
    final actualBgColor =
        backgroundColor ?? const Color(0xFF001628).withOpacity(0.7);

    // Skip hover effect on non-web platforms
    if (!kIsWeb) {
      return Card(
        margin: margin,
        elevation: elevation,
        shape: RoundedRectangleBorder(borderRadius: borderRadius),
        color: actualBgColor,
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
        color: actualBgColor,
        child: Padding(padding: padding, child: child),
      ),
    );
  }
}

/// Adds hover animation to buttons
class AnimatedButtonWrapper extends StatelessWidget {
  final Widget child;
  final VoidCallback onTap;
  final double hoverScale;
  final Color? hoverColor;
  final BorderRadius borderRadius;
  final Duration duration;

  const AnimatedButtonWrapper({
    super.key,
    required this.child,
    required this.onTap,
    this.hoverScale = 1.05,
    this.hoverColor,
    this.borderRadius = const BorderRadius.all(Radius.circular(8)),
    this.duration = const Duration(milliseconds: 150),
  });

  @override
  Widget build(BuildContext context) {
    final themeController = Get.find<ThemeController>();
    final effectiveHoverColor =
        hoverColor ?? themeController.primaryColor.withOpacity(0.1);

    // Skip hover effect on non-web platforms
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
