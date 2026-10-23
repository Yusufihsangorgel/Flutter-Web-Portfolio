import 'package:flutter/foundation.dart';
import 'package:flutter_web_portfolio/app/core/l10n/app_strings.g.dart';

/// Localized interface copy for the work atlas.
@immutable
final class ProjectAtlasLabels {
  ProjectAtlasLabels.fromStrings(AppStrings strings)
    : challenge = strings.projectsSectionChallenge,
      approach = strings.projectsSectionApproach,
      outcome = strings.projectsSectionOutcome,
      ownership = strings.projectsSectionOwnership,
      decision = strings.projectsSectionDecision,
      selectedCases = strings.projectsSectionSelectedCases,
      evidenceIndex = strings.projectsSectionEvidenceIndex,
      evidenceIntro = strings.projectsSectionEvidenceIntro,
      shippedProducts = strings.projectsSectionShippedProducts,
      openEngineering = strings.projectsSectionOpenEngineering,
      selectEvidence = strings.projectsSectionSelectEvidence,
      openEvidence = strings.projectsSectionOpenEvidence,
      caseLabel = strings.projectsSectionCaseLabel,
      indexLabel = strings.projectsSectionIndexLabel;

  final String challenge;
  final String approach;
  final String outcome;
  final String ownership;
  final String decision;
  final String selectedCases;
  final String evidenceIndex;
  final String evidenceIntro;
  final String shippedProducts;
  final String openEngineering;
  final String selectEvidence;
  final String openEvidence;
  final String caseLabel;
  final String indexLabel;
}
