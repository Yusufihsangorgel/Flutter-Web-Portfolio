import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_web_portfolio/app/core/l10n/app_strings.g.dart';
import 'package:flutter_web_portfolio/app/modules/home/sections/projects/widgets/atlas_labels.dart';

void main() {
  test(
    'maps every typed label and snapshots nested translations',
    _mapsEveryTypedLabelAndSnapshotsNestedTranslations,
  );
  test(
    'preserves generated getter fallbacks when translations are absent',
    _preservesGeneratedGetterFallbacks,
  );
}

void _mapsEveryTypedLabelAndSnapshotsNestedTranslations() {
  const expected = <String>[
    'mapped:challenge',
    'mapped:approach',
    'mapped:outcome',
    'mapped:ownership',
    'mapped:decision',
    'mapped:selected-cases',
    'mapped:evidence-index',
    'mapped:evidence-intro',
    'mapped:shipped-products',
    'mapped:open-engineering',
    'mapped:select-evidence',
    'mapped:open-evidence',
    'mapped:case-label',
    'mapped:index-label',
  ];
  final projectSection = <String, Object?>{
    'challenge': expected[0],
    'approach': expected[1],
    'outcome': expected[2],
    'ownership': expected[3],
    'decision': expected[4],
    'selected_cases': expected[5],
    'evidence_index': expected[6],
    'evidence_intro': expected[7],
    'shipped_products': expected[8],
    'open_engineering': expected[9],
    'select_evidence': expected[10],
    'open_evidence': expected[11],
    'case_label': expected[12],
    'index_label': expected[13],
  };
  final strings = AppStrings({'projects_section': projectSection});
  final labels = ProjectAtlasLabels.fromStrings(strings);

  expect(expected.toSet(), hasLength(expected.length));
  expect(_labelValues(labels), expected);

  projectSection.updateAll((key, _) => 'mutated:$key');

  expect(strings.projectsSectionChallenge, 'mutated:challenge');
  expect(_labelValues(labels), expected);
}

void _preservesGeneratedGetterFallbacks() {
  const strings = AppStrings({});
  final labels = ProjectAtlasLabels.fromStrings(strings);

  expect(_labelValues(labels), [
    strings.projectsSectionChallenge,
    strings.projectsSectionApproach,
    strings.projectsSectionOutcome,
    strings.projectsSectionOwnership,
    strings.projectsSectionDecision,
    strings.projectsSectionSelectedCases,
    strings.projectsSectionEvidenceIndex,
    strings.projectsSectionEvidenceIntro,
    strings.projectsSectionShippedProducts,
    strings.projectsSectionOpenEngineering,
    strings.projectsSectionSelectEvidence,
    strings.projectsSectionOpenEvidence,
    strings.projectsSectionCaseLabel,
    strings.projectsSectionIndexLabel,
  ]);
}

List<String> _labelValues(ProjectAtlasLabels labels) => [
  labels.challenge,
  labels.approach,
  labels.outcome,
  labels.ownership,
  labels.decision,
  labels.selectedCases,
  labels.evidenceIndex,
  labels.evidenceIntro,
  labels.shippedProducts,
  labels.openEngineering,
  labels.selectEvidence,
  labels.openEvidence,
  labels.caseLabel,
  labels.indexLabel,
];
