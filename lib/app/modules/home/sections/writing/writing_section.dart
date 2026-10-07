import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_web_portfolio/app/controllers/scroll_controller.dart';
import 'package:flutter_web_portfolio/app/core/constants/app_colors.dart';
import 'package:flutter_web_portfolio/app/core/theme/app_fonts.dart';
import 'package:flutter_web_portfolio/app/domain/models/portfolio_document.dart'
    hide PortfolioLink;
import 'package:flutter_web_portfolio/app/features/language/application/language_context.dart';
import 'package:flutter_web_portfolio/app/features/language/application/language_cubit.dart';
import 'package:flutter_web_portfolio/app/modules/home/sections/writing/writing_list.dart';
import 'package:flutter_web_portfolio/app/narrative/domain/narrative_document.dart';
import 'package:flutter_web_portfolio/app/widgets/accessible_action.dart';
import 'package:flutter_web_portfolio/app/widgets/numbered_section_heading.dart';
import 'package:flutter_web_portfolio/app/widgets/portfolio_link.dart';
import 'package:flutter_web_portfolio/app/widgets/scene_accent_builder.dart';

/// Curated writing with an accessible catalog disclosure.
class WritingSection extends StatefulWidget {
  const WritingSection({super.key});

  @override
  State<WritingSection> createState() => _WritingSectionState();
}

class _WritingSectionState extends State<WritingSection> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) =>
      BlocBuilder<LanguageCubit, LanguageState>(
        builder: (context, _) {
          final portfolio = context.read<PortfolioDocument>();
          final writing = portfolio.writing;
          if (writing.isEmpty) return const SizedBox.shrink();

          final featured = writing.where((entry) => entry.featured).toList();
          final remainder = writing.where((entry) => !entry.featured).toList();
          final primary = featured.isEmpty ? writing : featured;
          final canExpand = featured.isNotEmpty && remainder.isNotEmpty;
          final sources = {
            for (final source in portfolio.writingSources) source.id: source,
          };

          return ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _WritingHeader(),
                const SizedBox(height: 48),
                SceneAccentBuilder(
                  builder: (context, accent) => writingList(
                    entries: primary,
                    sources: sources,
                    accent: accent,
                    compact: false,
                  ),
                ),
                if (canExpand) ...[
                  const SizedBox(height: 28),
                  _WritingDisclosure(
                    count: writing.length,
                    expanded: _expanded,
                    onToggle: () => setState(() => _expanded = !_expanded),
                  ),
                  if (_expanded) ...[
                    const SizedBox(height: 28),
                    SceneAccentBuilder(
                      builder: (context, accent) => writingList(
                        entries: remainder,
                        sources: sources,
                        accent: accent,
                        compact: true,
                      ),
                    ),
                  ],
                ],
                const SizedBox(height: 32),
                _AllWritingRow(sources: portfolio.writingSources),
              ],
            ),
          );
        },
      );
}

class _WritingHeader extends StatelessWidget {
  const _WritingHeader();

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      SceneAccentBuilder(
        builder: (context, accent) => NumberedSectionHeading(
          number: context.read<NarrativeDocument>().sectionNumber(
            SectionId.writing,
          ),
          title: context.strings.writingSectionTitle,
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
          context.strings.writingSectionSubtitle,
          style: AppFonts.spaceGrotesk(
            fontSize: 20,
            fontWeight: FontWeight.w400,
            color: AppColors.textPrimary,
            height: 1.55,
          ),
        ),
      ),
    ],
  );
}

class _WritingDisclosure extends StatelessWidget {
  const _WritingDisclosure({
    required this.count,
    required this.expanded,
    required this.onToggle,
  });

  final int count;
  final bool expanded;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) => SceneAccentBuilder(
    builder: (context, accent) {
      final label = expanded
          ? context.strings.writingSectionShowLess
          : context.strings.writingSectionShowAll(count: '$count');
      return AccessibleAction(
        onTap: onToggle,
        semanticLabel: label,
        expanded: expanded,
        focusColor: accent,
        borderRadius: BorderRadius.circular(4),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: AppFonts.spaceGrotesk(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: accent,
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                expanded ? Icons.expand_less : Icons.expand_more,
                size: 18,
                color: accent,
              ),
            ],
          ),
        ),
      );
    },
  );
}

class _AllWritingRow extends StatelessWidget {
  const _AllWritingRow({required this.sources});

  final List<PortfolioWritingSource> sources;

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
            context.strings.writingSectionAllWriting.toUpperCase(),
            style: AppFonts.jetBrainsMono(
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              color: AppColors.textSecondary,
              letterSpacing: 1.1,
            ),
          ),
          for (final source in sources)
            PortfolioLink(
              uri: source.profileUrl,
              semanticLabel:
                  '${context.strings.writingSectionAllWriting}: '
                  '${source.label}',
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
