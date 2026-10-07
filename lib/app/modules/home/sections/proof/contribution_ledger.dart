part of '../proof_section.dart';

class _ContributionLedger extends StatelessWidget {
  const _ContributionLedger({
    required this.title,
    required this.entries,
    required this.accent,
  });

  final String title;
  final List<PortfolioContribution> entries;
  final Color accent;

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
              style: AppFonts.spaceGrotesk(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: accent,
                letterSpacing: 0.4,
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
    required this.accent,
    required this.isLast,
  });

  final int index;
  final PortfolioContribution contribution;
  final Color accent;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < Breakpoints.tablet;
    final statusLabel = _statusLabel(context, contribution);
    final semanticLabel = [
      context.strings.proofSectionOpenPullRequest,
      contribution.title,
      contribution.project,
      statusLabel,
      sectionDateLabel(contribution.date),
    ].join('. ');

    return PortfolioLink(
      uri: contribution.url,
      semanticLabel: semanticLabel,
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
          sectionDateLabel(contribution.date),
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
        '$statusLabel · ${sectionDateLabel(contribution.date)}',
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
  Widget build(BuildContext context) => PortfolioLink(
    uri: contribution.url,
    semanticLabel:
        '$label. ${contribution.title}. ${contribution.project}. $statusLabel.',
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
  const _SignalDot({required this.accent, this.anchorKey});

  final Color accent;
  final Key? anchorKey;

  @override
  Widget build(BuildContext context) => KeyedSubtree(
    key: anchorKey,
    child: Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(color: accent, shape: BoxShape.circle),
    ),
  );
}
