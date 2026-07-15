import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_web_portfolio/app/core/constants/app_colors.dart';
import 'package:flutter_web_portfolio/app/core/constants/breakpoints.dart';
import 'package:flutter_web_portfolio/app/core/theme/app_fonts.dart';
import 'package:flutter_web_portfolio/app/core/theme/app_typography.dart';
import 'package:flutter_web_portfolio/app/features/language/application/language_cubit.dart';
import 'package:flutter_web_portfolio/app/widgets/numbered_section_heading.dart';
import 'package:flutter_web_portfolio/app/widgets/scene_accent_builder.dart';

/// Practical principles presented as one continuous reading sequence.
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
            SceneAccentBuilder(
              builder: (context, accent) => NumberedSectionHeading(
                number: '03',
                title: language.getText(
                  'proof_section.title',
                  defaultValue: 'How I Work',
                ),
                accent: accent,
              ),
            ),
            const SizedBox(height: 18),
            ConstrainedBox(
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
            const SizedBox(height: 48),
            SceneAccentBuilder(
              builder: (context, accent) => Column(
                children: [
                  for (var index = 0; index < principles.length; index++)
                    _PrincipleRow(
                      principle: principles[index],
                      index: index,
                      accent: accent,
                      isLast: index == principles.length - 1,
                    ),
                ],
              ),
            ),
          ],
        ),
      );
    },
  );
}

class _PrincipleRow extends StatelessWidget {
  const _PrincipleRow({
    required this.principle,
    required this.index,
    required this.accent,
    required this.isLast,
  });

  final Map<String, dynamic> principle;
  final int index;
  final Color accent;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final title = principle['title'] as String? ?? '';
    final detail = principle['detail'] as String? ?? '';
    final note = principle['verification'] as String? ?? '';
    final compact = MediaQuery.sizeOf(context).width < Breakpoints.tablet;

    final number = Text(
      '${index + 1}'.padLeft(2, '0'),
      style: AppFonts.jetBrainsMono(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: accent,
        letterSpacing: 0.8,
      ),
    );
    final heading = Text(
      title,
      style: AppFonts.spaceGrotesk(
        fontSize: compact ? 24 : 28,
        fontWeight: FontWeight.w700,
        color: AppColors.textBright,
        height: 1.2,
        letterSpacing: -0.45,
      ),
    );
    final body = Text(detail, style: AppTypography.body.copyWith(height: 1.7));
    final caption = Text(
      note,
      style: AppFonts.jetBrainsMono(
        fontSize: 10,
        color: AppColors.textSecondary,
        height: 1.5,
      ),
    );

    return Semantics(
      container: true,
      label: '$title. $detail',
      child: ExcludeSemantics(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 34),
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
              bottom: isLast
                  ? BorderSide(color: Colors.white.withValues(alpha: 0.1))
                  : BorderSide.none,
            ),
          ),
          child: compact
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    number,
                    const SizedBox(height: 18),
                    heading,
                    const SizedBox(height: 14),
                    body,
                    if (note.isNotEmpty) ...[
                      const SizedBox(height: 18),
                      caption,
                    ],
                  ],
                )
              : Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(width: 70, child: number),
                    SizedBox(width: 280, child: heading),
                    const SizedBox(width: 34),
                    Expanded(child: body),
                    if (note.isNotEmpty) ...[
                      const SizedBox(width: 34),
                      SizedBox(width: 150, child: caption),
                    ],
                  ],
                ),
        ),
      ),
    );
  }
}
