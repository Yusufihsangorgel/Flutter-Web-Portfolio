import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_web_portfolio/app/controllers/audio_controller.dart';
import 'package:flutter_web_portfolio/app/controllers/language_controller.dart';
import 'package:flutter_web_portfolio/app/controllers/scroll_controller.dart';
import 'package:flutter_web_portfolio/app/controllers/scene_director.dart';
import 'package:flutter_web_portfolio/app/core/constants/app_colors.dart';
import 'package:flutter_web_portfolio/app/core/constants/breakpoints.dart';
import 'package:flutter_web_portfolio/app/core/constants/cinematic_curves.dart';
import 'package:flutter_web_portfolio/app/core/constants/durations.dart';
import 'package:flutter_web_portfolio/app/controllers/theme_controller.dart';
import 'package:flutter_web_portfolio/app/widgets/cinematic_focusable.dart';
import 'package:flutter_web_portfolio/app/widgets/circular_theme_reveal.dart';
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
      flexibleSpace: Obx(() {
        final isDark = Get.isRegistered<ThemeController>()
            ? Get.find<ThemeController>().isDarkMode.value
            : true;
        return Column(
          children: [
            Expanded(
              child: ClipRect(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                  child: Container(
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.background.withValues(alpha: 0.75)
                          : AppColors.lightBackground.withValues(alpha: 0.85),
                      border: Border(
                        bottom: BorderSide(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.05)
                              : Colors.black.withValues(alpha: 0.06),
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
        );
      }),
      title: _LogoText(
        onTap: () => widget.scrollController.scrollToSection('home'),
        scaleFactor: _scaleFactor,
      ),
      leading: isMobile
          ? Builder(
              builder: (context) {
                final isDark = Theme.of(context).brightness == Brightness.dark;
                return IconButton(
                  icon: Icon(
                    Icons.menu_rounded,
                    color: isDark ? AppColors.textPrimary : AppColors.lightTextPrimary,
                    size: 24 * _scaleFactor,
                  ),
                  onPressed: () => FullscreenMenu.show(context),
                );
              },
            )
          : null,
      actions: [
        if (!isMobile) _buildNavItems(),
        if (!isMobile) const _AudioToggleButton(),
        if (!isMobile) const _ThemeToggleButton(),
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

  void _showMobileMenu(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Close menu',
      barrierColor: isDark
          ? AppColors.background.withValues(alpha: 0.95)
          : AppColors.lightBackground.withValues(alpha: 0.95),
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
            navSections: CustomSliverAppBar.navSections(widget.languageController),
            languageController: widget.languageController,
            scrollController: widget.scrollController,
          ),
    );
  }
}

// ---------------------------------------------------------------------------
// Logo: "YG" — Space Grotesk Bold, hover glow
// ---------------------------------------------------------------------------
class _LogoText extends StatefulWidget {
  const _LogoText({required this.onTap, this.scaleFactor = 1.0});
  final VoidCallback onTap;
  final double scaleFactor;

  @override
  State<_LogoText> createState() => _LogoTextState();
}

class _LogoTextState extends State<_LogoText> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor = isDark ? AppColors.textBright : AppColors.lightTextBright;
    final hoverColor = isDark ? Colors.white : AppColors.lightTextBright;

    return Semantics(
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
// Audio toggle: speaker on/off icon
// ---------------------------------------------------------------------------
class _AudioToggleButton extends StatelessWidget {
  const _AudioToggleButton();

  @override
  Widget build(BuildContext context) {
    if (!Get.isRegistered<AudioController>()) {
      return const SizedBox.shrink();
    }
    final audioController = Get.find<AudioController>();

    return Obx(() {
      final muted = audioController.isMuted.value;
      final isDark = Get.isRegistered<ThemeController>()
          ? Get.find<ThemeController>().isDarkMode.value
          : true;

      return Semantics(
        button: true,
        label: muted ? 'Enable sound effects' : 'Mute sound effects',
        child: IconButton(
          onPressed: audioController.toggleMute,
          icon: AnimatedSwitcher(
            duration: AppDurations.buttonHover,
            switchInCurve: CinematicCurves.revealDecel,
            switchOutCurve: CinematicCurves.revealDecel,
            transitionBuilder: (child, animation) => FadeTransition(
              opacity: animation,
              child: ScaleTransition(scale: animation, child: child),
            ),
            child: Icon(
              muted ? Icons.volume_off_rounded : Icons.volume_up_rounded,
              key: ValueKey(muted),
              color: isDark
                  ? AppColors.textPrimary
                  : AppColors.lightTextPrimary,
              size: 20,
            ),
          ),
        ),
      );
    });
  }
}

// ---------------------------------------------------------------------------
// Theme toggle: animated sun/moon icon
// ---------------------------------------------------------------------------
class _ThemeToggleButton extends StatelessWidget {
  const _ThemeToggleButton();

  @override
  Widget build(BuildContext context) {
    if (!Get.isRegistered<ThemeController>()) {
      return const SizedBox.shrink();
    }
    final themeController = Get.find<ThemeController>();

    return Obx(() {
      final isDark = themeController.isDarkMode.value;
      return Semantics(
        button: true,
        label: isDark ? 'Switch to light mode' : 'Switch to dark mode',
        child: IconButton(
          onPressed: () => CircularThemeReveal.toggleWithReveal(context),
          icon: AnimatedSwitcher(
            duration: AppDurations.buttonHover,
            switchInCurve: CinematicCurves.revealDecel,
            switchOutCurve: CinematicCurves.revealDecel,
            transitionBuilder: (child, animation) => RotationTransition(
              turns: Tween(begin: 0.75, end: 1.0).animate(animation),
              child: FadeTransition(opacity: animation, child: child),
            ),
            child: Icon(
              isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
              key: ValueKey(isDark),
              color: isDark ? AppColors.textPrimary : AppColors.lightTextPrimary,
              size: 20,
            ),
          ),
        ),
      );
    });
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final activeColor = isDark ? AppColors.textBright : AppColors.lightTextBright;
    final inactiveColor = isDark ? AppColors.textPrimary : AppColors.lightTextPrimary;
    final underlineColor = isDark ? Colors.white : Colors.black;

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
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final iconColor = isDark ? AppColors.textPrimary : AppColors.lightTextPrimary;

    return Material(
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
                  icon: Icon(
                    Icons.close_rounded,
                    color: iconColor,
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
            const SizedBox(height: 32),
            // Mobile-only controls
            const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _AudioToggleButton(),
                SizedBox(width: 8),
                _ThemeToggleButton(),
                SizedBox(width: 8),
                LanguageSwitcher(key: ValueKey('mobile-lang')),
              ],
            ),
          ],
        ),
      ),
    );
  }
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
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final activeColor = isDark ? AppColors.textBright : AppColors.lightTextBright;
    final inactiveColor = isDark ? AppColors.textPrimary : AppColors.lightTextPrimary;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.label.toUpperCase(),
                style: GoogleFonts.spaceGrotesk(
                  color: _hovered ? activeColor : inactiveColor,
                  fontWeight: FontWeight.w500,
                  fontSize: 24,
                  letterSpacing: 4,
                ),
              ),
              const SizedBox(height: 4),
              AnimatedContainer(
                duration: AppDurations.fast,
                curve: CinematicCurves.hoverLift,
                height: 1,
                width: _hovered ? 40 : 0,
                color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.3),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
