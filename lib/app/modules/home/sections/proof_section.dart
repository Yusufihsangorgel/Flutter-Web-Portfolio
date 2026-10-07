import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_web_portfolio/app/controllers/scroll_controller.dart';
import 'package:flutter_web_portfolio/app/core/constants/app_colors.dart';
import 'package:flutter_web_portfolio/app/core/constants/breakpoints.dart';
import 'package:flutter_web_portfolio/app/core/theme/app_fonts.dart';
import 'package:flutter_web_portfolio/app/domain/models/portfolio_document.dart'
    hide PortfolioLink;
import 'package:flutter_web_portfolio/app/features/language/application/language_context.dart';
import 'package:flutter_web_portfolio/app/modules/home/sections/section_style.dart';
import 'package:flutter_web_portfolio/app/modules/home/sections/proof/widgets/contribution_event_order_lab.dart';
import 'package:flutter_web_portfolio/app/narrative/domain/narrative_document.dart';
import 'package:flutter_web_portfolio/app/widgets/portfolio_link.dart';
import 'package:flutter_web_portfolio/app/widgets/numbered_section_heading.dart';
import 'package:flutter_web_portfolio/app/widgets/scene_accent_builder.dart';

part 'proof/featured_contribution.dart';
part 'proof/contribution_ledger.dart';

class ProofSection extends StatelessWidget {
  const ProofSection({super.key});

  @override
  Widget build(BuildContext context) {
    final portfolio = context.read<PortfolioDocument>();
    if (portfolio.contributions.isEmpty) return const SizedBox.shrink();
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
              title: context.strings.proofSectionTitle,
              accent: accent,
            ),
          ),
          const SizedBox(height: 30),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 650),
            child: Text(
              _summary(context, portfolio),
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
            builder: (context, accent) =>
                _ProofEntries(portfolio: portfolio, accent: accent),
          ),
        ],
      ),
    );
  }

  String _summary(BuildContext context, PortfolioDocument portfolio) {
    final merged = portfolio.mergedContributions.length;
    final review = portfolio.contributionsUnderReview.length;
    final strings = context.strings;
    if (merged == 0) {
      return strings.proofSectionSummaryReview(review: '$review');
    }
    if (review == 0) {
      return strings.proofSectionSummaryAccepted(merged: '$merged');
    }
    return strings.proofSectionSummary(merged: '$merged', review: '$review');
  }
}

class _ProofEntries extends StatelessWidget {
  const _ProofEntries({required this.portfolio, required this.accent});

  final PortfolioDocument portfolio;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final featured = portfolio.featuredContribution;
    final accepted = portfolio.mergedContributions
        .where((entry) => entry != featured)
        .toList(growable: false);
    final review = portfolio.contributionsUnderReview
        .where((entry) => entry != featured)
        .toList(growable: false);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (featured != null)
          _FeaturedContribution(
            contribution: featured,
            accent: accent,
            anchorKey: context.read<AppScrollController>().anchorKeyFor(
              SectionId.proof,
            ),
          ),
        if (accepted.isNotEmpty) ...[
          SizedBox(height: featured == null ? 0 : 92),
          _ContributionLedger(
            title: context.strings.proofSectionAcceptedTitle,
            entries: accepted,
            accent: accent,
          ),
        ],
        if (review.isNotEmpty) ...[
          const SizedBox(height: 72),
          _ContributionLedger(
            title: context.strings.proofSectionReviewTitle,
            entries: review,
            accent: accent,
          ),
        ],
      ],
    );
  }
}

String _statusLabel(BuildContext context, PortfolioContribution contribution) =>
    contribution.status == ContributionStatus.merged
    ? context.strings.proofSectionStatusMerged
    : context.strings.proofSectionStatusUnderReview;
