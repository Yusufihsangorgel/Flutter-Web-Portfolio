import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_web_portfolio/app/core/constants/app_colors.dart';
import 'package:flutter_web_portfolio/app/core/constants/breakpoints.dart';
import 'package:flutter_web_portfolio/app/core/theme/app_fonts.dart';
import 'package:flutter_web_portfolio/app/domain/models/portfolio_document.dart';
import 'package:flutter_web_portfolio/app/features/language/application/language_cubit.dart';
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
          final mergedSummary =
              '${merged.length} merged changes across '
              '${merged.map((entry) => entry.project).join(', ')}.';

          return ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1160),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SceneAccentBuilder(
                  builder: (context, accent) => NumberedSectionHeading(
                    number: '03',
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
                    mergedSummary,
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
                          index: index,
                          accent: accent,
                          isLast: index == contributions.length - 1,
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
    required this.index,
    required this.accent,
    required this.isLast,
  });

  final PortfolioContribution contribution;
  final int index;
  final Color accent;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < Breakpoints.tablet;
    final title = contribution.title;
    final detail = contribution.problem;
    final verification = [
      contribution.project,
      contribution.status.wireValue.replaceAll('_', ' '),
      contribution.date.toIso8601String().split('T').first,
    ].join(' · ');
    final action = contribution.change;

    final number = ExcludeSemantics(
      child: Text(
        '${index + 1}'.padLeft(2, '0'),
        style: AppFonts.instrumentSerif(
          fontSize: compact ? 68 : 96,
          fontStyle: FontStyle.italic,
          color: accent.withValues(alpha: 0.9),
          height: 0.72,
          letterSpacing: -3,
        ),
      ),
    );
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
              children: [
                number,
                const SizedBox(height: 32),
                copy,
                const SizedBox(height: 24),
                verificationWidget,
              ],
            )
          : Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(width: 170, child: number),
                Expanded(flex: 6, child: copy),
                const SizedBox(width: 70),
                SizedBox(width: 190, child: verificationWidget),
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
  });

  final String title;
  final String verification;
  final Uri url;
  final Color accent;

  @override
  Widget build(BuildContext context) => CinematicFocusable(
    onTap: () => _openEvidence(url),
    semanticLabel: 'Open pull request. $title. $verification',
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
                'PULL REQUEST',
                style: AppFonts.jetBrainsMono(
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  color: accent,
                  height: 1.4,
                  letterSpacing: 0.9,
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
          value.toUpperCase(),
          style: AppFonts.jetBrainsMono(
            fontSize: 9,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
            height: 1.5,
            letterSpacing: 0.9,
          ),
        ),
      ),
    ],
  );
}
