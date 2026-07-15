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
    required List<PortfolioStoryBeat> story,
  }) : sources = List.unmodifiable(sources),
       experience = List.unmodifiable(experience),
       capabilities = List.unmodifiable(capabilities),
       contributions = List.unmodifiable(contributions),
       systems = List.unmodifiable(systems),
       story = List.unmodifiable(story);

  factory PortfolioDocument.fromJson(Map<String, dynamic> json) {
    final schemaVersion = _requiredInt(json, 'schema_version');
    if (schemaVersion != 1) {
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
      story: _objects(json, 'story').map(PortfolioStoryBeat.fromJson).toList(),
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
  final List<PortfolioStoryBeat> story;

  List<String> get activeSections => <String>[
    'home',
    'about',
    if (experience.isNotEmpty) 'experience',
    if (contributions.isNotEmpty) 'proof',
    if (systems.isNotEmpty) 'projects',
  ];

  Iterable<PortfolioContribution> get mergedContributions =>
      contributions.where((entry) => entry.status == ContributionStatus.merged);

  Iterable<PortfolioContribution> get contributionsUnderReview => contributions
      .where((entry) => entry.status == ContributionStatus.underReview);

  void _validate() {
    if (profile.role != 'Software Engineer') {
      throw const FormatException(
        'The public role must be exactly "Software Engineer".',
      );
    }
    if (sources.isEmpty ||
        experience.isEmpty ||
        capabilities.isEmpty ||
        contributions.isEmpty ||
        systems.isEmpty) {
      throw const FormatException(
        'Sources, experience, capabilities, contributions, and systems '
        'must not be empty.',
      );
    }
    if (mergedContributions.isEmpty) {
      throw const FormatException(
        'At least one accepted upstream contribution is required.',
      );
    }
    if (!site.title.contains(profile.role)) {
      throw const FormatException(
        'Site metadata must use the canonical public role.',
      );
    }
    if (story.length != activeSections.length - 1) {
      throw FormatException(
        'The story must contain one transition for each public chapter: '
        '${activeSections.length - 1} required, ${story.length} provided.',
      );
    }
    _assertUnique('source', sources.map((entry) => entry.id));
    _assertUnique('profile link', profile.links.map((entry) => entry.id));
    _assertUnique('experience', experience.map((entry) => entry.id));
    _assertUnique('capability', capabilities.map((entry) => entry.id));
    _assertUnique('contribution', contributions.map((entry) => entry.id));
    _assertUnique('system', systems.map((entry) => entry.id));
    _assertUnique('story beat', story.map((entry) => entry.id));
  }
}

final class PortfolioSite {
  const PortfolioSite({
    required this.url,
    required this.title,
    required this.description,
    required this.socialDescription,
    required this.socialImage,
    required this.domainLabel,
  });

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
    );
  }

  final Uri url;
  final String title;
  final String description;
  final String socialDescription;
  final String socialImage;
  final String domainLabel;
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
    required this.role,
    required this.location,
    required this.since,
    required this.headline,
    required this.summary,
    required List<String> focus,
    required List<PortfolioLink> links,
  }) : focus = List.unmodifiable(focus),
       links = List.unmodifiable(links);

  factory PortfolioProfile.fromJson(Map<String, dynamic> json) =>
      PortfolioProfile(
        role: _requiredString(json, 'role'),
        location: _requiredString(json, 'location'),
        since: _requiredString(json, 'since'),
        headline: _requiredString(json, 'headline'),
        summary: _requiredString(json, 'summary'),
        focus: _strings(json, 'focus'),
        links: _objects(json, 'links').map(PortfolioLink.fromJson).toList(),
      );

  final String role;
  final String location;
  final String since;
  final String headline;
  final String summary;
  final List<String> focus;
  final List<PortfolioLink> links;
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
    required this.role,
    required this.domain,
    required this.period,
    required this.summary,
    required List<String> evidence,
  }) : evidence = List.unmodifiable(evidence);

  factory PortfolioExperience.fromJson(Map<String, dynamic> json) =>
      PortfolioExperience(
        id: _requiredString(json, 'id'),
        role: _requiredString(json, 'role'),
        domain: _requiredString(json, 'domain'),
        period: _requiredString(json, 'period'),
        summary: _requiredString(json, 'summary'),
        evidence: _strings(json, 'evidence'),
      );

  final String id;
  final String role;
  final String domain;
  final String period;
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
    this.issueUrl,
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
        issueUrl: _optionalUri(json, 'issue_url'),
      );

  final String id;
  final String project;
  final ContributionStatus status;
  final DateTime date;
  final String title;
  final String problem;
  final String change;
  final Uri url;
  final Uri? issueUrl;
}

final class PortfolioSystem {
  PortfolioSystem({
    required this.id,
    required this.name,
    required this.kind,
    required this.visual,
    required this.summary,
    required this.decision,
    required this.url,
    required List<String> technologies,
  }) : technologies = List.unmodifiable(technologies);

  factory PortfolioSystem.fromJson(Map<String, dynamic> json) =>
      PortfolioSystem(
        id: _requiredString(json, 'id'),
        name: _requiredString(json, 'name'),
        kind: _requiredString(json, 'kind'),
        visual: PortfolioVisual.parse(_requiredString(json, 'visual')),
        summary: _requiredString(json, 'summary'),
        decision: _requiredString(json, 'decision'),
        url: _requiredUri(json, 'url'),
        technologies: _strings(json, 'technologies'),
      );

  final String id;
  final String name;
  final String kind;
  final PortfolioVisual visual;
  final String summary;
  final String decision;
  final Uri url;
  final List<String> technologies;
}

enum PortfolioVisual {
  framePipeline('frame-pipeline'),
  queueStates('queue-states'),
  tenantRouting('tenant-routing'),
  weightedQueue('weighted-queue'),
  spatialGrid('spatial-grid');

  const PortfolioVisual(this.wireValue);
  final String wireValue;

  static PortfolioVisual parse(String value) => values.firstWhere(
    (entry) => entry.wireValue == value,
    orElse: () => throw FormatException('Unsupported system visual: $value'),
  );
}

final class PortfolioStoryBeat {
  const PortfolioStoryBeat({
    required this.id,
    required this.eyebrow,
    required this.title,
    required this.body,
  });

  factory PortfolioStoryBeat.fromJson(Map<String, dynamic> json) =>
      PortfolioStoryBeat(
        id: _requiredString(json, 'id'),
        eyebrow: _requiredString(json, 'eyebrow'),
        title: _requiredString(json, 'title'),
        body: _requiredString(json, 'body'),
      );

  final String id;
  final String eyebrow;
  final String title;
  final String body;
}

Map<String, dynamic> _requiredObject(Map<String, dynamic> json, String key) =>
    switch (json[key]) {
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

int _requiredInt(Map<String, dynamic> json, String key) => switch (json[key]) {
  final int value => value,
  _ => throw FormatException('Expected integer at "$key".'),
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
