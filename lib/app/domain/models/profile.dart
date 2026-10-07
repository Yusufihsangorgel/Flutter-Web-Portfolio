import 'package:flutter_web_portfolio/app/domain/models/shared_value_types.dart';

typedef PortfolioProfileTranslation = ({
  String role,
  String location,
  String headline,
  String summary,
  String background,
  List<String> focus,
  List<PortfolioLink> links,
});

typedef PortfolioProfileFields = ({
  String name,
  PortfolioDisplayName displayName,
  String role,
  String location,
  String email,
  String since,
  String headline,
  String summary,
  String background,
  List<String> focus,
  List<PortfolioLink> links,
});

final class PortfolioProfile {
  PortfolioProfile(PortfolioProfileFields fields)
    : name = fields.name,
      displayName = fields.displayName,
      role = fields.role,
      location = fields.location,
      email = fields.email,
      since = fields.since,
      headline = fields.headline,
      summary = fields.summary,
      background = fields.background,
      focus = List.unmodifiable(fields.focus),
      links = List.unmodifiable(fields.links);

  PortfolioProfile copyWith(PortfolioProfileTranslation changes) =>
      PortfolioProfile((
        name: name,
        displayName: displayName,
        role: changes.role,
        location: changes.location,
        email: email,
        since: since,
        headline: changes.headline,
        summary: changes.summary,
        background: changes.background,
        focus: changes.focus,
        links: changes.links,
      ));

  Map<String, Object?> toJson() => {
    'name': name,
    'display_name': displayName.toJson(),
    'role': role,
    'location': location,
    'email': email,
    'since': since,
    'headline': headline,
    'summary': summary,
    'background': background,
    'focus': focus,
    'links': [for (final value in links) value.toJson()],
  };

  final String name;
  final PortfolioDisplayName displayName;
  final String role;
  final String location;
  final String email;
  final String since;
  final String headline;
  final String summary;
  final String background;
  final List<String> focus;
  final List<PortfolioLink> links;
}

/// Identity presentation supplied by the content, never derived from
/// [PortfolioProfile.name].
final class PortfolioDisplayName {
  const PortfolioDisplayName({
    required this.primary,
    required this.accent,
    required this.navigation,
    required this.accessible,
  });

  Map<String, Object?> toJson() => {
    'primary': primary,
    'accent': accent,
    'navigation': navigation,
    'accessible': accessible,
  };

  final String primary;
  final String accent;
  final String navigation;
  final String accessible;
}
