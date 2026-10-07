import 'package:flutter_web_portfolio/app/domain/models/artifact.dart';

typedef PortfolioSystemFields = ({
  String id,
  String name,
  String kind,
  String year,
  String summary,
  String ownership,
  String decision,
  PortfolioSystemPresentation presentation,
  PortfolioSystemArtifact artifact,
  List<PortfolioEvidence> evidence,
  Uri url,
  List<String> technologies,
});

sealed class PortfolioSystem {
  PortfolioSystem(PortfolioSystemFields fields)
    : id = fields.id,
      name = fields.name,
      kind = fields.kind,
      year = fields.year,
      summary = fields.summary,
      ownership = fields.ownership,
      decision = fields.decision,
      presentation = fields.presentation,
      artifact = fields.artifact,
      evidence = List.unmodifiable(fields.evidence),
      url = fields.url,
      technologies = List.unmodifiable(fields.technologies);

  Map<String, Object?> toJson();

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

typedef PortfolioFeaturedSystemTranslation = ({
  String kind,
  String year,
  String summary,
  String ownership,
  String decision,
  PortfolioSystemArtifact artifact,
  List<PortfolioEvidence> evidence,
  List<String> technologies,
  String challenge,
  String approach,
  String outcome,
});

typedef PortfolioFeaturedSystemFields = ({
  String id,
  String name,
  String kind,
  String year,
  String summary,
  String ownership,
  String decision,
  PortfolioSystemPresentation presentation,
  PortfolioSystemArtifact artifact,
  List<PortfolioEvidence> evidence,
  Uri url,
  List<String> technologies,
  String challenge,
  String approach,
  String outcome,
});

final class PortfolioFeaturedSystem extends PortfolioSystem {
  PortfolioFeaturedSystem(PortfolioFeaturedSystemFields fields)
    : challenge = fields.challenge,
      approach = fields.approach,
      outcome = fields.outcome,
      super((
        id: fields.id,
        name: fields.name,
        kind: fields.kind,
        year: fields.year,
        summary: fields.summary,
        ownership: fields.ownership,
        decision: fields.decision,
        presentation: fields.presentation,
        artifact: fields.artifact,
        evidence: fields.evidence,
        url: fields.url,
        technologies: fields.technologies,
      ));

  PortfolioFeaturedSystem copyWith(
    PortfolioFeaturedSystemTranslation changes,
  ) => PortfolioFeaturedSystem((
    id: id,
    name: name,
    kind: changes.kind,
    year: changes.year,
    summary: changes.summary,
    ownership: changes.ownership,
    decision: changes.decision,
    presentation: presentation,
    artifact: changes.artifact,
    evidence: changes.evidence,
    url: url,
    technologies: changes.technologies,
    challenge: changes.challenge,
    approach: changes.approach,
    outcome: changes.outcome,
  ));

  @override
  Map<String, Object?> toJson() => {
    'id': id,
    'name': name,
    'kind': kind,
    'year': year,
    'summary': summary,
    'ownership': ownership,
    'decision': decision,
    'presentation': presentation.toJson(),
    'artifact': artifact.toJson(),
    'evidence': [for (final value in evidence) value.toJson()],
    'url': url.toString(),
    'technologies': technologies,
    'challenge': challenge,
    'approach': approach,
    'outcome': outcome,
  };

  final String challenge;
  final String approach;
  final String outcome;
}

typedef PortfolioSupportingSystemTranslation = ({
  String kind,
  String year,
  String summary,
  String ownership,
  String decision,
  PortfolioSystemArtifact artifact,
  List<PortfolioEvidence> evidence,
  List<String> technologies,
  String spotlight,
});

typedef PortfolioSupportingSystemFields = ({
  String id,
  String name,
  String kind,
  String year,
  String summary,
  String ownership,
  String decision,
  PortfolioSystemPresentation presentation,
  PortfolioSystemArtifact artifact,
  List<PortfolioEvidence> evidence,
  Uri url,
  List<String> technologies,
  PortfolioSystemGroup group,
  String spotlight,
});

final class PortfolioSupportingSystem extends PortfolioSystem {
  PortfolioSupportingSystem(PortfolioSupportingSystemFields fields)
    : group = fields.group,
      spotlight = fields.spotlight,
      super((
        id: fields.id,
        name: fields.name,
        kind: fields.kind,
        year: fields.year,
        summary: fields.summary,
        ownership: fields.ownership,
        decision: fields.decision,
        presentation: fields.presentation,
        artifact: fields.artifact,
        evidence: fields.evidence,
        url: fields.url,
        technologies: fields.technologies,
      ));

  PortfolioSupportingSystem copyWith(
    PortfolioSupportingSystemTranslation changes,
  ) => PortfolioSupportingSystem((
    id: id,
    name: name,
    kind: changes.kind,
    year: changes.year,
    summary: changes.summary,
    ownership: changes.ownership,
    decision: changes.decision,
    presentation: presentation,
    artifact: changes.artifact,
    evidence: changes.evidence,
    url: url,
    technologies: changes.technologies,
    group: group,
    spotlight: changes.spotlight,
  ));

  @override
  Map<String, Object?> toJson() => {
    'id': id,
    'name': name,
    'kind': kind,
    'year': year,
    'summary': summary,
    'ownership': ownership,
    'decision': decision,
    'presentation': presentation.toJson(),
    'artifact': artifact.toJson(),
    'evidence': [for (final value in evidence) value.toJson()],
    'url': url.toString(),
    'technologies': technologies,
    'group': group.wireValue,
    'spotlight': spotlight,
  };

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

/// Content-authored palette for a project chapter, as `#RRGGBB` strings.
final class PortfolioSystemPresentation {
  PortfolioSystemPresentation({
    required this.background,
    required this.foreground,
    required this.accent,
  });

  Map<String, Object?> toJson() => {
    'background': background,
    'foreground': foreground,
    'accent': accent,
  };

  final String background;
  final String foreground;
  final String accent;
}

typedef PortfolioEvidenceTranslation = ({String label});

final class PortfolioEvidence {
  const PortfolioEvidence({
    required this.label,
    required this.url,
    required this.kind,
  });

  PortfolioEvidence copyWith(PortfolioEvidenceTranslation changes) =>
      PortfolioEvidence(label: changes.label, url: url, kind: kind);

  Map<String, Object?> toJson() => {
    'label': label,
    'url': url.toString(),
    'kind': kind,
  };

  final String label;
  final Uri url;
  final String kind;
}
