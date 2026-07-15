import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_web_portfolio/app/core/constants/app_colors.dart';
import 'package:flutter_web_portfolio/app/core/constants/breakpoints.dart';
import 'package:flutter_web_portfolio/app/core/constants/durations.dart';
import 'package:flutter_web_portfolio/app/core/theme/app_fonts.dart';
import 'package:flutter_web_portfolio/app/core/theme/app_typography.dart';
import 'package:flutter_web_portfolio/app/features/language/application/language_cubit.dart';
import 'package:flutter_web_portfolio/app/widgets/numbered_section_heading.dart';
import 'package:flutter_web_portfolio/app/widgets/scroll_fade_in.dart';
import 'package:flutter_web_portfolio/app/widgets/scene_accent_builder.dart';

/// Personal, professional context without publishing private identity details.
class AboutSection extends StatelessWidget {
  const AboutSection({super.key});

  @override
  Widget build(BuildContext context) =>
      BlocBuilder<LanguageCubit, LanguageState>(
        builder: (context, _) {
          final language = context.read<LanguageCubit>();
          final personal =
              language.cvData['personal_info'] as Map<String, dynamic>? ??
              const <String, dynamic>{};
          final skills = (language.cvData['skills'] as List? ?? const [])
              .whereType<Map<String, dynamic>>()
              .toList();

          return ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1100),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final stacked = constraints.maxWidth < Breakpoints.desktop;
                final biography = _Biography(
                  personal: personal,
                  language: language,
                );
                final skillSummary = _SkillSummary(skills: skills);

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ScrollFadeIn(
                      child: SceneAccentBuilder(
                        builder: (context, accent) => NumberedSectionHeading(
                          number: '01',
                          title: language.getText(
                            'about_section.title',
                            defaultValue: 'About Me',
                          ),
                          accent: accent,
                        ),
                      ),
                    ),
                    const SizedBox(height: 36),
                    if (stacked)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          biography,
                          const SizedBox(height: 32),
                          skillSummary,
                        ],
                      )
                    else
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(flex: 5, child: biography),
                          const SizedBox(width: 64),
                          Expanded(flex: 4, child: skillSummary),
                        ],
                      ),
                  ],
                );
              },
            ),
          );
        },
      );
}

class _Biography extends StatelessWidget {
  const _Biography({required this.personal, required this.language});

  final Map<String, dynamic> personal;
  final LanguageCubit language;

  @override
  Widget build(BuildContext context) => ScrollFadeIn(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          personal['bio'] as String? ??
              language.getText(
                'about_section.bio',
                defaultValue:
                    'I build production Flutter applications across mobile, desktop, and web.',
              ),
          style: AppFonts.spaceGrotesk(
            fontSize: 27,
            fontWeight: FontWeight.w500,
            color: AppColors.textBright,
            height: 1.45,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 24),
        Text(
          language.getText(
            'about_section.bio2',
            defaultValue:
                'Alongside client work, I design and operate independent SaaS products end to end.',
          ),
          style: AppTypography.body.copyWith(height: 1.75),
        ),
      ],
    ),
  );
}

class _SkillSummary extends StatelessWidget {
  const _SkillSummary({required this.skills});

  final List<Map<String, dynamic>> skills;

  @override
  Widget build(BuildContext context) => ScrollFadeIn(
    delay: AppDurations.staggerMedium,
    child: SceneAccentBuilder(
      builder: (context, accent) => Container(
        padding: const EdgeInsets.all(26),
        decoration: BoxDecoration(
          color: AppColors.backgroundLight.withValues(alpha: 0.68),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: Colors.white.withValues(alpha: 0.09)),
        ),
        child: Column(
          children: [
            for (var index = 0; index < skills.length; index++) ...[
              _SkillRow(skill: skills[index], accent: accent),
              if (index < skills.length - 1)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  child: Divider(
                    height: 1,
                    color: Colors.white.withValues(alpha: 0.07),
                  ),
                ),
            ],
          ],
        ),
      ),
    ),
  );
}

class _SkillRow extends StatelessWidget {
  const _SkillRow({required this.skill, required this.accent});

  final Map<String, dynamic> skill;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final category = skill['category'] as String? ?? '';
    final items = (skill['items'] as List? ?? const [])
        .whereType<String>()
        .take(4)
        .join(' · ');

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 7,
          height: 7,
          margin: const EdgeInsets.only(top: 7),
          decoration: BoxDecoration(color: accent, shape: BoxShape.circle),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                category,
                style: AppFonts.spaceGrotesk(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textBright,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                items,
                style: AppFonts.jetBrainsMono(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                  height: 1.55,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
