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
    Key? key,
    required this.child,
    required this.sectionKey,
    required this.sectionId,
    this.backgroundColor,
    this.useHoverLight = true,
    this.padding = const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
    this.noBackground = false,
    this.minHeight,
  }) : super(key: key);

  @override
  State<SectionWrapper> createState() => _SectionWrapperState();
}

class _SectionWrapperState extends State<SectionWrapper>
    with SingleTickerProviderStateMixin {
  // For tracking hover state
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    // Initialize SharedBackgroundController for the first section
    if (widget.sectionId == 'home' &&
        !SharedBackgroundController.isInitialized) {
      SharedBackgroundController.init(this);
    }
  }

  void _updateMousePosition(PointerEvent event) {
    // Update mouse position
    if (widget.sectionId == 'home') {
      SharedBackgroundController.updateMousePosition(event.localPosition);
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeController = Get.find<ThemeController>();
    final screenHeight = MediaQuery.of(context).size.height;

    // Base container
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
        // No margin to ensure no gaps between sections
        margin: EdgeInsets.zero,
        constraints: BoxConstraints(
          minHeight:
              widget.minHeight ??
              (widget.sectionId == 'home'
                  ? screenHeight - 80
                  : (widget.sectionId == 'about'
                      ? screenHeight -
                          80 // Same height for about section
                      : screenHeight * 0.7)),
        ),
        // Background should be completely transparent
        color: Colors.transparent,
        child: Stack(
          children: [
            // Hover effect - Very light and transparent (hidden if noBackground is true)
            if (!widget.noBackground)
              AnimatedOpacity(
                opacity: _isHovered ? 0.5 : 0.0, // Reduced opacity
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

            // Content - tighter padding and transition for Home and About
            Padding(
              padding:
                  widget.sectionId == 'home'
                      ? const EdgeInsets.only(
                        bottom: 0,
                      ) // No bottom padding for home section
                      : (widget.sectionId == 'about'
                          ? const EdgeInsets.only(
                            top: 0,
                          ) // No top padding for about section
                          : widget.padding),
              child: widget.child,
            ),
          ],
        ),
      ),
    );
  }
}

/// Card biçimindeki widget'lara hover animasyonu ekler
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
    Key? key,
    required this.child,
    this.elevation = 5,
    this.borderRadius = const BorderRadius.all(Radius.circular(16)),
    this.backgroundColor,
    this.hoverScale = 1.03,
    this.duration = const Duration(milliseconds: 200),
    this.margin = const EdgeInsets.all(8),
    this.padding = const EdgeInsets.all(16),
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final themeController = Get.find<ThemeController>();
    final actualBgColor =
        backgroundColor ?? const Color(0xFF001628).withOpacity(0.7);

    // Web platformu dışında hover efekti olmayan normal kart
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

/// Butonlar için hover animasyonu ekler
class AnimatedButtonWrapper extends StatelessWidget {
  final Widget child;
  final VoidCallback onTap;
  final double hoverScale;
  final Color? hoverColor;
  final BorderRadius borderRadius;
  final Duration duration;

  const AnimatedButtonWrapper({
    Key? key,
    required this.child,
    required this.onTap,
    this.hoverScale = 1.05,
    this.hoverColor,
    this.borderRadius = const BorderRadius.all(Radius.circular(8)),
    this.duration = const Duration(milliseconds: 150),
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final themeController = Get.find<ThemeController>();
    final effectiveHoverColor =
        hoverColor ?? themeController.primaryColor.withOpacity(0.1);

    // Web platformu dışında hover efekti olmayan normal buton
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
