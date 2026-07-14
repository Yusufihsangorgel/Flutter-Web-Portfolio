import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_web_portfolio/app/core/theme/app_fonts.dart';

import 'package:flutter_web_portfolio/app/core/constants/app_colors.dart';
import 'package:flutter_web_portfolio/app/core/constants/breakpoints.dart';
import 'package:flutter_web_portfolio/app/core/constants/durations.dart';
import 'package:flutter_web_portfolio/app/core/theme/app_typography.dart';
import 'package:flutter_web_portfolio/app/features/language/application/language_cubit.dart';
import 'package:flutter_web_portfolio/app/utils/responsive_utils.dart';
import 'package:flutter_web_portfolio/app/widgets/border_light_card.dart';
import 'package:flutter_web_portfolio/app/widgets/numbered_section_heading.dart';
import 'package:flutter_web_portfolio/app/widgets/scroll_fade_in.dart';
import 'package:flutter_web_portfolio/app/widgets/scene_accent_builder.dart';

/// Inspectable engineering evidence, sourced from this repository.
///
/// This section deliberately avoids endorsements and vanity metrics. Each card
/// describes a property a reviewer can verify in the build, tests, runtime lab,
/// or server configuration.
class ProofSection extends StatelessWidget {
  const ProofSection({super.key});

  @override
  Widget build(BuildContext context) {
    final language = context.read<LanguageCubit>();
    final screenWidth = MediaQuery.sizeOf(context).width;

    return BlocBuilder<LanguageCubit, LanguageState>(
      builder: (context, _) {
        final raw = language.cvData['proof'] as List? ?? const [];
        final evidence = raw.whereType<Map<String, dynamic>>().toList();
        if (evidence.isEmpty) return const SizedBox.shrink();

        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1100),
            child: Stack(
              children: [
                Positioned(
                  top: -20,
                  left: -10,
                  child: Text(
                    language
                        .getText('nav.proof', defaultValue: 'Proof')
                        .toUpperCase(),
                    style: AppFonts.spaceGrotesk(
                      fontSize: ResponsiveUtils.getValueForScreenType<double>(
                        context: context,
                        mobile: 36,
                        tablet: screenWidth * 0.10,
                        desktop: screenWidth * 0.12,
                      ),
                      fontWeight: FontWeight.w800,
                      color: Colors.white.withValues(alpha: 0.03),
                      letterSpacing: -3,
                    ),
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 40),
                    ScrollFadeIn(
                      child: SceneAccentBuilder(
                        builder: (context, accent) => NumberedSectionHeading(
                          number: '03',
                          title: language.getText(
                            'proof_section.title',
                            defaultValue: 'Engineering Proof',
                          ),
                          accent: accent,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    ScrollFadeIn(
                      delay: AppDurations.staggerShort,
                      child: Text(
                        language.getText(
                          'proof_section.subtitle',
                          defaultValue:
                              'Claims you can inspect in the repository and the live runtime',
                        ),
                        style: AppTypography.body,
                      ),
                    ),
                    const SizedBox(height: 40),
                    _ProofGrid(evidence: evidence),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ProofGrid extends StatelessWidget {
  const _ProofGrid({required this.evidence});

  final List<Map<String, dynamic>> evidence;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final columns = width >= Breakpoints.desktop
        ? 3
        : width >= Breakpoints.tablet
        ? 2
        : 1;

    return LayoutBuilder(
      builder: (context, constraints) {
        const gap = 20.0;
        final cardWidth =
            (constraints.maxWidth - (columns - 1) * gap) / columns;

        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (var index = 0; index < evidence.length; index++)
              SizedBox(
                width: cardWidth,
                child: ScrollFadeIn(
                  delay: Duration(milliseconds: 70 * index),
                  child: _ProofCard(evidence: evidence[index], index: index),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _ProofCard extends StatelessWidget {
  const _ProofCard({required this.evidence, required this.index});

  final Map<String, dynamic> evidence;
  final int index;

  static const _icons = <IconData>[
    Icons.account_tree_outlined,
    Icons.speed_outlined,
    Icons.security_outlined,
  ];

  @override
  Widget build(BuildContext context) {
    final title = evidence['title'] as String? ?? '';
    final detail = evidence['detail'] as String? ?? '';
    final verification = evidence['verification'] as String? ?? '';

    return SceneAccentBuilder(
      builder: (context, accent) => Semantics(
        container: true,
        label: '$title. $detail. $verification',
        child: ExcludeSemantics(
          child: BorderLightCard(
            glowColor: accent,
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 240),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: accent.withValues(alpha: 0.24)),
                    ),
                    child: Icon(
                      _icons[index % _icons.length],
                      color: accent,
                      size: 22,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    title,
                    style: AppFonts.spaceGrotesk(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textBright,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    detail,
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textPrimary,
                      height: 1.6,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.07),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      verification,
                      style: AppTypography.caption.copyWith(
                        color: accent,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
