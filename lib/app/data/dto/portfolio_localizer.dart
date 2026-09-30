import 'package:flutter_web_portfolio/app/data/dto/json_fields.dart';
import 'package:flutter_web_portfolio/app/domain/models/portfolio_document.dart';

/// Applies translated copy while preserving factual fields.
final class PortfolioLocalizer implements PortfolioLocalizationStrategy {
  const PortfolioLocalizer();

  @override
  PortfolioDocument localize(
    PortfolioDocument document,
    Map<String, dynamic>? localization,
  ) {
    if (localization == null || localization.isEmpty) return document;
    final copy = _PortfolioLocalization(localization);
    return document.copyWith((
      site: _localizedSite(document.site, copy.object('site')),
      profile: _localizedProfile(document.profile, copy.object('profile')),
      experience: [
        for (final entry in document.experience)
          _localizedExperience(entry, copy.entry('experience', entry.id)),
      ],
      capabilities: [
        for (final entry in document.capabilities)
          _localizedCapability(entry, copy.entry('capabilities', entry.id)),
      ],
      contributions: [
        for (final entry in document.contributions)
          _localizedContribution(entry, copy.entry('contributions', entry.id)),
      ],
      systems: [
        for (final entry in document.systems)
          _localizedSystem(entry, copy.entry('systems', entry.id)),
      ],
    ));
  }
}

final class _PortfolioLocalization {
  _PortfolioLocalization(Map<String, dynamic> json) : _json = json {
    if (requiredInt(json, 'schema_version') != 1) {
      throw const FormatException(
        'Unsupported portfolio localization schema version.',
      );
    }
    final locale = requiredString(json, 'locale');
    if (!RegExp(r'^[a-z]{2}$').hasMatch(locale) || locale == 'en') {
      throw FormatException('Invalid translated portfolio locale: $locale');
    }
  }

  final Map<String, dynamic> _json;

  Map<String, dynamic> object(String key) => requiredObject(_json, key);

  Map<String, dynamic> entry(String section, String id) =>
      requiredObject(requiredObject(_json, section), id);
}

PortfolioSite _localizedSite(PortfolioSite source, Map<String, dynamic> json) =>
    source.copyWith((
      title: requiredString(json, 'title'),
      description: requiredString(json, 'description'),
      socialDescription: requiredString(json, 'social_description'),
      engineeringLinks: _localizedLinks(
        source.engineeringLinks,
        requiredObject(json, 'engineering_links'),
      ),
    ));

PortfolioProfile _localizedProfile(
  PortfolioProfile source,
  Map<String, dynamic> json,
) => source.copyWith((
  role: requiredString(json, 'role'),
  location: requiredString(json, 'location'),
  headline: requiredString(json, 'headline'),
  summary: requiredString(json, 'summary'),
  background: requiredString(json, 'background'),
  focus: requiredStrings(json, 'focus'),
  links: _localizedLinks(source.links, requiredObject(json, 'links')),
));

List<PortfolioLink> _localizedLinks(
  List<PortfolioLink> source,
  Map<String, dynamic> labels,
) => [
  for (final link in source)
    link.copyWith((label: requiredString(labels, link.id))),
];

PortfolioExperience _localizedExperience(
  PortfolioExperience source,
  Map<String, dynamic> json,
) => source.copyWith((
  role: requiredString(json, 'role'),
  domain: requiredString(json, 'domain'),
  period: requiredString(json, 'period'),
  summary: requiredString(json, 'summary'),
  evidence: requiredStrings(json, 'evidence'),
));

PortfolioCapability _localizedCapability(
  PortfolioCapability source,
  Map<String, dynamic> json,
) => source.copyWith((
  label: requiredString(json, 'label'),
  items: requiredStrings(json, 'items'),
));

PortfolioContribution _localizedContribution(
  PortfolioContribution source,
  Map<String, dynamic> json,
) => source.copyWith((
  title: requiredString(json, 'title'),
  problem: requiredString(json, 'problem'),
  change: requiredString(json, 'change'),
  eventOrderLab: switch (source.eventOrderLab) {
    final lab? => _localizedEventOrderLab(
      lab,
      requiredObject(json, 'event_order_lab'),
    ),
    null => null,
  },
));

PortfolioEventOrderLab _localizedEventOrderLab(
  PortfolioEventOrderLab source,
  Map<String, dynamic> json,
) {
  final eventLabels = requiredObject(json, 'events');
  return source.copyWith((
    title: requiredString(json, 'title'),
    events: [
      for (final event in source.events)
        event.copyWith((label: requiredString(eventLabels, event.id))),
    ],
    baseline: source.baseline.copyWith((
      summary: requiredString(json, 'baseline_summary'),
      gap: source.baseline.gap?.copyWith((
        label: requiredString(json, 'gap_label'),
      )),
    )),
    withPatch: source.withPatch.copyWith((
      summary: requiredString(json, 'with_patch_summary'),
      gap: source.withPatch.gap,
    )),
  ));
}

PortfolioSystem _localizedSystem(
  PortfolioSystem source,
  Map<String, dynamic> json,
) {
  final evidenceLabels = requiredStrings(json, 'evidence');
  if (evidenceLabels.length != source.evidence.length) {
    throw FormatException(
      'Localized evidence count does not match system "${source.id}".',
    );
  }
  final evidence = [
    for (var index = 0; index < source.evidence.length; index++)
      source.evidence[index].copyWith((label: evidenceLabels[index])),
  ];
  final artifact = _localizedArtifact(
    source.artifact,
    requiredObject(json, 'artifact'),
  );
  final kind = requiredString(json, 'kind');
  final year = requiredString(json, 'year');
  final technologies = requiredStrings(json, 'technologies');
  final summary = requiredString(json, 'summary');
  final ownership = requiredString(json, 'ownership');
  final decision = requiredString(json, 'decision');
  return switch (source) {
    final PortfolioFeaturedSystem featured => featured.copyWith((
      kind: kind,
      year: year,
      technologies: technologies,
      summary: summary,
      ownership: ownership,
      decision: decision,
      artifact: artifact,
      evidence: evidence,
      challenge: requiredString(json, 'challenge'),
      approach: requiredString(json, 'approach'),
      outcome: requiredString(json, 'outcome'),
    )),
    final PortfolioSupportingSystem supporting => supporting.copyWith((
      kind: kind,
      year: year,
      technologies: technologies,
      summary: summary,
      ownership: ownership,
      decision: decision,
      artifact: artifact,
      evidence: evidence,
      spotlight: requiredString(json, 'spotlight'),
    )),
  };
}

PortfolioSystemArtifact _localizedArtifact(
  PortfolioSystemArtifact source,
  Map<String, dynamic> json,
) => source.copyWith((
  label: requiredString(json, 'label'),
  alt: requiredString(json, 'alt'),
  caption: requiredString(json, 'caption'),
  compact: source.compact?.copyWith((
    alt: requiredString(json, 'compact_alt'),
    caption: requiredString(json, 'compact_caption'),
  )),
));
