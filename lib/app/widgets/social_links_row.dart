import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_web_portfolio/app/controllers/scroll_controller.dart';
import 'package:flutter_web_portfolio/app/core/constants/app_colors.dart';
import 'package:flutter_web_portfolio/app/core/constants/breakpoints.dart';
import 'package:flutter_web_portfolio/app/core/constants/cinematic_curves.dart';
import 'package:flutter_web_portfolio/app/core/constants/durations.dart';

// =============================================================================
// SocialLinkData — model for a single social link
// =============================================================================

/// Data model for a single social link.
class SocialLinkData {
  const SocialLinkData({
    required this.label,
    required this.url,
    required this.icon,
    this.brandColor,
  });

  final String label;
  final String url;
  final IconData icon;

  /// Brand color used on hover. Falls back to [AppColors.accent].
  final Color? brandColor;
}

// =============================================================================
// SocialPresets — pre-configured social link factories
// =============================================================================

/// Predefined social link presets with brand colors.
class SocialPresets {
  const SocialPresets._();

  static SocialLinkData github(String url) => SocialLinkData(
        label: 'GitHub',
        url: url,
        icon: Icons.code_rounded,
        brandColor: const Color(0xFFE6EDF3),
      );

  static SocialLinkData linkedin(String url) => SocialLinkData(
        label: 'LinkedIn',
        url: url,
        icon: Icons.business_center_outlined,
        brandColor: const Color(0xFF0A66C2),
      );

  static SocialLinkData twitter(String url) => SocialLinkData(
        label: 'X / Twitter',
        url: url,
        icon: Icons.alternate_email_rounded,
        brandColor: const Color(0xFF1DA1F2),
      );

  static SocialLinkData medium(String url) => SocialLinkData(
        label: 'Medium',
        url: url,
        icon: Icons.article_outlined,
        brandColor: const Color(0xFF00AB6C),
      );

  static SocialLinkData email(String address) => SocialLinkData(
        label: 'Email',
        url: 'mailto:$address',
        icon: Icons.email_outlined,
        brandColor: const Color(0xFFEA4335),
      );
}

// =============================================================================
// SocialLinksRow — reusable row/grid of social icons
// =============================================================================

/// Reusable row/grid of social media icon links with staggered entrance,
/// hover scale, brand color shift, tooltip, and magnetic cursor effect.
class SocialLinksRow extends StatefulWidget {
  const SocialLinksRow({
    super.key,
    required this.links,
    this.iconSize = 22.0,
    this.spacing = 16.0,
    this.animate = true,
    this.staggerDelay = const Duration(milliseconds: 80),
    this.alignment = MainAxisAlignment.center,
  });

  final List<SocialLinkData> links;
  final double iconSize;
  final double spacing;
  final bool animate;
  final Duration staggerDelay;
  final MainAxisAlignment alignment;

  @override
  State<SocialLinksRow> createState() => _SocialLinksRowState();
}

class _SocialLinksRowState extends State<SocialLinksRow>
    with SingleTickerProviderStateMixin {
  late final AnimationController _entranceCtrl;
  late final List<Animation<double>> _staggerAnimations;

  @override
  void initState() {
    super.initState();
    final totalDuration = widget.animate
        ? Duration(
            milliseconds: 400 +
                widget.links.length * widget.staggerDelay.inMilliseconds)
        : Duration.zero;
    _entranceCtrl = AnimationController(vsync: this, duration: totalDuration);
    _buildStaggerAnimations();
    if (widget.animate) {
      _entranceCtrl.forward();
    }
  }

  void _buildStaggerAnimations() {
    final total = _entranceCtrl.duration?.inMilliseconds ?? 1;
    _staggerAnimations = List.generate(widget.links.length, (i) {
      final start = (i * widget.staggerDelay.inMilliseconds) / total;
      final end = math.min(1.0, start + 400.0 / total);
      return CurvedAnimation(
        parent: _entranceCtrl,
        curve: Interval(start, end, curve: CinematicCurves.dramaticEntrance),
      );
    });
  }

  @override
  void dispose() {
    _entranceCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Wrap(
      alignment: _wrapAlignment,
      spacing: widget.spacing,
      runSpacing: widget.spacing * 0.75,
      children: List.generate(widget.links.length, (i) {
        final child = _SocialIconButton(
          data: widget.links[i],
          iconSize: widget.iconSize,
        );

        if (!widget.animate) return child;

        return AnimatedBuilder(
          animation: _staggerAnimations[i],
          builder: (_, __) {
            final value = _staggerAnimations[i].value;
            return Opacity(
              opacity: value,
              child: Transform.translate(
                offset: Offset(-16 * (1 - value), 0),
                child: child,
              ),
            );
          },
        );
      }),
    );

  WrapAlignment get _wrapAlignment => switch (widget.alignment) {
        MainAxisAlignment.start => WrapAlignment.start,
        MainAxisAlignment.end => WrapAlignment.end,
        _ => WrapAlignment.center,
      };
}

// =============================================================================
// _SocialIconButton — individual icon with hover scale, color, magnetic pull
// =============================================================================

/// Individual social icon with hover effects: scale, color shift, magnetic pull.
class _SocialIconButton extends StatefulWidget {
  const _SocialIconButton({
    required this.data,
    required this.iconSize,
  });

  final SocialLinkData data;
  final double iconSize;

  @override
  State<_SocialIconButton> createState() => _SocialIconButtonState();
}

class _SocialIconButtonState extends State<_SocialIconButton> {
  bool _hovered = false;
  Offset _magneticOffset = Offset.zero;

  void _onHover(PointerEvent event) {
    final center = Offset(widget.iconSize * 1.2, widget.iconSize * 1.2);
    final delta = event.localPosition - center;
    final clamped = Offset(
      delta.dx.clamp(-4.0, 4.0),
      delta.dy.clamp(-4.0, 4.0),
    );
    if ((_magneticOffset - clamped).distance > 1.5) {
      setState(() => _magneticOffset = clamped);
    }
  }

  @override
  Widget build(BuildContext context) {
    const baseColor = AppColors.textSecondary;
    final hoverColor = widget.data.brandColor ?? AppColors.accent;

    return Tooltip(
      message: widget.data.label,
      preferBelow: false,
      textStyle: GoogleFonts.jetBrainsMono(
        fontSize: 11,
        color: Colors.white,
      ),
      decoration: BoxDecoration(
        color: AppColors.backgroundLight.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: AppColors.accent.withValues(alpha: 0.2),
        ),
      ),
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onHover: _onHover,
        onExit: (_) => setState(() {
          _hovered = false;
          _magneticOffset = Offset.zero;
        }),
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: _launch,
          child: Semantics(
            link: true,
            label: widget.data.label,
            child: AnimatedContainer(
              duration: AppDurations.fast,
              curve: CinematicCurves.magneticPull,
              transform: Matrix4.identity()
                ..translateByDouble(
                  _hovered ? _magneticOffset.dx : 0.0,
                  _hovered ? _magneticOffset.dy : 0.0,
                  0.0,
                  1.0,
                )
                ..scaleByDouble(
                  _hovered ? 1.2 : 1.0,
                  _hovered ? 1.2 : 1.0,
                  _hovered ? 1.2 : 1.0,
                  1.0,
                ),
              transformAlignment: Alignment.center,
              padding: EdgeInsets.all(widget.iconSize * 0.45),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _hovered
                    ? hoverColor.withValues(alpha: 0.12)
                    : Colors.transparent,
                boxShadow: _hovered
                    ? [
                        BoxShadow(
                          color: hoverColor.withValues(alpha: 0.25),
                          blurRadius: 12,
                          spreadRadius: 0,
                        ),
                      ]
                    : [],
              ),
              child: Icon(
                widget.data.icon,
                size: widget.iconSize,
                color: _hovered ? hoverColor : baseColor,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _launch() async {
    final uri = Uri.parse(widget.data.url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}

// =============================================================================
// PremiumBackToTopButton — floating button with scroll progress arc & glow
// =============================================================================

/// Floating back-to-top button positioned at bottom-right.
///
/// Features:
/// - Appears after scrolling past the hero section (> 500px)
/// - Smooth entrance animation (slide up + scale + fade)
/// - Circular progress arc showing overall scroll position
/// - Accent border fill that tracks scroll percentage
/// - Hover glow effect with icon scale
/// - Responsive sizing (smaller on mobile)
class PremiumBackToTopButton extends StatefulWidget {
  const PremiumBackToTopButton({super.key});

  @override
  State<PremiumBackToTopButton> createState() => _PremiumBackToTopButtonState();
}

class _PremiumBackToTopButtonState extends State<PremiumBackToTopButton>
    with SingleTickerProviderStateMixin {
  bool _visible = false;
  bool _hovered = false;
  double _scrollProgress = 0.0;
  late final AnimationController _entranceCtrl;
  late final Animation<double> _entranceAnimation;

  @override
  void initState() {
    super.initState();
    _entranceCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _entranceAnimation = CurvedAnimation(
      parent: _entranceCtrl,
      curve: CinematicCurves.dramaticEntrance,
    );
    Get.find<AppScrollController>().scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    final controller = Get.find<AppScrollController>().scrollController;
    if (!controller.hasClients) return;

    final offset = controller.offset;
    final maxExtent = controller.position.maxScrollExtent;
    final shouldShow = offset > 500;

    if (shouldShow != _visible) {
      setState(() => _visible = shouldShow);
      if (shouldShow) {
        _entranceCtrl.forward();
      } else {
        _entranceCtrl.reverse();
      }
    }

    // Update scroll progress (debounced to avoid excessive repaints)
    final progress =
        maxExtent > 0 ? (offset / maxExtent).clamp(0.0, 1.0) : 0.0;
    if ((progress - _scrollProgress).abs() > 0.005) {
      setState(() => _scrollProgress = progress);
    }
  }

  @override
  void dispose() {
    if (Get.isRegistered<AppScrollController>()) {
      Get.find<AppScrollController>()
          .scrollController
          .removeListener(_onScroll);
    }
    _entranceCtrl.dispose();
    super.dispose();
  }

  void _scrollToTop() {
    Get.find<AppScrollController>().scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 800),
      curve: Curves.easeInOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final isMobile = width < Breakpoints.mobile;
    final buttonSize = isMobile ? 40.0 : 48.0;
    final bottomOffset = isMobile ? 20.0 : 32.0;
    final rightOffset = isMobile ? 16.0 : 32.0;

    return Positioned(
      bottom: bottomOffset,
      right: rightOffset,
      child: AnimatedBuilder(
        animation: _entranceAnimation,
        builder: (_, __) {
          final v = _entranceAnimation.value;
          return Opacity(
            opacity: v,
            child: Transform.translate(
              offset: Offset(0, 20 * (1 - v)),
              child: Transform.scale(
                scale: 0.6 + 0.4 * v,
                child: IgnorePointer(
                  ignoring: !_visible,
                  child: MouseRegion(
                    onEnter: (_) => setState(() => _hovered = true),
                    onExit: (_) => setState(() => _hovered = false),
                    cursor: SystemMouseCursors.click,
                    child: GestureDetector(
                      onTap: _scrollToTop,
                      child: Semantics(
                        button: true,
                        label: 'Back to top',
                        child: AnimatedContainer(
                          duration: AppDurations.fast,
                          width: buttonSize,
                          height: buttonSize,
                          child: CustomPaint(
                            painter: _ScrollProgressPainter(
                              progress: _scrollProgress,
                              hovered: _hovered,
                            ),
                            child: Center(
                              child: AnimatedContainer(
                                duration: AppDurations.fast,
                                transform: Matrix4.identity()
                                  ..scaleByDouble(
                                    _hovered ? 1.15 : 1.0,
                                    _hovered ? 1.15 : 1.0,
                                    _hovered ? 1.15 : 1.0,
                                    1.0,
                                  ),
                                transformAlignment: Alignment.center,
                                child: Icon(
                                  Icons.arrow_upward_rounded,
                                  size: isMobile ? 18 : 22,
                                  color: _hovered
                                      ? AppColors.accent
                                      : AppColors.textPrimary,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// =============================================================================
// _ScrollProgressPainter — circular arc showing scroll position
// =============================================================================

/// Paints a circular progress arc showing scroll position with optional
/// hover glow effect.
class _ScrollProgressPainter extends CustomPainter {
  _ScrollProgressPainter({
    required this.progress,
    required this.hovered,
  });

  final double progress;
  final bool hovered;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 3;
    final strokeWidth = hovered ? 2.5 : 2.0;

    final bgPaint = Paint()
      ..color = AppColors.backgroundLight.withValues(alpha: hovered ? 0.8 : 0.6)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius + 1, bgPaint);

    final trackPaint = Paint()
      ..color = Colors.white.withValues(alpha: hovered ? 0.15 : 0.08)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    canvas.drawCircle(center, radius, trackPaint);

    // Progress arc — accent border fill
    if (progress > 0.01) {
      final progressPaint = Paint()
        ..color = AppColors.accent.withValues(alpha: hovered ? 1.0 : 0.7)
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;

      // Glow layer on hover
      if (hovered) {
        final glowPaint = Paint()
          ..color = AppColors.accent.withValues(alpha: 0.3)
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth + 4
          ..strokeCap = StrokeCap.round
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);

        canvas.drawArc(
          Rect.fromCircle(center: center, radius: radius),
          -math.pi / 2,
          2 * math.pi * progress,
          false,
          glowPaint,
        );
      }

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -math.pi / 2,
        2 * math.pi * progress,
        false,
        progressPaint,
      );
    }
  }

  @override
  bool shouldRepaint(_ScrollProgressPainter old) =>
      progress != old.progress ||
      hovered != old.hovered;
}
