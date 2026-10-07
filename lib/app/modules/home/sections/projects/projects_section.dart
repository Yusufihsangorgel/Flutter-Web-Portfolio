import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_web_portfolio/app/controllers/scroll_controller.dart';
import 'package:flutter_web_portfolio/app/core/constants/app_colors.dart';
import 'package:flutter_web_portfolio/app/core/l10n/app_strings.g.dart';
import 'package:flutter_web_portfolio/app/core/theme/app_fonts.dart';
import 'package:flutter_web_portfolio/app/domain/models/portfolio_document.dart';
import 'package:flutter_web_portfolio/app/features/language/application/language_context.dart';
import 'package:flutter_web_portfolio/app/features/language/application/language_cubit.dart';
import 'package:flutter_web_portfolio/app/modules/home/sections/projects/widgets/atlas_style.dart';
import 'package:flutter_web_portfolio/app/modules/home/sections/projects/widgets/project_atlas.dart';
import 'package:flutter_web_portfolio/app/narrative/domain/narrative_document.dart';
import 'package:flutter_web_portfolio/app/widgets/numbered_section_heading.dart';
import 'package:flutter_web_portfolio/app/widgets/scene_accent_builder.dart';

/// Real products and public engineering work presented as one continuous
/// full-width atlas. No card grid, accordion, or project-specific widget copy.
final class ProjectsSection extends StatelessWidget {
  const ProjectsSection({super.key});

  @override
  Widget build(BuildContext context) =>
      BlocBuilder<LanguageCubit, LanguageState>(
        builder: (context, _) {
          final strings = context.strings;
          final portfolio = context.read<PortfolioDocument>();
          final labels = ProjectAtlasLabels(
            challenge: strings.projectsSectionChallenge,
            approach: strings.projectsSectionApproach,
            outcome: strings.projectsSectionOutcome,
            ownership: strings.projectsSectionOwnership,
            decision: strings.projectsSectionDecision,
            selectedCases: strings.projectsSectionSelectedCases,
            evidenceIndex: strings.projectsSectionEvidenceIndex,
            evidenceIntro: strings.projectsSectionEvidenceIntro,
            shippedProducts: strings.projectsSectionShippedProducts,
            openEngineering: strings.projectsSectionOpenEngineering,
            selectEvidence: strings.projectsSectionSelectEvidence,
            openEvidence: strings.projectsSectionOpenEvidence,
            caseLabel: strings.projectsSectionCaseLabel,
            indexLabel: strings.projectsSectionIndexLabel,
          );

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _ProjectsIntroduction(strings: strings),
              ProjectAtlas(systems: portfolio.systems, labels: labels),
            ],
          );
        },
      );
}

final class _ProjectsIntroduction extends StatelessWidget {
  const _ProjectsIntroduction({required this.strings});

  final AppStrings strings;

  @override
  Widget build(BuildContext context) {
    final layout = AtlasLayout.of(context);
    final tablet = layout.tablet;
    final horizontal = layout.horizontalPadding;

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
                title: strings.projectsSectionTitle,
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
                strings.projectsSectionSubtitle,
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
