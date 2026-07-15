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

/// Three practical principles that describe how the work gets done.
class ProofSection extends StatelessWidget {
  const ProofSection({super.key});

  @override
  Widget build(
    BuildContext context,
  ) => BlocBuilder<LanguageCubit, LanguageState>(
    builder: (context, _) {
      final language = context.read<LanguageCubit>();
      final principles = (language.cvData['proof'] as List? ?? const [])
          .whereType<Map<String, dynamic>>()
          .toList();
      if (principles.isEmpty) return const SizedBox.shrink();

      return ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ScrollFadeIn(
              child: SceneAccentBuilder(
                builder: (context, accent) => NumberedSectionHeading(
                  number: '03',
                  title: language.getText(
                    'proof_section.title',
                    defaultValue: 'How I Work',
                  ),
                  accent: accent,
                ),
              ),
            ),
            const SizedBox(height: 18),
            ScrollFadeIn(
              delay: AppDurations.staggerShort,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 650),
                child: Text(
                  language.getText(
                    'proof_section.subtitle',
                    defaultValue:
                        'A practical approach shaped by shipping and maintaining real products.',
                  ),
                  style: AppTypography.body.copyWith(height: 1.65),
                ),
              ),
            ),
            const SizedBox(height: 36),
            _PrincipleGrid(principles: principles),
          ],
        ),
      );
    },
  );
}

class _PrincipleGrid extends StatelessWidget {
  const _PrincipleGrid({required this.principles});

  final List<Map<String, dynamic>> principles;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      const gap = 18.0;
      final columns = constraints.maxWidth >= Breakpoints.desktop
          ? 3
          : constraints.maxWidth >= Breakpoints.tablet
          ? 2
          : 1;
      final width = (constraints.maxWidth - gap * (columns - 1)) / columns;

      return Wrap(
        spacing: gap,
        runSpacing: gap,
        children: [
          for (var index = 0; index < principles.length; index++)
            SizedBox(
              width: width,
              child: ScrollFadeIn(
                delay: Duration(milliseconds: 70 * index),
                child: _PrincipleCard(
                  principle: principles[index],
                  index: index,
                ),
              ),
            ),
        ],
      );
    },
  );
}

class _PrincipleCard extends StatelessWidget {
  const _PrincipleCard({required this.principle, required this.index});

  final Map<String, dynamic> principle;
  final int index;

  @override
  Widget build(BuildContext context) {
    final title = principle['title'] as String? ?? '';
    final detail = principle['detail'] as String? ?? '';
    final note = principle['verification'] as String? ?? '';

    return SceneAccentBuilder(
      builder: (context, accent) => Semantics(
        container: true,
        label: '$title. $detail',
        child: ExcludeSemantics(
          child: Container(
            constraints: const BoxConstraints(minHeight: 250),
            padding: const EdgeInsets.all(26),
            decoration: BoxDecoration(
              color: AppColors.backgroundLight.withValues(alpha: 0.62),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${index + 1}'.padLeft(2, '0'),
                  style: AppFonts.jetBrainsMono(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: accent,
                  ),
                ),
                const SizedBox(height: 28),
                Text(
                  title,
                  style: AppFonts.spaceGrotesk(
                    fontSize: 21,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textBright,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  detail,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textPrimary,
                    height: 1.65,
                  ),
                ),
                if (note.isNotEmpty) ...[
                  const SizedBox(height: 28),
                  Text(
                    note,
                    style: AppFonts.jetBrainsMono(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
