import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_web_portfolio/app/controllers/scroll_controller.dart';
import 'package:flutter_web_portfolio/app/core/constants/app_colors.dart';
import 'package:flutter_web_portfolio/app/core/constants/breakpoints.dart';
import 'package:flutter_web_portfolio/app/core/theme/app_fonts.dart';
import 'package:flutter_web_portfolio/app/domain/models/portfolio_document.dart';
import 'package:flutter_web_portfolio/app/features/language/application/language_cubit.dart';
import 'package:flutter_web_portfolio/app/narrative/domain/narrative_document.dart';
import 'package:flutter_web_portfolio/app/widgets/accessible_action.dart';
import 'package:flutter_web_portfolio/app/widgets/numbered_section_heading.dart';
import 'package:flutter_web_portfolio/app/widgets/scene_accent_builder.dart';
import 'package:url_launcher/url_launcher.dart';

/// Newest six articles from every feed the owner declared in
/// `writing_sources`, aggregated by the refresh tool. Hidden entirely when
/// the content document carries no writing.
class WritingSection extends StatelessWidget {
  const WritingSection({super.key});

  static const _displayCount = 6;

  @override
  Widget build(BuildContext context) =>
      BlocBuilder<LanguageCubit, LanguageState>(
        builder: (context, _) {
          final language = context.read<LanguageCubit>();
          final portfolio = context.read<PortfolioDocument>();
          final writing = portfolio.writing;
          if (writing.isEmpty) return const SizedBox.shrink();

          final sourcesById = {
            for (final source in portfolio.writingSources) source.id: source,
          };
          final entries = writing.take(_displayCount).toList(growable: false);
          final subtitle = language.getText(
            'writing_section.subtitle',
            defaultValue:
                'Recent articles from every place I publish, newest first.',
          );
          final allWritingLabel = language.getText(
            'writing_section.all_writing',
            defaultValue: 'All writing',
          );
          final openLabel = language.getText(
            'writing_section.open_article',
            defaultValue: 'Read article',
          );

          return ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SceneAccentBuilder(
                  builder: (context, accent) => NumberedSectionHeading(
                    number: context.read<NarrativeDocument>().sectionNumber(
                      SectionId.writing,
                    ),
                    title: language.getText(
                      'writing_section.title',
                      defaultValue: 'Writing',
                    ),
                    accent: accent,
                    anchorKey: context.read<AppScrollController>().anchorKeyFor(
                      SectionId.writing,
                    ),
                  ),
                ),
                const SizedBox(height: 30),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 640),
                  child: Text(
                    subtitle,
                    style: AppFonts.spaceGrotesk(
                      fontSize: 20,
                      fontWeight: FontWeight.w400,
                      color: AppColors.textPrimary,
                      height: 1.55,
                    ),
                  ),
                ),
                const SizedBox(height: 48),
                SceneAccentBuilder(
                  builder: (context, accent) => Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (var index = 0; index < entries.length; index++)
                        _WritingRow(
                          entry: entries[index],
                          source: sourcesById[entries[index].source],
                          accent: accent,
                          openLabel: openLabel,
                          isLast: index == entries.length - 1,
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                _AllWritingRow(
                  sources: portfolio.writingSources,
                  label: allWritingLabel,
                ),
              ],
            ),
          );
        },
      );
}

class _WritingRow extends StatelessWidget {
  const _WritingRow({
    required this.entry,
    required this.source,
    required this.accent,
    required this.openLabel,
    required this.isLast,
  });

  final PortfolioWritingEntry entry;
  final PortfolioWritingSource? source;
  final Color accent;
  final String openLabel;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < Breakpoints.tablet;
    // The source id itself is a legible fallback if a locale-loaded document
    // ever lags the content document's declared sources.
    final sourceLabel = source?.label ?? entry.source;
    final dateLabel = _dateLabel(entry.date);
    final semanticLabel =
        '$openLabel. ${entry.title}. $sourceLabel. $dateLabel.';

    return AccessibleAction(
      onTap: () => _openWriting(entry.url),
      semanticLabel: semanticLabel,
      semanticRole: ActionSemanticRole.link,
      focusColor: accent,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: compact ? 20 : 22),
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
            ? _CompactWritingContent(
                entry: entry,
                sourceLabel: sourceLabel,
                dateLabel: dateLabel,
                accent: accent,
              )
            : _WideWritingContent(
                entry: entry,
                sourceLabel: sourceLabel,
                dateLabel: dateLabel,
                accent: accent,
              ),
      ),
    );
  }
}

class _WideWritingContent extends StatelessWidget {
  const _WideWritingContent({
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
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.center,
    children: [
      Expanded(
        child: Text(
          entry.title,
          style: AppFonts.spaceGrotesk(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: AppColors.textBright,
          ),
        ),
      ),
      const SizedBox(width: 24),
      Text(
        sourceLabel,
        style: AppFonts.jetBrainsMono(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: accent,
          letterSpacing: 0.3,
        ),
      ),
      const SizedBox(width: 16),
      Text(
        dateLabel,
        style: AppFonts.jetBrainsMono(
          fontSize: 11,
          color: AppColors.textSecondary,
          letterSpacing: 0.2,
        ),
      ),
      const SizedBox(width: 18),
      Icon(Icons.north_east_rounded, size: 16, color: accent),
    ],
  );
}

class _CompactWritingContent extends StatelessWidget {
  const _CompactWritingContent({
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
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          Expanded(
            child: Text(
              entry.title,
              style: AppFonts.spaceGrotesk(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: AppColors.textBright,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Icon(Icons.north_east_rounded, size: 16, color: accent),
        ],
      ),
      const SizedBox(height: 8),
      Text(
        '$sourceLabel · $dateLabel',
        style: AppFonts.jetBrainsMono(
          fontSize: 11,
          color: AppColors.textSecondary,
          letterSpacing: 0.2,
        ),
      ),
    ],
  );
}

/// One link per declared feed, so a visitor can keep reading past the six
/// most recent entries without the site mirroring a full archive.
class _AllWritingRow extends StatelessWidget {
  const _AllWritingRow({required this.sources, required this.label});

  final List<PortfolioWritingSource> sources;
  final String label;

  @override
  Widget build(BuildContext context) {
    if (sources.isEmpty) return const SizedBox.shrink();
    return SceneAccentBuilder(
      builder: (context, accent) => Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 20,
        runSpacing: 12,
        children: [
          Text(
            label.toUpperCase(),
            style: AppFonts.jetBrainsMono(
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              color: AppColors.textSecondary.withValues(alpha: 0.85),
              letterSpacing: 1.1,
            ),
          ),
          for (final source in sources)
            AccessibleAction(
              onTap: () => _openWriting(source.profileUrl),
              semanticLabel: '$label: ${source.label}',
              semanticRole: ActionSemanticRole.link,
              focusColor: accent,
              child: Text(
                source.label,
                style: AppFonts.spaceGrotesk(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: accent,
                  decoration: TextDecoration.underline,
                  decorationColor: accent,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

String _dateLabel(DateTime date) => [
  date.year.toString().padLeft(4, '0'),
  date.month.toString().padLeft(2, '0'),
  date.day.toString().padLeft(2, '0'),
].join('—');

Future<void> _openWriting(Uri uri) async =>
    launchUrl(uri, webOnlyWindowName: '_blank');
