import 'package:flutter/painting.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_web_portfolio/app/core/constants/app_colors.dart';

/// Centralized text styles — display, heading, body, and monospace tiers.
///
/// Dark-only theme. Call site can override with `.copyWith(color: ...)` when needed.
final class AppTypography {
  const AppTypography._();

  // ─── Display tier (Space Grotesk — cinematic) ─────────────────────────
  static final display = GoogleFonts.spaceGrotesk(
    fontSize: 120,
    fontWeight: FontWeight.w800,
    height: 0.95,
    letterSpacing: -4,
    color: AppColors.textBright,
  );

  static final displayMobile = GoogleFonts.spaceGrotesk(
    fontSize: 60,
    fontWeight: FontWeight.w800,
    height: 0.95,
    letterSpacing: -2,
    color: AppColors.textBright,
  );

  // Hero (responsive — use clamp at call site)
  static final hero = GoogleFonts.spaceGrotesk(
    fontSize: 80,
    fontWeight: FontWeight.w800,
    height: 1.0,
    letterSpacing: -4,
    color: AppColors.textBright,
  );

  static final heroMobile = GoogleFonts.spaceGrotesk(
    fontSize: 40,
    fontWeight: FontWeight.w800,
    height: 1.0,
    letterSpacing: -1,
    color: AppColors.textBright,
  );

  // H1 — section titles
  static final h1 = GoogleFonts.spaceGrotesk(
    fontSize: 32,
    fontWeight: FontWeight.w700,
    height: 1.2,
    color: AppColors.textBright,
  );

  // H2 — subsection titles
  static final h2 = GoogleFonts.spaceGrotesk(
    fontSize: 22,
    fontWeight: FontWeight.w600,
    height: 1.3,
    color: AppColors.textBright,
  );

  // H3 — card titles
  static final h3 = GoogleFonts.spaceGrotesk(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    height: 1.4,
    color: AppColors.textBright,
  );

  // Body
  static final body = GoogleFonts.inter(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 1.6,
    letterSpacing: 0.2,
    color: AppColors.textPrimary,
  );

  // Body small
  static final bodySmall = GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.6,
    color: AppColors.textPrimary,
  );

  // Label — monospace accent
  static final label = GoogleFonts.jetBrainsMono(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.4,
    color: AppColors.heroAccent,
  );

  // Nav label
  static final navLabel = GoogleFonts.spaceGrotesk(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    height: 1.4,
    letterSpacing: 2,
    color: AppColors.textPrimary,
  );

  // Caption — monospace secondary
  static final caption = GoogleFonts.jetBrainsMono(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    height: 1.5,
    color: AppColors.textSecondary,
  );

  // Monospace body (for tech tags, dates)
  static final mono = GoogleFonts.jetBrainsMono(
    fontSize: 13,
    fontWeight: FontWeight.w400,
    height: 1.5,
    color: AppColors.textSecondary,
  );

}
