import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_web_portfolio/app/controllers/scroll_controller.dart';
import 'package:flutter_web_portfolio/app/core/constants/app_colors.dart';
import 'package:flutter_web_portfolio/app/core/constants/app_dimensions.dart';
import 'package:flutter_web_portfolio/app/core/constants/breakpoints.dart';
import 'package:flutter_web_portfolio/app/core/theme/app_fonts.dart';
import 'package:flutter_web_portfolio/app/domain/models/portfolio_document.dart';
import 'package:flutter_web_portfolio/app/features/language/application/language_cubit.dart';
import 'package:flutter_web_portfolio/app/modules/home/sections/projects/widgets/project_atlas.dart';
import 'package:flutter_web_portfolio/app/narrative/domain/narrative_document.dart';
import 'package:flutter_web_portfolio/app/widgets/numbered_section_heading.dart';
import 'package:flutter_web_portfolio/app/widgets/scene_accent_builder.dart';

/// Real products and public engineering work presented as one continuous
/// full-width atlas. No card grid, accordion, or project-specific widget copy.
final class ProjectsSection extends StatelessWidget {
  const ProjectsSection({super.key});

  @override
  Widget build(
    BuildContext context,
  ) => BlocBuilder<LanguageCubit, LanguageState>(
    builder: (context, _) {
      final language = context.read<LanguageCubit>();
      final portfolio = context.read<PortfolioDocument>();
      final labels = ProjectAtlasLabels(
        challenge: language.getText(
          'projects_section.challenge',
          defaultValue: 'The problem',
        ),
        approach: language.getText(
          'projects_section.approach',
          defaultValue: 'The approach',
        ),
        outcome: language.getText(
          'projects_section.outcome',
          defaultValue: 'The result',
        ),
        ownership: language.getText(
          'projects_section.ownership',
          defaultValue: 'What I owned',
        ),
        decision: language.getText(
          'projects_section.decision',
          defaultValue: 'Engineering focus',
        ),
        selectedCases: language.getText(
          'projects_section.selected_cases',
          defaultValue: 'Selected cases',
        ),
        evidenceIndex: language.getText(
          'projects_section.evidence_index',
          defaultValue: 'More work',
        ),
        evidenceIntro: language.getText(
          'projects_section.evidence_intro',
          defaultValue:
              'Released products and public engineering records, shown through their source material.',
        ),
        shippedProducts: language.getText(
          'projects_section.shipped_products',
          defaultValue: 'Shipped products',
        ),
        openEngineering: language.getText(
          'projects_section.open_engineering',
          defaultValue: 'Open engineering',
        ),
        selectEvidence: language.getText(
          'projects_section.select_evidence',
          defaultValue: 'Choose a project',
        ),
        openEvidence: language.getText(
          'projects_section.open_evidence',
          defaultValue: 'View project',
        ),
        caseLabel: language.getText(
          'projects_section.case_label',
          defaultValue: 'Case',
        ),
        indexLabel: language.getText(
          'projects_section.index_label',
          defaultValue: 'Index',
        ),
      );

      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _ProjectsIntroduction(language: language),
          ProjectAtlas(systems: portfolio.systems, labels: labels),
        ],
      );
    },
  );
}

final class _ProjectsIntroduction extends StatelessWidget {
  const _ProjectsIntroduction({required this.language});

  final LanguageCubit language;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final tablet = width >= Breakpoints.tablet;
    final horizontal = width > AppDimensions.maxContentWidth
        ? AppDimensions.sectionPaddingDesktop
        : tablet
        ? AppDimensions.sectionPaddingTablet
        : AppDimensions.sectionPaddingMobile;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        horizontal,
        tablet ? 80 : 44,
        horizontal,
        tablet ? 72 : 48,
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1160),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SceneAccentBuilder(
              builder: (context, accent) => NumberedSectionHeading(
                number: context.read<NarrativeDocument>().sectionNumber(
                  SectionId.projects,
                ),
                title: language.getText(
                  'projects_section.title',
                  defaultValue: 'Selected Work',
                ),
                accent: accent,
                anchorKey: context.read<AppScrollController>().anchorKeyFor(
                  SectionId.projects,
                ),
              ),
            ),
            const SizedBox(height: 26),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 760),
              child: Text(
                language.getText(
                  'projects_section.subtitle',
                  defaultValue:
                      'Products I shipped and tools I continue to maintain.',
                ),
                style: AppFonts.spaceGrotesk(
                  fontSize: tablet ? 26 : 20,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textBright,
                  height: 1.35,
                  letterSpacing: -0.45,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
