import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_web_portfolio/app/core/theme/app_typography.dart';

/// Numbered section heading — monospace number prefix + title + accent line.
///
/// Pattern: `01. About Me` with a thin accent-colored divider below.
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
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                '$number.',
                style: GoogleFonts.jetBrainsMono(
                  fontSize: AppTypography.h1.fontSize,
                  fontWeight: FontWeight.w400,
                  height: AppTypography.h1.height,
                  color: accent,
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  title,
                  style: AppTypography.h1.copyWith(color: accent),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            width: 100,
            height: 1,
            color: accent.withValues(alpha: 0.15),
          ),
        ],
      );
}
