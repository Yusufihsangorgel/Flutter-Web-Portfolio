import 'package:flutter/material.dart';
import 'package:flutter_web_portfolio/app/core/constants/app_colors.dart';
import 'package:flutter_web_portfolio/app/core/theme/app_fonts.dart';
import 'package:flutter_web_portfolio/app/core/constants/breakpoints.dart';

/// Clear editorial marker shared by the portfolio sections.
class NumberedSectionHeading extends StatelessWidget {
  const NumberedSectionHeading({
    super.key,
    required this.number,
    required this.title,
    required this.accent,
    this.anchorKey,
  });

  /// Two-digit section number (e.g. "01", "02").
  final String number;

  /// Section title text.
  final String title;

  /// Accent color for the section number and divider.
  final Color accent;

  /// Optional document-space anchor placed just outside the section marker.
  ///
  /// The narrative stage can join chapter headings without drawing through
  /// the section's editorial content.
  final Key? anchorKey;

  @override
  Widget build(BuildContext context) {
    final anchorOffset = Directionality.of(context) == TextDirection.rtl
        ? const Offset(14, 0)
        : const Offset(-14, 0);

    return Semantics(
      header: true,
      headingLevel: 2,
      label: title,
      excludeSemantics: true,
      child: ExcludeSemantics(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.centerLeft,
                  children: [
                    if (anchorKey != null)
                      Transform.translate(
                        offset: anchorOffset,
                        child: SizedBox(key: anchorKey, width: 1, height: 1),
                      ),
                    Text(
                      number,
                      style: AppFonts.spaceGrotesk(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: accent,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 18),
                Expanded(
                  child: Container(
                    key: const ValueKey('chapter-divider'),
                    height: 1,
                    color: accent.withValues(alpha: 0.32),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: AppFonts.spaceGrotesk(
                fontSize: MediaQuery.sizeOf(context).width < Breakpoints.tablet
                    ? 44
                    : 68,
                fontWeight: FontWeight.w600,
                color: AppColors.textBright,
                height: 0.98,
                letterSpacing: -2.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
