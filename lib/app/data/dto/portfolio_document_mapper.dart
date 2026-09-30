import 'package:flutter_web_portfolio/app/data/dto/capability_mapper.dart';
import 'package:flutter_web_portfolio/app/data/dto/contribution_mapper.dart';
import 'package:flutter_web_portfolio/app/data/dto/experience_mapper.dart';
import 'package:flutter_web_portfolio/app/data/dto/json_fields.dart';
import 'package:flutter_web_portfolio/app/data/dto/package_mapper.dart';
import 'package:flutter_web_portfolio/app/data/dto/portfolio_localizer.dart';
import 'package:flutter_web_portfolio/app/data/dto/profile_mapper.dart';
import 'package:flutter_web_portfolio/app/data/dto/site_mapper.dart';
import 'package:flutter_web_portfolio/app/data/dto/system_mapper.dart';
import 'package:flutter_web_portfolio/app/data/dto/writing_mapper.dart';
import 'package:flutter_web_portfolio/app/domain/models/portfolio_document.dart';

/// Parses and validates the canonical portfolio document.
PortfolioDocument parsePortfolioDocument(Map<String, dynamic> json) {
  final schemaVersion = requiredInt(json, 'schema_version');
  if (schemaVersion != 10) {
    throw FormatException(
      'Unsupported portfolio schema version: $schemaVersion',
    );
  }

  return PortfolioDocument((
    schemaVersion: schemaVersion,
    contentVersion: requiredString(json, 'content_version'),
    verifiedAt: DateTime.parse(requiredString(json, 'verified_at')),
    site: parsePortfolioSite(requiredObject(json, 'site')),
    sources: requiredObjects(
      json,
      'sources',
    ).map(parsePortfolioSource).toList(),
    profile: parsePortfolioProfile(requiredObject(json, 'profile')),
    experience: requiredObjects(
      json,
      'experience',
    ).map(parsePortfolioExperience).toList(),
    capabilities: requiredObjects(
      json,
      'capabilities',
    ).map(parsePortfolioCapability).toList(),
    contributions: requiredObjects(
      json,
      'contributions',
    ).map(parsePortfolioContribution).toList(),
    systems: requiredObjects(
      json,
      'systems',
    ).map(parsePortfolioSystem).toList(),
    packages: requiredObjects(
      json,
      'packages',
    ).map(parsePortfolioPackage).toList(),
    writingSources: switch (json['writing_sources']) {
      null => const [],
      _ => requiredObjects(
        json,
        'writing_sources',
      ).map(parsePortfolioWritingSource).toList(growable: false),
    },
    writing: switch (json['writing']) {
      null => const [],
      _ => requiredObjects(
        json,
        'writing',
      ).map(parsePortfolioWritingEntry).toList(growable: false),
    },
  ), const PortfolioLocalizer());
}
