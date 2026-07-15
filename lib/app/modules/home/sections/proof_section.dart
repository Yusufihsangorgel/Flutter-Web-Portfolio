import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_web_portfolio/app/core/constants/app_colors.dart';
import 'package:flutter_web_portfolio/app/core/constants/breakpoints.dart';
import 'package:flutter_web_portfolio/app/core/theme/app_fonts.dart';
import 'package:flutter_web_portfolio/app/domain/models/portfolio_document.dart';
import 'package:flutter_web_portfolio/app/features/language/application/language_cubit.dart';
import 'package:flutter_web_portfolio/app/narrative/domain/narrative_document.dart';
import 'package:flutter_web_portfolio/app/widgets/cinematic_focusable.dart';
import 'package:flutter_web_portfolio/app/widgets/numbered_section_heading.dart';
import 'package:flutter_web_portfolio/app/widgets/scene_accent_builder.dart';
import 'package:url_launcher/url_launcher.dart';

/// Verified upstream work, ordered from accepted patches to work in review.
class ProofSection extends StatelessWidget {
  const ProofSection({super.key});

  @override
  Widget build(BuildContext context) =>
      BlocBuilder<LanguageCubit, LanguageState>(
        builder: (context, _) {
          final language = context.read<LanguageCubit>();
          final portfolio = context.read<PortfolioDocument>();
          final contributions = portfolio.contributions;
          if (contributions.isEmpty) return const SizedBox.shrink();
          final merged = portfolio.mergedContributions.toList();
          final summary = merged.isEmpty
              ? language
                    .getText(
                      'proof_section.review_summary',
                      defaultValue: '{count} open-source changes under review.',
                    )
                    .replaceAll('{count}', '${contributions.length}')
              : language
                    .getText(
                      'proof_section.merged_summary',
                      defaultValue: '{count} merged changes across {projects}.',
                    )
                    .replaceAll('{count}', '${merged.length}')
                    .replaceAll(
                      '{projects}',
                      merged.map((entry) => entry.project).join(', '),
                    );

          return ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1160),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SceneAccentBuilder(
                  builder: (context, accent) => NumberedSectionHeading(
                    number: context.read<NarrativeDocument>().sectionNumber(
                      SectionId.proof,
                    ),
                    title: language.getText(
                      'proof_section.title',
                      defaultValue: 'Open Source',
                    ),
                    accent: accent,
                  ),
                ),
                const SizedBox(height: 30),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 720),
                  child: Text(
                    summary,
                    style: AppFonts.spaceGrotesk(
                      fontSize: 20,
                      fontWeight: FontWeight.w400,
                      color: AppColors.textPrimary,
                      height: 1.55,
                    ),
                  ),
                ),
                const SizedBox(height: 72),
                SceneAccentBuilder(
                  builder: (context, accent) => Column(
                    children: [
                      for (var index = 0; index < contributions.length; index++)
                        _PrinciplePlate(
                          contribution: contributions[index],
                          accent: accent,
                          isLast: index == contributions.length - 1,
                          statusLabel: language.getText(
                            contributions[index].status ==
                                    ContributionStatus.merged
                                ? 'proof_section.status_merged'
                                : 'proof_section.status_under_review',
                            defaultValue:
                                contributions[index].status ==
                                    ContributionStatus.merged
                                ? 'Merged'
                                : 'Under review',
                          ),
                          openLabel: language.getText(
                            'proof_section.open_pull_request',
                            defaultValue: 'View pull request',
                          ),
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

class _PrinciplePlate extends StatelessWidget {
  const _PrinciplePlate({
    required this.contribution,
    required this.accent,
    required this.isLast,
    required this.statusLabel,
    required this.openLabel,
  });

  final PortfolioContribution contribution;
  final Color accent;
  final bool isLast;
  final String statusLabel;
  final String openLabel;

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < Breakpoints.tablet;
    final title = contribution.title;
    final detail = contribution.problem;
    final verification = [
      contribution.project,
      statusLabel,
      contribution.date.toIso8601String().split('T').first,
    ].join(' · ');
    final action = contribution.change;

    final copy = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AppFonts.spaceGrotesk(
            fontSize: compact ? 29 : 38,
            fontWeight: FontWeight.w600,
            color: AppColors.textBright,
            height: 1.05,
            letterSpacing: -1.15,
          ),
        ),
        const SizedBox(height: 18),
        Text(
          detail,
          style: AppFonts.inter(
            fontSize: 15,
            color: AppColors.textPrimary,
            height: 1.72,
          ),
        ),
        const SizedBox(height: 18),
        Text(
          action,
          style: AppFonts.inter(
            fontSize: 15,
            color: AppColors.textBright,
            height: 1.72,
          ),
        ),
      ],
    );

    final verificationWidget = _EvidenceLink(
      title: title,
      verification: verification,
      url: contribution.url,
      accent: accent,
      openLabel: openLabel,
    );
    final plate = Container(
      padding: EdgeInsets.symmetric(vertical: compact ? 38 : 54),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: accent.withValues(alpha: 0.32)),
          bottom: isLast
              ? BorderSide(color: accent.withValues(alpha: 0.32))
              : BorderSide.none,
        ),
      ),
      child: compact
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [verificationWidget, const SizedBox(height: 28), copy],
            )
          : Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(width: 210, child: verificationWidget),
                const SizedBox(width: 72),
                Expanded(child: copy),
              ],
            ),
    );

    return plate;
  }
}

class _EvidenceLink extends StatelessWidget {
  const _EvidenceLink({
    required this.title,
    required this.verification,
    required this.url,
    required this.accent,
    required this.openLabel,
  });

  final String title;
  final String verification;
  final Uri url;
  final Color accent;
  final String openLabel;

  @override
  Widget build(BuildContext context) => CinematicFocusable(
    onTap: () => _openEvidence(url),
    semanticLabel: '$openLabel. $title. $verification',
    semanticRole: CinematicControlRole.link,
    focusColor: accent,
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Verification(value: verification, accent: accent),
          const SizedBox(height: 18),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                openLabel,
                style: AppFonts.spaceGrotesk(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: accent,
                  height: 1.4,
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.north_east_rounded, size: 15, color: accent),
            ],
          ),
        ],
      ),
    ),
  );
}

Future<void> _openEvidence(Uri uri) async =>
    launchUrl(uri, webOnlyWindowName: '_blank');

class _Verification extends StatelessWidget {
  const _Verification({required this.value, required this.accent});

  final String value;
  final Color accent;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Container(
        width: 7,
        height: 7,
        margin: const EdgeInsets.only(top: 4),
        decoration: BoxDecoration(color: accent, shape: BoxShape.circle),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: Text(
          value,
          style: AppFonts.spaceGrotesk(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: AppColors.textSecondary,
            height: 1.5,
            letterSpacing: 0.9,
          ),
        ),
      ),
    ],
  );
}
