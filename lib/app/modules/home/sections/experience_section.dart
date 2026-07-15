import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_web_portfolio/app/core/constants/app_colors.dart';
import 'package:flutter_web_portfolio/app/core/constants/breakpoints.dart';
import 'package:flutter_web_portfolio/app/core/theme/app_fonts.dart';
import 'package:flutter_web_portfolio/app/domain/models/portfolio_document.dart';
import 'package:flutter_web_portfolio/app/features/language/application/language_cubit.dart';
import 'package:flutter_web_portfolio/app/widgets/numbered_section_heading.dart';
import 'package:flutter_web_portfolio/app/widgets/scene_accent_builder.dart';

/// An editorial career ledger with every entry visible in document order.
class ExperienceSection extends StatelessWidget {
  const ExperienceSection({super.key});

  @override
  Widget build(BuildContext context) =>
      BlocBuilder<LanguageCubit, LanguageState>(
        builder: (context, _) {
          final language = context.read<LanguageCubit>();
          final experiences = context.read<PortfolioDocument>().experience;

          return ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1160),
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
                const SizedBox(height: 66),
                for (var index = 0; index < experiences.length; index++)
                  SceneAccentBuilder(
                    builder: (context, accent) => _ExperienceLedgerRow(
                      index: index,
                      experience: experiences[index],
                      accent: accent,
                      isLast: index == experiences.length - 1,
                    ),
                  ),
              ],
            ),
          );
        },
      );
}

class _ExperienceLedgerRow extends StatelessWidget {
  const _ExperienceLedgerRow({
    required this.index,
    required this.experience,
    required this.accent,
    required this.isLast,
  });

  final int index;
  final PortfolioExperience experience;
  final Color accent;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < Breakpoints.tablet;
    final period = experience.period;
    final title = experience.role;
    final position = experience.domain;
    final description = experience.summary;
    final technologies = experience.evidence.join(' / ');

    return Semantics(
      container: true,
      label: '$title. $position. $period. $description',
      child: ExcludeSemantics(
        child: Container(
          padding: EdgeInsets.symmetric(vertical: compact ? 34 : 42),
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(color: accent.withValues(alpha: 0.34)),
              bottom: isLast
                  ? BorderSide(color: accent.withValues(alpha: 0.34))
                  : BorderSide.none,
            ),
          ),
          child: compact
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _LedgerMeta(index: index, period: period, accent: accent),
                    const SizedBox(height: 26),
                    _LedgerRole(title: title, position: position),
                    const SizedBox(height: 22),
                    _LedgerDetail(
                      description: description,
                      technologies: technologies,
                    ),
                  ],
                )
              : Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 190,
                      child: _LedgerMeta(
                        index: index,
                        period: period,
                        accent: accent,
                      ),
                    ),
                    const SizedBox(width: 42),
                    SizedBox(
                      width: 310,
                      child: _LedgerRole(title: title, position: position),
                    ),
                    const SizedBox(width: 56),
                    Expanded(
                      child: _LedgerDetail(
                        description: description,
                        technologies: technologies,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

class _LedgerMeta extends StatelessWidget {
  const _LedgerMeta({
    required this.index,
    required this.period,
    required this.accent,
  });

  final int index;
  final String period;
  final Color accent;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        '${index + 1}'.padLeft(2, '0'),
        style: AppFonts.instrumentSerif(
          fontSize: 40,
          fontStyle: FontStyle.italic,
          color: accent,
          height: 0.8,
        ),
      ),
      const SizedBox(width: 18),
      Expanded(
        child: Text(
          period.toUpperCase(),
          style: AppFonts.jetBrainsMono(
            fontSize: 9,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
            letterSpacing: 0.65,
            height: 1.55,
          ),
        ),
      ),
    ],
  );
}

class _LedgerRole extends StatelessWidget {
  const _LedgerRole({required this.title, required this.position});

  final String title;
  final String position;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        title,
        style: AppFonts.instrumentSerif(
          fontSize: 36,
          fontStyle: FontStyle.italic,
          color: AppColors.textBright,
          height: 0.95,
          letterSpacing: -0.65,
        ),
      ),
      const SizedBox(height: 14),
      Text(
        position,
        style: AppFonts.spaceGrotesk(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
          height: 1.4,
        ),
      ),
    ],
  );
}

class _LedgerDetail extends StatelessWidget {
  const _LedgerDetail({required this.description, required this.technologies});

  final String description;
  final String technologies;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        description,
        style: AppFonts.inter(
          fontSize: 14,
          color: AppColors.textPrimary,
          height: 1.72,
        ),
      ),
      if (technologies.isNotEmpty) ...[
        const SizedBox(height: 22),
        Text(
          technologies.toUpperCase(),
          style: AppFonts.jetBrainsMono(
            fontSize: 9,
            color: AppColors.textSecondary,
            height: 1.55,
            letterSpacing: 0.45,
          ),
        ),
      ],
    ],
  );
}
