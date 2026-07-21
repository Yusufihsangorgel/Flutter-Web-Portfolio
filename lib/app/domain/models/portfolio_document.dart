/// Strict, framework-independent representation of the public portfolio.
///
/// The UI consumes this model; names, roles, project copy, URLs, and
/// contribution status never live in widgets or painters.
final class PortfolioDocument {
  PortfolioDocument._({
    required this.schemaVersion,
    required this.contentVersion,
    required this.verifiedAt,
    required this.site,
    required List<PortfolioSource> sources,
    required this.profile,
    required List<PortfolioExperience> experience,
    required List<PortfolioCapability> capabilities,
    required List<PortfolioContribution> contributions,
    required List<PortfolioSystem> systems,
    required List<PortfolioPackage> packages,
  }) : sources = List.unmodifiable(sources),
       experience = List.unmodifiable(experience),
       capabilities = List.unmodifiable(capabilities),
       contributions = List.unmodifiable(contributions),
       systems = List.unmodifiable(systems),
       packages = List.unmodifiable(packages);

  factory PortfolioDocument.fromJson(Map<String, dynamic> json) {
    final schemaVersion = _requiredInt(json, 'schema_version');
    if (schemaVersion != 9) {
      throw FormatException(
        'Unsupported portfolio schema version: $schemaVersion',
      );
    }

    return PortfolioDocument._(
      schemaVersion: schemaVersion,
      contentVersion: _requiredString(json, 'content_version'),
      verifiedAt: DateTime.parse(_requiredString(json, 'verified_at')),
      site: PortfolioSite.fromJson(_requiredObject(json, 'site')),
      sources: _objects(json, 'sources').map(PortfolioSource.fromJson).toList(),
      profile: PortfolioProfile.fromJson(_requiredObject(json, 'profile')),
      experience: _objects(
        json,
        'experience',
      ).map(PortfolioExperience.fromJson).toList(),
      capabilities: _objects(
        json,
        'capabilities',
      ).map(PortfolioCapability.fromJson).toList(),
      contributions: _objects(
        json,
        'contributions',
      ).map(PortfolioContribution.fromJson).toList(),
      systems: _objects(json, 'systems').map(PortfolioSystem.fromJson).toList(),
      packages: _objects(
        json,
        'packages',
      ).map(PortfolioPackage.fromJson).toList(),
    ).._validate();
  }

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

  List<String> get activeSections => <String>[
    'home',
    if (experience.isNotEmpty) 'experience',
    if (contributions.isNotEmpty) 'proof',
    if (systems.isNotEmpty) 'projects',
    if (packages.isNotEmpty) 'packages',
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

  /// Returns a locale-specific view of the canonical portfolio document.
  ///
  /// URLs, identifiers, dates, product names, and other factual fields remain
  /// owned by `portfolio.json`. Locale documents may replace only authored
  /// human-facing copy. A locale document is deliberately all-or-nothing: a
  /// missing field throws instead of silently producing a mixed-language page.
  PortfolioDocument localized(Map<String, dynamic>? localization) {
    if (localization == null || localization.isEmpty) return this;
    final copy = _PortfolioLocalization(localization);
    final localizedDocument = PortfolioDocument._(
      schemaVersion: schemaVersion,
      contentVersion: contentVersion,
      verifiedAt: verifiedAt,
      site: _localizedSite(site, copy.object('site')),
      sources: sources,
      profile: _localizedProfile(profile, copy.object('profile')),
      experience: [
        for (final entry in experience)
          _localizedExperience(entry, copy.entry('experience', entry.id)),
      ],
      capabilities: [
        for (final entry in capabilities)
          _localizedCapability(entry, copy.entry('capabilities', entry.id)),
      ],
      contributions: [
        for (final entry in contributions)
          _localizedContribution(entry, copy.entry('contributions', entry.id)),
      ],
      systems: [
        for (final entry in systems)
          _localizedSystem(entry, copy.entry('systems', entry.id)),
      ],
      packages: packages,
    ).._validate();
    return localizedDocument;
  }

  void _validate() {
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
    _assertUnique('source', sources.map((entry) => entry.id));
    _assertUnique(
      'engineering link',
      site.engineeringLinks.map((entry) => entry.id),
    );
    _assertUnique('profile link', profile.links.map((entry) => entry.id));
    _assertUnique('experience', experience.map((entry) => entry.id));
    _assertUnique('capability', capabilities.map((entry) => entry.id));
    _assertUnique('contribution', contributions.map((entry) => entry.id));
    _assertUnique('system', systems.map((entry) => entry.id));
    _assertUnique('package', packages.map((entry) => entry.id));
    _assertUnique(
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

final class PortfolioSite {
  PortfolioSite({
    required this.url,
    required this.title,
    required this.description,
    required this.socialDescription,
    required this.socialImage,
    required this.domainLabel,
    required List<String> locales,
    required List<PortfolioLink> engineeringLinks,
    this.analytics,
  }) : locales = List.unmodifiable(locales),
       engineeringLinks = List.unmodifiable(engineeringLinks);

  factory PortfolioSite.fromJson(Map<String, dynamic> json) {
    final socialImage = _requiredString(json, 'social_image');
    if (!socialImage.startsWith('/') || socialImage.startsWith('//')) {
      throw const FormatException(
        'The social image must be a root-relative asset path.',
      );
    }
    return PortfolioSite(
      url: _requiredUri(json, 'url'),
      title: _requiredString(json, 'title'),
      description: _requiredString(json, 'description'),
      socialDescription: _requiredString(json, 'social_description'),
      socialImage: socialImage,
      domainLabel: _requiredString(json, 'domain_label'),
      locales: switch (json['locales']) {
        null => const ['en'],
        _ => _strings(json, 'locales'),
      },
      engineeringLinks: _objects(
        json,
        'engineering_links',
      ).map(PortfolioLink.fromJson).toList(),
      analytics: switch (_optionalObject(json, 'analytics')) {
        final value? => PortfolioAnalytics.fromJson(value),
        null => null,
      },
    );
  }

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

  factory PortfolioAnalytics.fromJson(Map<String, dynamic> json) =>
      PortfolioAnalytics(
        scriptUrl: _requiredUri(json, 'script_url'),
        domain: _requiredString(json, 'domain'),
      );

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

  factory PortfolioSource.fromJson(Map<String, dynamic> json) =>
      PortfolioSource(
        id: _requiredString(json, 'id'),
        label: _requiredString(json, 'label'),
        url: _requiredUri(json, 'url'),
        scope: _requiredString(json, 'scope'),
      );

  final String id;
  final String label;
  final Uri url;
  final String scope;
}

final class PortfolioProfile {
  PortfolioProfile({
    required this.name,
    required this.displayName,
    required this.role,
    required this.location,
    required this.email,
    required this.since,
    required this.headline,
    required this.summary,
    required this.background,
    required List<String> focus,
    required List<PortfolioLink> links,
  }) : focus = List.unmodifiable(focus),
       links = List.unmodifiable(links);

  factory PortfolioProfile.fromJson(Map<String, dynamic> json) =>
      PortfolioProfile(
        name: _requiredString(json, 'name'),
        displayName: PortfolioDisplayName.fromJson(
          _requiredObject(json, 'display_name'),
        ),
        role: _requiredString(json, 'role'),
        location: _requiredString(json, 'location'),
        email: _requiredEmail(json, 'email'),
        since: _requiredString(json, 'since'),
        headline: _requiredString(json, 'headline'),
        summary: _requiredString(json, 'summary'),
        background: _requiredString(json, 'background'),
        focus: _strings(json, 'focus'),
        links: _objects(json, 'links').map(PortfolioLink.fromJson).toList(),
      );

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

/// Explicit identity presentation supplied by the content document.
///
/// These values deliberately avoid guessing given names, surnames, or word
/// order from [PortfolioProfile.name].
final class PortfolioDisplayName {
  const PortfolioDisplayName({
    required this.primary,
    required this.accent,
    required this.navigation,
    required this.accessible,
  });

  factory PortfolioDisplayName.fromJson(Map<String, dynamic> json) =>
      PortfolioDisplayName(
        primary: _requiredString(json, 'primary'),
        accent: _requiredString(json, 'accent'),
        navigation: _requiredString(json, 'navigation'),
        accessible: _requiredString(json, 'accessible'),
      );

  final String primary;
  final String accent;
  final String navigation;
  final String accessible;
}

final class PortfolioLink {
  const PortfolioLink({
    required this.id,
    required this.label,
    required this.url,
  });

  factory PortfolioLink.fromJson(Map<String, dynamic> json) => PortfolioLink(
    id: _requiredString(json, 'id'),
    label: _requiredString(json, 'label'),
    url: _requiredUri(json, 'url'),
  );

  final String id;
  final String label;
  final Uri url;
}

final class PortfolioExperience {
  PortfolioExperience({
    required this.id,
    required this.company,
    required this.role,
    required this.domain,
    required this.period,
    required this.current,
    required this.summary,
    required List<String> evidence,
  }) : evidence = List.unmodifiable(evidence);

  factory PortfolioExperience.fromJson(Map<String, dynamic> json) =>
      PortfolioExperience(
        id: _requiredString(json, 'id'),
        company: _requiredString(json, 'company'),
        role: _requiredString(json, 'role'),
        domain: _requiredString(json, 'domain'),
        period: _requiredString(json, 'period'),
        current: _requiredBool(json, 'current'),
        summary: _requiredString(json, 'summary'),
        evidence: _strings(json, 'evidence'),
      );

  final String id;
  final String company;
  final String role;
  final String domain;
  final String period;
  final bool current;
  final String summary;
  final List<String> evidence;
}

final class PortfolioCapability {
  PortfolioCapability({
    required this.id,
    required this.label,
    required List<String> items,
  }) : items = List.unmodifiable(items);

  factory PortfolioCapability.fromJson(Map<String, dynamic> json) =>
      PortfolioCapability(
        id: _requiredString(json, 'id'),
        label: _requiredString(json, 'label'),
        items: _strings(json, 'items'),
      );

  final String id;
  final String label;
  final List<String> items;
}

enum ContributionStatus {
  merged('merged'),
  underReview('under_review');

  const ContributionStatus(this.wireValue);
  final String wireValue;

  static ContributionStatus parse(String value) => values.firstWhere(
    (entry) => entry.wireValue == value,
    orElse: () =>
        throw FormatException('Unsupported contribution status: $value'),
  );
}

final class PortfolioContribution {
  const PortfolioContribution({
    required this.id,
    required this.project,
    required this.status,
    required this.date,
    required this.title,
    required this.problem,
    required this.change,
    required this.url,
    required this.featured,
    this.issueUrl,
    this.eventOrderLab,
  });

  factory PortfolioContribution.fromJson(Map<String, dynamic> json) =>
      PortfolioContribution(
        id: _requiredString(json, 'id'),
        project: _requiredString(json, 'project'),
        status: ContributionStatus.parse(_requiredString(json, 'status')),
        date: DateTime.parse(_requiredString(json, 'date')),
        title: _requiredString(json, 'title'),
        problem: _requiredString(json, 'problem'),
        change: _requiredString(json, 'change'),
        url: _requiredUri(json, 'url'),
        featured: _requiredBool(json, 'featured'),
        issueUrl: _optionalUri(json, 'issue_url'),
        eventOrderLab: switch (_optionalObject(json, 'event_order_lab')) {
          final value? => PortfolioEventOrderLab.fromJson(value),
          null => null,
        },
      );

  final String id;
  final String project;
  final ContributionStatus status;
  final DateTime date;
  final String title;
  final String problem;
  final String change;
  final Uri url;
  final bool featured;
  final Uri? issueUrl;
  final PortfolioEventOrderLab? eventOrderLab;
}

/// A content-authored comparison of two event sequences.
///
/// This is deliberately contribution-agnostic: the renderer only understands
/// ordered events, a baseline risk window, and a proposed ordering.
final class PortfolioEventOrderLab {
  PortfolioEventOrderLab({
    required this.title,
    required List<PortfolioEventOrderItem> events,
    required this.baseline,
    required this.withPatch,
  }) : events = List.unmodifiable(events);

  factory PortfolioEventOrderLab.fromJson(Map<String, dynamic> json) {
    final lab = PortfolioEventOrderLab(
      title: _requiredString(json, 'title'),
      events: _objects(
        json,
        'events',
      ).map(PortfolioEventOrderItem.fromJson).toList(),
      baseline: PortfolioEventSequence.fromJson(
        _requiredObject(json, 'baseline'),
      ),
      withPatch: PortfolioEventSequence.fromJson(
        _requiredObject(json, 'with_patch'),
      ),
    ).._validate();
    return lab;
  }

  final String title;
  final List<PortfolioEventOrderItem> events;
  final PortfolioEventSequence baseline;
  final PortfolioEventSequence withPatch;

  PortfolioEventOrderItem eventById(String id) =>
      events.firstWhere((event) => event.id == id);

  void _validate() {
    if (events.length < 3) {
      throw const FormatException(
        'An event-order lab requires at least three events.',
      );
    }
    _assertUnique('event-order lab event', events.map((event) => event.id));
    final eventIds = events.map((event) => event.id).toSet();
    for (final sequence in [baseline, withPatch]) {
      if (sequence.order.length < 2 ||
          sequence.order.toSet().length != sequence.order.length ||
          sequence.order.any((id) => !eventIds.contains(id))) {
        throw const FormatException(
          'Event-order sequences require unique, declared event ids.',
        );
      }
    }
    final usedIds = {...baseline.order, ...withPatch.order};
    if (!usedIds.containsAll(eventIds) || usedIds.length != eventIds.length) {
      throw const FormatException(
        'Every declared event must be used by an event-order sequence.',
      );
    }
    if (_sameStrings(baseline.order, withPatch.order)) {
      throw const FormatException(
        'Baseline and patched event orders must differ.',
      );
    }

    final gap = baseline.gap;
    if (gap == null || withPatch.gap != null) {
      throw const FormatException(
        'Only the baseline sequence must declare one risk gap.',
      );
    }
    final baselineAfter = baseline.order.indexOf(gap.after);
    final baselineBefore = baseline.order.indexOf(gap.before);
    final patchedAfter = withPatch.order.indexOf(gap.after);
    final patchedBefore = withPatch.order.indexOf(gap.before);
    if (baselineAfter < 0 ||
        baselineBefore != baselineAfter + 1 ||
        patchedBefore < 0 ||
        patchedAfter < 0 ||
        patchedBefore >= patchedAfter) {
      throw const FormatException(
        'The patched order must close the baseline risk gap.',
      );
    }
  }
}

final class PortfolioEventOrderItem {
  const PortfolioEventOrderItem({required this.id, required this.label});

  factory PortfolioEventOrderItem.fromJson(Map<String, dynamic> json) =>
      PortfolioEventOrderItem(
        id: _requiredString(json, 'id'),
        label: _requiredString(json, 'label'),
      );

  final String id;
  final String label;
}

final class PortfolioEventSequence {
  PortfolioEventSequence({
    required this.summary,
    required List<String> order,
    this.gap,
  }) : order = List.unmodifiable(order);

  factory PortfolioEventSequence.fromJson(Map<String, dynamic> json) =>
      PortfolioEventSequence(
        summary: _requiredString(json, 'summary'),
        order: _strings(json, 'order'),
        gap: switch (_optionalObject(json, 'gap')) {
          final value? => PortfolioEventGap.fromJson(value),
          null => null,
        },
      );

  final String summary;
  final List<String> order;
  final PortfolioEventGap? gap;
}

final class PortfolioEventGap {
  const PortfolioEventGap({
    required this.after,
    required this.before,
    required this.label,
  });

  factory PortfolioEventGap.fromJson(Map<String, dynamic> json) =>
      PortfolioEventGap(
        after: _requiredString(json, 'after'),
        before: _requiredString(json, 'before'),
        label: _requiredString(json, 'label'),
      );

  final String after;
  final String before;
  final String label;
}

sealed class PortfolioSystem {
  PortfolioSystem({
    required this.id,
    required this.name,
    required this.kind,
    required this.year,
    required this.summary,
    required this.ownership,
    required this.decision,
    required this.presentation,
    required this.artifact,
    required List<PortfolioEvidence> evidence,
    required this.url,
    required List<String> technologies,
  }) : evidence = List.unmodifiable(evidence),
       technologies = List.unmodifiable(technologies);

  factory PortfolioSystem.fromJson(Map<String, dynamic> json) {
    final featured = _requiredBool(json, 'featured');
    final id = _requiredString(json, 'id');
    final name = _requiredString(json, 'name');
    final kind = _requiredString(json, 'kind');
    final year = _requiredString(json, 'year');
    final summary = _requiredString(json, 'summary');
    final ownership = _requiredString(json, 'ownership');
    final decision = _requiredString(json, 'decision');
    final presentation = PortfolioSystemPresentation.fromJson(
      _requiredObject(json, 'presentation'),
    );
    final artifact = PortfolioSystemArtifact.fromJson(
      _requiredObject(json, 'artifact'),
    );
    final evidence = _objects(
      json,
      'evidence',
    ).map(PortfolioEvidence.fromJson).toList();
    final url = _requiredUri(json, 'url');
    final technologies = _strings(json, 'technologies');
    if (evidence.isEmpty) {
      throw FormatException('System "$id" must declare evidence.');
    }

    if (featured) {
      return PortfolioFeaturedSystem(
        id: id,
        name: name,
        kind: kind,
        year: year,
        summary: summary,
        ownership: ownership,
        decision: decision,
        presentation: presentation,
        artifact: artifact,
        challenge: _requiredString(json, 'challenge'),
        approach: _requiredString(json, 'approach'),
        outcome: _requiredString(json, 'outcome'),
        evidence: evidence,
        url: url,
        technologies: technologies,
      );
    }

    return PortfolioSupportingSystem(
      id: id,
      name: name,
      kind: kind,
      year: year,
      summary: summary,
      ownership: ownership,
      decision: decision,
      presentation: presentation,
      artifact: artifact,
      evidence: evidence,
      group: PortfolioSystemGroup.parse(_requiredString(json, 'group')),
      spotlight: _requiredString(json, 'spotlight'),
      url: url,
      technologies: technologies,
    );
  }

  final String id;
  final String name;
  final String kind;
  final String year;
  final String summary;
  final String ownership;
  final String decision;
  final PortfolioSystemPresentation presentation;
  final PortfolioSystemArtifact artifact;
  final List<PortfolioEvidence> evidence;
  final Uri url;
  final List<String> technologies;
}

final class PortfolioFeaturedSystem extends PortfolioSystem {
  PortfolioFeaturedSystem({
    required super.id,
    required super.name,
    required super.kind,
    required super.year,
    required super.summary,
    required super.ownership,
    required super.decision,
    required super.presentation,
    required super.artifact,
    required this.challenge,
    required this.approach,
    required this.outcome,
    required super.evidence,
    required super.url,
    required super.technologies,
  });

  final String challenge;
  final String approach;
  final String outcome;
}

final class PortfolioSupportingSystem extends PortfolioSystem {
  PortfolioSupportingSystem({
    required super.id,
    required super.name,
    required super.kind,
    required super.year,
    required super.summary,
    required super.ownership,
    required super.decision,
    required super.presentation,
    required super.artifact,
    required super.evidence,
    required this.group,
    required this.spotlight,
    required super.url,
    required super.technologies,
  });

  final PortfolioSystemGroup group;
  final String spotlight;
}

enum PortfolioSystemGroup {
  shippedProduct('shipped_product'),
  openEngineering('open_engineering');

  const PortfolioSystemGroup(this.wireValue);
  final String wireValue;

  static PortfolioSystemGroup parse(String value) => values.firstWhere(
    (entry) => entry.wireValue == value,
    orElse: () => throw FormatException('Unsupported work group: $value'),
  );
}

/// Content-authored palette for a project chapter.
final class PortfolioSystemPresentation {
  PortfolioSystemPresentation({
    required this.background,
    required this.foreground,
    required this.accent,
  });

  factory PortfolioSystemPresentation.fromJson(Map<String, dynamic> json) =>
      PortfolioSystemPresentation(
        background: _requiredHexColor(json, 'background'),
        foreground: _requiredHexColor(json, 'foreground'),
        accent: _requiredHexColor(json, 'accent'),
      );

  final String background;
  final String foreground;
  final String accent;
}

final class PortfolioEvidence {
  const PortfolioEvidence({
    required this.label,
    required this.url,
    required this.kind,
  });

  factory PortfolioEvidence.fromJson(Map<String, dynamic> json) =>
      PortfolioEvidence(
        label: _requiredString(json, 'label'),
        url: _requiredUri(json, 'url'),
        kind: _requiredString(json, 'kind'),
      );

  final String label;
  final Uri url;
  final String kind;
}

/// A real, content-authored artifact for a selected work record.
///
/// Asset choice, alternative text, caption, intrinsic dimensions, fit, and
/// alignment all live in the external content document. The rendering layer
/// never branches on project ids, names, or technologies.
final class PortfolioSystemArtifact {
  const PortfolioSystemArtifact({
    required this.label,
    required this.asset,
    required this.alt,
    required this.caption,
    required this.width,
    required this.height,
    required this.fit,
    required this.alignment,
    required this.composition,
    this.compact,
  });

  factory PortfolioSystemArtifact.fromJson(Map<String, dynamic> json) {
    final asset = _requiredString(json, 'asset');
    final alt = _requiredString(json, 'alt');
    final caption = _requiredString(json, 'caption');
    final width = _requiredInt(json, 'width');
    final height = _requiredInt(json, 'height');
    _validateArtifactMedia(
      asset: asset,
      alt: alt,
      caption: caption,
      width: width,
      height: height,
    );
    final artifact = PortfolioSystemArtifact(
      label: _requiredString(json, 'label'),
      asset: asset,
      alt: alt,
      caption: caption,
      width: width,
      height: height,
      fit: PortfolioArtifactFit.parse(_requiredString(json, 'fit')),
      alignment: PortfolioArtifactAlignment.parse(
        _requiredString(json, 'alignment'),
      ),
      composition: PortfolioArtifactComposition.parse(
        _requiredString(json, 'composition'),
      ),
      compact: switch (_optionalObject(json, 'compact')) {
        final value? => PortfolioArtifactVariant.fromJson(value),
        null => null,
      },
    );
    if ((artifact.composition == PortfolioArtifactComposition.portraitSplit &&
            artifact.width >= artifact.height) ||
        (artifact.composition == PortfolioArtifactComposition.evidenceStack &&
            artifact.width < artifact.height)) {
      throw const FormatException(
        'Project artifact composition must match its intrinsic orientation.',
      );
    }
    return artifact;
  }

  final String label;
  final String asset;
  final String alt;
  final String caption;
  final int width;
  final int height;
  final PortfolioArtifactFit fit;
  final PortfolioArtifactAlignment alignment;
  final PortfolioArtifactComposition composition;
  final PortfolioArtifactVariant? compact;
}

/// An optional portrait asset authored for compact project stages.
///
/// It carries its own accessible copy and intrinsic dimensions so the renderer
/// can switch media without project-specific branches or runtime cropping.
final class PortfolioArtifactVariant {
  const PortfolioArtifactVariant({
    required this.asset,
    required this.alt,
    required this.caption,
    required this.width,
    required this.height,
    required this.fit,
    required this.alignment,
  });

  factory PortfolioArtifactVariant.fromJson(Map<String, dynamic> json) {
    final asset = _requiredString(json, 'asset');
    final alt = _requiredString(json, 'alt');
    final caption = _requiredString(json, 'caption');
    final width = _requiredInt(json, 'width');
    final height = _requiredInt(json, 'height');
    _validateArtifactMedia(
      asset: asset,
      alt: alt,
      caption: caption,
      width: width,
      height: height,
    );
    if (width >= height) {
      throw const FormatException(
        'Compact project artifacts must use a portrait asset.',
      );
    }
    return PortfolioArtifactVariant(
      asset: asset,
      alt: alt,
      caption: caption,
      width: width,
      height: height,
      fit: PortfolioArtifactFit.parse(_requiredString(json, 'fit')),
      alignment: PortfolioArtifactAlignment.parse(
        _requiredString(json, 'alignment'),
      ),
    );
  }

  final String asset;
  final String alt;
  final String caption;
  final int width;
  final int height;
  final PortfolioArtifactFit fit;
  final PortfolioArtifactAlignment alignment;
}

enum PortfolioArtifactFit {
  contain('contain'),
  cover('cover');

  const PortfolioArtifactFit(this.wireValue);
  final String wireValue;

  static PortfolioArtifactFit parse(String value) => values.firstWhere(
    (entry) => entry.wireValue == value,
    orElse: () => throw FormatException('Unsupported artifact fit: $value'),
  );
}

enum PortfolioArtifactAlignment {
  start('start'),
  center('center'),
  end('end');

  const PortfolioArtifactAlignment(this.wireValue);
  final String wireValue;

  static PortfolioArtifactAlignment parse(String value) => values.firstWhere(
    (entry) => entry.wireValue == value,
    orElse: () =>
        throw FormatException('Unsupported artifact alignment: $value'),
  );
}

enum PortfolioArtifactComposition {
  portraitSplit('portrait_split'),
  evidenceStack('evidence_stack');

  const PortfolioArtifactComposition(this.wireValue);
  final String wireValue;

  static PortfolioArtifactComposition parse(String value) => values.firstWhere(
    (entry) => entry.wireValue == value,
    orElse: () =>
        throw FormatException('Unsupported artifact composition: $value'),
  );
}

/// A published pub.dev package, presented with its real, verified metrics.
///
/// Packages are deliberately not part of the translated localization path:
/// names, versions, and pub.dev metrics are factual records rather than
/// authored copy, so every locale renders the same values as English.
final class PortfolioPackage {
  PortfolioPackage({
    required this.id,
    required this.name,
    required this.description,
    required this.url,
    required this.version,
    required this.likes,
    required this.pubPoints,
    required this.downloads,
    required this.category,
    required List<String> topics,
    this.repository,
  }) : topics = List.unmodifiable(topics);

  factory PortfolioPackage.fromJson(Map<String, dynamic> json) =>
      PortfolioPackage(
        id: _requiredString(json, 'id'),
        name: _requiredString(json, 'name'),
        description: _requiredString(json, 'description'),
        url: _requiredUri(json, 'url'),
        version: _requiredString(json, 'version'),
        likes: _requiredInt(json, 'likes'),
        pubPoints: _requiredInt(json, 'pub_points'),
        downloads: _requiredInt(json, 'downloads'),
        category: _requiredString(json, 'category'),
        topics: switch (json['topics']) {
          null => const [],
          _ => _strings(json, 'topics'),
        },
        repository: _optionalUri(json, 'repository'),
      );

  final String id;
  final String name;
  final String description;
  final Uri url;
  final String version;
  final int likes;
  final int pubPoints;
  final int downloads;
  final String category;
  final List<String> topics;
  final Uri? repository;
}

final class _PortfolioLocalization {
  _PortfolioLocalization(Map<String, dynamic> json) : _json = json {
    if (_requiredInt(json, 'schema_version') != 1) {
      throw const FormatException(
        'Unsupported portfolio localization schema version.',
      );
    }
    final locale = _requiredString(json, 'locale');
    if (!RegExp(r'^[a-z]{2}$').hasMatch(locale) || locale == 'en') {
      throw FormatException('Invalid translated portfolio locale: $locale');
    }
  }

  final Map<String, dynamic> _json;

  Map<String, dynamic> object(String key) => _requiredObject(_json, key);

  Map<String, dynamic> entry(String section, String id) =>
      _requiredObject(_requiredObject(_json, section), id);
}

PortfolioSite _localizedSite(PortfolioSite source, Map<String, dynamic> json) =>
    PortfolioSite(
      url: source.url,
      title: _requiredString(json, 'title'),
      description: _requiredString(json, 'description'),
      socialDescription: _requiredString(json, 'social_description'),
      socialImage: source.socialImage,
      domainLabel: source.domainLabel,
      locales: source.locales,
      engineeringLinks: _localizedLinks(
        source.engineeringLinks,
        _requiredObject(json, 'engineering_links'),
      ),
      analytics: source.analytics,
    );

PortfolioProfile _localizedProfile(
  PortfolioProfile source,
  Map<String, dynamic> json,
) => PortfolioProfile(
  name: source.name,
  displayName: source.displayName,
  role: _requiredString(json, 'role'),
  location: _requiredString(json, 'location'),
  email: source.email,
  since: source.since,
  headline: _requiredString(json, 'headline'),
  summary: _requiredString(json, 'summary'),
  background: _requiredString(json, 'background'),
  focus: _strings(json, 'focus'),
  links: _localizedLinks(source.links, _requiredObject(json, 'links')),
);

List<PortfolioLink> _localizedLinks(
  List<PortfolioLink> source,
  Map<String, dynamic> labels,
) => [
  for (final link in source)
    PortfolioLink(
      id: link.id,
      label: _requiredString(labels, link.id),
      url: link.url,
    ),
];

PortfolioExperience _localizedExperience(
  PortfolioExperience source,
  Map<String, dynamic> json,
) => PortfolioExperience(
  id: source.id,
  company: source.company,
  role: _requiredString(json, 'role'),
  domain: _requiredString(json, 'domain'),
  period: _requiredString(json, 'period'),
  current: source.current,
  summary: _requiredString(json, 'summary'),
  evidence: _strings(json, 'evidence'),
);

PortfolioCapability _localizedCapability(
  PortfolioCapability source,
  Map<String, dynamic> json,
) => PortfolioCapability(
  id: source.id,
  label: _requiredString(json, 'label'),
  items: _strings(json, 'items'),
);

PortfolioContribution _localizedContribution(
  PortfolioContribution source,
  Map<String, dynamic> json,
) => PortfolioContribution(
  id: source.id,
  project: source.project,
  status: source.status,
  date: source.date,
  title: _requiredString(json, 'title'),
  problem: _requiredString(json, 'problem'),
  change: _requiredString(json, 'change'),
  url: source.url,
  featured: source.featured,
  issueUrl: source.issueUrl,
  eventOrderLab: switch (source.eventOrderLab) {
    final lab? => _localizedEventOrderLab(
      lab,
      _requiredObject(json, 'event_order_lab'),
    ),
    null => null,
  },
);

PortfolioEventOrderLab _localizedEventOrderLab(
  PortfolioEventOrderLab source,
  Map<String, dynamic> json,
) {
  final eventLabels = _requiredObject(json, 'events');
  return PortfolioEventOrderLab(
    title: _requiredString(json, 'title'),
    events: [
      for (final event in source.events)
        PortfolioEventOrderItem(
          id: event.id,
          label: _requiredString(eventLabels, event.id),
        ),
    ],
    baseline: PortfolioEventSequence(
      summary: _requiredString(json, 'baseline_summary'),
      order: source.baseline.order,
      gap: switch (source.baseline.gap) {
        final gap? => PortfolioEventGap(
          after: gap.after,
          before: gap.before,
          label: _requiredString(json, 'gap_label'),
        ),
        null => null,
      },
    ),
    withPatch: PortfolioEventSequence(
      summary: _requiredString(json, 'with_patch_summary'),
      order: source.withPatch.order,
      gap: null,
    ),
  );
}

PortfolioSystem _localizedSystem(
  PortfolioSystem source,
  Map<String, dynamic> json,
) {
  final evidenceLabels = _strings(json, 'evidence');
  if (evidenceLabels.length != source.evidence.length) {
    throw FormatException(
      'Localized evidence count does not match system "${source.id}".',
    );
  }
  final evidence = [
    for (var index = 0; index < source.evidence.length; index++)
      PortfolioEvidence(
        label: evidenceLabels[index],
        url: source.evidence[index].url,
        kind: source.evidence[index].kind,
      ),
  ];
  final artifact = _localizedArtifact(
    source.artifact,
    _requiredObject(json, 'artifact'),
  );
  final common = (
    kind: _requiredString(json, 'kind'),
    year: _requiredString(json, 'year'),
    technologies: _strings(json, 'technologies'),
    summary: _requiredString(json, 'summary'),
    ownership: _requiredString(json, 'ownership'),
    decision: _requiredString(json, 'decision'),
  );

  return switch (source) {
    final PortfolioFeaturedSystem featured => PortfolioFeaturedSystem(
      id: featured.id,
      name: featured.name,
      kind: common.kind,
      year: common.year,
      summary: common.summary,
      ownership: common.ownership,
      decision: common.decision,
      presentation: featured.presentation,
      artifact: artifact,
      challenge: _requiredString(json, 'challenge'),
      approach: _requiredString(json, 'approach'),
      outcome: _requiredString(json, 'outcome'),
      evidence: evidence,
      url: featured.url,
      technologies: common.technologies,
    ),
    final PortfolioSupportingSystem supporting => PortfolioSupportingSystem(
      id: supporting.id,
      name: supporting.name,
      kind: common.kind,
      year: common.year,
      summary: common.summary,
      ownership: common.ownership,
      decision: common.decision,
      presentation: supporting.presentation,
      artifact: artifact,
      evidence: evidence,
      group: supporting.group,
      spotlight: _requiredString(json, 'spotlight'),
      url: supporting.url,
      technologies: common.technologies,
    ),
  };
}

PortfolioSystemArtifact _localizedArtifact(
  PortfolioSystemArtifact source,
  Map<String, dynamic> json,
) => PortfolioSystemArtifact(
  label: _requiredString(json, 'label'),
  asset: source.asset,
  alt: _requiredString(json, 'alt'),
  caption: _requiredString(json, 'caption'),
  width: source.width,
  height: source.height,
  fit: source.fit,
  alignment: source.alignment,
  composition: source.composition,
  compact: switch (source.compact) {
    final compact? => PortfolioArtifactVariant(
      asset: compact.asset,
      alt: _requiredString(json, 'compact_alt'),
      caption: _requiredString(json, 'compact_caption'),
      width: compact.width,
      height: compact.height,
      fit: compact.fit,
      alignment: compact.alignment,
    ),
    null => null,
  },
);

Map<String, dynamic> _requiredObject(Map<String, dynamic> json, String key) =>
    switch (json[key]) {
      final Map<String, dynamic> value => value,
      _ => throw FormatException('Expected object at "$key".'),
    };

Map<String, dynamic>? _optionalObject(Map<String, dynamic> json, String key) =>
    switch (json[key]) {
      null => null,
      final Map<String, dynamic> value => value,
      _ => throw FormatException('Expected object at "$key".'),
    };

List<Map<String, dynamic>> _objects(Map<String, dynamic> json, String key) =>
    switch (json[key]) {
      final List<dynamic> value =>
        value
            .map(
              (entry) => switch (entry) {
                final Map<String, dynamic> object => object,
                _ => throw FormatException(
                  'Expected object entries at "$key".',
                ),
              },
            )
            .toList(growable: false),
      _ => throw FormatException('Expected list at "$key".'),
    };

List<String> _strings(Map<String, dynamic> json, String key) =>
    switch (json[key]) {
      final List<dynamic> value =>
        value
            .map(
              (entry) => switch (entry) {
                final String string when string.trim().isNotEmpty => string,
                _ => throw FormatException(
                  'Expected non-empty strings at "$key".',
                ),
              },
            )
            .toList(growable: false),
      _ => throw FormatException('Expected list at "$key".'),
    };

String _requiredString(Map<String, dynamic> json, String key) =>
    switch (json[key]) {
      final String value when value.trim().isNotEmpty => value,
      _ => throw FormatException('Expected non-empty string at "$key".'),
    };

String _requiredEmail(Map<String, dynamic> json, String key) {
  final value = _requiredString(json, key);
  if (value.length > 254 ||
      !RegExp(
        r'^[A-Za-z0-9._%+\-]+@[A-Za-z0-9](?:[A-Za-z0-9\-]{0,61}[A-Za-z0-9])?(?:\.[A-Za-z0-9](?:[A-Za-z0-9\-]{0,61}[A-Za-z0-9])?)+$',
      ).hasMatch(value)) {
    throw FormatException('Expected an email address at "$key".');
  }
  return value;
}

String _requiredHexColor(Map<String, dynamic> json, String key) {
  final value = _requiredString(json, key);
  if (!RegExp(r'^#[0-9A-Fa-f]{6}$').hasMatch(value)) {
    throw FormatException('Expected a six-digit hex colour at "$key".');
  }
  return value.toUpperCase();
}

int _requiredInt(Map<String, dynamic> json, String key) => switch (json[key]) {
  final int value => value,
  _ => throw FormatException('Expected integer at "$key".'),
};

bool _requiredBool(Map<String, dynamic> json, String key) =>
    switch (json[key]) {
      final bool value => value,
      _ => throw FormatException('Expected boolean at "$key".'),
    };

Uri _requiredUri(Map<String, dynamic> json, String key) {
  final value = Uri.parse(_requiredString(json, key));
  if (value.scheme != 'https' || value.host.isEmpty) {
    throw FormatException('Expected an absolute HTTPS URL at "$key".');
  }
  return value;
}

Uri? _optionalUri(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value == null) return null;
  if (value case final String string when string.trim().isNotEmpty) {
    final uri = Uri.parse(string);
    if (uri.scheme == 'https' && uri.host.isNotEmpty) return uri;
  }
  throw FormatException('Expected an absolute HTTPS URL at "$key".');
}

void _assertUnique(String label, Iterable<String> ids) {
  final seen = <String>{};
  for (final id in ids) {
    if (!seen.add(id)) {
      throw FormatException('Duplicate $label id: $id');
    }
  }
}

bool _sameStrings(List<String> first, List<String> second) {
  if (first.length != second.length) return false;
  for (var index = 0; index < first.length; index += 1) {
    if (first[index] != second[index]) return false;
  }
  return true;
}

void _validateArtifactMedia({
  required String asset,
  required String alt,
  required String caption,
  required int width,
  required int height,
}) {
  if (!asset.startsWith('assets/work/') ||
      asset.contains('..') ||
      !const ['.png', '.jpg', '.jpeg', '.webp'].any(asset.endsWith) ||
      width <= 0 ||
      height <= 0 ||
      alt == caption) {
    throw const FormatException(
      'Project artifacts require a supported local asset, positive dimensions, and distinct accessible copy.',
    );
  }
}
