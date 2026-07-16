import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_web_portfolio/app/controllers/scroll_controller.dart';
import 'package:flutter_web_portfolio/app/core/constants/app_colors.dart';
import 'package:flutter_web_portfolio/app/core/constants/breakpoints.dart';
import 'package:flutter_web_portfolio/app/core/theme/app_fonts.dart';
import 'package:flutter_web_portfolio/app/domain/models/portfolio_document.dart';
import 'package:flutter_web_portfolio/app/features/language/application/language_cubit.dart';
import 'package:flutter_web_portfolio/app/narrative/domain/narrative_document.dart';
import 'package:flutter_web_portfolio/app/widgets/numbered_section_heading.dart';
import 'package:flutter_web_portfolio/app/widgets/scene_accent_builder.dart';

/// A readable career chronology with real organisations and responsibilities.
class ExperienceSection extends StatelessWidget {
  const ExperienceSection({super.key});

  @override
  Widget build(BuildContext context) =>
      BlocBuilder<LanguageCubit, LanguageState>(
        builder: (context, _) {
          final language = context.read<LanguageCubit>();
          final portfolio = context.read<PortfolioDocument>();
          final experiences = portfolio.experience;

          return ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1160),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SceneAccentBuilder(
                  builder: (context, accent) => NumberedSectionHeading(
                    number: context.read<NarrativeDocument>().sectionNumber(
                      SectionId.experience,
                    ),
                    title: language.getText(
                      'experience_section.title',
                      defaultValue: 'Experience',
                    ),
                    accent: accent,
                  ),
                ),
                const SizedBox(height: 66),
                for (var index = 0; index < experiences.length; index++)
                  _ExperienceEntry(
                    experience: experiences[index],
                    isLast: index == experiences.length - 1,
                    anchorKey: index == 0
                        ? context.read<AppScrollController>().anchorKeyFor(
                            SectionId.experience,
                          )
                        : null,
                  ),
              ],
            ),
          );
        },
      );
}

class _ExperienceEntry extends StatelessWidget {
  const _ExperienceEntry({
    required this.experience,
    required this.isLast,
    this.anchorKey,
  });

  final PortfolioExperience experience;
  final bool isLast;
  final Key? anchorKey;

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < Breakpoints.tablet;
    final content = _ExperienceContent(experience: experience);
    return Semantics(
      container: true,
      label:
          '${experience.company}. ${experience.role}. ${experience.domain}. '
          '${experience.period}. ${experience.summary}',
      child: ExcludeSemantics(
        child: Container(
          padding: EdgeInsets.symmetric(vertical: compact ? 36 : 48),
          decoration: BoxDecoration(
            border: Border(
              top: const BorderSide(color: Color(0x3D1E51FF)),
              bottom: isLast
                  ? const BorderSide(color: Color(0x3D1E51FF))
                  : BorderSide.none,
            ),
          ),
          child: compact
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _Period(period: experience.period, anchorKey: anchorKey),
                    const SizedBox(height: 24),
                    content,
                  ],
                )
              : Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 205,
                      child: _Period(
                        period: experience.period,
                        anchorKey: anchorKey,
                      ),
                    ),
                    const SizedBox(width: 64),
                    Expanded(child: content),
                  ],
                ),
        ),
      ),
    );
  }
}

class _Period extends StatelessWidget {
  const _Period({required this.period, this.anchorKey});

  final String period;
  final Key? anchorKey;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      KeyedSubtree(
        key: anchorKey,
        child: Container(
          width: 8,
          height: 8,
          margin: const EdgeInsets.only(top: 6),
          decoration: const BoxDecoration(
            color: AppColors.heroAccent,
            shape: BoxShape.circle,
          ),
        ),
      ),
      const SizedBox(width: 14),
      Expanded(
        child: Text(
          period,
          style: AppFonts.spaceGrotesk(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
            height: 1.5,
          ),
        ),
      ),
    ],
  );
}

class _ExperienceContent extends StatelessWidget {
  const _ExperienceContent({required this.experience});

  final PortfolioExperience experience;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        experience.company,
        style: AppFonts.spaceGrotesk(
          fontSize: MediaQuery.sizeOf(context).width < Breakpoints.tablet
              ? 31
              : 42,
          fontWeight: FontWeight.w600,
          color: AppColors.textBright,
          height: 1.02,
          letterSpacing: -1.15,
        ),
      ),
      const SizedBox(height: 12),
      Text(
        '${experience.role} · ${experience.domain}',
        style: AppFonts.spaceGrotesk(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: AppColors.heroAccent,
          height: 1.45,
        ),
      ),
      const SizedBox(height: 24),
      ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 740),
        child: Text(
          experience.summary,
          style: AppFonts.inter(
            fontSize: 16,
            color: AppColors.textPrimary,
            height: 1.72,
          ),
        ),
      ),
      const SizedBox(height: 24),
      Container(
        constraints: const BoxConstraints(maxWidth: 740),
        padding: const EdgeInsets.only(top: 16),
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: Color(0x3D1E51FF))),
        ),
        child: Text(
          experience.evidence.take(4).join('  /  '),
          style: AppFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: AppColors.textSecondary,
            height: 1.65,
          ),
        ),
      ),
    ],
  );
}
