import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:flutter_web_portfolio/app/controllers/scroll_controller.dart';
import 'package:flutter_web_portfolio/app/controllers/language_controller.dart';
import 'package:flutter_web_portfolio/app/controllers/sound_controller.dart';
import 'package:flutter_web_portfolio/app/core/constants/app_colors.dart';
import 'package:flutter_web_portfolio/app/core/constants/breakpoints.dart';
import 'package:flutter_web_portfolio/app/core/constants/cinematic_curves.dart';

/// Full-screen overlay menu with staggered panel animations.
///
/// Inspired by award-winning portfolio navigation — panels drop in like a
/// curtain, each item enters with a staggered delay, and the background
/// blurs behind a glassmorphic overlay.
///
/// Usage:
/// ```dart
/// FullscreenMenu.show(context);
/// ```
class FullscreenMenu extends StatefulWidget {
  const FullscreenMenu({super.key});

  static void show(BuildContext context) {
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierDismissible: true,
        barrierColor: Colors.transparent,
        transitionDuration: const Duration(milliseconds: 600),
        reverseTransitionDuration: const Duration(milliseconds: 400),
        pageBuilder: (_, __, ___) => const FullscreenMenu(),
      ),
    );
  }

  @override
  State<FullscreenMenu> createState() => _FullscreenMenuState();
}

class _FullscreenMenuState extends State<FullscreenMenu>
    with TickerProviderStateMixin {
  late AnimationController _masterController;
  late Animation<double> _backdropBlur;
  late Animation<double> _overlayOpacity;

  int _hoveredIndex = -1;

  static const _iconMap = <String, IconData>{
    'home': Icons.home_outlined,
    'about': Icons.person_outline,
    'experience': Icons.work_outline,
    'projects': Icons.code_outlined,
    'blog': Icons.article_outlined,
    'testimonials': Icons.format_quote_outlined,
    'contact': Icons.mail_outline,
  };

  List<_MenuItem> _buildMenuItems() {
    // Drop 'home' — the logo already scrolls to top, so listing it here
    // produces a confusing duplicate row at the top of the drawer.
    final sections = Get.find<LanguageController>()
        .activeSections
        .where((s) => s != 'home')
        .toList();
    return [
      for (var i = 0; i < sections.length; i++)
        _MenuItem(
          sectionId: sections[i],
          icon: _iconMap[sections[i]] ?? Icons.circle_outlined,
          number: (i + 1).toString().padLeft(2, '0'),
        ),
    ];
  }

  @override
  void initState() {
    super.initState();

    _masterController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _backdropBlur = Tween<double>(begin: 0, end: 20).animate(
      CurvedAnimation(
        parent: _masterController,
        curve: const Interval(0.0, 0.4, curve: Curves.easeOut),
      ),
    );

    _overlayOpacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _masterController,
        curve: const Interval(0.0, 0.3, curve: Curves.easeOut),
      ),
    );

    _masterController.forward();
    if (Get.isRegistered<SoundController>()) {
      Get.find<SoundController>().playTransition();
    }
  }

  @override
  void dispose() {
    _masterController.dispose();
    super.dispose();
  }

  void _close() {
    _masterController.reverse().then((_) {
      if (mounted) Navigator.of(context).pop();
    });
  }

  void _navigateToSection(String key) {
    _close();
    Future.delayed(const Duration(milliseconds: 300), () {
      Get.find<AppScrollController>().scrollToSection(key);
    });
  }

  @override
  Widget build(BuildContext context) {
    final languageController = Get.find<LanguageController>();
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isMobile = screenWidth < Breakpoints.tablet;
    final menuItems = _buildMenuItems();

    return AnimatedBuilder(
      animation: _masterController,
      builder: (context, _) => Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              onTap: _close,
              child: BackdropFilter(
                filter: ImageFilter.blur(
                  sigmaX: _backdropBlur.value,
                  sigmaY: _backdropBlur.value,
                ),
                child: Container(
                  color: Colors.black
                      .withValues(alpha: 0.7 * _overlayOpacity.value),
                ),
              ),
            ),
          ),

          Positioned(
            top: 24,
            right: 24,
            child: Opacity(
              opacity: _overlayOpacity.value,
              child: IconButton(
                onPressed: _close,
                icon: const Icon(
                  Icons.close,
                  color: Colors.white,
                  size: 32,
                ),
              ),
            ),
          ),

          // Menu items
          Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: isMobile ? screenWidth * 0.9 : 700,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: List.generate(menuItems.length, (index) {
                  final item = menuItems[index];
                  final itemDelay = 0.15 + (index * 0.06);
                  final itemEnd = (itemDelay + 0.25).clamp(0.0, 1.0);

                  final itemAnimation = Tween<double>(begin: 0, end: 1).animate(
                    CurvedAnimation(
                      parent: _masterController,
                      curve: Interval(
                        itemDelay,
                        itemEnd,
                        curve: CinematicCurves.dramaticEntrance,
                      ),
                    ),
                  );

                  final label = languageController.getText(
                    'nav.${item.sectionId}',
                    defaultValue: item.sectionId[0].toUpperCase() + item.sectionId.substring(1),
                  );

                  return Opacity(
                    opacity: itemAnimation.value,
                    child: Transform.translate(
                      offset: Offset(0, 30 * (1 - itemAnimation.value)),
                      child: _MenuItemWidget(
                        item: item,
                        label: label,
                        isHovered: _hoveredIndex == index,
                        isMobile: isMobile,
                        onTap: () => _navigateToSection(item.sectionId),
                        onHover: (hovered) {
                          setState(() => _hoveredIndex = hovered ? index : -1);
                        },
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MenuItem {
  const _MenuItem({
    required this.sectionId,
    required this.icon,
    required this.number,
  });
  final String sectionId;
  final IconData icon;
  final String number;
}

class _MenuItemWidget extends StatelessWidget {
  const _MenuItemWidget({
    required this.item,
    required this.label,
    required this.isHovered,
    required this.isMobile,
    required this.onTap,
    required this.onHover,
  });

  final _MenuItem item;
  final String label;
  final bool isHovered;
  final bool isMobile;
  final VoidCallback onTap;
  final ValueChanged<bool> onHover;

  @override
  Widget build(BuildContext context) {
    const textColor = Colors.white;
    const accentColor = AppColors.accent;
    final fontSize = isMobile ? 28.0 : 48.0;

    return MouseRegion(
      onEnter: (_) => onHover(true),
      onExit: (_) => onHover(false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          padding: EdgeInsets.symmetric(
            vertical: isMobile ? 12 : 16,
            horizontal: isHovered ? 16 : 0,
          ),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: Colors.white.withValues(alpha: 0.08),
                width: 1,
              ),
            ),
          ),
          child: Row(
            children: [
              // Number
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 200),
                style: GoogleFonts.jetBrainsMono(
                  fontSize: isMobile ? 12 : 14,
                  fontWeight: FontWeight.w400,
                  color: isHovered ? accentColor : textColor.withValues(alpha: 0.4),
                  letterSpacing: 2,
                ),
                child: Text(item.number),
              ),
              SizedBox(width: isMobile ? 16 : 32),

              // Icon
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                child: Icon(
                  item.icon,
                  size: isMobile ? 20 : 24,
                  color: isHovered ? accentColor : textColor.withValues(alpha: 0.5),
                ),
              ),
              SizedBox(width: isMobile ? 12 : 24),

              // Label
              Expanded(
                child: AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 200),
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: fontSize,
                    fontWeight: isHovered ? FontWeight.w700 : FontWeight.w300,
                    color: isHovered ? accentColor : textColor,
                    letterSpacing: isHovered ? 2 : 0,
                  ),
                  child: Text(label),
                ),
              ),

              // Arrow on hover
              AnimatedOpacity(
                duration: const Duration(milliseconds: 200),
                opacity: isHovered ? 1.0 : 0.0,
                child: AnimatedSlide(
                  duration: const Duration(milliseconds: 200),
                  offset: Offset(isHovered ? 0 : -0.5, 0),
                  child: Icon(
                    Icons.arrow_forward,
                    color: accentColor,
                    size: isMobile ? 20 : 28,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
