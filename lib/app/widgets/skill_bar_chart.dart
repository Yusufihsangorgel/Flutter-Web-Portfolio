import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_web_portfolio/app/core/constants/app_colors.dart';
import 'package:flutter_web_portfolio/app/core/constants/cinematic_curves.dart';

/// Animated skill proficiency chart.
///
/// Each category is rendered as a gradient bar that fills from 0% to its target
/// width when the widget's [animation] value progresses from 0.0 to 1.0.
/// Uses [CustomPaint] for smooth gradient bar rendering.
class SkillBarChart extends StatelessWidget {
  const SkillBarChart({
    super.key,
    required this.categories,
    required this.proficiencies,
    required this.accent,
    required this.animation,
    this.barHeight = 28.0,
    this.barSpacing = 20.0,
  });

  /// Category labels (e.g. "Mobile", "Backend").
  final List<String> categories;

  /// Target fill fraction per category, 0.0–1.0.
  final List<double> proficiencies;

  /// Scene accent colour for the gradient fill.
  final Color accent;

  /// Master animation value driving all bar fills (0.0–1.0).
  final Animation<double> animation;

  /// Height of each bar (responsive — caller passes smaller value on mobile).
  final double barHeight;

  /// Vertical spacing between bars.
  final double barSpacing;

  @override
  Widget build(BuildContext context) {
    final count = categories.length;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.backgroundLight.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: accent.withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: List.generate(count, (i) {
          // Stagger: each bar starts 100ms later (normalised to 0.0–1.0 range).
          // Total animation window = 800ms per bar + 100ms * (count-1) stagger.
          // We map each bar to an interval within [0, 1].
          final totalMs = 800.0 + 100.0 * (count - 1);
          final startFraction = (100.0 * i) / totalMs;
          final endFraction = (800.0 + 100.0 * i) / totalMs;

          final staggered = CurvedAnimation(
            parent: animation,
            curve: Interval(
              startFraction.clamp(0.0, 1.0),
              endFraction.clamp(0.0, 1.0),
              curve: CinematicCurves.dramaticEntrance,
            ),
          );

          return Padding(
            padding: EdgeInsets.only(bottom: i < count - 1 ? barSpacing : 0),
            child: _SkillBar(
              label: categories[i],
              proficiency: proficiencies[i],
              accent: accent,
              animation: staggered,
              barHeight: barHeight,
            ),
          );
        }),
      ),
    );
  }
}

// ─── Single bar ──────────────────────────────────────────────────────────────

class _SkillBar extends StatelessWidget {
  const _SkillBar({
    required this.label,
    required this.proficiency,
    required this.accent,
    required this.animation,
    required this.barHeight,
  });

  final String label;
  final double proficiency;
  final Color accent;
  final Animation<double> animation;
  final double barHeight;

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
      animation: animation,
      builder: (_, __) {
        final progress = animation.value;
        final displayPercent = (proficiency * progress * 100).round();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Label row: category on left, percentage on right.
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  label,
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textBright,
                  ),
                ),
                Opacity(
                  opacity: progress.clamp(0.0, 1.0),
                  child: Text(
                    '$displayPercent%',
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: accent,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Bar track + fill via CustomPaint.
            ClipRRect(
              borderRadius: BorderRadius.circular(barHeight / 2),
              child: CustomPaint(
                size: Size(double.infinity, barHeight),
                painter: _BarPainter(
                  fillFraction: proficiency * progress,
                  accent: accent,
                  trackColor: AppColors.backgroundDark.withValues(alpha: 0.6),
                  borderRadius: barHeight / 2,
                ),
              ),
            ),
          ],
        );
      },
    );
}

// ─── CustomPainter ───────────────────────────────────────────────────────────

class _BarPainter extends CustomPainter {
  _BarPainter({
    required this.fillFraction,
    required this.accent,
    required this.trackColor,
    required this.borderRadius,
  });

  final double fillFraction;
  final Color accent;
  final Color trackColor;
  final double borderRadius;

  @override
  void paint(Canvas canvas, Size size) {
    final trackRRect = RRect.fromRectAndRadius(
      Offset.zero & size,
      Radius.circular(borderRadius),
    );

    // Track background.
    canvas.drawRRect(
      trackRRect,
      Paint()..color = trackColor,
    );

    // Filled portion with gradient.
    final fillWidth = size.width * fillFraction.clamp(0.0, 1.0);
    if (fillWidth <= 0) return;

    final fillRect = Rect.fromLTWH(0, 0, fillWidth, size.height);
    final fillRRect = RRect.fromRectAndRadius(
      fillRect,
      Radius.circular(borderRadius),
    );

    final gradient = LinearGradient(
      colors: [
        accent.withValues(alpha: 0.7),
        accent,
        accent.withValues(alpha: 0.85),
      ],
      stops: const [0.0, 0.6, 1.0],
    );

    canvas.drawRRect(
      fillRRect,
      Paint()..shader = gradient.createShader(fillRect),
    );

    // Subtle glow at the leading edge.
    if (fillWidth > 4) {
      final glowRect = Rect.fromLTWH(
        fillWidth - 4,
        0,
        4,
        size.height,
      );
      canvas.drawRect(
        glowRect,
        Paint()
          ..shader = LinearGradient(
            colors: [
              Colors.transparent,
              accent.withValues(alpha: 0.4),
            ],
          ).createShader(glowRect),
      );
    }
  }

  @override
  bool shouldRepaint(_BarPainter old) =>
      fillFraction != old.fillFraction || accent != old.accent;
}
