import 'dart:math' show min;

import 'package:flutter_web_portfolio/app/domain/models/portfolio_document.dart';

/// Central configuration resolved from i18n JSON at runtime.
///
/// Public content remains data-driven through `assets/i18n/*.json`, keeping
/// locale changes separate from layout and rendering code.
///
/// This class provides typed helpers so widgets never hard-code personal data.
final class AppConfig {
  AppConfig._();

  // ─── Identity ──────────────────────────────────────────────────────

  /// Public display label.
  static String name(PortfolioDocument portfolio) => portfolio.profile.role;

  /// Compact brand mark derived from the current public display label.
  static String initials(PortfolioDocument portfolio) {
    final full = name(portfolio).trim();
    if (full.isEmpty) return 'SP';
    if (full.toLowerCase().contains('flutter')) return 'FLUTTER';
    final parts = full.split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    }
    return full.substring(0, min(2, full.length)).toUpperCase();
  }

  /// Short brand tagline for the hero and footer.
  static String tagline(PortfolioDocument portfolio) =>
      portfolio.profile.headline;
}
