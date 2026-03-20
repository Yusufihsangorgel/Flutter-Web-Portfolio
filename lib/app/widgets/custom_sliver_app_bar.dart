import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_web_portfolio/app/controllers/language_controller.dart';
import 'package:flutter_web_portfolio/app/controllers/scroll_controller.dart';
import 'package:flutter_web_portfolio/app/controllers/scene_director.dart';
import 'package:flutter_web_portfolio/app/core/constants/app_colors.dart';
import 'package:flutter_web_portfolio/app/core/constants/breakpoints.dart';
import 'package:flutter_web_portfolio/app/core/constants/cinematic_curves.dart';
import 'package:flutter_web_portfolio/app/core/constants/durations.dart';
import 'package:flutter_web_portfolio/app/widgets/cinematic_focusable.dart';
import 'package:flutter_web_portfolio/app/widgets/language_switcher.dart';

/// Minimal floating navigation — cinematic, no numbered sections.
class CustomSliverAppBar extends StatelessWidget {
  const CustomSliverAppBar({
    super.key,
    required this.languageController,
    required this.scrollController,
    this.actions,
  });

  final LanguageController languageController;
  final AppScrollController scrollController;
  final List<Widget>? actions;

  static const _navSections = ['about', 'experience', 'projects', 'contact'];

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isMobile = screenWidth < Breakpoints.tablet;

    return SliverAppBar(
      floating: false,
      snap: false,
      pinned: true,
      toolbarHeight: 70,
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
                    border: Border(
                      bottom: BorderSide(
                        color: Colors.white.withValues(alpha: 0.05),
                        width: 1,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          _SceneProgressBar(scrollController: scrollController),
        ],
      ),
      title: _LogoText(
        onTap: () => scrollController.scrollToSection('home'),
      ),
      leading: isMobile
          ? Builder(
              builder: (context) => IconButton(
                icon: const Icon(
                  Icons.menu_rounded,
                  color: AppColors.textPrimary,
                  size: 24,
                ),
                onPressed: () => _showMobileMenu(context),
              ),
            )
          : null,
      actions: [
        if (!isMobile) _buildNavItems(),
        const LanguageSwitcher(),
        ...?actions,
        const SizedBox(width: 16),
      ],
    );
  }

  Widget _buildNavItems() => Obx(() {
    final currentSection = scrollController.activeSection.value;
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        for (int i = 0; i < _navSections.length; i++)
          _NavItem(
            label: languageController.getText(
              'nav.${_navSections[i]}',
              defaultValue: _navSections[i].toUpperCase(),
            ),
            isActive: currentSection == _navSections[i],
            onTap: () => scrollController.scrollToSection(_navSections[i]),
          ),
      ],
    );
  });

  void _showMobileMenu(BuildContext context) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Close menu',
      barrierColor: AppColors.background.withValues(alpha: 0.95),
      transitionDuration: AppDurations.medium,
      transitionBuilder: (context, animation, secondaryAnimation, child) =>
          FadeTransition(
            opacity: CurvedAnimation(
              parent: animation,
              curve: CinematicCurves.revealDecel,
            ),
            child: child,
          ),
      pageBuilder: (context, animation, secondaryAnimation) =>
          _MobileMenuOverlay(
            navSections: _navSections,
            languageController: languageController,
            scrollController: scrollController,
          ),
    );
  }
}

// ---------------------------------------------------------------------------
// Logo: "YG" — Space Grotesk Bold, hover glow
// ---------------------------------------------------------------------------
class _LogoText extends StatefulWidget {
  const _LogoText({required this.onTap});
  final VoidCallback onTap;

  @override
  State<_LogoText> createState() => _LogoTextState();
}

class _LogoTextState extends State<_LogoText> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: 'Scroll to top',
    child: CinematicFocusable(
      onTap: widget.onTap,
      onHoverChanged: (h) => setState(() => _hovered = h),
      child: AnimatedContainer(
        duration: AppDurations.buttonHover,
        child: Text(
          'YG',
        style: GoogleFonts.spaceGrotesk(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: _hovered ? Colors.white : AppColors.textBright,
          letterSpacing: 1,
          shadows: _hovered
              ? [
                  Shadow(
                    color: Colors.white.withValues(alpha: 0.3),
                    blurRadius: 12,
                  ),
                ]
              : [],
        ),
      ),
    )),
  );
}

// ---------------------------------------------------------------------------
// Nav item: uppercase, hover underline animation
// ---------------------------------------------------------------------------
class _NavItem extends StatefulWidget {
  const _NavItem({
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  final String label;
  final bool isActive;
  final VoidCallback onTap;

  @override
  State<_NavItem> createState() => _NavItemState();
}

class _NavItemState extends State<_NavItem> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) => Semantics(
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
              fontSize: 12,
              fontWeight: widget.isActive ? FontWeight.w600 : FontWeight.w400,
              color: widget.isActive
                  ? AppColors.textBright
                  : (_hovered ? AppColors.textBright : AppColors.textPrimary),
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 4),
          // Underline — animates from left
          AnimatedContainer(
            duration: AppDurations.buttonHover,
            curve: CinematicCurves.hoverLift,
            width: widget.isActive || _hovered ? 20 : 0,
            height: 1,
            color: Colors.white.withValues(
              alpha: widget.isActive ? 0.6 : 0.3,
            ),
          ),
          ],
        ),
      ),
    ),
  );
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
            Container(color: Colors.transparent),
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

// ---------------------------------------------------------------------------
// Mobile menu overlay — fullscreen, cinematic
// ---------------------------------------------------------------------------
class _MobileMenuOverlay extends StatelessWidget {
  const _MobileMenuOverlay({
    required this.navSections,
    required this.languageController,
    required this.scrollController,
  });

  final List<String> navSections;
  final LanguageController languageController;
  final AppScrollController scrollController;

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.transparent,
    child: Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Close button
          Align(
            alignment: Alignment.topRight,
            child: Padding(
              padding: const EdgeInsets.only(right: 24, bottom: 40),
              child: IconButton(
                icon: const Icon(
                  Icons.close_rounded,
                  color: AppColors.textPrimary,
                  size: 28,
                ),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ),
          // Nav items — clean, centered
          for (final section in navSections)
            _MobileNavItem(
              label: languageController.getText(
                'nav.$section',
                defaultValue: section.toUpperCase(),
              ),
              onTap: () {
                Navigator.pop(context);
                scrollController.scrollToSection(section);
              },
            ),
          const SizedBox(height: 24),
          const LanguageSwitcher(),
        ],
      ),
    ),
  );
}

class _MobileNavItem extends StatefulWidget {
  const _MobileNavItem({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  State<_MobileNavItem> createState() => _MobileNavItemState();
}

class _MobileNavItemState extends State<_MobileNavItem> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) => MouseRegion(
    onEnter: (_) => setState(() => _hovered = true),
    onExit: (_) => setState(() => _hovered = false),
    cursor: SystemMouseCursors.click,
    child: GestureDetector(
      onTap: widget.onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Text(
          widget.label.toUpperCase(),
          style: GoogleFonts.spaceGrotesk(
            color: _hovered ? AppColors.textBright : AppColors.textPrimary,
            fontWeight: FontWeight.w500,
            fontSize: 24,
            letterSpacing: 4,
          ),
        ),
      ),
    ),
  );
}
