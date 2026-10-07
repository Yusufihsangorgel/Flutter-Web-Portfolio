part of '../proof_section.dart';

class _FeaturedContribution extends StatelessWidget {
  const _FeaturedContribution({
    required this.contribution,
    required this.accent,
    this.anchorKey,
  });

  final PortfolioContribution contribution;
  final Color accent;
  final Key? anchorKey;

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < Breakpoints.tablet;
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
            context.strings.proofSectionFeaturedLabel.toUpperCase(),
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
            _metadataAndLink(context),
            const SizedBox(height: 28),
            _story(context),
          ] else
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(width: 196, child: _metadataAndLink(context)),
                const SizedBox(width: 58),
                Expanded(child: _story(context)),
              ],
            ),
          if (contribution.eventOrderLab != null) ...[
            SizedBox(height: compact ? 46 : 64),
            ContributionEventOrderLab(
              lab: contribution.eventOrderLab!,
              accent: accent,
            ),
          ],
        ],
      ),
    );
  }

  Widget _metadataAndLink(BuildContext context) {
    final metadata = _ContributionMetadata(
      contribution: contribution,
      statusLabel: _statusLabel(context, contribution),
      accent: accent,
      anchorKey: anchorKey,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        metadata,
        const SizedBox(height: 24),
        _OpenPullRequest(
          contribution: contribution,
          label: context.strings.proofSectionOpenPullRequest,
          statusLabel: _statusLabel(context, contribution),
          accent: accent,
        ),
      ],
    );
  }

  Widget _story(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < Breakpoints.tablet;
    return Column(
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
        _storyColumns(context),
      ],
    );
  }

  Widget _storyColumns(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final columns = constraints.maxWidth >= 680;
      final problem = _StoryColumn(
        label: context.strings.proofSectionProblemLabel,
        body: contribution.problem,
        accent: accent,
      );
      final change = _StoryColumn(
        label: context.strings.proofSectionChangeLabel,
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
  );
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
    this.anchorKey,
  });

  final PortfolioContribution contribution;
  final String statusLabel;
  final Color accent;
  final Key? anchorKey;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _SignalDot(accent: accent, anchorKey: anchorKey),
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
        '$statusLabel\n${sectionDateLabel(contribution.date)}',
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
