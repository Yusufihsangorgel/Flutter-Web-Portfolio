import 'package:flutter/material.dart';
import 'package:flutter_web_portfolio/app/widgets/cosmic_background.dart';
import 'package:get/get.dart';
import 'package:flutter_web_portfolio/app/controllers/theme_controller.dart';
import 'package:flutter_web_portfolio/app/widgets/mouse_effects.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_web_portfolio/app/modules/home/sections/home_section.dart';
import 'package:flutter_web_portfolio/app/controllers/shared_background_controller.dart';

/// Bölümleri hover animasyonları ve kozmik arka plan ile sarmalayan widget
class SectionWrapper extends StatefulWidget {
  final Widget child;
  final GlobalKey sectionKey;
  final String sectionId;
  final Color? backgroundColor;
  final bool useHoverLight;
  final EdgeInsetsGeometry padding;

  const SectionWrapper({
    Key? key,
    required this.child,
    required this.sectionKey,
    required this.sectionId,
    this.backgroundColor,
    this.useHoverLight = true,
    this.padding = const EdgeInsets.symmetric(vertical: 80, horizontal: 24),
  }) : super(key: key);

  @override
  State<SectionWrapper> createState() => _SectionWrapperState();
}

class _SectionWrapperState extends State<SectionWrapper>
    with SingleTickerProviderStateMixin {
  @override
  void initState() {
    super.initState();
    // İlk bölüm için SharedBackgroundController'ı başlat
    SharedBackgroundController.init(this);
  }

  @override
  Widget build(BuildContext context) {
    final themeController = Get.find<ThemeController>();
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    // Temel container
    return MouseRegion(
      onHover: (event) {
        SharedBackgroundController.updateMousePosition(event.localPosition);
      },
      child: Container(
        key: widget.sectionKey,
        constraints: BoxConstraints(
          minHeight: screenHeight - 80, // AppBar yüksekliği çıkarılmış
        ),
        child: Stack(
          children: [
            // Kozmik arka plan - artık ortak controller kullanıyor
            Positioned.fill(
              child: CosmicBackground(
                animationController:
                    SharedBackgroundController.animationController,
                scrollController: null,
                pageHeight: screenHeight,
              ),
            ),

            // İçerik
            Padding(padding: widget.padding, child: widget.child),
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
