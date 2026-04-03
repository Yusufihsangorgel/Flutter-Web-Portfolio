import 'dart:math' show min;

import 'package:flutter_web_portfolio/app/controllers/language_controller.dart';

/// Central configuration resolved from i18n JSON at runtime.
///
/// **For fork users**: customise your portfolio by editing only the
/// `assets/i18n/*.json` files. Every personal detail — name, email,
/// stats, social links — is pulled from there at startup.
///
/// This class provides typed helpers so widgets never hard-code personal data.
final class AppConfig {
  AppConfig._();

  // ─── Identity ──────────────────────────────────────────────────────

  /// Full display name (e.g. "Jane Doe").
  static String name(LanguageController lc) =>
      lc.getText('cv_data.personal_info.name', defaultValue: 'Your Name');

  /// Two-letter initials derived from [name] (e.g. "JD").
  static String initials(LanguageController lc) {
    final full = name(lc);
    final parts = full.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    }
    return full.substring(0, min(2, full.length)).toUpperCase();
  }

  /// Primary job title / tagline shown in the hero section.
  static String title(LanguageController lc) => lc.getText(
        'home_section.subtitle',
        defaultValue: 'Software Engineer',
      );

  /// Short brand tagline for the preloader and footer.
  static String tagline(LanguageController lc) => lc.getText(
        'cv_data.personal_info.tagline',
        defaultValue: 'Building digital experiences',
      );

  /// Contact e-mail address.
  static String email(LanguageController lc) =>
      (lc.cvData['personal_info']?['email'] as String?) ?? 'hello@example.com';

  /// Physical location string.
  static String location(LanguageController lc) => lc.getText(
        'cv_data.personal_info.location',
        defaultValue: '',
      );

  // ─── Stats ─────────────────────────────────────────────────────────

  static int yearsExperience(LanguageController lc) =>
      _stat(lc, 'years_experience');

  static int projectsCompleted(LanguageController lc) =>
      _stat(lc, 'projects_completed');

  static int technologies(LanguageController lc) =>
      _stat(lc, 'technologies');

  /// Returns `true` when at least one stat is non-zero, meaning
  /// the section should be rendered.
  static bool hasStats(LanguageController lc) =>
      yearsExperience(lc) > 0 ||
      projectsCompleted(lc) > 0 ||
      technologies(lc) > 0;

  static int _stat(LanguageController lc, String key) =>
      (lc.cvData['personal_info']?['stats']?[key] as int?) ?? 0;
}
