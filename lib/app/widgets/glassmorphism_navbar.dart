import 'dart:ui';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:flutter_web_portfolio/app/controllers/audio_controller.dart';
import 'package:flutter_web_portfolio/app/controllers/language_controller.dart';
import 'package:flutter_web_portfolio/app/controllers/scroll_controller.dart';
import 'package:flutter_web_portfolio/app/controllers/scene_director.dart';
import 'package:flutter_web_portfolio/app/controllers/theme_controller.dart';
import 'package:flutter_web_portfolio/app/core/constants/app_colors.dart';
import 'package:flutter_web_portfolio/app/core/constants/breakpoints.dart';
import 'package:flutter_web_portfolio/app/core/constants/cinematic_curves.dart';
import 'package:flutter_web_portfolio/app/core/constants/durations.dart';
import 'package:flutter_web_portfolio/app/widgets/language_switcher.dart';

/// Glassmorphism floating navigation bar with frosted-glass effect.
///
/// Features:
/// - BackdropFilter blur with semi-transparent background and subtle border
/// - Floats at top with margin, centered with rounded corners
/// - Show/hide on scroll direction (hides on scroll down, shows on scroll up)
/// - Active section detection from scroll position
/// - Scene-aware accent color transitions
/// - Magnetic hover effect on nav items
/// - Animated hamburger/X morph for mobile
/// - Entrance slide-down animation on page load
/// - Shadow intensifies on scroll
class GlassmorphismNavbar extends StatefulWidget {
  const GlassmorphismNavbar({super.key});

  @override
  State<GlassmorphismNavbar> createState() => _GlassmorphismNavbarState();
}

class _GlassmorphismNavbarState extends State<GlassmorphismNavbar>
    with TickerProviderStateMixin {
  late final AppScrollController _scrollCtrl;
  late final LanguageController _langCtrl;

  late final AnimationController _entranceController;
  late final Animation<double> _entranceSlide;
  late final Animation<double> _entranceOpacity;

  late final AnimationController _visibilityController;
  late final Animation<double> _visibilitySlide;

  double _lastScrollOffset = 0;
  bool _isVisible = true;
  double _scrollShadowOpacity = 0;

  /// Threshold in pixels before hide/show triggers.
  static const _scrollThreshold = 12.0;

  /// Maximum horizontal margin on desktop.
  static const _maxHorizontalMargin = 24.0;

  /// Navbar height.
  static const _navbarHeight = 64.0;

  /// Top margin.
  static const _topMargin = 16.0;

  @override
  void initState() {
    super.initState();
    _scrollCtrl = Get.find<AppScrollController>();
    _langCtrl = Get.find<LanguageController>();

    // Entrance animation — slides down from above on page load
    _entranceController = AnimationController(
      vsync: this,
      duration: AppDurations.entrance,
    );
    _entranceSlide = Tween<double>(begin: -1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: CinematicCurves.dramaticEntrance,
      ),
    );
    _entranceOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );

    // Visibility animation — slides up to hide, down to show
    _visibilityController = AnimationController(
      vsync: this,
      duration: AppDurations.medium,
    );
    _visibilitySlide = Tween<double>(begin: 0.0, end: -1.0).animate(
      CurvedAnimation(
        parent: _visibilityController,
        curve: CinematicCurves.easeInOutCinematic,
      ),
    );

    _scrollCtrl.scrollController.addListener(_onScroll);

    // Trigger entrance after a short delay for the hero to settle
    Future.delayed(AppDurations.heroInitialPause, () {
      if (mounted) _entranceController.forward();
    });
  }

  @override
  void dispose() {
    _scrollCtrl.scrollController.removeListener(_onScroll);
    _entranceController.dispose();
    _visibilityController.dispose();
    super.dispose();
  }

  void _onScroll() {
    final controller = _scrollCtrl.scrollController;
    if (!controller.hasClients) return;

    final offset = controller.offset;
    final delta = offset - _lastScrollOffset;

    // Update shadow intensity based on scroll position
    final newShadow = (offset / 200.0).clamp(0.0, 1.0);
    if ((newShadow - _scrollShadowOpacity).abs() > 0.02) {
      setState(() => _scrollShadowOpacity = newShadow);
    }

    // Show/hide based on scroll direction
    if (delta.abs() > _scrollThreshold) {
      if (delta > 0 && _isVisible && offset > _navbarHeight * 2) {
        // Scrolling down — hide
        _isVisible = false;
        _visibilityController.forward();
      } else if (delta < 0 && !_isVisible) {
        // Scrolling up — show
        _isVisible = true;
        _visibilityController.reverse();
      }
    }

    // Always show when near top
    if (offset < _navbarHeight && !_isVisible) {
      _isVisible = true;
      _visibilityController.reverse();
    }

    _lastScrollOffset = offset;
  }

  List<String> get _navSections =>
      _langCtrl.activeSections.where((s) => s != 'home').toList();

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isMobile = screenWidth < Breakpoints.tablet;

    // Responsive horizontal margin — more on wide screens, less on mobile
    final horizontalMargin = isMobile
        ? 12.0
        : math.min(_maxHorizontalMargin, screenWidth * 0.03);

    return AnimatedBuilder(
      animation: Listenable.merge([_entranceController, _visibilityController]),
      builder: (context, child) {
        final entranceOffset = _entranceSlide.value * (_navbarHeight + _topMargin + 20);
        final visibilityOffset = _visibilitySlide.value * (_navbarHeight + _topMargin + 20);

        return Positioned(
          top: _topMargin + entranceOffset + visibilityOffset,
          left: horizontalMargin,
          right: horizontalMargin,
          child: Opacity(
            opacity: _entranceOpacity.value,
            child: child!,
          ),
        );
      },
      child: Obx(() {
        final isDark = Get.isRegistered<ThemeController>()
            ? Get.find<ThemeController>().isDarkMode.value
            : true;
        final accent = Get.isRegistered<SceneDirector>()
            ? Get.find<SceneDirector>().currentAccent.value
            : AppColors.heroAccent;

        return _GlassContainer(
          height: _navbarHeight,
          isDark: isDark,
          accent: accent,
          shadowOpacity: _scrollShadowOpacity,
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: isMobile ? 16 : 24,
            ),
            child: Row(
              children: [
                // Left: Logo
                _GlassLogo(
                  onTap: () => _scrollCtrl.scrollToSection('home'),
                  accent: accent,
                ),

                const Spacer(),

                // Center: Nav links (desktop only)
                if (!isMobile)
                  _DesktopNavLinks(
                    sections: _navSections,
                    langCtrl: _langCtrl,
                    scrollCtrl: _scrollCtrl,
                    accent: accent,
                  ),

                if (!isMobile) const Spacer(),

                // Right: Controls
                if (!isMobile) ...[
                  _GlassThemeToggle(accent: accent),
                  const SizedBox(width: 4),
                  const LanguageSwitcher(),
                ],

                // Mobile: hamburger
                if (isMobile)
                  _GlassHamburger(
                    navSections: _navSections,
                    langCtrl: _langCtrl,
                    scrollCtrl: _scrollCtrl,
                    accent: accent,
                  ),
              ],
            ),
          ),
        );
      }),
    );
  }
}

// ---------------------------------------------------------------------------
// Glass container — frosted background with border and shadow
// ---------------------------------------------------------------------------
class _GlassContainer extends StatelessWidget {
  const _GlassContainer({
    required this.height,
    required this.isDark,
    required this.accent,
    required this.shadowOpacity,
    required this.child,
  });

  final double height;
  final bool isDark;
  final Color accent;
  final double shadowOpacity;
  final Widget child;

  @override
  Widget build(BuildContext context) => ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: AnimatedContainer(
          duration: AppDurations.medium,
          curve: CinematicCurves.easeInOutCinematic,
          height: height,
          decoration: BoxDecoration(
            color: isDark
                ? AppColors.background.withValues(alpha: 0.55)
                : AppColors.lightBackground.withValues(alpha: 0.65),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.10)
                  : Colors.white.withValues(alpha: 0.60),
              width: 1,
            ),
            boxShadow: [
              // Base shadow
              BoxShadow(
                color: Colors.black.withValues(
                  alpha: 0.08 + (shadowOpacity * 0.12),
                ),
                blurRadius: 16 + (shadowOpacity * 16),
                offset: Offset(0, 4 + (shadowOpacity * 4)),
              ),
              // Accent glow — subtle, scene-colored
              BoxShadow(
                color: accent.withValues(alpha: 0.04 + (shadowOpacity * 0.04)),
                blurRadius: 24,
                spreadRadius: -4,
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
}

// ---------------------------------------------------------------------------
// Logo — "YG" with accent-colored hover glow
// ---------------------------------------------------------------------------
class _GlassLogo extends StatefulWidget {
  const _GlassLogo({required this.onTap, required this.accent});
  final VoidCallback onTap;
  final Color accent;

  @override
  State<_GlassLogo> createState() => _GlassLogoState();
}

class _GlassLogoState extends State<_GlassLogo> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor = isDark ? AppColors.textBright : AppColors.lightTextBright;

    return Semantics(
      button: true,
      label: 'Scroll to top',
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: GestureDetector(
          onTap: () {
            if (Get.isRegistered<AudioController>()) {
              Get.find<AudioController>().playClick();
            }
            widget.onTap();
          },
          child: AnimatedContainer(
            duration: AppDurations.buttonHover,
            curve: CinematicCurves.hoverLift,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: _hovered
                  ? widget.accent.withValues(alpha: 0.08)
                  : Colors.transparent,
            ),
            child: Text(
              'YG',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: _hovered ? widget.accent : baseColor,
                letterSpacing: 2,
                shadows: _hovered
                    ? [
                        Shadow(
                          color: widget.accent.withValues(alpha: 0.4),
                          blurRadius: 16,
                        ),
                      ]
                    : [],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Desktop nav links row — centered, with magnetic hover and active indicator
// ---------------------------------------------------------------------------
class _DesktopNavLinks extends StatelessWidget {
  const _DesktopNavLinks({
    required this.sections,
    required this.langCtrl,
    required this.scrollCtrl,
    required this.accent,
  });

  final List<String> sections;
  final LanguageController langCtrl;
  final AppScrollController scrollCtrl;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final activeSection = scrollCtrl.activeSection.value;
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final section in sections)
            _MagneticNavItem(
              label: langCtrl.getText(
                'nav.$section',
                defaultValue: section.toUpperCase(),
              ),
              isActive: activeSection == section,
              accent: accent,
              onTap: () => scrollCtrl.scrollToSection(section),
            ),
        ],
      );
    });
  }
}

// ---------------------------------------------------------------------------
// Magnetic nav item — text follows cursor, animated underline
// ---------------------------------------------------------------------------
class _MagneticNavItem extends StatefulWidget {
  const _MagneticNavItem({
    required this.label,
    required this.isActive,
    required this.accent,
    required this.onTap,
  });

  final String label;
  final bool isActive;
  final Color accent;
  final VoidCallback onTap;

  @override
  State<_MagneticNavItem> createState() => _MagneticNavItemState();
}

class _MagneticNavItemState extends State<_MagneticNavItem>
    with SingleTickerProviderStateMixin {
  bool _hovered = false;
  Offset _magneticOffset = Offset.zero;

  late final AnimationController _underlineController;
  late final Animation<double> _underlineWidth;

  @override
  void initState() {
    super.initState();
    _underlineController = AnimationController(
      vsync: this,
      duration: AppDurations.buttonHover,
    );
    _underlineWidth = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _underlineController,
        curve: CinematicCurves.hoverLift,
      ),
    );
    if (widget.isActive) _underlineController.forward();
  }

  @override
  void didUpdateWidget(_MagneticNavItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive != oldWidget.isActive) {
      widget.isActive
          ? _underlineController.forward()
          : _underlineController.reverse();
    }
  }

  @override
  void dispose() {
    _underlineController.dispose();
    super.dispose();
  }

  void _onHover(PointerEvent event) {
    final box = context.findRenderObject() as RenderBox?;
    if (box == null) return;
    final localPosition = box.globalToLocal(event.position);
    final center = Offset(box.size.width / 2, box.size.height / 2);
    final delta = localPosition - center;
    // Magnetic pull: text shifts slightly toward cursor (max 3px)
    setState(() {
      _magneticOffset = Offset(
        (delta.dx * 0.06).clamp(-3.0, 3.0),
        (delta.dy * 0.08).clamp(-2.0, 2.0),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final activeColor = widget.accent;
    final inactiveColor =
        isDark ? AppColors.textPrimary : AppColors.lightTextPrimary;
    final brightColor =
        isDark ? AppColors.textBright : AppColors.lightTextBright;

    return Semantics(
      button: true,
      label: widget.label,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) {
          setState(() => _hovered = true);
          if (!widget.isActive) _underlineController.forward();
          if (Get.isRegistered<AudioController>()) {
            Get.find<AudioController>().playHover();
          }
        },
        onHover: _onHover,
        onExit: (_) {
          setState(() {
            _hovered = false;
            _magneticOffset = Offset.zero;
          });
          if (!widget.isActive) _underlineController.reverse();
        },
        child: GestureDetector(
          onTap: () {
            if (Get.isRegistered<AudioController>()) {
              Get.find<AudioController>().playClick();
            }
            widget.onTap();
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            child: AnimatedBuilder(
              animation: _underlineController,
              builder: (context, _) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Magnetic text offset
                    AnimatedContainer(
                      duration: AppDurations.microFast,
                      curve: CinematicCurves.magneticPull,
                      transform: Matrix4.translationValues(
                        _magneticOffset.dx,
                        _magneticOffset.dy,
                        0,
                      ),
                      child: Text(
                        widget.label.toUpperCase(),
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 12,
                          fontWeight: widget.isActive
                              ? FontWeight.w600
                              : FontWeight.w400,
                          color: widget.isActive
                              ? activeColor
                              : (_hovered ? brightColor : inactiveColor),
                          letterSpacing: 2,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    // Animated underline — expands from center
                    SizedBox(
                      height: 2,
                      width: 24,
                      child: Align(
                        child: Container(
                          width: 24 * _underlineWidth.value,
                          height: 2,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(1),
                            color: widget.isActive
                                ? activeColor
                                : activeColor.withValues(alpha: 0.4),
                            boxShadow: widget.isActive
                                ? [
                                    BoxShadow(
                                      color:
                                          activeColor.withValues(alpha: 0.3),
                                      blurRadius: 6,
                                    ),
                                  ]
                                : null,
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Theme toggle — sun/moon icon with glass styling
// ---------------------------------------------------------------------------
class _GlassThemeToggle extends StatelessWidget {
  const _GlassThemeToggle({required this.accent});
  final Color accent;

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
          onPressed: themeController.toggleTheme,
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
// Hamburger button — animated morph to X
// ---------------------------------------------------------------------------
class _GlassHamburger extends StatefulWidget {
  const _GlassHamburger({
    required this.navSections,
    required this.langCtrl,
    required this.scrollCtrl,
    required this.accent,
  });

  final List<String> navSections;
  final LanguageController langCtrl;
  final AppScrollController scrollCtrl;
  final Color accent;

  @override
  State<_GlassHamburger> createState() => _GlassHamburgerState();
}

class _GlassHamburgerState extends State<_GlassHamburger>
    with SingleTickerProviderStateMixin {
  late final AnimationController _morphController;
  bool _menuOpen = false;

  @override
  void initState() {
    super.initState();
    _morphController = AnimationController(
      vsync: this,
      duration: AppDurations.medium,
    );
  }

  @override
  void dispose() {
    _morphController.dispose();
    super.dispose();
  }

  void _toggleMenu() {
    if (_menuOpen) {
      _morphController.reverse();
      Navigator.of(context).pop();
    } else {
      _morphController.forward();
      _showMobileDrawer();
    }
    _menuOpen = !_menuOpen;
  }

  void _showMobileDrawer() {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Close menu',
      barrierColor: Colors.transparent,
      transitionDuration: AppDurations.normal,
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: CurvedAnimation(
            parent: animation,
            curve: CinematicCurves.revealDecel,
          ),
          child: child,
        );
      },
      pageBuilder: (context, animation, secondaryAnimation) {
        return _GlassMobileMenu(
          navSections: widget.navSections,
          langCtrl: widget.langCtrl,
          scrollCtrl: widget.scrollCtrl,
          accent: widget.accent,
          onClose: () {
            _morphController.reverse();
            _menuOpen = false;
            Navigator.of(context).pop();
          },
        );
      },
    ).then((_) {
      // If dismissed by barrier tap, reset state
      if (_menuOpen) {
        _morphController.reverse();
        _menuOpen = false;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = isDark ? AppColors.textPrimary : AppColors.lightTextPrimary;

    return Semantics(
      button: true,
      label: _menuOpen ? 'Close menu' : 'Open menu',
      child: GestureDetector(
        onTap: _toggleMenu,
        child: SizedBox(
          width: 40,
          height: 40,
          child: AnimatedBuilder(
            animation: _morphController,
            builder: (context, _) {
              return CustomPaint(
                painter: _HamburgerXPainter(
                  progress: _morphController.value,
                  color: color,
                  accent: widget.accent,
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Custom painter: hamburger -> X morph
// ---------------------------------------------------------------------------
class _HamburgerXPainter extends CustomPainter {
  _HamburgerXPainter({
    required this.progress,
    required this.color,
    required this.accent,
  });

  final double progress;
  final Color color;
  final Color accent;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Color.lerp(color, accent, progress)!
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    final cx = size.width / 2;
    final cy = size.height / 2;
    const halfW = 10.0;
    const gap = 5.0;

    // Top line -> rotates to form top-left to bottom-right of X
    final topY = cy - gap;
    final topStartX = lerpDouble(cx - halfW, cx - 7, progress)!;
    final topStartY = lerpDouble(topY, cy - 7, progress)!;
    final topEndX = lerpDouble(cx + halfW, cx + 7, progress)!;
    final topEndY = lerpDouble(topY, cy + 7, progress)!;
    canvas.drawLine(
      Offset(topStartX, topStartY),
      Offset(topEndX, topEndY),
      paint,
    );

    // Middle line -> fades out
    paint.color = Color.lerp(color, accent, progress)!
        .withValues(alpha: 1.0 - progress);
    canvas.drawLine(
      Offset(cx - halfW, cy),
      Offset(cx + halfW * (1.0 - progress * 0.5), cy),
      paint,
    );

    // Bottom line -> rotates to form bottom-left to top-right of X
    paint.color = Color.lerp(color, accent, progress)!;
    final botY = cy + gap;
    final botStartX = lerpDouble(cx - halfW, cx - 7, progress)!;
    final botStartY = lerpDouble(botY, cy + 7, progress)!;
    final botEndX = lerpDouble(cx + halfW, cx + 7, progress)!;
    final botEndY = lerpDouble(botY, cy - 7, progress)!;
    canvas.drawLine(
      Offset(botStartX, botStartY),
      Offset(botEndX, botEndY),
      paint,
    );
  }

  @override
  bool shouldRepaint(_HamburgerXPainter oldDelegate) =>
      progress != oldDelegate.progress ||
      color != oldDelegate.color ||
      accent != oldDelegate.accent;
}

// ---------------------------------------------------------------------------
// Glass mobile menu — fullscreen overlay with frosted glass
// ---------------------------------------------------------------------------
class _GlassMobileMenu extends StatelessWidget {
  const _GlassMobileMenu({
    required this.navSections,
    required this.langCtrl,
    required this.scrollCtrl,
    required this.accent,
    required this.onClose,
  });

  final List<String> navSections;
  final LanguageController langCtrl;
  final AppScrollController scrollCtrl;
  final Color accent;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: Colors.transparent,
      child: Stack(
        children: [
          // Frosted background
          Positioned.fill(
            child: ClipRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
                child: Container(
                  color: isDark
                      ? AppColors.background.withValues(alpha: 0.85)
                      : AppColors.lightBackground.withValues(alpha: 0.90),
                ),
              ),
            ),
          ),
          // Close button
          Positioned(
            top: 24,
            right: 24,
            child: IconButton(
              onPressed: onClose,
              icon: Icon(
                Icons.close_rounded,
                color: isDark
                    ? AppColors.textPrimary
                    : AppColors.lightTextPrimary,
                size: 28,
              ),
            ),
          ),
          // Nav items
          Center(
            child: Obx(() {
              final activeSection = scrollCtrl.activeSection.value;
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (var i = 0; i < navSections.length; i++)
                    _MobileGlassNavItem(
                      label: langCtrl.getText(
                        'nav.${navSections[i]}',
                        defaultValue: navSections[i].toUpperCase(),
                      ),
                      isActive: activeSection == navSections[i],
                      accent: accent,
                      delay: Duration(milliseconds: 50 * i),
                      onTap: () {
                        onClose();
                        scrollCtrl.scrollToSection(navSections[i]);
                      },
                    ),
                  const SizedBox(height: 40),
                  // Controls row
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _GlassThemeToggle(accent: accent),
                      const SizedBox(width: 8),
                      const LanguageSwitcher(
                        key: ValueKey('mobile-glass-lang'),
                      ),
                    ],
                  ),
                ],
              );
            }),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Mobile nav item — staggered entrance, active accent indicator
// ---------------------------------------------------------------------------
class _MobileGlassNavItem extends StatefulWidget {
  const _MobileGlassNavItem({
    required this.label,
    required this.isActive,
    required this.accent,
    required this.delay,
    required this.onTap,
  });

  final String label;
  final bool isActive;
  final Color accent;
  final Duration delay;
  final VoidCallback onTap;

  @override
  State<_MobileGlassNavItem> createState() => _MobileGlassNavItemState();
}

class _MobileGlassNavItemState extends State<_MobileGlassNavItem>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animController;
  late final Animation<double> _slideAnimation;
  late final Animation<double> _opacityAnimation;
  bool _hovered = false;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: AppDurations.normal,
    );
    _slideAnimation = Tween<double>(begin: 30.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _animController,
        curve: CinematicCurves.dramaticEntrance,
      ),
    );
    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animController,
        curve: const Interval(0.0, 0.7, curve: Curves.easeOut),
      ),
    );
    Future.delayed(widget.delay, () {
      if (mounted) _animController.forward();
    });
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final activeColor = widget.accent;
    final inactiveColor =
        isDark ? AppColors.textPrimary : AppColors.lightTextPrimary;
    final brightColor =
        isDark ? AppColors.textBright : AppColors.lightTextBright;

    return AnimatedBuilder(
      animation: _animController,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _slideAnimation.value),
          child: Opacity(
            opacity: _opacityAnimation.value,
            child: child,
          ),
        );
      },
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
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
                    fontSize: 24,
                    fontWeight:
                        widget.isActive ? FontWeight.w600 : FontWeight.w400,
                    color: widget.isActive
                        ? activeColor
                        : (_hovered ? brightColor : inactiveColor),
                    letterSpacing: 4,
                    shadows: widget.isActive
                        ? [
                            Shadow(
                              color: activeColor.withValues(alpha: 0.3),
                              blurRadius: 12,
                            ),
                          ]
                        : null,
                  ),
                ),
                const SizedBox(height: 6),
                AnimatedContainer(
                  duration: AppDurations.fast,
                  curve: CinematicCurves.hoverLift,
                  height: 2,
                  width: widget.isActive ? 40 : (_hovered ? 24 : 0),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(1),
                    color: widget.isActive
                        ? activeColor
                        : activeColor.withValues(alpha: 0.4),
                    boxShadow: widget.isActive
                        ? [
                            BoxShadow(
                              color: activeColor.withValues(alpha: 0.4),
                              blurRadius: 8,
                            ),
                          ]
                        : null,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
