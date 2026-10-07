import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_web_portfolio/app/domain/models/portfolio_document.dart';

/// Content-authored colours for one project surface.
@immutable
final class ProjectPalette {
  const ProjectPalette({
    required this.background,
    required this.foreground,
    required this.accent,
  });

  factory ProjectPalette.from(PortfolioSystemPresentation value) =>
      ProjectPalette(
        background: hexColor(value.background),
        foreground: hexColor(value.foreground),
        accent: hexColor(value.accent),
      );

  final Color background;
  final Color foreground;
  final Color accent;

  /// [foreground] at one of the `AtlasAlpha` opacity steps.
  Color ink(double alpha) => foreground.withValues(alpha: alpha);
}

/// Parses an opaque `#RRGGBB` content colour.
Color hexColor(String value) =>
    Color(int.parse('FF${value.substring(1)}', radix: 16));
