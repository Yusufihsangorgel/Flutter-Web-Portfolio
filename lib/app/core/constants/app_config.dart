import 'dart:math' show min;

import 'package:flutter_web_portfolio/app/features/language/application/language_cubit.dart';

/// Central configuration resolved from i18n JSON at runtime.
///
/// **For fork users**: customise your portfolio by editing only the
/// `assets/i18n/*.json` files. Public-facing labels and optional links are
/// pulled from there at startup.
///
/// This class provides typed helpers so widgets never hard-code personal data.
final class AppConfig {
  AppConfig._();

  // ─── Identity ──────────────────────────────────────────────────────

  /// Public display label.
  static String name(LanguageCubit lc) => lc.getText(
    'cv_data.personal_info.name',
    defaultValue: 'Systems Portfolio',
  );

  /// Two-letter initials derived from the current public display label.
  static String initials(LanguageCubit lc) {
    final full = name(lc).trim();
    if (full.isEmpty) return 'SP';
    final parts = full.split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    }
    return full.substring(0, min(2, full.length)).toUpperCase();
  }

  /// Short brand tagline for the preloader and footer.
  static String tagline(LanguageCubit lc) => lc.getText(
    'cv_data.personal_info.tagline',
    defaultValue: 'Building digital experiences',
  );
}
