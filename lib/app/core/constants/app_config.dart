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

  /// Two-letter initials derived from [name] (e.g. "JD").
  static String initials(LanguageCubit lc) {
    final full = name(lc);
    final parts = full.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    }
    return full.substring(0, min(2, full.length)).toUpperCase();
  }

  /// Primary job title / tagline shown in the hero section.
  static String title(LanguageCubit lc) =>
      lc.getText('home_section.subtitle', defaultValue: 'Software Engineer');

  /// Short brand tagline for the preloader and footer.
  static String tagline(LanguageCubit lc) => lc.getText(
    'cv_data.personal_info.tagline',
    defaultValue: 'Building digital experiences',
  );

  /// Contact e-mail address.
  static String email(LanguageCubit lc) =>
      (lc.cvData['personal_info']?['email'] as String?) ?? '';

  /// Physical location string.
  static String location(LanguageCubit lc) =>
      lc.getText('cv_data.personal_info.location', defaultValue: '');
}
