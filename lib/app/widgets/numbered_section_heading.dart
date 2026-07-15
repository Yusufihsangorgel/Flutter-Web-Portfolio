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
  });

  /// Two-digit section number (e.g. "01", "02").
  final String number;

  /// Section title text.
  final String title;

  /// Accent color for the section number and divider.
  final Color accent;

  @override
  Widget build(BuildContext context) => Semantics(
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
              Text(
                number,
                style: AppFonts.jetBrainsMono(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: accent,
                  letterSpacing: 1.1,
                ),
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
