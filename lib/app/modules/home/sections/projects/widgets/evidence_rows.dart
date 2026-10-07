import 'package:flutter/material.dart';
import 'package:flutter_web_portfolio/app/core/theme/app_fonts.dart';
import 'package:flutter_web_portfolio/app/domain/models/portfolio_document.dart';
import 'package:flutter_web_portfolio/app/modules/home/sections/projects/widgets/atlas_style.dart';
import 'package:flutter_web_portfolio/app/modules/home/sections/projects/widgets/evidence_index_model.dart';
import 'package:flutter_web_portfolio/app/modules/home/sections/projects/widgets/selected_evidence.dart';
import 'package:flutter_web_portfolio/app/widgets/accessible_action.dart';

/// A numbered supporting system within the evidence index.
typedef EvidenceEntry = ({PortfolioSupportingSystem system, int ordinal});

/// Supporting systems grouped by kind. In [compact] layouts the selected
/// system's preview opens directly beneath its row.
final class EvidenceRows extends StatelessWidget {
  const EvidenceRows({super.key, required this.model, required this.compact});

  final EvidenceIndexModel model;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    var ordinal = 0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final group in PortfolioSystemGroup.values) ...[
          if (model.systems.any((system) => system.group == group))
            EvidenceGroupLabel(label: model.groupLabel(group)),
          for (final system in model.systems.where((s) => s.group == group))
            ..._entry((system: system, ordinal: ++ordinal)),
          if (group != PortfolioSystemGroup.values.last)
            SizedBox(height: compact ? 30 : 38),
        ],
      ],
    );
  }

  List<Widget> _entry(EvidenceEntry entry) => [
    EvidenceRow(model: model, entry: entry, hoverSelects: !compact),
    if (compact && model.isSelected(entry.system))
      Padding(
        padding: const EdgeInsets.only(bottom: 28),
        child: SelectedEvidenceStage(
          key: ValueKey('compact-evidence-${entry.system.id}'),
          system: entry.system,
          labels: model.labels,
        ),
      ),
  ];
}

/// Accent caption above one group of index rows.
final class EvidenceGroupLabel extends StatelessWidget {
  const EvidenceGroupLabel({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.only(bottom: 10),
    decoration: const BoxDecoration(
      border: Border(bottom: BorderSide(color: AtlasColors.rule)),
    ),
    child: Text(
      label,
      style: AtlasText.label(
        size: 10,
        color: AtlasColors.accent,
        letterSpacing: 0.8,
      ),
    ),
  );
}

/// A selectable index row. With [hoverSelects], pointer hover previews it.
final class EvidenceRow extends StatelessWidget {
  const EvidenceRow({
    super.key,
    required this.model,
    required this.entry,
    required this.hoverSelects,
  });

  static const double ordinalWidth = 34;
  static const Duration selectionDuration = Duration(milliseconds: 180);

  final EvidenceIndexModel model;
  final EvidenceEntry entry;
  final bool hoverSelects;

  @override
  Widget build(BuildContext context) {
    final system = entry.system;
    final selected = model.isSelected(system);
    final tablet = AtlasLayout.of(context).tablet;
    void select() => model.onSelect(system);

    return AccessibleAction(
      key: ValueKey('evidence-row-${system.id}'),
      onTap: select,
      onHoverChanged: hoverSelects
          ? (hovered) {
              if (hovered) select();
            }
          : null,
      semanticLabel: '${model.labels.selectEvidence}: ${system.name}',
      selected: selected,
      expanded: selected,
      focusColor: AtlasColors.accent,
      child: AnimatedContainer(
        duration: MediaQuery.disableAnimationsOf(context)
            ? Duration.zero
            : selectionDuration,
        padding: EdgeInsets.symmetric(
          vertical: tablet ? 18 : 16,
          horizontal: hoverSelects || selected ? 12 : 0,
        ),
        decoration: BoxDecoration(
          color: selected ? AtlasColors.selectedRow : Colors.transparent,
          border: const Border(bottom: BorderSide(color: AtlasColors.rule)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: ordinalWidth,
              child: Text(
                entry.ordinal.toString().padLeft(2, '0'),
                style: AtlasText.label(
                  size: 10,
                  color: selected ? AtlasColors.accent : AtlasColors.mutedText,
                ),
              ),
            ),
            Expanded(
              child: _EvidenceRowText(
                system: system,
                spotlightLines: hoverSelects || !selected ? 2 : 3,
                tablet: tablet,
              ),
            ),
            const SizedBox(width: 14),
            Icon(
              selected ? Icons.south_east_rounded : Icons.arrow_forward_rounded,
              size: 18,
              color: selected ? AtlasColors.accent : AtlasColors.idleIcon,
            ),
          ],
        ),
      ),
    );
  }
}

final class _EvidenceRowText extends StatelessWidget {
  const _EvidenceRowText({
    required this.system,
    required this.spotlightLines,
    required this.tablet,
  });

  final PortfolioSupportingSystem system;
  final int spotlightLines;
  final bool tablet;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          Expanded(
            child: Text(
              system.name,
              style: AppFonts.spaceGrotesk(
                fontSize: tablet ? 20 : 18,
                fontWeight: FontWeight.w700,
                color: AtlasColors.ink,
                height: 1.15,
                letterSpacing: -0.45,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            system.year,
            style: AtlasText.label(
              size: 10,
              weight: FontWeight.w600,
              color: AtlasColors.mutedText,
            ),
          ),
        ],
      ),
      const SizedBox(height: 7),
      Text(
        system.spotlight,
        maxLines: spotlightLines,
        overflow: TextOverflow.ellipsis,
        style: AppFonts.inter(
          fontSize: 12,
          color: AtlasColors.spotlightText,
          height: 1.45,
        ),
      ),
    ],
  );
}
