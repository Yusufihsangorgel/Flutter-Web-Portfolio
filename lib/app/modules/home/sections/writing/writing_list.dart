import 'package:flutter/material.dart';
import 'package:flutter_web_portfolio/app/core/constants/app_colors.dart';
import 'package:flutter_web_portfolio/app/core/constants/breakpoints.dart';
import 'package:flutter_web_portfolio/app/core/theme/app_fonts.dart';
import 'package:flutter_web_portfolio/app/domain/models/portfolio_document.dart'
    hide PortfolioLink;
import 'package:flutter_web_portfolio/app/features/language/application/language_context.dart';
import 'package:flutter_web_portfolio/app/modules/home/sections/section_style.dart';
import 'package:flutter_web_portfolio/app/widgets/portfolio_link.dart';

Widget writingList({
  required List<PortfolioWritingEntry> entries,
  required Map<String, PortfolioWritingSource> sources,
  required Color accent,
  required bool compact,
}) => _WritingList(
  entries: entries,
  sources: sources,
  accent: accent,
  compact: compact,
);

class _WritingList extends StatelessWidget {
  const _WritingList({
    required this.entries,
    required this.sources,
    required this.accent,
    required this.compact,
  });

  final List<PortfolioWritingEntry> entries;
  final Map<String, PortfolioWritingSource> sources;
  final Color accent;
  final bool compact;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      for (var index = 0; index < entries.length; index++) ...[
        if (index > 0) const SizedBox(height: 12),
        _WritingRow(
          entry: entries[index],
          source: sources[entries[index].source],
          accent: accent,
          compact: compact,
        ),
      ],
    ],
  );
}

class _WritingRow extends StatelessWidget {
  const _WritingRow({
    required this.entry,
    required this.source,
    required this.accent,
    required this.compact,
  });

  final PortfolioWritingEntry entry;
  final PortfolioWritingSource? source;
  final Color accent;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final sourceLabel = source?.label ?? entry.source;
    final dateLabel = sectionDateLabel(entry.date);
    return PortfolioLink(
      uri: entry.url,
      semanticLabel:
          '${context.strings.writingSectionOpenArticle}: ${entry.title}. '
          '$sourceLabel. $dateLabel.',
      focusColor: accent,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(compact ? 16 : 22),
        decoration: BoxDecoration(
          border: Border.all(
            color: AppColors.textSecondary.withValues(alpha: 0.25),
          ),
        ),
        child: compact
            ? _CompactWriting(
                entry: entry,
                sourceLabel: sourceLabel,
                dateLabel: dateLabel,
                accent: accent,
              )
            : _FeaturedWriting(
                entry: entry,
                sourceLabel: sourceLabel,
                dateLabel: dateLabel,
                accent: accent,
              ),
      ),
    );
  }
}

class _FeaturedWriting extends StatelessWidget {
  const _FeaturedWriting({
    required this.entry,
    required this.sourceLabel,
    required this.dateLabel,
    required this.accent,
  });

  final PortfolioWritingEntry entry;
  final String sourceLabel;
  final String dateLabel;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final meta = _WritingMeta(
      sourceLabel: sourceLabel,
      dateLabel: dateLabel,
      accent: accent,
    );
    if (MediaQuery.sizeOf(context).width < Breakpoints.tablet) {
      return _NarrowWriting(
        entry: entry,
        meta: meta,
        accent: accent,
        compact: false,
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Text(
            entry.title,
            style: AppFonts.spaceGrotesk(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.textBright,
            ),
          ),
        ),
        const SizedBox(width: 24),
        meta,
        const SizedBox(width: 18),
        Icon(Icons.north_east_rounded, size: 16, color: accent),
      ],
    );
  }
}

class _CompactWriting extends StatelessWidget {
  const _CompactWriting({
    required this.entry,
    required this.sourceLabel,
    required this.dateLabel,
    required this.accent,
  });

  final PortfolioWritingEntry entry;
  final String sourceLabel;
  final String dateLabel;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final meta = _WritingMeta(
      sourceLabel: sourceLabel,
      dateLabel: dateLabel,
      accent: accent,
    );
    if (MediaQuery.sizeOf(context).width < Breakpoints.tablet) {
      return _NarrowWriting(
        entry: entry,
        meta: meta,
        accent: accent,
        compact: true,
      );
    }
    return Row(
      children: [
        Expanded(
          child: Text(
            entry.title,
            style: AppFonts.spaceGrotesk(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppColors.textBright,
            ),
          ),
        ),
        const SizedBox(width: 16),
        meta,
        const SizedBox(width: 12),
        Icon(Icons.north_east_rounded, size: 15, color: accent),
      ],
    );
  }
}

class _NarrowWriting extends StatelessWidget {
  const _NarrowWriting({
    required this.entry,
    required this.meta,
    required this.accent,
    required this.compact,
  });

  final PortfolioWritingEntry entry;
  final Widget meta;
  final Color accent;
  final bool compact;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              entry.title,
              style: AppFonts.spaceGrotesk(
                fontSize: compact ? 15 : 18,
                fontWeight: FontWeight.w600,
                color: AppColors.textBright,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Icon(Icons.north_east_rounded, size: 16, color: accent),
        ],
      ),
      const SizedBox(height: 12),
      meta,
    ],
  );
}

class _WritingMeta extends StatelessWidget {
  const _WritingMeta({
    required this.sourceLabel,
    required this.dateLabel,
    required this.accent,
  });

  final String sourceLabel;
  final String dateLabel;
  final Color accent;

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 16,
    runSpacing: 4,
    children: [
      Text(
        sourceLabel,
        style: AppFonts.jetBrainsMono(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: accent,
        ),
      ),
      Text(
        dateLabel,
        style: AppFonts.jetBrainsMono(
          fontSize: 11,
          color: AppColors.textSecondary,
        ),
      ),
    ],
  );
}
