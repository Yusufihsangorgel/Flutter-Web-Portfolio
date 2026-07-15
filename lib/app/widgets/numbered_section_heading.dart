import 'package:flutter/material.dart';
import 'package:flutter_web_portfolio/app/core/constants/app_colors.dart';
import 'package:flutter_web_portfolio/app/core/theme/app_fonts.dart';
import 'package:flutter_web_portfolio/app/core/constants/breakpoints.dart';

/// Editorial chapter marker shared by the long-form portfolio document.
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

  /// Scene accent color for number and divider.
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
            children: [
              Text(
                'CHAPTER / $number',
                style: AppFonts.jetBrainsMono(
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                  color: accent,
                  letterSpacing: 1.3,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Container(
                  key: const ValueKey('chapter-divider'),
                  height: 1,
                  color: accent.withValues(alpha: 0.32),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: AppFonts.instrumentSerif(
                    fontSize:
                        MediaQuery.sizeOf(context).width < Breakpoints.tablet
                        ? 48
                        : 72,
                    fontStyle: FontStyle.italic,
                    color: AppColors.textBright,
                    height: 0.9,
                    letterSpacing: -1.8,
                  ),
                ),
              ),
              const SizedBox(width: 18),
              Text(
                '$number / 04',
                style: AppFonts.jetBrainsMono(
                  fontSize: 9,
                  color: accent,
                  letterSpacing: 0.9,
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}
