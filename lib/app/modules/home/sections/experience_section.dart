import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_web_portfolio/app/core/constants/app_colors.dart';
import 'package:flutter_web_portfolio/app/core/constants/breakpoints.dart';
import 'package:flutter_web_portfolio/app/core/theme/app_fonts.dart';
import 'package:flutter_web_portfolio/app/core/theme/app_typography.dart';
import 'package:flutter_web_portfolio/app/features/language/application/language_cubit.dart';
import 'package:flutter_web_portfolio/app/widgets/numbered_section_heading.dart';
import 'package:flutter_web_portfolio/app/widgets/scene_accent_builder.dart';

/// A chronological, fully visible account of professional work.
///
/// Every entry is part of the document flow. There are no hidden tabs or
/// oversized decorative labels competing with the actual experience.
class ExperienceSection extends StatelessWidget {
  const ExperienceSection({super.key});

  @override
  Widget build(BuildContext context) =>
      BlocBuilder<LanguageCubit, LanguageState>(
        builder: (context, _) {
          final language = context.read<LanguageCubit>();
          final experiences =
              (language.cvData['experiences'] as List? ?? const [])
                  .whereType<Map<String, dynamic>>()
                  .toList();

          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1100),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SceneAccentBuilder(
                    builder: (context, accent) => NumberedSectionHeading(
                      number: '02',
                      title: language.getText(
                        'experience_section.title',
                        defaultValue: 'Experience',
                      ),
                      accent: accent,
                    ),
                  ),
                  const SizedBox(height: 52),
                  for (var index = 0; index < experiences.length; index++)
                    SceneAccentBuilder(
                      builder: (context, accent) => _ExperienceEntry(
                        index: index,
                        experience: experiences[index],
                        accent: accent,
                        isLast: index == experiences.length - 1,
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      );
}

class _ExperienceEntry extends StatelessWidget {
  const _ExperienceEntry({
    required this.index,
    required this.experience,
    required this.accent,
    required this.isLast,
  });

  final int index;
  final Map<String, dynamic> experience;
  final Color accent;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final isCompact = width < Breakpoints.tablet;
    final period = (experience['period'] as String?)?.trim() ?? '';
    final title = (experience['title'] as String?)?.trim() ?? '';
    final position = (experience['position'] as String?)?.trim() ?? '';
    final company = (experience['company'] as String?)?.trim() ?? '';
    final description = (experience['description'] as String?)?.trim() ?? '';
    final technologies = (experience['technologies'] as List? ?? const [])
        .whereType<String>()
        .toList();

    final content = _ExperienceContent(
      title: title,
      position: position,
      company: company,
      description: description,
      technologies: technologies,
      accent: accent,
    );

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: isCompact ? 38 : 54,
            child: Column(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                    border: Border.all(color: accent.withValues(alpha: 0.5)),
                  ),
                  child: Text(
                    (index + 1).toString().padLeft(2, '0'),
                    style: AppFonts.jetBrainsMono(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      color: accent,
                    ),
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 1,
                      margin: const EdgeInsets.symmetric(vertical: 10),
                      color: Colors.white.withValues(alpha: 0.1),
                    ),
                  ),
              ],
            ),
          ),
          SizedBox(width: isCompact ? 14 : 28),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 58),
              child: isCompact
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _Period(period: period, accent: accent),
                        const SizedBox(height: 14),
                        content,
                      ],
                    )
                  : Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: 210,
                          child: _Period(period: period, accent: accent),
                        ),
                        const SizedBox(width: 34),
                        Expanded(child: content),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Period extends StatelessWidget {
  const _Period({required this.period, required this.accent});

  final String period;
  final Color accent;

  @override
  Widget build(BuildContext context) => Text(
    period,
    style: AppFonts.jetBrainsMono(
      fontSize: 11,
      fontWeight: FontWeight.w600,
      color: accent,
      letterSpacing: 0.7,
      height: 1.5,
    ),
  );
}

class _ExperienceContent extends StatelessWidget {
  const _ExperienceContent({
    required this.title,
    required this.position,
    required this.company,
    required this.description,
    required this.technologies,
    required this.accent,
  });

  final String title;
  final String position;
  final String company;
  final String description;
  final List<String> technologies;
  final Color accent;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        title,
        style: AppFonts.spaceGrotesk(
          fontSize: 27,
          fontWeight: FontWeight.w700,
          color: AppColors.textBright,
          height: 1.15,
          letterSpacing: -0.5,
        ),
      ),
      const SizedBox(height: 8),
      Text(
        '$position · $company',
        style: AppFonts.spaceGrotesk(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: AppColors.textPrimary,
          height: 1.4,
        ),
      ),
      const SizedBox(height: 18),
      Text(description, style: AppTypography.body.copyWith(height: 1.7)),
      if (technologies.isNotEmpty) ...[
        const SizedBox(height: 22),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final technology in technologies)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 11,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.07),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: accent.withValues(alpha: 0.16)),
                ),
                child: Text(
                  technology,
                  style: AppFonts.jetBrainsMono(
                    fontSize: 10,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
          ],
        ),
      ],
    ],
  );
}
