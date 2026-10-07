import 'package:flutter_web_portfolio/app/data/dto/json_fields.dart';
import 'package:flutter_web_portfolio/app/data/dto/link_mapper.dart';
import 'package:flutter_web_portfolio/app/domain/models/site.dart';

PortfolioSite parsePortfolioSite(Map<String, dynamic> json) {
  final socialImage = requiredString(json, 'social_image');
  if (!socialImage.startsWith('/') || socialImage.startsWith('//')) {
    throw const FormatException(
      'The social image must be a root-relative asset path.',
    );
  }
  return PortfolioSite((
    url: requiredUri(json, 'url'),
    title: requiredString(json, 'title'),
    description: requiredString(json, 'description'),
    socialDescription: requiredString(json, 'social_description'),
    socialImage: socialImage,
    domainLabel: requiredString(json, 'domain_label'),
    locales: switch (json['locales']) {
      null => const ['en'],
      _ => requiredStrings(json, 'locales'),
    },
    engineeringLinks: requiredObjects(
      json,
      'engineering_links',
    ).map(parsePortfolioLink).toList(),
    analytics: switch (optionalObject(json, 'analytics')) {
      final value? => _parsePortfolioAnalytics(value),
      null => null,
    },
  ));
}

PortfolioAnalytics _parsePortfolioAnalytics(Map<String, dynamic> json) =>
    PortfolioAnalytics(
      scriptUrl: requiredUri(json, 'script_url'),
      domain: requiredString(json, 'domain'),
    );

PortfolioSource parsePortfolioSource(Map<String, dynamic> json) =>
    PortfolioSource(
      id: requiredString(json, 'id'),
      label: requiredString(json, 'label'),
      url: requiredUri(json, 'url'),
      scope: requiredString(json, 'scope'),
    );
