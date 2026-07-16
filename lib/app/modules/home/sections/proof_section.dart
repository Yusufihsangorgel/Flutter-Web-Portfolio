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

/// Verified upstream work presented as one editorial case and a compact ledger.
class ProofSection extends StatelessWidget {
  const ProofSection({super.key});

  @override
  Widget build(
    BuildContext context,
  ) => BlocBuilder<LanguageCubit, LanguageState>(
    builder: (context, _) {
      final language = context.read<LanguageCubit>();
      final portfolio = context.read<PortfolioDocument>();
      if (portfolio.contributions.isEmpty) {
        return const SizedBox.shrink();
      }

      final featured = portfolio.featuredContribution;
      final accepted = portfolio.mergedContributions
          .where((entry) => !entry.featured)
          .toList(growable: false);
      final inReview = portfolio.contributionsUnderReview
          .where((entry) => !entry.featured)
          .toList(growable: false);
      final mergedCount = portfolio.mergedContributions.length;
      final reviewCount = portfolio.contributionsUnderReview.length;
      final summary = language
          .getText(
            'proof_section.summary',
            defaultValue:
                '{merged} changes accepted upstream; {review} more under review.',
          )
          .replaceAll('{merged}', '$mergedCount')
          .replaceAll('{review}', '$reviewCount');
      final openLabel = language.getText(
        'proof_section.open_pull_request',
        defaultValue: 'View pull request',
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
              constraints: const BoxConstraints(maxWidth: 650),
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (featured != null)
                    _FeaturedContribution(
                      contribution: featured,
                      accent: accent,
                      eyebrow: language.getText(
                        'proof_section.featured_label',
                        defaultValue: 'Featured contribution',
                      ),
                      problemLabel: language.getText(
                        'proof_section.problem_label',
                        defaultValue: 'The failure',
                      ),
                      changeLabel: language.getText(
                        'proof_section.change_label',
                        defaultValue: 'The patch',
                      ),
                      statusLabel: _statusLabel(language, featured),
                      openLabel: openLabel,
                    ),
                  if (accepted.isNotEmpty) ...[
                    SizedBox(height: featured == null ? 0 : 92),
                    _ContributionLedger(
                      title: language.getText(
                        'proof_section.accepted_title',
                        defaultValue: 'Accepted upstream',
                      ),
                      entries: accepted,
                      accent: accent,
                      openLabel: openLabel,
                      statusLabel: (entry) => _statusLabel(language, entry),
                    ),
                  ],
                  if (inReview.isNotEmpty) ...[
                    const SizedBox(height: 72),
                    _ContributionLedger(
                      title: language.getText(
                        'proof_section.review_title',
                        defaultValue: 'In review',
                      ),
                      entries: inReview,
                      accent: accent,
                      openLabel: openLabel,
                      statusLabel: (entry) => _statusLabel(language, entry),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      );
    },
  );
}

String _statusLabel(
  LanguageCubit language,
  PortfolioContribution contribution,
) => language.getText(
  contribution.status == ContributionStatus.merged
      ? 'proof_section.status_merged'
      : 'proof_section.status_under_review',
  defaultValue: contribution.status == ContributionStatus.merged
      ? 'Merged'
      : 'Under review',
);

class _FeaturedContribution extends StatelessWidget {
  const _FeaturedContribution({
    required this.contribution,
    required this.accent,
    required this.eyebrow,
    required this.problemLabel,
    required this.changeLabel,
    required this.statusLabel,
    required this.openLabel,
  });

  final PortfolioContribution contribution;
  final Color accent;
  final String eyebrow;
  final String problemLabel;
  final String changeLabel;
  final String statusLabel;
  final String openLabel;

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < Breakpoints.tablet;
    final metadata = _ContributionMetadata(
      contribution: contribution,
      statusLabel: statusLabel,
      accent: accent,
    );
    final metadataAndLink = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        metadata,
        const SizedBox(height: 24),
        _OpenPullRequest(
          contribution: contribution,
          label: openLabel,
          statusLabel: statusLabel,
          accent: accent,
        ),
      ],
    );
    final story = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          contribution.title,
          style: AppFonts.spaceGrotesk(
            fontSize: compact ? 36 : 54,
            fontWeight: FontWeight.w600,
            color: AppColors.textBright,
            height: 0.98,
            letterSpacing: compact ? -1.4 : -2.3,
          ),
        ),
        SizedBox(height: compact ? 34 : 48),
        LayoutBuilder(
          builder: (context, constraints) {
            final columns = constraints.maxWidth >= 680;
            final problem = _StoryColumn(
              label: problemLabel,
              body: contribution.problem,
              accent: accent,
            );
            final change = _StoryColumn(
              label: changeLabel,
              body: contribution.change,
              accent: accent,
            );
            if (!columns) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [problem, const SizedBox(height: 30), change],
              );
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: problem),
                const SizedBox(width: 48),
                Expanded(child: change),
              ],
            );
          },
        ),
      ],
    );

    return Container(
      padding: EdgeInsets.symmetric(vertical: compact ? 34 : 54),
      decoration: BoxDecoration(
        border: Border.symmetric(
          horizontal: BorderSide(color: accent.withValues(alpha: 0.34)),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            eyebrow.toUpperCase(),
            style: AppFonts.jetBrainsMono(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: accent,
              height: 1.4,
              letterSpacing: 1.4,
            ),
          ),
          SizedBox(height: compact ? 26 : 38),
          if (compact) ...[
            metadataAndLink,
            const SizedBox(height: 28),
            story,
          ] else
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(width: 196, child: metadataAndLink),
                const SizedBox(width: 58),
                Expanded(child: story),
              ],
            ),
        ],
      ),
    );
  }
}

class _StoryColumn extends StatelessWidget {
  const _StoryColumn({
    required this.label,
    required this.body,
    required this.accent,
  });

  final String label;
  final String body;
  final Color accent;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label.toUpperCase(),
        style: AppFonts.jetBrainsMono(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: accent,
          letterSpacing: 1.2,
        ),
      ),
      const SizedBox(height: 13),
      Text(
        body,
        style: AppFonts.inter(
          fontSize: 15,
          color: AppColors.textPrimary,
          height: 1.72,
        ),
      ),
    ],
  );
}

class _ContributionMetadata extends StatelessWidget {
  const _ContributionMetadata({
    required this.contribution,
    required this.statusLabel,
    required this.accent,
  });

  final PortfolioContribution contribution;
  final String statusLabel;
  final Color accent;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _SignalDot(accent: accent),
      const SizedBox(height: 18),
      Text(
        contribution.project,
        style: AppFonts.spaceGrotesk(
          fontSize: 17,
          fontWeight: FontWeight.w600,
          color: AppColors.textBright,
          height: 1.25,
        ),
      ),
      const SizedBox(height: 9),
      Text(
        '$statusLabel\n${_dateLabel(contribution.date)}',
        style: AppFonts.jetBrainsMono(
          fontSize: 10,
          color: AppColors.textSecondary,
          height: 1.65,
          letterSpacing: 0.7,
        ),
      ),
    ],
  );
}

class _ContributionLedger extends StatelessWidget {
  const _ContributionLedger({
    required this.title,
    required this.entries,
    required this.accent,
    required this.openLabel,
    required this.statusLabel,
  });

  final String title;
  final List<PortfolioContribution> entries;
  final Color accent;
  final String openLabel;
  final String Function(PortfolioContribution entry) statusLabel;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Semantics(
        header: true,
        headingLevel: 3,
        child: Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 12,
          children: [
            Text(
              title,
              style: AppFonts.spaceGrotesk(
                fontSize: 24,
                fontWeight: FontWeight.w600,
                color: AppColors.textBright,
                letterSpacing: -0.5,
              ),
            ),
            Text(
              entries.length.toString().padLeft(2, '0'),
              style: AppFonts.instrumentSerif(
                fontSize: 17,
                fontStyle: FontStyle.italic,
                color: accent,
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 24),
      for (var index = 0; index < entries.length; index++)
        _LedgerRow(
          index: index + 1,
          contribution: entries[index],
          statusLabel: statusLabel(entries[index]),
          openLabel: openLabel,
          accent: accent,
          isLast: index == entries.length - 1,
        ),
    ],
  );
}

class _LedgerRow extends StatelessWidget {
  const _LedgerRow({
    required this.index,
    required this.contribution,
    required this.statusLabel,
    required this.openLabel,
    required this.accent,
    required this.isLast,
  });

  final int index;
  final PortfolioContribution contribution;
  final String statusLabel;
  final String openLabel;
  final Color accent;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < Breakpoints.tablet;
    final semanticLabel = [
      openLabel,
      contribution.title,
      contribution.project,
      statusLabel,
      _dateLabel(contribution.date),
    ].join('. ');

    return CinematicFocusable(
      onTap: () => _openEvidence(contribution.url),
      semanticLabel: semanticLabel,
      semanticRole: CinematicControlRole.link,
      focusColor: accent,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: compact ? 25 : 27),
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(
              color: AppColors.textSecondary.withValues(alpha: 0.3),
            ),
            bottom: isLast
                ? BorderSide(
                    color: AppColors.textSecondary.withValues(alpha: 0.3),
                  )
                : BorderSide.none,
          ),
        ),
        child: compact
            ? _CompactLedgerContent(
                index: index,
                contribution: contribution,
                statusLabel: statusLabel,
                accent: accent,
              )
            : _WideLedgerContent(
                index: index,
                contribution: contribution,
                statusLabel: statusLabel,
                accent: accent,
              ),
      ),
    );
  }
}

class _WideLedgerContent extends StatelessWidget {
  const _WideLedgerContent({
    required this.index,
    required this.contribution,
    required this.statusLabel,
    required this.accent,
  });

  final int index;
  final PortfolioContribution contribution;
  final String statusLabel;
  final Color accent;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.center,
    children: [
      SizedBox(
        width: 54,
        child: Text(
          index.toString().padLeft(2, '0'),
          style: AppFonts.jetBrainsMono(
            fontSize: 10,
            color: accent,
            letterSpacing: 0.8,
          ),
        ),
      ),
      SizedBox(
        width: 184,
        child: Text(
          contribution.project,
          style: AppFonts.spaceGrotesk(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
      ),
      Expanded(
        child: Text(
          contribution.title,
          style: AppFonts.spaceGrotesk(
            fontSize: 20,
            fontWeight: FontWeight.w500,
            color: AppColors.textBright,
            height: 1.25,
            letterSpacing: -0.35,
          ),
        ),
      ),
      const SizedBox(width: 32),
      SizedBox(
        width: 116,
        child: Text(
          statusLabel,
          style: AppFonts.jetBrainsMono(
            fontSize: 10,
            color: AppColors.textSecondary,
            letterSpacing: 0.6,
          ),
        ),
      ),
      SizedBox(
        width: 96,
        child: Text(
          _dateLabel(contribution.date),
          textAlign: TextAlign.end,
          style: AppFonts.jetBrainsMono(
            fontSize: 10,
            color: AppColors.textSecondary,
          ),
        ),
      ),
      const SizedBox(width: 18),
      Icon(Icons.north_east_rounded, size: 17, color: accent),
    ],
  );
}

class _CompactLedgerContent extends StatelessWidget {
  const _CompactLedgerContent({
    required this.index,
    required this.contribution,
    required this.statusLabel,
    required this.accent,
  });

  final int index;
  final PortfolioContribution contribution;
  final String statusLabel;
  final Color accent;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          Text(
            index.toString().padLeft(2, '0'),
            style: AppFonts.jetBrainsMono(fontSize: 10, color: accent),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              contribution.project,
              style: AppFonts.jetBrainsMono(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
                letterSpacing: 0.6,
              ),
            ),
          ),
          Icon(Icons.north_east_rounded, size: 16, color: accent),
        ],
      ),
      const SizedBox(height: 15),
      Text(
        contribution.title,
        style: AppFonts.spaceGrotesk(
          fontSize: 22,
          fontWeight: FontWeight.w500,
          color: AppColors.textBright,
          height: 1.2,
          letterSpacing: -0.45,
        ),
      ),
      const SizedBox(height: 14),
      Text(
        '$statusLabel · ${_dateLabel(contribution.date)}',
        style: AppFonts.jetBrainsMono(
          fontSize: 10,
          color: AppColors.textSecondary,
          height: 1.4,
        ),
      ),
    ],
  );
}

class _OpenPullRequest extends StatelessWidget {
  const _OpenPullRequest({
    required this.contribution,
    required this.label,
    required this.statusLabel,
    required this.accent,
  });

  final PortfolioContribution contribution;
  final String label;
  final String statusLabel;
  final Color accent;

  @override
  Widget build(BuildContext context) => CinematicFocusable(
    onTap: () => _openEvidence(contribution.url),
    semanticLabel:
        '$label. ${contribution.title}. ${contribution.project}. $statusLabel.',
    semanticRole: CinematicControlRole.link,
    focusColor: accent,
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
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
    ),
  );
}

class _SignalDot extends StatelessWidget {
  const _SignalDot({required this.accent});

  final Color accent;

  @override
  Widget build(BuildContext context) => Container(
    width: 8,
    height: 8,
    decoration: BoxDecoration(color: accent, shape: BoxShape.circle),
  );
}

String _dateLabel(DateTime date) => [
  date.year.toString().padLeft(4, '0'),
  date.month.toString().padLeft(2, '0'),
  date.day.toString().padLeft(2, '0'),
].join('—');

Future<void> _openEvidence(Uri uri) async =>
    launchUrl(uri, webOnlyWindowName: '_blank');
