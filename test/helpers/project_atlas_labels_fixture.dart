import 'package:flutter_web_portfolio/app/core/l10n/app_strings.g.dart';
import 'package:flutter_web_portfolio/app/modules/home/sections/projects/widgets/atlas_labels.dart';

ProjectAtlasLabels projectAtlasLabelsFixture() =>
    ProjectAtlasLabels.fromStrings(
      const AppStrings({
        'projects_section': {
          'challenge': 'The problem',
          'approach': 'The approach',
          'outcome': 'The result',
          'ownership': 'What I owned',
          'decision': 'Engineering focus',
          'selected_cases': 'Case studies',
          'evidence_index': 'More work',
          'evidence_intro': 'Released products and open-source projects.',
          'shipped_products': 'Shipped products',
          'open_engineering': 'Open engineering',
          'select_evidence': 'Choose a project',
          'open_evidence': 'View project',
          'case_label': 'Case',
          'index_label': 'Index',
        },
      }),
    );
