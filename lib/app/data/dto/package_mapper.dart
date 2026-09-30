import 'package:flutter_web_portfolio/app/data/dto/json_fields.dart';
import 'package:flutter_web_portfolio/app/domain/models/package.dart';

PortfolioPackage parsePortfolioPackage(Map<String, dynamic> json) {
  if (json.containsKey('maturity')) {
    throw const FormatException(
      'Package field "maturity" was replaced by "maturity_level" in schema 11.',
    );
  }
  return PortfolioPackage((
    id: requiredString(json, 'id'),
    name: requiredString(json, 'name'),
    description: requiredString(json, 'description'),
    url: requiredUri(json, 'url'),
    version: requiredString(json, 'version'),
    likes: requiredInt(json, 'likes'),
    pubPoints: requiredInt(json, 'pub_points'),
    downloads: requiredInt(json, 'downloads'),
    category: PortfolioPackageCategory.parse(requiredString(json, 'category')),
    featured: switch (json['featured']) {
      null => false,
      _ => requiredBool(json, 'featured'),
    },
    topics: switch (json['topics']) {
      null => const [],
      _ => requiredStrings(json, 'topics'),
    },
    roadmap: switch (json['roadmap']) {
      null => const [],
      _ => requiredObjects(
        json,
        'roadmap',
      ).map(_parsePackageRoadmapItem).toList(growable: false),
    },
    repository: optionalUri(json, 'repository'),
    maturityLevel: switch (json['maturity_level']) {
      null => null,
      _ => requiredInt(json, 'maturity_level'),
    },
    proof: switch (json['proof']) {
      null => null,
      _ => requiredString(json, 'proof'),
    },
  ));
}

PackageRoadmapItem _parsePackageRoadmapItem(Map<String, dynamic> json) =>
    PackageRoadmapItem(
      title: requiredString(json, 'title'),
      status: requiredString(json, 'status'),
    );
