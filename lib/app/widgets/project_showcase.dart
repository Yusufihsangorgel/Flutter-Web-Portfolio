import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:flutter_web_portfolio/app/controllers/scene_director.dart';
import 'package:flutter_web_portfolio/app/core/constants/app_colors.dart';
import 'package:flutter_web_portfolio/app/core/constants/cinematic_curves.dart';
import 'package:flutter_web_portfolio/app/core/constants/durations.dart';
import 'package:flutter_web_portfolio/app/core/theme/app_typography.dart';
import 'package:flutter_web_portfolio/app/domain/entities/project.dart';
import 'package:flutter_web_portfolio/app/utils/responsive_utils.dart';
import 'package:flutter_web_portfolio/app/widgets/cinematic_focusable.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// 1. ProjectShowcase — Full-screen detail overlay
// ═══════════════════════════════════════════════════════════════════════════════

/// Full-screen project detail overlay with glassmorphism, parallax hero image,
/// animated title entrance, counting metrics, screenshot carousel, and
/// keyboard navigation (arrows for prev/next, Escape to close).
class ProjectShowcase extends StatefulWidget {
  const ProjectShowcase({
    super.key,
    required this.project,
    required this.projects,
    required this.initialIndex,
    this.screenshots = const [],
    this.metrics = const {},
    this.expandFromRect,
  });

  final Project project;

  /// Full list for keyboard prev/next navigation.
  final List<Project> projects;

  /// Index of [project] within [projects].
  final int initialIndex;

  /// Optional screenshot URLs for the carousel.
  final List<String> screenshots;

  /// Metrics displayed with counting animation, e.g. {'Users': 12000}.
  final Map<String, int> metrics;

  /// If provided, the overlay expands from this rect (hero animation origin).
  final Rect? expandFromRect;

  /// Show the overlay as a modal dialog.
  static Future<void> show(
    BuildContext context, {
    required Project project,
    required List<Project> projects,
    required int initialIndex,
    List<String> screenshots = const [],
    Map<String, int> metrics = const {},
    Rect? expandFromRect,
  }) =>
      showGeneralDialog(
        context: context,
        barrierDismissible: true,
        barrierLabel: 'Close project showcase',
        barrierColor: Colors.transparent,
        transitionDuration: AppDurations.entrance,
        pageBuilder: (_, __, ___) => ProjectShowcase(
          project: project,
          projects: projects,
          initialIndex: initialIndex,
          screenshots: screenshots,
          metrics: metrics,
          expandFromRect: expandFromRect,
        ),
        transitionBuilder: (context, animation, _, child) {
          final curved = CurvedAnimation(
            parent: animation,
            curve: CinematicCurves.dramaticEntrance,
          );
          return FadeTransition(
            opacity: curved,
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.92, end: 1.0).animate(curved),
              child: child,
            ),
          );
        },
      );

  @override
  State<ProjectShowcase> createState() => _ProjectShowcaseState();
}

class _ProjectShowcaseState extends State<ProjectShowcase>
    with TickerProviderStateMixin {
  late final FocusNode _focusNode;
  late final AnimationController _entranceCtrl;
  late final AnimationController _parallaxCtrl;
  late final ScrollController _scrollCtrl;

  late int _currentIndex;
  late Project _currentProject;
  late List<String> _currentScreenshots;
  late Map<String, int> _currentMetrics;

  // Parallax offset driven by scroll.
  double _parallaxOffset = 0;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode()..requestFocus();
    _currentIndex = widget.initialIndex;
    _currentProject = widget.project;
    _currentScreenshots = widget.screenshots;
    _currentMetrics = widget.metrics;

    _entranceCtrl = AnimationController(
      vsync: this,
      duration: AppDurations.slow,
    )..forward();

    _parallaxCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );

    _scrollCtrl = ScrollController()..addListener(_onScroll);
  }

  void _onScroll() {
    setState(() {
      _parallaxOffset = _scrollCtrl.offset * 0.3;
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _entranceCtrl.dispose();
    _parallaxCtrl.dispose();
    _scrollCtrl
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  void _navigateTo(int index) {
    if (index < 0 || index >= widget.projects.length) return;
    setState(() {
      _currentIndex = index;
      _currentProject = widget.projects[index];
      // Reset screenshots/metrics for new project — consumers should
      // provide a callback; for now we clear them.
      _currentScreenshots = [];
      _currentMetrics = {};
    });
    _entranceCtrl
      ..reset()
      ..forward();
    _scrollCtrl.jumpTo(0);
  }

  void _onKey(KeyEvent event) {
    if (event is! KeyDownEvent) return;
    switch (event.logicalKey) {
      case LogicalKeyboardKey.escape:
        Navigator.of(context).pop();
      case LogicalKeyboardKey.arrowRight:
        _navigateTo(_currentIndex + 1);
      case LogicalKeyboardKey.arrowLeft:
        _navigateTo(_currentIndex - 1);
      default:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isMobile = ResponsiveUtils.isMobile(context);
    final horizontalPad = ResponsiveUtils.getValueForScreenType<double>(
      context: context,
      mobile: 16,
      tablet: 48,
      desktop: 80,
    );
    final maxWidth = ResponsiveUtils.getValueForScreenType<double>(
      context: context,
      mobile: double.infinity,
      tablet: 800,
      desktop: 960,
    );

    return KeyboardListener(
      focusNode: _focusNode,
      autofocus: true,
      onKeyEvent: _onKey,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Stack(
          children: [
            // ── Glassmorphism backdrop ────────────────────────────────────
            Positioned.fill(
              child: GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                  child: ColoredBox(
                    color: (isDark
                            ? AppColors.background
                            : AppColors.lightBackground)
                        .withValues(alpha: 0.88),
                  ),
                ),
              ),
            ),

            // ── Content ──────────────────────────────────────────────────
            Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: maxWidth),
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: horizontalPad,
                    vertical: isMobile ? 20 : 40,
                  ),
                  child: Obx(() {
                    final accent =
                        Get.find<SceneDirector>().currentAccent.value;
                    return _ShowcaseContent(
                      project: _currentProject,
                      screenshots: _currentScreenshots,
                      metrics: _currentMetrics,
                      accent: accent,
                      entranceAnimation: _entranceCtrl,
                      scrollController: _scrollCtrl,
                      parallaxOffset: _parallaxOffset,
                      isMobile: isMobile,
                      isDark: isDark,
                    );
                  }),
                ),
              ),
            ),

            // ── Navigation arrows ────────────────────────────────────────
            if (!isMobile && widget.projects.length > 1) ...[
              if (_currentIndex > 0)
                Positioned(
                  left: 16,
                  top: 0,
                  bottom: 0,
                  child: Center(
                    child: _NavArrow(
                      icon: Icons.chevron_left_rounded,
                      onTap: () => _navigateTo(_currentIndex - 1),
                    ),
                  ),
                ),
              if (_currentIndex < widget.projects.length - 1)
                Positioned(
                  right: 16,
                  top: 0,
                  bottom: 0,
                  child: Center(
                    child: _NavArrow(
                      icon: Icons.chevron_right_rounded,
                      onTap: () => _navigateTo(_currentIndex + 1),
                    ),
                  ),
                ),
            ],

            // ── Close button ─────────────────────────────────────────────
            Positioned(
              top: isMobile ? 12 : 28,
              right: isMobile ? 12 : 28,
              child: _ShowcaseCloseButton(
                onTap: () => Navigator.of(context).pop(),
              ),
            ),

            // ── Page indicator ───────────────────────────────────────────
            if (widget.projects.length > 1)
              Positioned(
                bottom: isMobile ? 8 : 20,
                left: 0,
                right: 0,
                child: Center(
                  child: Obx(() {
                    final accent =
                        Get.find<SceneDirector>().currentAccent.value;
                    return Text(
                      '${_currentIndex + 1} / ${widget.projects.length}',
                      style: AppTypography.caption.copyWith(color: accent),
                    );
                  }),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Showcase content — scrollable body with staggered entrance
// ─────────────────────────────────────────────────────────────────────────────

class _ShowcaseContent extends StatelessWidget {
  const _ShowcaseContent({
    required this.project,
    required this.screenshots,
    required this.metrics,
    required this.accent,
    required this.entranceAnimation,
    required this.scrollController,
    required this.parallaxOffset,
    required this.isMobile,
    required this.isDark,
  });

  final Project project;
  final List<String> screenshots;
  final Map<String, int> metrics;
  final Color accent;
  final AnimationController entranceAnimation;
  final ScrollController scrollController;
  final double parallaxOffset;
  final bool isMobile;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: entranceAnimation,
      builder: (context, _) {
        final t = CurvedAnimation(
          parent: entranceAnimation,
          curve: CinematicCurves.dramaticEntrance,
        ).value;

        return SingleChildScrollView(
          controller: scrollController,
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Hero image with parallax ─────────────────────────────
              if (project.imageUrl.isNotEmpty)
                _StaggerSlide(
                  delay: 0.0,
                  progress: t,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: SizedBox(
                      height: isMobile ? 200 : 340,
                      width: double.infinity,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          Transform.translate(
                            offset: Offset(0, -parallaxOffset),
                            child: project.imageUrl.startsWith('assets/')
                                ? Image.asset(
                                    project.imageUrl,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) =>
                                        _ImagePlaceholder(accent: accent),
                                  )
                                : Image.network(
                                    project.imageUrl,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) =>
                                        _ImagePlaceholder(accent: accent),
                                  ),
                          ),
                          // Gradient overlay at the bottom
                          Positioned(
                            left: 0,
                            right: 0,
                            bottom: 0,
                            height: 100,
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Colors.transparent,
                                    (isDark
                                            ? AppColors.background
                                            : AppColors.lightBackground)
                                        .withValues(alpha: 0.8),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

              SizedBox(height: project.imageUrl.isNotEmpty ? 28 : 0),

              // ── Animated title entrance ──────────────────────────────
              _StaggerSlide(
                delay: 0.1,
                progress: t,
                child: Text(
                  project.title,
                  style: AppTypography.h1.copyWith(
                    color: accent,
                    fontSize: isMobile ? 28 : 40,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // ── Description ──────────────────────────────────────────
              _StaggerSlide(
                delay: 0.2,
                progress: t,
                child: Text(
                  project.description,
                  style: AppTypography.body.copyWith(
                    color: isDark
                        ? AppColors.textPrimary
                        : AppColors.lightTextPrimary,
                    height: 1.7,
                  ),
                ),
              ),

              const SizedBox(height: 28),

              // ── Technologies ─────────────────────────────────────────
              if (project.technologies.isNotEmpty)
                _StaggerSlide(
                  delay: 0.3,
                  progress: t,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Technologies',
                        style: AppTypography.label.copyWith(color: accent),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: project.technologies
                            .map((tech) =>
                                _ShowcaseTechPill(label: tech, accent: accent))
                            .toList(),
                      ),
                    ],
                  ),
                ),

              if (project.technologies.isNotEmpty) const SizedBox(height: 32),

              // ── Metrics with counting animation ──────────────────────
              if (metrics.isNotEmpty)
                _StaggerSlide(
                  delay: 0.4,
                  progress: t,
                  child: _MetricsRow(metrics: metrics, accent: accent),
                ),

              if (metrics.isNotEmpty) const SizedBox(height: 32),

              // ── Screenshot carousel ──────────────────────────────────
              if (screenshots.isNotEmpty)
                _StaggerSlide(
                  delay: 0.5,
                  progress: t,
                  child: _ScreenshotCarousel(
                    screenshots: screenshots,
                    accent: accent,
                    isMobile: isMobile,
                  ),
                ),

              if (screenshots.isNotEmpty) const SizedBox(height: 36),

              // ── Action buttons ───────────────────────────────────────
              _StaggerSlide(
                delay: 0.6,
                progress: t,
                child: Row(
                  children: [
                    if (project.liveUrl.isNotEmpty)
                      _ShowcaseActionButton(
                        label: 'View Live',
                        icon: Icons.launch_rounded,
                        accent: accent,
                        isPrimary: true,
                        onTap: () => _openUrl(project.liveUrl),
                      ),
                    if (project.liveUrl.isNotEmpty &&
                        project.githubUrl.isNotEmpty)
                      const SizedBox(width: 12),
                    if (project.githubUrl.isNotEmpty)
                      _ShowcaseActionButton(
                        label: 'View Source',
                        icon: Icons.code_rounded,
                        accent: accent,
                        isPrimary: false,
                        onTap: () => _openUrl(project.githubUrl),
                      ),
                  ],
                ),
              ),

              // Bottom padding for breathing room.
              const SizedBox(height: 48),
            ],
          ),
        );
      },
    );
  }

  Future<void> _openUrl(String url) async {
    var urlStr = url;
    if (!urlStr.startsWith('http://') && !urlStr.startsWith('https://')) {
      urlStr = 'https://$urlStr';
    }
    final uri = Uri.parse(urlStr);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Stagger slide helper — slide-up + fade driven by a 0..1 progress value
// ─────────────────────────────────────────────────────────────────────────────

class _StaggerSlide extends StatelessWidget {
  const _StaggerSlide({
    required this.delay,
    required this.progress,
    required this.child,
  });

  /// Normalised delay within 0..1.
  final double delay;
  final double progress;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final localT = ((progress - delay) / (1.0 - delay)).clamp(0.0, 1.0);
    final opacity = localT;
    final offsetY = (1.0 - localT) * 24;

    return Opacity(
      opacity: opacity,
      child: Transform.translate(
        offset: Offset(0, offsetY),
        child: child,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Metrics row with counting animation
// ─────────────────────────────────────────────────────────────────────────────

class _MetricsRow extends StatelessWidget {
  const _MetricsRow({required this.metrics, required this.accent});
  final Map<String, int> metrics;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Metrics', style: AppTypography.label.copyWith(color: accent)),
        const SizedBox(height: 16),
        Wrap(
          spacing: 32,
          runSpacing: 16,
          children: metrics.entries.map((entry) {
            return _MetricTile(
              label: entry.key,
              value: entry.value,
              accent: accent,
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _MetricTile extends StatefulWidget {
  const _MetricTile({
    required this.label,
    required this.value,
    required this.accent,
  });
  final String label;
  final int value;
  final Color accent;

  @override
  State<_MetricTile> createState() => _MetricTileState();
}

class _MetricTileState extends State<_MetricTile>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _countAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    _countAnim = Tween<double>(begin: 0, end: widget.value.toDouble()).animate(
      CurvedAnimation(parent: _ctrl, curve: CinematicCurves.revealDecel),
    );
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  String _formatValue(int v) {
    if (v >= 1000000) return '${(v / 1000000).toStringAsFixed(1)}M';
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(1)}K';
    return '$v';
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _countAnim,
      builder: (_, __) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _formatValue(_countAnim.value.toInt()),
              style: GoogleFonts.spaceGrotesk(
                fontSize: 28,
                fontWeight: FontWeight.w700,
                color: widget.accent,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              widget.label,
              style: AppTypography.caption.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Screenshot carousel
// ─────────────────────────────────────────────────────────────────────────────

class _ScreenshotCarousel extends StatefulWidget {
  const _ScreenshotCarousel({
    required this.screenshots,
    required this.accent,
    required this.isMobile,
  });
  final List<String> screenshots;
  final Color accent;
  final bool isMobile;

  @override
  State<_ScreenshotCarousel> createState() => _ScreenshotCarouselState();
}

class _ScreenshotCarouselState extends State<_ScreenshotCarousel> {
  late final PageController _pageCtrl;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageCtrl = PageController(viewportFraction: 0.85);
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Screenshots',
          style: AppTypography.label.copyWith(color: widget.accent),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: widget.isMobile ? 180 : 280,
          child: PageView.builder(
            controller: _pageCtrl,
            itemCount: widget.screenshots.length,
            onPageChanged: (i) => setState(() => _currentPage = i),
            itemBuilder: (context, index) {
              return AnimatedBuilder(
                animation: _pageCtrl,
                builder: (context, child) {
                  double scale = 1.0;
                  if (_pageCtrl.position.haveDimensions) {
                    final page = _pageCtrl.page ?? _currentPage.toDouble();
                    final diff = (page - index).abs();
                    scale = (1.0 - diff * 0.1).clamp(0.85, 1.0);
                  }
                  return Transform.scale(
                    scale: scale,
                    child: child,
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: widget.screenshots[index].startsWith('assets/')
                        ? Image.asset(
                            widget.screenshots[index],
                            fit: BoxFit.cover,
                            width: double.infinity,
                            errorBuilder: (_, __, ___) =>
                                _ImagePlaceholder(accent: widget.accent),
                          )
                        : Image.network(
                            widget.screenshots[index],
                            fit: BoxFit.cover,
                            width: double.infinity,
                            errorBuilder: (_, __, ___) =>
                                _ImagePlaceholder(accent: widget.accent),
                          ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 12),
        // Dot indicators
        if (widget.screenshots.length > 1)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(widget.screenshots.length, (i) {
              final isActive = i == _currentPage;
              return AnimatedContainer(
                duration: AppDurations.fast,
                curve: CinematicCurves.hoverLift,
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: isActive ? 20 : 6,
                height: 6,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(3),
                  color: isActive
                      ? widget.accent
                      : widget.accent.withValues(alpha: 0.25),
                ),
              );
            }),
          ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Sub-widgets
// ─────────────────────────────────────────────────────────────────────────────

class _ShowcaseTechPill extends StatelessWidget {
  const _ShowcaseTechPill({required this.label, required this.accent});
  final String label;
  final Color accent;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: accent.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: accent.withValues(alpha: 0.15)),
        ),
        child: Text(
          label,
          style: GoogleFonts.jetBrainsMono(fontSize: 12, color: accent),
        ),
      );
}

class _ShowcaseActionButton extends StatefulWidget {
  const _ShowcaseActionButton({
    required this.label,
    required this.icon,
    required this.accent,
    required this.isPrimary,
    required this.onTap,
  });
  final String label;
  final IconData icon;
  final Color accent;
  final bool isPrimary;
  final VoidCallback onTap;

  @override
  State<_ShowcaseActionButton> createState() => _ShowcaseActionButtonState();
}

class _ShowcaseActionButtonState extends State<_ShowcaseActionButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: widget.label,
      child: CinematicFocusable(
        onTap: widget.onTap,
        onHoverChanged: (h) => setState(() => _hovered = h),
        borderRadius: BorderRadius.circular(8),
        child: AnimatedContainer(
          duration: AppDurations.buttonHover,
          curve: CinematicCurves.hoverLift,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          decoration: widget.isPrimary
              ? BoxDecoration(
                  color: _hovered
                      ? widget.accent.withValues(alpha: 0.9)
                      : widget.accent,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: _hovered
                      ? [
                          BoxShadow(
                            color: widget.accent.withValues(alpha: 0.35),
                            blurRadius: 20,
                          ),
                        ]
                      : [],
                )
              : BoxDecoration(
                  color: _hovered
                      ? widget.accent.withValues(alpha: 0.08)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _hovered
                        ? widget.accent.withValues(alpha: 0.5)
                        : widget.accent.withValues(alpha: 0.2),
                  ),
                ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                widget.icon,
                size: 18,
                color: widget.isPrimary ? AppColors.white : widget.accent,
              ),
              const SizedBox(width: 10),
              Text(
                widget.label,
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.2,
                  color: widget.isPrimary ? AppColors.white : widget.accent,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavArrow extends StatefulWidget {
  const _NavArrow({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  State<_NavArrow> createState() => _NavArrowState();
}

class _NavArrowState extends State<_NavArrow> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return CinematicFocusable(
      onTap: widget.onTap,
      onHoverChanged: (h) => setState(() => _hovered = h),
      borderRadius: BorderRadius.circular(24),
      child: AnimatedContainer(
        duration: AppDurations.fast,
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: (Theme.of(context).brightness == Brightness.dark
                  ? Colors.white
                  : Colors.black)
              .withValues(alpha: _hovered ? 0.12 : 0.05),
          border: Border.all(
            color: (Theme.of(context).brightness == Brightness.dark
                    ? Colors.white
                    : Colors.black)
                .withValues(alpha: _hovered ? 0.25 : 0.08),
          ),
        ),
        child: Icon(
          widget.icon,
          size: 28,
          color: _hovered ? AppColors.textBright : AppColors.textPrimary,
        ),
      ),
    );
  }
}

class _ShowcaseCloseButton extends StatefulWidget {
  const _ShowcaseCloseButton({required this.onTap});
  final VoidCallback onTap;

  @override
  State<_ShowcaseCloseButton> createState() => _ShowcaseCloseButtonState();
}

class _ShowcaseCloseButtonState extends State<_ShowcaseCloseButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) => CinematicFocusable(
        onTap: widget.onTap,
        onHoverChanged: (h) => setState(() => _hovered = h),
        borderRadius: BorderRadius.circular(20),
        child: AnimatedContainer(
          duration: AppDurations.fast,
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: (Theme.of(context).brightness == Brightness.dark
                    ? Colors.white
                    : Colors.black)
                .withValues(alpha: _hovered ? 0.12 : 0.04),
            border: Border.all(
              color: (Theme.of(context).brightness == Brightness.dark
                      ? Colors.white
                      : Colors.black)
                  .withValues(alpha: _hovered ? 0.25 : 0.08),
            ),
          ),
          child: Icon(
            Icons.close_rounded,
            size: 22,
            color: _hovered ? AppColors.textBright : AppColors.textPrimary,
          ),
        ),
      );
}

class _ImagePlaceholder extends StatelessWidget {
  const _ImagePlaceholder({required this.accent});
  final Color accent;

  @override
  Widget build(BuildContext context) => Container(
        color: accent.withValues(alpha: 0.06),
        child: Center(
          child: Icon(
            Icons.image_outlined,
            size: 48,
            color: accent.withValues(alpha: 0.3),
          ),
        ),
      );
}

// ═══════════════════════════════════════════════════════════════════════════════
// 2. ProjectCarousel — Horizontal carousel with centered focus card
// ═══════════════════════════════════════════════════════════════════════════════

/// Horizontal project carousel with a centered large card, side cards that are
/// smaller/rotated/faded, snap scrolling, drag, dot indicators, and auto-advance
/// every 5 seconds (paused on hover).
class ProjectCarousel extends StatefulWidget {
  const ProjectCarousel({
    super.key,
    required this.projects,
    required this.cardBuilder,
    this.cardWidth = 360,
    this.cardHeight = 420,
    this.autoAdvanceInterval = const Duration(seconds: 5),
    this.onProjectTap,
  });

  final List<Project> projects;

  /// Builder for each card. Receives the project and whether the card is
  /// the currently focused (centered) card.
  final Widget Function(Project project, bool isFocused) cardBuilder;

  final double cardWidth;
  final double cardHeight;
  final Duration autoAdvanceInterval;
  final ValueChanged<int>? onProjectTap;

  @override
  State<ProjectCarousel> createState() => _ProjectCarouselState();
}

class _ProjectCarouselState extends State<ProjectCarousel> {
  late final PageController _pageCtrl;
  int _currentPage = 0;
  Timer? _autoTimer;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _pageCtrl = PageController(
      viewportFraction: 0.7,
      initialPage: 0,
    );
    _startAutoAdvance();
  }

  @override
  void dispose() {
    _autoTimer?.cancel();
    _pageCtrl.dispose();
    super.dispose();
  }

  void _startAutoAdvance() {
    _autoTimer?.cancel();
    _autoTimer = Timer.periodic(widget.autoAdvanceInterval, (_) {
      if (_isHovered) return;
      if (!_pageCtrl.hasClients) return;
      final next = (_currentPage + 1) % widget.projects.length;
      _pageCtrl.animateToPage(
        next,
        duration: AppDurations.slow,
        curve: CinematicCurves.easeInOutCinematic,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.projects.isEmpty) return const SizedBox.shrink();
    final isMobile = ResponsiveUtils.isMobile(context);
    final cardH = isMobile ? widget.cardHeight * 0.8 : widget.cardHeight;

    return MouseRegion(
      onEnter: (_) => _isHovered = true,
      onExit: (_) => _isHovered = false,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: cardH + 40, // extra for shadow/rotation overflow
            child: PageView.builder(
              controller: _pageCtrl,
              itemCount: widget.projects.length,
              onPageChanged: (i) => setState(() => _currentPage = i),
              physics: const BouncingScrollPhysics(),
              itemBuilder: (context, index) {
                return AnimatedBuilder(
                  animation: _pageCtrl,
                  builder: (context, child) {
                    double page = _currentPage.toDouble();
                    if (_pageCtrl.position.haveDimensions) {
                      page = _pageCtrl.page ?? page;
                    }
                    final diff = page - index;
                    final absDiff = diff.abs();

                    // Scale: focused = 1.0, side cards shrink
                    final scale = (1.0 - absDiff * 0.15).clamp(0.75, 1.0);

                    // Rotation: slight Y-axis perspective rotation for side cards
                    final rotationY = diff.clamp(-1.0, 1.0) * 0.08;

                    // Opacity: fade side cards
                    final opacity = (1.0 - absDiff * 0.35).clamp(0.4, 1.0);

                    // Vertical offset: push side cards down slightly
                    final translateY = absDiff * 20;

                    return Transform(
                      alignment: Alignment.center,
                      transform: Matrix4.identity()
                        ..setEntry(3, 2, 0.001)
                        ..rotateY(rotationY)
                        ..scaleByDouble(scale, scale, scale, 1.0)
                        ..translateByDouble(0.0, translateY, 0.0, 0.0),
                      child: Opacity(
                        opacity: opacity,
                        child: GestureDetector(
                          onTap: () {
                            if (index == _currentPage) {
                              widget.onProjectTap?.call(index);
                            } else {
                              _pageCtrl.animateToPage(
                                index,
                                duration: AppDurations.normal,
                                curve: CinematicCurves.easeInOutCinematic,
                              );
                            }
                          },
                          child: widget.cardBuilder(
                            widget.projects[index],
                            index == _currentPage,
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),

          const SizedBox(height: 20),

          // ── Dot indicators ───────────────────────────────────────────
          Obx(() {
            final accent = Get.find<SceneDirector>().currentAccent.value;
            return Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(widget.projects.length, (i) {
                final isActive = i == _currentPage;
                return GestureDetector(
                  onTap: () => _pageCtrl.animateToPage(
                    i,
                    duration: AppDurations.normal,
                    curve: CinematicCurves.easeInOutCinematic,
                  ),
                  child: AnimatedContainer(
                    duration: AppDurations.fast,
                    curve: CinematicCurves.hoverLift,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: isActive ? 24 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(4),
                      color: isActive
                          ? accent
                          : accent.withValues(alpha: 0.2),
                    ),
                  ),
                );
              }),
            );
          }),
        ],
      ),
    );
  }
}
