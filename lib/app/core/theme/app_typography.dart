import 'package:flutter/painting.dart';
import 'package:flutter_web_portfolio/app/core/theme/app_fonts.dart';
import 'package:flutter_web_portfolio/app/core/constants/app_colors.dart';

/// Centralized text styles — display, heading, body, and monospace tiers.
///
/// Dark-only theme. Call site can override with `.copyWith(color: ...)` when needed.
final class AppTypography {
  const AppTypography._();

  // ─── Display tier (Space Grotesk) ──────────────────────────────────────
  static final display = AppFonts.spaceGrotesk(
    fontSize: 120,
    fontWeight: FontWeight.w800,
    height: 0.95,
    letterSpacing: -4,
    color: AppColors.textBright,
  );

  static final displayMobile = AppFonts.spaceGrotesk(
    fontSize: 60,
    fontWeight: FontWeight.w800,
    height: 0.95,
    letterSpacing: -2,
    color: AppColors.textBright,
  );

  // Hero (responsive — use clamp at call site)
  static final hero = AppFonts.spaceGrotesk(
    fontSize: 80,
    fontWeight: FontWeight.w800,
    height: 1.0,
    letterSpacing: -4,
    color: AppColors.textBright,
  );

  static final heroMobile = AppFonts.spaceGrotesk(
    fontSize: 40,
    fontWeight: FontWeight.w800,
    height: 1.0,
    letterSpacing: -1,
    color: AppColors.textBright,
  );

  // H1 — section titles
  static final h1 = AppFonts.spaceGrotesk(
    fontSize: 32,
    fontWeight: FontWeight.w700,
    height: 1.2,
    color: AppColors.textBright,
  );

  // H2 — subsection titles
  static final h2 = AppFonts.spaceGrotesk(
    fontSize: 22,
    fontWeight: FontWeight.w600,
    height: 1.3,
    color: AppColors.textBright,
  );

  // H3 — card titles
  static final h3 = AppFonts.spaceGrotesk(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    height: 1.4,
    color: AppColors.textBright,
  );

  // Body
  static final body = AppFonts.inter(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 1.6,
    letterSpacing: 0.2,
    color: AppColors.textPrimary,
  );

  // Body small
  static final bodySmall = AppFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.6,
    color: AppColors.textPrimary,
  );

  // Label — monospace accent
  static final label = AppFonts.jetBrainsMono(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.4,
    color: AppColors.heroAccent,
  );

  // Nav label
  static final navLabel = AppFonts.spaceGrotesk(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    height: 1.4,
    letterSpacing: 2,
    color: AppColors.textPrimary,
  );

  // Caption — monospace secondary
  static final caption = AppFonts.jetBrainsMono(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    height: 1.5,
    color: AppColors.textSecondary,
  );

  // Monospace body (for tech tags, dates)
  static final mono = AppFonts.jetBrainsMono(
    fontSize: 13,
    fontWeight: FontWeight.w400,
    height: 1.5,
    color: AppColors.textSecondary,
  );
}
