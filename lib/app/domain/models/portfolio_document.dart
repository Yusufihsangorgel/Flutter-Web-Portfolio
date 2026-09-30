import 'package:flutter_web_portfolio/app/domain/models/capability.dart';
import 'package:flutter_web_portfolio/app/domain/models/contribution.dart';
import 'package:flutter_web_portfolio/app/domain/models/experience.dart';
import 'package:flutter_web_portfolio/app/domain/models/model_validation.dart';
import 'package:flutter_web_portfolio/app/domain/models/package.dart';
import 'package:flutter_web_portfolio/app/domain/models/profile.dart';
import 'package:flutter_web_portfolio/app/domain/models/site.dart';
import 'package:flutter_web_portfolio/app/domain/models/system.dart';
import 'package:flutter_web_portfolio/app/domain/models/writing.dart';

export 'package:flutter_web_portfolio/app/domain/models/artifact.dart';
export 'package:flutter_web_portfolio/app/domain/models/capability.dart';
export 'package:flutter_web_portfolio/app/domain/models/contribution.dart';
export 'package:flutter_web_portfolio/app/domain/models/experience.dart';
export 'package:flutter_web_portfolio/app/domain/models/package.dart';
export 'package:flutter_web_portfolio/app/domain/models/profile.dart';
export 'package:flutter_web_portfolio/app/domain/models/shared_value_types.dart';
export 'package:flutter_web_portfolio/app/domain/models/site.dart';
export 'package:flutter_web_portfolio/app/domain/models/system.dart';
export 'package:flutter_web_portfolio/app/domain/models/writing.dart';

typedef PortfolioDocumentContent = ({
  int schemaVersion,
  String contentVersion,
  DateTime verifiedAt,
  PortfolioSite site,
  List<PortfolioSource> sources,
  PortfolioProfile profile,
  List<PortfolioExperience> experience,
  List<PortfolioCapability> capabilities,
  List<PortfolioContribution> contributions,
  List<PortfolioSystem> systems,
  List<PortfolioPackage> packages,
  List<PortfolioWritingSource> writingSources,
  List<PortfolioWritingEntry> writing,
});

typedef PortfolioDocumentTranslation = ({
  PortfolioSite site,
  PortfolioProfile profile,
  List<PortfolioExperience> experience,
  List<PortfolioCapability> capabilities,
  List<PortfolioContribution> contributions,
  List<PortfolioSystem> systems,
});

abstract interface class PortfolioLocalizationStrategy {
  PortfolioDocument localize(
    PortfolioDocument document,
    Map<String, dynamic>? localization,
  );
}

/// Strict, framework-independent representation of the public portfolio.
///
/// The UI consumes this model; names, roles, project copy, URLs, and
/// contribution status never live in widgets or painters. Construction
/// validates every document-level invariant, whether the content came from
/// the parser or was assembled in code.
final class PortfolioDocument {
  PortfolioDocument(PortfolioDocumentContent content, this._localizer)
    : schemaVersion = content.schemaVersion,
      contentVersion = content.contentVersion,
      verifiedAt = content.verifiedAt,
      site = content.site,
      sources = List.unmodifiable(content.sources),
      profile = content.profile,
      experience = List.unmodifiable(content.experience),
      capabilities = List.unmodifiable(content.capabilities),
      contributions = List.unmodifiable(content.contributions),
      systems = List.unmodifiable(content.systems),
      packages = List.unmodifiable(content.packages),
      writingSources = List.unmodifiable(content.writingSources),
      writing = List.unmodifiable(content.writing) {
    _validate();
  }

  PortfolioDocument copyWith(PortfolioDocumentTranslation changes) =>
      PortfolioDocument((
        schemaVersion: schemaVersion,
        contentVersion: contentVersion,
        verifiedAt: verifiedAt,
        site: changes.site,
        sources: sources,
        profile: changes.profile,
        experience: changes.experience,
        capabilities: changes.capabilities,
        contributions: changes.contributions,
        systems: changes.systems,
        packages: packages,
        writingSources: writingSources,
        writing: writing,
      ), _localizer);

  Map<String, Object?> toJson() => {
    'schema_version': schemaVersion,
    'content_version': contentVersion,
    'verified_at': verifiedAt.toIso8601String(),
    'site': site.toJson(),
    'sources': [for (final value in sources) value.toJson()],
    'profile': profile.toJson(),
    'experience': [for (final value in experience) value.toJson()],
    'capabilities': [for (final value in capabilities) value.toJson()],
    'contributions': [for (final value in contributions) value.toJson()],
    'systems': [for (final value in systems) value.toJson()],
    'packages': [for (final value in packages) value.toJson()],
    'writing_sources': [for (final value in writingSources) value.toJson()],
    'writing': [for (final value in writing) value.toJson()],
  };

  final PortfolioLocalizationStrategy _localizer;

  final int schemaVersion;
  final String contentVersion;
  final DateTime verifiedAt;
  final PortfolioSite site;
  final List<PortfolioSource> sources;
  final PortfolioProfile profile;
  final List<PortfolioExperience> experience;
  final List<PortfolioCapability> capabilities;
  final List<PortfolioContribution> contributions;
  final List<PortfolioSystem> systems;
  final List<PortfolioPackage> packages;

  /// Factual source metadata shared across locales.
  final List<PortfolioWritingSource> writingSources;

  /// Factual writing entries shared across locales.
  final List<PortfolioWritingEntry> writing;

  List<String> get activeSections => <String>[
    'home',
    if (experience.isNotEmpty) 'experience',
    if (contributions.isNotEmpty) 'proof',
    if (systems.isNotEmpty) 'projects',
    if (packages.isNotEmpty) 'packages',
    if (writing.isNotEmpty) 'writing',
    'about',
  ];

  Iterable<PortfolioContribution> get mergedContributions =>
      contributions.where((entry) => entry.status == ContributionStatus.merged);

  Iterable<PortfolioExperience> get currentExperience =>
      experience.where((entry) => entry.current);

  Iterable<PortfolioContribution> get contributionsUnderReview => contributions
      .where((entry) => entry.status == ContributionStatus.underReview);

  PortfolioContribution? get featuredContribution {
    for (final contribution in contributions) {
      if (contribution.featured) return contribution;
    }
    return null;
  }

  Iterable<PortfolioFeaturedSystem> get featuredSystems =>
      systems.whereType<PortfolioFeaturedSystem>();

  Iterable<PortfolioSupportingSystem> get supportingSystems =>
      systems.whereType<PortfolioSupportingSystem>();

  Set<String> get supportedLocales => site.locales.toSet();

  /// Returns the document in the locale described by [localization].
  ///
  /// A locale overlay is all-or-nothing: a missing field throws instead of
  /// producing a page that mixes languages.
  PortfolioDocument localized(Map<String, dynamic>? localization) =>
      _localizer.localize(this, localization);

  void _validate() {
    _validateStructure();
    _validateContributions();
    _validateWriting();
    _validateUnique();
  }

  void _validateStructure() {
    if (schemaVersion != 10) {
      throw FormatException(
        'Unsupported portfolio schema version: $schemaVersion',
      );
    }
    if (sources.isEmpty || capabilities.isEmpty) {
      throw const FormatException(
        'Sources and capabilities must not be empty.',
      );
    }
    if (profile.focus.length < 3) {
      throw const FormatException(
        'The profile must declare at least three focus areas.',
      );
    }
    if (!site.title.contains(profile.name) ||
        !site.title.contains(profile.role)) {
      throw const FormatException(
        'Site metadata must use the canonical profile name and role.',
      );
    }
    if (systems.isNotEmpty && featuredSystems.isEmpty) {
      throw const FormatException(
        'At least one work item must be selected as featured.',
      );
    }
    if (site.engineeringLinks.isEmpty) {
      throw const FormatException(
        'The site must declare at least one engineering link.',
      );
    }
    if (!site.locales.contains('en') ||
        site.locales.toSet().length != site.locales.length ||
        site.locales.any((locale) => !RegExp(r'^[a-z]{2}$').hasMatch(locale))) {
      throw const FormatException(
        'Site locales must be unique two-letter codes and include English.',
      );
    }
  }

  void _validateContributions() {
    if (contributions.where((entry) => entry.featured).length > 1) {
      throw const FormatException(
        'At most one open-source contribution may be featured.',
      );
    }
    if (contributions.any(
      (entry) => entry.eventOrderLab != null && !entry.featured,
    )) {
      throw const FormatException(
        'An event-order lab may only belong to the featured contribution.',
      );
    }
  }

  void _validateWriting() {
    if (writing.length > 12) {
      throw const FormatException('At most 12 writing entries may be listed.');
    }
    if (writing.any(
      (entry) => !writingSources.any((source) => source.id == entry.source),
    )) {
      throw const FormatException(
        'Every writing entry must reference a declared writing source.',
      );
    }
  }

  void _validateUnique() {
    assertUnique('source', sources.map((entry) => entry.id));
    assertUnique(
      'engineering link',
      site.engineeringLinks.map((entry) => entry.id),
    );
    assertUnique('profile link', profile.links.map((entry) => entry.id));
    assertUnique('experience', experience.map((entry) => entry.id));
    assertUnique('capability', capabilities.map((entry) => entry.id));
    assertUnique('contribution', contributions.map((entry) => entry.id));
    assertUnique('system', systems.map((entry) => entry.id));
    assertUnique('package', packages.map((entry) => entry.id));
    assertUnique('writing source', writingSources.map((entry) => entry.id));
    assertUnique(
      'work artifact asset',
      systems.expand(
        (entry) => [
          entry.artifact.asset,
          if (entry.artifact.compact case final compact?) compact.asset,
        ],
      ),
    );
  }
}
