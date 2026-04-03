import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_web_portfolio/app/controllers/language_controller.dart';
import 'package:flutter_web_portfolio/app/core/constants/app_config.dart';
import 'package:flutter_web_portfolio/app/controllers/scroll_controller.dart';
import 'package:flutter_web_portfolio/app/controllers/scene_director.dart';
import 'package:flutter_web_portfolio/app/core/constants/app_colors.dart';
import 'package:flutter_web_portfolio/app/core/constants/breakpoints.dart';
import 'package:flutter_web_portfolio/app/core/constants/cinematic_curves.dart';
import 'package:flutter_web_portfolio/app/core/constants/durations.dart';
import 'package:flutter_web_portfolio/app/widgets/cinematic_focusable.dart';
import 'package:flutter_web_portfolio/app/widgets/fullscreen_menu.dart';
import 'package:flutter_web_portfolio/app/widgets/language_switcher.dart';

/// Minimal floating navigation — cinematic, no numbered sections.
/// Shrinks from 80px to 60px as the user scrolls down (200px threshold).
class CustomSliverAppBar extends StatefulWidget {
  const CustomSliverAppBar({
    super.key,
    required this.languageController,
    required this.scrollController,
    this.actions,
  });

  final LanguageController languageController;
  final AppScrollController scrollController;
  final List<Widget>? actions;

  /// Nav sections derived at build-time from active sections (excludes 'home').
  static List<String> navSections(LanguageController lc) =>
      lc.activeSections.where((s) => s != 'home').toList();

  /// Maximum (expanded) toolbar height.
  static const _maxHeight = 80.0;

  /// Minimum (collapsed) toolbar height.
  static const _minHeight = 60.0;

  /// Scroll distance over which the bar shrinks.
  static const _shrinkScrollExtent = 200.0;

  @override
  State<CustomSliverAppBar> createState() => _CustomSliverAppBarState();
}

class _CustomSliverAppBarState extends State<CustomSliverAppBar> {
  double _toolbarHeight = CustomSliverAppBar._maxHeight;

  /// Scale factor for logo and nav items: 1.0 at top, smaller when collapsed.
  double get _scaleFactor =>
      _toolbarHeight / CustomSliverAppBar._maxHeight;

  @override
  void initState() {
    super.initState();
    widget.scrollController.scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    widget.scrollController.scrollController.removeListener(_onScroll);
    super.dispose();
  }

  void _onScroll() {
    final controller = widget.scrollController.scrollController;
    if (!controller.hasClients) return;

    final offset = controller.offset.clamp(0.0, CustomSliverAppBar._shrinkScrollExtent);
    final t = offset / CustomSliverAppBar._shrinkScrollExtent;
    final newHeight = lerpDouble(
      CustomSliverAppBar._maxHeight,
      CustomSliverAppBar._minHeight,
      t,
    )!;

    if ((newHeight - _toolbarHeight).abs() > 0.5) {
      setState(() => _toolbarHeight = newHeight);
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isMobile = screenWidth < Breakpoints.tablet;

    return SliverAppBar(
      floating: false,
      snap: false,
      pinned: true,
      toolbarHeight: _toolbarHeight,
      backgroundColor: Colors.transparent,
      elevation: 0,
      automaticallyImplyLeading: false,
      flexibleSpace: Column(
        children: [
          Expanded(
            child: ClipRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.background.withValues(alpha: 0.75),
                    border: const Border(
                      bottom: BorderSide(
                        color: Color(0x0DFFFFFF),
                        width: 1,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          _SceneProgressBar(scrollController: widget.scrollController),
        ],
      ),
      title: _LogoText(
        onTap: () => widget.scrollController.scrollToSection('home'),
        scaleFactor: _scaleFactor,
        languageController: widget.languageController,
      ),
      leading: isMobile
          ? IconButton(
              icon: Icon(
                Icons.menu_rounded,
                color: AppColors.textPrimary,
                size: 24 * _scaleFactor,
              ),
              onPressed: () => FullscreenMenu.show(context),
            )
          : null,
      actions: [
        if (!isMobile) _buildNavItems(),
        const LanguageSwitcher(),
        ...?widget.actions,
        const SizedBox(width: 16),
      ],
    );
  }

  Widget _buildNavItems() => Obx(() {
    final currentSection = widget.scrollController.activeSection.value;
    final sections = CustomSliverAppBar.navSections(widget.languageController);
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        for (final section in sections)
          _NavItem(
            label: widget.languageController.getText(
              'nav.$section',
              defaultValue: section.toUpperCase(),
            ),
            isActive: currentSection == section,
            onTap: () => widget.scrollController.scrollToSection(section),
            scaleFactor: _scaleFactor,
          ),
      ],
    );
  });

}

// ---------------------------------------------------------------------------
// Logo: "YG" — Space Grotesk Bold, hover glow
// ---------------------------------------------------------------------------
class _LogoText extends StatefulWidget {
  const _LogoText({required this.onTap, this.scaleFactor = 1.0, required this.languageController});
  final VoidCallback onTap;
  final double scaleFactor;
  final LanguageController languageController;

  @override
  State<_LogoText> createState() => _LogoTextState();
}

class _LogoTextState extends State<_LogoText> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    const baseColor = AppColors.textBright;
    const hoverColor = Colors.white;

    return Semantics(
      button: true,
      label: 'Scroll to top',
      child: CinematicFocusable(
        onTap: widget.onTap,
        onHoverChanged: (h) => setState(() => _hovered = h),
        child: AnimatedContainer(
          duration: AppDurations.buttonHover,
          child: Text(
            AppConfig.initials(widget.languageController),
            style: GoogleFonts.spaceGrotesk(
              fontSize: 20 * widget.scaleFactor,
              fontWeight: FontWeight.w700,
              color: _hovered ? hoverColor : baseColor,
              letterSpacing: 1,
              shadows: _hovered
                  ? [
                      Shadow(
                        color: hoverColor.withValues(alpha: 0.3),
                        blurRadius: 12,
                      ),
                    ]
                  : [],
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Nav item: uppercase, hover underline animation
// ---------------------------------------------------------------------------
class _NavItem extends StatefulWidget {
  const _NavItem({
    required this.label,
    required this.isActive,
    required this.onTap,
    this.scaleFactor = 1.0,
  });

  final String label;
  final bool isActive;
  final VoidCallback onTap;
  final double scaleFactor;

  @override
  State<_NavItem> createState() => _NavItemState();
}

class _NavItemState extends State<_NavItem> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    const activeColor = AppColors.textBright;
    const inactiveColor = AppColors.textPrimary;
    const underlineColor = Colors.white;

    return Semantics(
      button: true,
      label: widget.label,
      child: CinematicFocusable(
        onTap: widget.onTap,
        onHoverChanged: (h) => setState(() => _hovered = h),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.label.toUpperCase(),
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 12 * widget.scaleFactor,
                  fontWeight: widget.isActive ? FontWeight.w600 : FontWeight.w400,
                  color: widget.isActive
                      ? activeColor
                      : (_hovered ? activeColor : inactiveColor),
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 4),
              // Underline — animates from left
              Align(
                alignment: Alignment.centerLeft,
                child: AnimatedContainer(
                  duration: AppDurations.buttonHover,
                  curve: CinematicCurves.hoverLift,
                  width: widget.isActive || _hovered ? 20 : 0,
                  height: 1,
                  color: underlineColor.withValues(
                    alpha: widget.isActive ? 0.6 : 0.3,
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

// ---------------------------------------------------------------------------
// Scene-aware scroll progress bar (1px, gradient with scene accent)
// ---------------------------------------------------------------------------
class _SceneProgressBar extends StatefulWidget {
  const _SceneProgressBar({required this.scrollController});
  final AppScrollController scrollController;

  @override
  State<_SceneProgressBar> createState() => _SceneProgressBarState();
}

class _SceneProgressBarState extends State<_SceneProgressBar> {
  double _progress = 0;

  @override
  void initState() {
    super.initState();
    widget.scrollController.scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    widget.scrollController.scrollController.removeListener(_onScroll);
    super.dispose();
  }

  void _onScroll() {
    final controller = widget.scrollController.scrollController;
    if (!controller.hasClients) return;
    final maxExtent = controller.position.maxScrollExtent;
    if (maxExtent <= 0) return;
    setState(() {
      _progress = (controller.offset / maxExtent).clamp(0.0, 1.0);
    });
  }

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 1,
    child: LayoutBuilder(
      builder: (context, constraints) => Obx(() {
        final accent = Get.find<SceneDirector>().currentAccent.value;
        return Stack(
          children: [
            AnimatedContainer(
              duration: AppDurations.microFast,
              width: constraints.maxWidth * _progress,
              height: 1,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    accent.withValues(alpha: 0.2),
                    accent,
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: accent.withValues(alpha: 0.3),
                    blurRadius: 4,
                  ),
                ],
              ),
            ),
          ],
        );
      }),
    ),
  );
}

