import 'package:flutter_web_portfolio/app/data/dto/artifact_mapper.dart';
import 'package:flutter_web_portfolio/app/data/dto/json_fields.dart';
import 'package:flutter_web_portfolio/app/domain/models/system.dart';

PortfolioSystem parsePortfolioSystem(Map<String, dynamic> json) {
  final featured = requiredBool(json, 'featured');
  final common = _parseCommonSystemFields(json);
  return featured
      ? _parseFeaturedSystem(json, common)
      : _parseSupportingSystem(json, common);
}

PortfolioSystemFields _parseCommonSystemFields(Map<String, dynamic> json) {
  final id = requiredString(json, 'id');
  final fields = (
    id: id,
    name: requiredString(json, 'name'),
    kind: requiredString(json, 'kind'),
    year: requiredString(json, 'year'),
    summary: requiredString(json, 'summary'),
    ownership: requiredString(json, 'ownership'),
    decision: requiredString(json, 'decision'),
    presentation: _parsePortfolioSystemPresentation(
      requiredObject(json, 'presentation'),
    ),
    artifact: parsePortfolioSystemArtifact(requiredObject(json, 'artifact')),
    evidence: requiredObjects(
      json,
      'evidence',
    ).map(_parsePortfolioEvidence).toList(),
    url: requiredUri(json, 'url'),
    technologies: requiredStrings(json, 'technologies'),
  );
  if (fields.evidence.isEmpty) {
    throw FormatException('System "$id" must declare evidence.');
  }
  return fields;
}

PortfolioFeaturedSystem _parseFeaturedSystem(
  Map<String, dynamic> json,
  PortfolioSystemFields common,
) => PortfolioFeaturedSystem((
  id: common.id,
  name: common.name,
  kind: common.kind,
  year: common.year,
  summary: common.summary,
  ownership: common.ownership,
  decision: common.decision,
  presentation: common.presentation,
  artifact: common.artifact,
  evidence: common.evidence,
  url: common.url,
  technologies: common.technologies,
  challenge: requiredString(json, 'challenge'),
  approach: requiredString(json, 'approach'),
  outcome: requiredString(json, 'outcome'),
));

PortfolioSupportingSystem _parseSupportingSystem(
  Map<String, dynamic> json,
  PortfolioSystemFields common,
) => PortfolioSupportingSystem((
  id: common.id,
  name: common.name,
  kind: common.kind,
  year: common.year,
  summary: common.summary,
  ownership: common.ownership,
  decision: common.decision,
  presentation: common.presentation,
  artifact: common.artifact,
  evidence: common.evidence,
  url: common.url,
  technologies: common.technologies,
  group: PortfolioSystemGroup.parse(requiredString(json, 'group')),
  spotlight: requiredString(json, 'spotlight'),
));

PortfolioSystemPresentation _parsePortfolioSystemPresentation(
  Map<String, dynamic> json,
) => PortfolioSystemPresentation(
  background: requiredHexColor(json, 'background'),
  foreground: requiredHexColor(json, 'foreground'),
  accent: requiredHexColor(json, 'accent'),
);

PortfolioEvidence _parsePortfolioEvidence(Map<String, dynamic> json) =>
    PortfolioEvidence(
      label: requiredString(json, 'label'),
      url: requiredUri(json, 'url'),
      kind: requiredString(json, 'kind'),
    );
