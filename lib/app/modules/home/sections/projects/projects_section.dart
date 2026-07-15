import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_web_portfolio/app/core/constants/app_colors.dart';
import 'package:flutter_web_portfolio/app/core/theme/app_fonts.dart';
import 'package:flutter_web_portfolio/app/domain/models/portfolio_document.dart';
import 'package:flutter_web_portfolio/app/features/language/application/language_cubit.dart';
import 'package:flutter_web_portfolio/app/narrative/domain/narrative_document.dart';
import 'package:flutter_web_portfolio/app/modules/home/sections/projects/widgets/editorial_project_chapter.dart';
import 'package:flutter_web_portfolio/app/modules/home/sections/projects/widgets/project_archive.dart';
import 'package:flutter_web_portfolio/app/widgets/numbered_section_heading.dart';
import 'package:flutter_web_portfolio/app/widgets/scene_accent_builder.dart';

/// Selected professional and independent work as a continuous editorial index.
///
/// Featured systems read as case-study chapters. Supporting systems remain a
/// compact archive so the section never falls back to a card catalogue.
final class ProjectsSection extends StatelessWidget {
  const ProjectsSection({super.key});

  @override
  Widget build(
    BuildContext context,
  ) => BlocBuilder<LanguageCubit, LanguageState>(
    builder: (context, _) {
      final language = context.read<LanguageCubit>();
      final portfolio = context.read<PortfolioDocument>();
      final featured = portfolio.featuredSystems.toList(growable: false);
      final supporting = portfolio.supportingSystems.toList(growable: false);
      final labels = ProjectChapterLabels(
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
        evidence: language.getText(
          'projects_section.evidence',
          defaultValue: 'Evidence',
        ),
        openProject: language.getText(
          'projects_section.open_project',
          defaultValue: 'Open project',
        ),
        openEvidence: language.getText(
          'projects_section.open_evidence',
          defaultValue: 'Open evidence',
        ),
      );

      return ConstrainedBox(
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
              ),
            ),
            const SizedBox(height: 26),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: Text(
                language.getText(
                  'projects_section.subtitle',
                  defaultValue:
                      'Products I shipped and tools I continue to maintain.',
                ),
                style: AppFonts.inter(
                  fontSize: 17,
                  color: AppColors.textPrimary,
                  height: 1.65,
                ),
              ),
            ),
            const SizedBox(height: 60),
            for (var index = 0; index < featured.length; index++)
              EditorialProjectChapter(
                key: ValueKey('project-chapter-${featured[index].id}'),
                system: featured[index],
                index: index,
                labels: labels,
              ),
            if (supporting.isNotEmpty) ...[
              const SizedBox(height: 108),
              Builder(
                builder: (context) {
                  final label = language.getText(
                    'projects_section.archive',
                    defaultValue: 'More work',
                  );
                  return Semantics(
                    header: true,
                    headingLevel: 3,
                    label: label,
                    excludeSemantics: true,
                    child: ExcludeSemantics(
                      child: Text(
                        label,
                        style: AppFonts.spaceGrotesk(
                          fontSize: 26,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textBright,
                          letterSpacing: -0.55,
                        ),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 22),
              ProjectArchive(systems: supporting),
            ],
          ],
        ),
      );
    },
  );
}
