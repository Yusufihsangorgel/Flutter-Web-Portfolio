import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:flutter_web_portfolio/app/core/constants/app_colors.dart';
import 'package:flutter_web_portfolio/app/core/constants/breakpoints.dart';
import 'package:flutter_web_portfolio/app/core/constants/cinematic_curves.dart';
import 'package:flutter_web_portfolio/app/core/theme/app_typography.dart';

// ─────────────────────────────────────────────────────────────────────────────
// AnimatedStatCard — Number counting animation triggered on scroll-into-view
// ─────────────────────────────────────────────────────────────────────────────

/// Displays a single stat that counts up from 0 to [value] when the widget
/// first scrolls into the viewport.
///
/// Supports an optional [suffix] (e.g. "+", "k", "%") and a [label] displayed
/// below the number. The animation fires only once.
class AnimatedStatCard extends StatefulWidget {
  const AnimatedStatCard({
    super.key,
    required this.value,
    this.suffix = '',
    this.label = '',
    this.duration = const Duration(milliseconds: 1800),
    this.curve = CinematicCurves.revealDecel,
    this.accentColor,
    this.delay = Duration.zero,
  });

  /// Target numeric value to count up to.
  final int value;

  /// Text appended after the number ("+", "k", "%", etc.).
  final String suffix;

  /// Description below the number.
  final String label;

  /// Duration of the counting animation.
  final Duration duration;

  /// Easing curve for the animation.
  final Curve curve;

  /// Accent color for the number. Falls back to [AppColors.heroAccent].
  final Color? accentColor;

  /// Optional delay before the animation starts (used for stagger).
  final Duration delay;

  @override
  State<AnimatedStatCard> createState() => _AnimatedStatCardState();
}

class _AnimatedStatCardState extends State<AnimatedStatCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _countAnimation;
  late Animation<double> _opacityAnimation;
  late Animation<double> _scaleAnimation;
  bool _triggered = false;
  ScrollPosition? _scrollPosition;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);

    _countAnimation = Tween<double>(
      begin: 0,
      end: widget.value.toDouble(),
    ).animate(CurvedAnimation(parent: _controller, curve: widget.curve));

    _opacityAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0, 0.3, curve: Curves.easeOut),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0, 0.5, curve: Curves.easeOutCubic),
      ),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) => _checkVisibility());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _scrollPosition?.removeListener(_checkVisibility);
    _scrollPosition = Scrollable.maybeOf(context)?.position;
    _scrollPosition?.addListener(_checkVisibility);
  }

  void _checkVisibility() {
    if (_triggered || !mounted) return;

    final renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null || !renderBox.hasSize) return;

    final position = renderBox.localToGlobal(Offset.zero);
    final screenHeight = MediaQuery.sizeOf(context).height;

    if (position.dy < screenHeight * 0.85 &&
        position.dy > -renderBox.size.height) {
      _triggered = true;
      _scrollPosition?.removeListener(_checkVisibility);

      if (widget.delay == Duration.zero) {
        _controller.forward();
      } else {
        Future.delayed(widget.delay, () {
          if (mounted) _controller.forward();
        });
      }
    }
  }

  @override
  void dispose() {
    _scrollPosition?.removeListener(_checkVisibility);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accent = widget.accentColor ?? AppColors.heroAccent;

    return AnimatedBuilder(
      animation: _controller,
      builder: (_, __) {
        final currentValue = _countAnimation.value.toInt();

        return Opacity(
          opacity: _opacityAnimation.value,
          child: Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
              decoration: BoxDecoration(
                color: AppColors.backgroundLight.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: accent.withValues(alpha: 0.1),
                  width: 1,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Number + suffix with neon glow
                  Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: _formatNumber(currentValue),
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 36,
                            fontWeight: FontWeight.w800,
                            color: accent,
                            shadows: [
                              Shadow(
                                color: accent.withValues(alpha: 0.5),
                                blurRadius: 12,
                              ),
                              Shadow(
                                color: accent.withValues(alpha: 0.25),
                                blurRadius: 24,
                              ),
                            ],
                          ),
                        ),
                        if (widget.suffix.isNotEmpty)
                          TextSpan(
                            text: widget.suffix,
                            style: GoogleFonts.spaceGrotesk(
                              fontSize: 24,
                              fontWeight: FontWeight.w600,
                              color: accent.withValues(alpha: 0.7),
                            ),
                          ),
                      ],
                    ),
                    textAlign: TextAlign.center,
                  ),
                  if (widget.label.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      widget.label,
                      style: AppTypography.caption.copyWith(
                        color: AppColors.textPrimary,
                        fontSize: 12,
                        letterSpacing: 1,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  /// Formats large numbers with comma separators (e.g. 50000 -> 50,000).
  String _formatNumber(int n) {
    if (n < 1000) return '$n';
    final s = n.toString();
    final buffer = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buffer.write(',');
      buffer.write(s[i]);
    }
    return buffer.toString();
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// StatsGrid — Responsive grid of AnimatedStatCards with stagger animation
// ─────────────────────────────────────────────────────────────────────────────

/// A responsive grid displaying key portfolio statistics. Each stat animates
/// in sequence with a configurable stagger delay.
///
/// By default renders four stats: Years Experience, Projects Completed,
/// Happy Clients, and Lines of Code. Override [stats] to customize.
class StatsGrid extends StatelessWidget {
  const StatsGrid({
    super.key,
    this.stats,
    this.accentColor,
    this.staggerDelay = const Duration(milliseconds: 150),
  });

  /// Custom list of stats. When null, uses the default set.
  final List<StatItem>? stats;

  /// Accent color applied to all stat numbers. Falls back to
  /// [AppColors.heroAccent].
  final Color? accentColor;

  /// Delay between each card's animation start.
  final Duration staggerDelay;

  static const List<StatItem> _defaultStats = [
    StatItem(value: 5, suffix: '+', label: 'Years Experience'),
    StatItem(value: 30, suffix: '+', label: 'Projects Completed'),
    StatItem(value: 20, suffix: '+', label: 'Happy Clients'),
    StatItem(value: 50, suffix: 'k+', label: 'Lines of Code'),
  ];

  @override
  Widget build(BuildContext context) {
    final items = stats ?? _defaultStats;
    final screenWidth = MediaQuery.sizeOf(context).width;

    // Responsive column count
    final crossAxisCount = screenWidth >= Breakpoints.desktop
        ? 4
        : screenWidth >= Breakpoints.tablet
            ? 4
            : screenWidth >= Breakpoints.mobile
                ? 2
                : 2;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: screenWidth >= Breakpoints.mobile ? 1.4 : 1.2,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return AnimatedStatCard(
          value: item.value,
          suffix: item.suffix,
          label: item.label,
          accentColor: accentColor ?? AppColors.heroAccent,
          delay: Duration(
            milliseconds: staggerDelay.inMilliseconds * index,
          ),
        );
      },
    );
  }
}

/// Data class describing a single stat for [StatsGrid].
class StatItem {
  const StatItem({
    required this.value,
    this.suffix = '',
    this.label = '',
  });

  final int value;
  final String suffix;
  final String label;
}
