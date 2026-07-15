import 'package:flutter_web_portfolio/app/domain/models/portfolio_document.dart';

/// Typed identity helpers resolved from the canonical portfolio document.
///
/// Widgets never hard-code a person's name or derive a second content source.
final class AppConfig {
  AppConfig._();

  // ─── Identity ──────────────────────────────────────────────────────

  /// Public display label.
  static String name(PortfolioDocument portfolio) => portfolio.profile.name;

  /// Human-readable navigation wordmark derived from the public display name.
  static String navigationName(PortfolioDocument portfolio) {
    final full = name(portfolio).trim();
    if (full.isEmpty) return 'Portfolio';
    final parts = full.split(RegExp(r'\s+'));
    if (parts.length >= 2) return '${parts.first} ${parts.last}';
    return full;
  }

  /// Short brand tagline for the hero and footer.
  static String tagline(PortfolioDocument portfolio) =>
      portfolio.profile.headline;
}
