import 'package:flutter_web_portfolio/app/domain/models/shared_value_types.dart';

typedef PortfolioSiteTranslation = ({
  String title,
  String description,
  String socialDescription,
  List<PortfolioLink> engineeringLinks,
});

typedef PortfolioSiteFields = ({
  Uri url,
  String title,
  String description,
  String socialDescription,
  String socialImage,
  String domainLabel,
  List<String> locales,
  List<PortfolioLink> engineeringLinks,
  PortfolioAnalytics? analytics,
});

final class PortfolioSite {
  PortfolioSite(PortfolioSiteFields fields)
    : url = fields.url,
      title = fields.title,
      description = fields.description,
      socialDescription = fields.socialDescription,
      socialImage = fields.socialImage,
      domainLabel = fields.domainLabel,
      locales = List.unmodifiable(fields.locales),
      engineeringLinks = List.unmodifiable(fields.engineeringLinks),
      analytics = fields.analytics;

  PortfolioSite copyWith(PortfolioSiteTranslation changes) => PortfolioSite((
    url: url,
    title: changes.title,
    description: changes.description,
    socialDescription: changes.socialDescription,
    socialImage: socialImage,
    domainLabel: domainLabel,
    locales: locales,
    engineeringLinks: changes.engineeringLinks,
    analytics: analytics,
  ));

  Map<String, Object?> toJson() => {
    'url': url.toString(),
    'title': title,
    'description': description,
    'social_description': socialDescription,
    'social_image': socialImage,
    'domain_label': domainLabel,
    'locales': locales,
    'engineering_links': [for (final value in engineeringLinks) value.toJson()],
    'analytics': analytics?.toJson(),
  };

  final Uri url;
  final String title;
  final String description;
  final String socialDescription;
  final String socialImage;
  final String domainLabel;
  final List<String> locales;
  final List<PortfolioLink> engineeringLinks;
  final PortfolioAnalytics? analytics;
}

final class PortfolioAnalytics {
  const PortfolioAnalytics({required this.scriptUrl, required this.domain});

  Map<String, Object?> toJson() => {
    'script_url': scriptUrl.toString(),
    'domain': domain,
  };

  final Uri scriptUrl;
  final String domain;
}

final class PortfolioSource {
  const PortfolioSource({
    required this.id,
    required this.label,
    required this.url,
    required this.scope,
  });

  Map<String, Object?> toJson() => {
    'id': id,
    'label': label,
    'url': url.toString(),
    'scope': scope,
  };

  final String id;
  final String label;
  final Uri url;
  final String scope;
}
