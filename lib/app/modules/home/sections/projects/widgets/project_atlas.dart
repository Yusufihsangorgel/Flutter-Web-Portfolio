import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_web_portfolio/app/core/constants/app_dimensions.dart';
import 'package:flutter_web_portfolio/app/core/constants/breakpoints.dart';
import 'package:flutter_web_portfolio/app/core/theme/app_fonts.dart';
import 'package:flutter_web_portfolio/app/domain/models/portfolio_document.dart';
import 'package:flutter_web_portfolio/app/widgets/cinematic_focusable.dart';
import 'package:url_launcher/url_launcher.dart';

@immutable
final class ProjectAtlasLabels {
  const ProjectAtlasLabels({
    required this.challenge,
    required this.approach,
    required this.outcome,
    required this.ownership,
    required this.decision,
    required this.selectedCases,
    required this.evidenceIndex,
    required this.evidenceIntro,
    required this.shippedProducts,
    required this.openEngineering,
    required this.selectEvidence,
    required this.openEvidence,
    required this.caseLabel,
    required this.indexLabel,
  });

  final String challenge;
  final String approach;
  final String outcome;
  final String ownership;
  final String decision;
  final String selectedCases;
  final String evidenceIndex;
  final String evidenceIntro;
  final String shippedProducts;
  final String openEngineering;
  final String selectEvidence;
  final String openEvidence;
  final String caseLabel;
  final String indexLabel;
}

/// Professional cases followed by a compact, source-backed evidence index.
///
/// Every colour, image, label, URL, and line of project copy comes from the
/// external content document. The renderer has no project-specific branches.
final class ProjectAtlas extends StatelessWidget {
  const ProjectAtlas({super.key, required this.systems, required this.labels});

  final List<PortfolioSystem> systems;
  final ProjectAtlasLabels labels;

  @override
  Widget build(BuildContext context) {
    final featured = systems.whereType<PortfolioFeaturedSystem>().toList(
      growable: false,
    );
    final supporting = systems.whereType<PortfolioSupportingSystem>().toList(
      growable: false,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (featured.isNotEmpty)
          _AtlasDivider(
            label: labels.selectedCases,
            count: featured.length,
            dark: true,
          ),
        for (var index = 0; index < featured.length; index++)
          _FeaturedCase(
            key: ValueKey('project-atlas-${featured[index].id}'),
            system: featured[index],
            index: index,
            labels: labels,
          ),
        if (supporting.isNotEmpty)
          _EvidenceIndex(
            key: const ValueKey('project-evidence-index'),
            systems: supporting,
            labels: labels,
          ),
      ],
    );
  }
}

final class _AtlasDivider extends StatelessWidget {
  const _AtlasDivider({
    required this.label,
    required this.count,
    required this.dark,
  });

  final String label;
  final int count;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    final foreground = dark ? const Color(0xFFF4EFE5) : const Color(0xFF14130F);
    final width = MediaQuery.sizeOf(context).width;
    final horizontal = _horizontalPadding(width);

    return ColoredBox(
      color: dark ? const Color(0xFF10110F) : const Color(0xFFF2EFE8),
      child: Padding(
        padding: EdgeInsets.fromLTRB(horizontal, 22, horizontal, 20),
        child: Container(
          padding: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(color: foreground.withValues(alpha: 0.28)),
            ),
          ),
          child: Row(
            children: [
              Text(
                label,
                style: AppFonts.spaceGrotesk(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: foreground,
                  letterSpacing: 0.8,
                ),
              ),
              const Spacer(),
              Text(
                count.toString().padLeft(2, '0'),
                style: AppFonts.spaceGrotesk(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: foreground.withValues(alpha: 0.65),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

final class _FeaturedCase extends StatelessWidget {
  const _FeaturedCase({
    super.key,
    required this.system,
    required this.index,
    required this.labels,
  });

  final PortfolioFeaturedSystem system;
  final int index;
  final ProjectAtlasLabels labels;

  @override
  Widget build(BuildContext context) {
    final palette = _ProjectPalette.from(system.presentation);
    final width = MediaQuery.sizeOf(context).width;
    final desktop = width >= Breakpoints.desktop;
    final tablet = width >= Breakpoints.tablet;
    final horizontal = _horizontalPadding(width);

    return Semantics(
      container: true,
      label:
          '${system.name}. ${system.kind}. ${system.year}. ${system.summary}',
      child: ColoredBox(
        color: palette.background,
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            horizontal,
            desktop ? 52 : 38,
            horizontal,
            desktop ? 72 : 54,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _CaseRail(
                system: system,
                index: index,
                palette: palette,
                caseLabel: labels.caseLabel,
              ),
              SizedBox(height: desktop ? 42 : 30),
              _CaseTitle(system: system, palette: palette),
              SizedBox(height: tablet ? 44 : 30),
              if (desktop)
                _DesktopCaseBody(
                  system: system,
                  labels: labels,
                  palette: palette,
                  artifactFirst: index.isEven,
                )
              else
                _CompactCaseBody(
                  system: system,
                  labels: labels,
                  palette: palette,
                ),
              SizedBox(height: desktop ? 42 : 32),
              _EvidenceLinks(system: system, labels: labels, palette: palette),
            ],
          ),
        ),
      ),
    );
  }
}

final class _CaseRail extends StatelessWidget {
  const _CaseRail({
    required this.system,
    required this.index,
    required this.palette,
    required this.caseLabel,
  });

  final PortfolioFeaturedSystem system;
  final int index;
  final _ProjectPalette palette;
  final String caseLabel;

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < Breakpoints.mobile;
    final caseMarker = Text(
      '${caseLabel.toUpperCase()} ${(index + 1).toString().padLeft(2, '0')}',
      style: AppFonts.spaceGrotesk(
        fontSize: 11,
        fontWeight: FontWeight.w800,
        color: palette.accent,
        letterSpacing: 0.7,
      ),
    );
    final year = Text(
      system.year,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      textAlign: TextAlign.end,
      style: AppFonts.spaceGrotesk(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: palette.foreground.withValues(alpha: 0.72),
      ),
    );
    final kind = Text(
      system.kind,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: AppFonts.spaceGrotesk(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: palette.foreground,
      ),
    );

    return Container(
      padding: const EdgeInsets.only(bottom: 13),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: palette.foreground.withValues(alpha: 0.3)),
        ),
      ),
      child: compact
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    caseMarker,
                    const SizedBox(width: 20),
                    Expanded(child: year),
                  ],
                ),
                const SizedBox(height: 9),
                kind,
              ],
            )
          : Row(
              children: [
                caseMarker,
                const SizedBox(width: 26),
                Expanded(child: kind),
                const SizedBox(width: 20),
                year,
              ],
            ),
    );
  }
}

final class _CaseTitle extends StatelessWidget {
  const _CaseTitle({required this.system, required this.palette});

  final PortfolioFeaturedSystem system;
  final _ProjectPalette palette;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final fontSize = width >= Breakpoints.desktop
        ? (width * 0.052).clamp(60.0, 82.0)
        : (width * 0.11).clamp(42.0, 66.0);

    return Semantics(
      header: true,
      headingLevel: 3,
      label: system.name,
      excludeSemantics: true,
      child: ExcludeSemantics(
        child: Text(
          system.name,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: AppFonts.spaceGrotesk(
            fontSize: fontSize,
            fontWeight: FontWeight.w700,
            color: palette.foreground,
            height: 0.95,
            letterSpacing: -fontSize * 0.047,
          ),
        ),
      ),
    );
  }
}

final class _DesktopCaseBody extends StatelessWidget {
  const _DesktopCaseBody({
    required this.system,
    required this.labels,
    required this.palette,
    required this.artifactFirst,
  });

  final PortfolioFeaturedSystem system;
  final ProjectAtlasLabels labels;
  final _ProjectPalette palette;
  final bool artifactFirst;

  @override
  Widget build(BuildContext context) {
    final artifact = Expanded(
      flex: 58,
      child: _ArtifactStage(system: system, palette: palette, prominent: true),
    );
    final narrative = Expanded(
      flex: 42,
      child: _CaseNarrative(system: system, labels: labels, palette: palette),
    );

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: artifactFirst
          ? [artifact, const SizedBox(width: 68), narrative]
          : [narrative, const SizedBox(width: 68), artifact],
    );
  }
}

final class _CompactCaseBody extends StatelessWidget {
  const _CompactCaseBody({
    required this.system,
    required this.labels,
    required this.palette,
  });

  final PortfolioFeaturedSystem system;
  final ProjectAtlasLabels labels;
  final _ProjectPalette palette;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      _ArtifactStage(system: system, palette: palette, prominent: true),
      const SizedBox(height: 34),
      _CaseNarrative(system: system, labels: labels, palette: palette),
    ],
  );
}

final class _CaseNarrative extends StatelessWidget {
  const _CaseNarrative({
    required this.system,
    required this.labels,
    required this.palette,
  });

  final PortfolioFeaturedSystem system;
  final ProjectAtlasLabels labels;
  final _ProjectPalette palette;

  @override
  Widget build(BuildContext context) {
    final beats = <({String label, String value})>[
      (label: labels.challenge, value: system.challenge),
      (label: labels.approach, value: system.approach),
      (label: labels.outcome, value: system.outcome),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          system.summary,
          style: AppFonts.spaceGrotesk(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: palette.foreground,
            height: 1.25,
            letterSpacing: -0.55,
          ),
        ),
        const SizedBox(height: 30),
        for (var index = 0; index < beats.length; index++) ...[
          if (index > 0) const SizedBox(height: 24),
          _NarrativeBeat(
            label: beats[index].label,
            value: beats[index].value,
            palette: palette,
          ),
        ],
      ],
    );
  }
}

final class _NarrativeBeat extends StatelessWidget {
  const _NarrativeBeat({
    required this.label,
    required this.value,
    required this.palette,
  });

  final String label;
  final String value;
  final _ProjectPalette palette;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.only(top: 12),
    decoration: BoxDecoration(
      border: Border(
        top: BorderSide(color: palette.foreground.withValues(alpha: 0.28)),
      ),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppFonts.spaceGrotesk(
            fontSize: 10,
            fontWeight: FontWeight.w800,
            color: palette.accent,
            letterSpacing: 0.7,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: AppFonts.inter(
            fontSize: 14,
            color: palette.foreground.withValues(alpha: 0.84),
            height: 1.58,
          ),
        ),
      ],
    ),
  );
}

final class _ArtifactStage extends StatelessWidget {
  const _ArtifactStage({
    required this.system,
    required this.palette,
    required this.prominent,
  });

  final PortfolioSystem system;
  final _ProjectPalette palette;
  final bool prominent;

  @override
  Widget build(BuildContext context) {
    final artifact = system.artifact;
    final fit = switch (artifact.fit) {
      PortfolioArtifactFit.contain => BoxFit.contain,
      PortfolioArtifactFit.cover => BoxFit.cover,
    };
    final alignment = switch (artifact.alignment) {
      PortfolioArtifactAlignment.start => AlignmentDirectional.centerStart,
      PortfolioArtifactAlignment.center => Alignment.center,
      PortfolioArtifactAlignment.end => AlignmentDirectional.centerEnd,
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                artifact.label,
                style: AppFonts.spaceGrotesk(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: palette.foreground.withValues(alpha: 0.78),
                  letterSpacing: 0.75,
                ),
              ),
            ),
            Text(
              '${artifact.width} × ${artifact.height}',
              style: AppFonts.spaceGrotesk(
                fontSize: 9,
                fontWeight: FontWeight.w600,
                color: palette.foreground.withValues(alpha: 0.52),
              ),
            ),
          ],
        ),
        const SizedBox(height: 13),
        Container(
          decoration: BoxDecoration(
            color: palette.foreground.withValues(alpha: 0.035),
            border: Border.all(
              color: palette.foreground.withValues(alpha: 0.28),
            ),
          ),
          child: AspectRatio(
            aspectRatio: artifact.width / artifact.height,
            child: Padding(
              padding: EdgeInsets.all(prominent ? 10 : 8),
              child: Semantics(
                image: true,
                label: artifact.alt,
                excludeSemantics: true,
                child: ExcludeSemantics(
                  child: Image.asset(
                    artifact.asset,
                    fit: fit,
                    alignment: alignment,
                    filterQuality: FilterQuality.high,
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          artifact.caption,
          style: AppFonts.inter(
            fontSize: 11,
            color: palette.foreground.withValues(alpha: 0.68),
            height: 1.45,
          ),
        ),
      ],
    );
  }
}

final class _EvidenceIndex extends StatefulWidget {
  const _EvidenceIndex({
    super.key,
    required this.systems,
    required this.labels,
  });

  final List<PortfolioSupportingSystem> systems;
  final ProjectAtlasLabels labels;

  @override
  State<_EvidenceIndex> createState() => _EvidenceIndexState();
}

final class _EvidenceIndexState extends State<_EvidenceIndex> {
  late String _selectedId = widget.systems.first.id;

  PortfolioSupportingSystem get _selected => widget.systems.firstWhere(
    (system) => system.id == _selectedId,
    orElse: () => widget.systems.first,
  );

  @override
  void didUpdateWidget(covariant _EvidenceIndex oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.systems.any((system) => system.id == _selectedId)) {
      _selectedId = widget.systems.first.id;
    }
  }

  void _select(PortfolioSupportingSystem system) {
    if (_selectedId == system.id) return;
    setState(() => _selectedId = system.id);
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final desktop = width >= Breakpoints.desktop;
    final horizontal = _horizontalPadding(width);

    return Semantics(
      container: true,
      label: widget.labels.evidenceIndex,
      child: ColoredBox(
        color: const Color(0xFFF2EFE8),
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            horizontal,
            desktop ? 78 : 54,
            horizontal,
            desktop ? 88 : 64,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _EvidenceIndexHeader(labels: widget.labels),
              SizedBox(height: desktop ? 54 : 38),
              if (desktop)
                _DesktopEvidenceIndex(
                  systems: widget.systems,
                  selected: _selected,
                  labels: widget.labels,
                  onSelect: _select,
                )
              else
                _CompactEvidenceIndex(
                  systems: widget.systems,
                  selected: _selected,
                  labels: widget.labels,
                  onSelect: _select,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

final class _EvidenceIndexHeader extends StatelessWidget {
  const _EvidenceIndexHeader({required this.labels});

  final ProjectAtlasLabels labels;

  @override
  Widget build(BuildContext context) {
    final tablet = MediaQuery.sizeOf(context).width >= Breakpoints.tablet;
    return Container(
      padding: const EdgeInsets.only(bottom: 24),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0x4014130F))),
      ),
      child: tablet
          ? Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(child: _EvidenceIndexTitle(labels: labels)),
                const SizedBox(width: 48),
                SizedBox(
                  width: 420,
                  child: Text(
                    labels.evidenceIntro,
                    style: AppFonts.inter(
                      fontSize: 15,
                      color: const Color(0xC914130F),
                      height: 1.55,
                    ),
                  ),
                ),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _EvidenceIndexTitle(labels: labels),
                const SizedBox(height: 18),
                Text(
                  labels.evidenceIntro,
                  style: AppFonts.inter(
                    fontSize: 14,
                    color: const Color(0xC914130F),
                    height: 1.55,
                  ),
                ),
              ],
            ),
    );
  }
}

final class _EvidenceIndexTitle extends StatelessWidget {
  const _EvidenceIndexTitle({required this.labels});

  final ProjectAtlasLabels labels;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        labels.indexLabel.toUpperCase(),
        style: AppFonts.spaceGrotesk(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          color: const Color(0xFF1E51FF),
          letterSpacing: 0.9,
        ),
      ),
      const SizedBox(height: 10),
      Semantics(
        header: true,
        headingLevel: 3,
        child: Text(
          labels.evidenceIndex,
          style: AppFonts.spaceGrotesk(
            fontSize: MediaQuery.sizeOf(context).width >= Breakpoints.tablet
                ? 46
                : 36,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF14130F),
            height: 1,
            letterSpacing: -1.7,
          ),
        ),
      ),
    ],
  );
}

final class _DesktopEvidenceIndex extends StatelessWidget {
  const _DesktopEvidenceIndex({
    required this.systems,
    required this.selected,
    required this.labels,
    required this.onSelect,
  });

  final List<PortfolioSupportingSystem> systems;
  final PortfolioSupportingSystem selected;
  final ProjectAtlasLabels labels;
  final ValueChanged<PortfolioSupportingSystem> onSelect;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Expanded(
        flex: 58,
        child: _SelectedEvidenceStage(system: selected, labels: labels),
      ),
      const SizedBox(width: 68),
      Expanded(
        flex: 42,
        child: _EvidenceRows(
          systems: systems,
          selected: selected,
          labels: labels,
          onSelect: onSelect,
          compact: false,
        ),
      ),
    ],
  );
}

final class _CompactEvidenceIndex extends StatelessWidget {
  const _CompactEvidenceIndex({
    required this.systems,
    required this.selected,
    required this.labels,
    required this.onSelect,
  });

  final List<PortfolioSupportingSystem> systems;
  final PortfolioSupportingSystem selected;
  final ProjectAtlasLabels labels;
  final ValueChanged<PortfolioSupportingSystem> onSelect;

  @override
  Widget build(BuildContext context) => _EvidenceRows(
    systems: systems,
    selected: selected,
    labels: labels,
    onSelect: onSelect,
    compact: true,
  );
}

final class _EvidenceRows extends StatelessWidget {
  const _EvidenceRows({
    required this.systems,
    required this.selected,
    required this.labels,
    required this.onSelect,
    required this.compact,
  });

  final List<PortfolioSupportingSystem> systems;
  final PortfolioSupportingSystem selected;
  final ProjectAtlasLabels labels;
  final ValueChanged<PortfolioSupportingSystem> onSelect;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    var ordinal = 0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final group in PortfolioSystemGroup.values) ...[
          if (systems.any((system) => system.group == group))
            _EvidenceGroupLabel(
              label: switch (group) {
                PortfolioSystemGroup.shippedProduct => labels.shippedProducts,
                PortfolioSystemGroup.openEngineering => labels.openEngineering,
              },
            ),
          for (final system in systems.where(
            (system) => system.group == group,
          )) ...[
            _EvidenceRow(
              system: system,
              ordinal: ++ordinal,
              selected: system.id == selected.id,
              labels: labels,
              onSelect: () => onSelect(system),
            ),
            if (compact && system.id == selected.id)
              Padding(
                padding: const EdgeInsets.only(bottom: 28),
                child: _SelectedEvidenceStage(
                  key: ValueKey('compact-evidence-${system.id}'),
                  system: system,
                  labels: labels,
                ),
              ),
          ],
          if (group != PortfolioSystemGroup.values.last)
            SizedBox(height: compact ? 30 : 38),
        ],
      ],
    );
  }
}

final class _EvidenceGroupLabel extends StatelessWidget {
  const _EvidenceGroupLabel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.only(bottom: 10),
    decoration: const BoxDecoration(
      border: Border(bottom: BorderSide(color: Color(0x4014130F))),
    ),
    child: Text(
      label,
      style: AppFonts.spaceGrotesk(
        fontSize: 10,
        fontWeight: FontWeight.w800,
        color: const Color(0xFF1E51FF),
        letterSpacing: 0.8,
      ),
    ),
  );
}

final class _EvidenceRow extends StatelessWidget {
  const _EvidenceRow({
    required this.system,
    required this.ordinal,
    required this.selected,
    required this.labels,
    required this.onSelect,
  });

  final PortfolioSupportingSystem system;
  final int ordinal;
  final bool selected;
  final ProjectAtlasLabels labels;
  final VoidCallback onSelect;

  @override
  Widget build(BuildContext context) {
    final tablet = MediaQuery.sizeOf(context).width >= Breakpoints.tablet;
    return CinematicFocusable(
      onTap: onSelect,
      onHoverChanged: (hovered) {
        if (hovered) onSelect();
      },
      semanticLabel: '${labels.selectEvidence}: ${system.name}',
      selected: selected,
      expanded: selected,
      focusColor: const Color(0xFF1E51FF),
      child: AnimatedContainer(
        duration: MediaQuery.disableAnimationsOf(context)
            ? Duration.zero
            : const Duration(milliseconds: 180),
        padding: EdgeInsets.symmetric(
          vertical: tablet ? 18 : 16,
          horizontal: selected ? 12 : 0,
        ),
        decoration: BoxDecoration(
          color: selected ? const Color(0x0F1E51FF) : Colors.transparent,
          border: const Border(bottom: BorderSide(color: Color(0x4014130F))),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 34,
              child: Text(
                ordinal.toString().padLeft(2, '0'),
                style: AppFonts.spaceGrotesk(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: selected
                      ? const Color(0xFF1E51FF)
                      : const Color(0x9914130F),
                ),
              ),
            ),
            Expanded(
              child: Column(
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
                            color: const Color(0xFF14130F),
                            height: 1.15,
                            letterSpacing: -0.45,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        system.year,
                        style: AppFonts.spaceGrotesk(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: const Color(0x9914130F),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 7),
                  Text(
                    system.spotlight,
                    maxLines: selected ? 3 : 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppFonts.inter(
                      fontSize: 12,
                      color: const Color(0xBF14130F),
                      height: 1.45,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 14),
            Icon(
              selected ? Icons.south_east_rounded : Icons.arrow_forward_rounded,
              size: 18,
              color: selected
                  ? const Color(0xFF1E51FF)
                  : const Color(0x8014130F),
            ),
          ],
        ),
      ),
    );
  }
}

final class _SelectedEvidenceStage extends StatelessWidget {
  const _SelectedEvidenceStage({
    super.key,
    required this.system,
    required this.labels,
  });

  final PortfolioSupportingSystem system;
  final ProjectAtlasLabels labels;

  @override
  Widget build(BuildContext context) {
    final palette = _ProjectPalette.from(system.presentation);
    final motionDisabled = MediaQuery.disableAnimationsOf(context);

    return AnimatedContainer(
      duration: motionDisabled
          ? Duration.zero
          : const Duration(milliseconds: 260),
      color: palette.background,
      padding: EdgeInsets.all(
        MediaQuery.sizeOf(context).width >= Breakpoints.tablet ? 28 : 20,
      ),
      child: AnimatedSwitcher(
        duration: motionDisabled
            ? Duration.zero
            : const Duration(milliseconds: 220),
        child: _SelectedEvidenceContent(
          key: ValueKey(system.id),
          system: system,
          labels: labels,
          palette: palette,
        ),
      ),
    );
  }
}

final class _SelectedEvidenceContent extends StatelessWidget {
  const _SelectedEvidenceContent({
    super.key,
    required this.system,
    required this.labels,
    required this.palette,
  });

  final PortfolioSupportingSystem system;
  final ProjectAtlasLabels labels;
  final _ProjectPalette palette;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    mainAxisSize: MainAxisSize.min,
    children: [
      Row(
        children: [
          Expanded(
            child: Text(
              system.kind.toUpperCase(),
              style: AppFonts.spaceGrotesk(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                color: palette.accent,
                letterSpacing: 0.75,
              ),
            ),
          ),
          Text(
            system.year,
            style: AppFonts.spaceGrotesk(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: palette.foreground.withValues(alpha: 0.65),
            ),
          ),
        ],
      ),
      const SizedBox(height: 22),
      Semantics(
        header: true,
        headingLevel: 4,
        child: Text(
          system.name,
          style: AppFonts.spaceGrotesk(
            fontSize: MediaQuery.sizeOf(context).width >= Breakpoints.tablet
                ? 34
                : 27,
            fontWeight: FontWeight.w700,
            color: palette.foreground,
            height: 1.02,
            letterSpacing: -1.1,
          ),
        ),
      ),
      const SizedBox(height: 14),
      Text(
        system.spotlight,
        style: AppFonts.inter(
          fontSize: 14,
          color: palette.foreground.withValues(alpha: 0.82),
          height: 1.52,
        ),
      ),
      const SizedBox(height: 28),
      _ArtifactStage(system: system, palette: palette, prominent: false),
      const SizedBox(height: 28),
      _NarrativeBeat(
        label: labels.ownership,
        value: system.ownership,
        palette: palette,
      ),
      const SizedBox(height: 22),
      _NarrativeBeat(
        label: labels.decision,
        value: system.decision,
        palette: palette,
      ),
      const SizedBox(height: 26),
      _EvidenceLinks(system: system, labels: labels, palette: palette),
    ],
  );
}

final class _EvidenceLinks extends StatelessWidget {
  const _EvidenceLinks({
    required this.system,
    required this.labels,
    required this.palette,
  });

  final PortfolioSystem system;
  final ProjectAtlasLabels labels;
  final _ProjectPalette palette;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.only(top: 16),
    decoration: BoxDecoration(
      border: Border(
        top: BorderSide(color: palette.foreground.withValues(alpha: 0.3)),
      ),
    ),
    child: Wrap(
      spacing: 24,
      runSpacing: 12,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        for (final evidence in system.evidence)
          _AtlasLink(
            label: evidence.label,
            semanticLabel:
                '${labels.openEvidence}: ${system.name}, ${evidence.label}',
            url: evidence.url,
            palette: palette,
          ),
        Text(
          system.technologies.join(' · '),
          style: AppFonts.spaceGrotesk(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: palette.foreground.withValues(alpha: 0.68),
          ),
        ),
      ],
    ),
  );
}

final class _AtlasLink extends StatelessWidget {
  const _AtlasLink({
    required this.label,
    required this.semanticLabel,
    required this.url,
    required this.palette,
  });

  final String label;
  final String semanticLabel;
  final Uri url;
  final _ProjectPalette palette;

  @override
  Widget build(BuildContext context) {
    final maxWidth = math.min(360.0, MediaQuery.sizeOf(context).width - 48);
    return CinematicFocusable(
      onTap: () => launchUrl(url, webOnlyWindowName: '_blank'),
      semanticLabel: semanticLabel,
      semanticRole: CinematicControlRole.link,
      focusColor: palette.accent,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppFonts.spaceGrotesk(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: palette.foreground,
                  ),
                ),
              ),
              const SizedBox(width: 7),
              Icon(Icons.north_east_rounded, size: 15, color: palette.accent),
            ],
          ),
        ),
      ),
    );
  }
}

@immutable
final class _ProjectPalette {
  const _ProjectPalette({
    required this.background,
    required this.foreground,
    required this.accent,
  });

  factory _ProjectPalette.from(PortfolioSystemPresentation value) =>
      _ProjectPalette(
        background: _hexColor(value.background),
        foreground: _hexColor(value.foreground),
        accent: _hexColor(value.accent),
      );

  final Color background;
  final Color foreground;
  final Color accent;
}

double _horizontalPadding(double width) => width > AppDimensions.maxContentWidth
    ? AppDimensions.sectionPaddingDesktop
    : width >= Breakpoints.tablet
    ? AppDimensions.sectionPaddingTablet
    : AppDimensions.sectionPaddingMobile;

Color _hexColor(String value) =>
    Color(int.parse('FF${value.substring(1)}', radix: 16));
