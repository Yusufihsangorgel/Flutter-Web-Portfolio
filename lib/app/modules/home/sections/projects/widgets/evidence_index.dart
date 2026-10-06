import 'package:flutter/material.dart';
import 'package:flutter_web_portfolio/app/core/theme/app_fonts.dart';
import 'package:flutter_web_portfolio/app/domain/models/portfolio_document.dart';
import 'package:flutter_web_portfolio/app/modules/home/sections/projects/widgets/atlas_labels.dart';
import 'package:flutter_web_portfolio/app/modules/home/sections/projects/widgets/atlas_style.dart';
import 'package:flutter_web_portfolio/app/modules/home/sections/projects/widgets/evidence_index_model.dart';
import 'package:flutter_web_portfolio/app/modules/home/sections/projects/widgets/evidence_rows.dart';
import 'package:flutter_web_portfolio/app/modules/home/sections/projects/widgets/selected_evidence.dart';

/// Released products and open engineering work behind one selectable index.
final class EvidenceIndex extends StatefulWidget {
  const EvidenceIndex({super.key, required this.systems, required this.labels});

  final List<PortfolioSupportingSystem> systems;
  final ProjectAtlasLabels labels;

  @override
  State<EvidenceIndex> createState() => _EvidenceIndexState();
}

final class _EvidenceIndexState extends State<EvidenceIndex> {
  late String _selectedId = widget.systems.first.id;

  @override
  void didUpdateWidget(covariant EvidenceIndex oldWidget) {
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
    final layout = AtlasLayout.of(context);
    final horizontal = layout.horizontalPadding;
    final model = EvidenceIndexModel(
      systems: widget.systems,
      selected: EvidenceIndexModel.resolve(widget.systems, _selectedId),
      labels: widget.labels,
      onSelect: _select,
    );

    return Semantics(
      container: true,
      label: widget.labels.evidenceIndex,
      child: ColoredBox(
        color: AtlasColors.indexPaper,
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            horizontal,
            layout.desktop ? 78 : 54,
            horizontal,
            layout.desktop ? 88 : 64,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              EvidenceIndexHeader(labels: widget.labels),
              SizedBox(height: layout.desktop ? 54 : 38),
              if (layout.desktop)
                DesktopEvidenceIndex(model: model)
              else
                EvidenceRows(model: model, compact: true),
            ],
          ),
        ),
      ),
    );
  }
}

/// Preview pane beside the index rows. Pointer entry warms the image cache.
final class DesktopEvidenceIndex extends StatefulWidget {
  const DesktopEvidenceIndex({super.key, required this.model});

  final EvidenceIndexModel model;

  @override
  State<DesktopEvidenceIndex> createState() => _DesktopEvidenceIndexState();
}

final class _DesktopEvidenceIndexState extends State<DesktopEvidenceIndex> {
  bool _warm = false;

  void _warmUp() {
    if (_warm) return;
    setState(() => _warm = true);
  }

  @override
  Widget build(BuildContext context) => MouseRegion(
    opaque: false,
    onEnter: (_) => _warmUp(),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: AtlasLayout.artifactFlex,
          child: DesktopSelectedEvidenceStage(model: widget.model, warm: _warm),
        ),
        const SizedBox(width: AtlasLayout.columnGap),
        Expanded(
          flex: AtlasLayout.narrativeFlex,
          child: EvidenceRows(model: widget.model, compact: false),
        ),
      ],
    ),
  );
}

/// Index title with its introduction beside it (tablet) or below it.
final class EvidenceIndexHeader extends StatelessWidget {
  const EvidenceIndexHeader({super.key, required this.labels});

  static const double introWidth = 420;

  final ProjectAtlasLabels labels;

  @override
  Widget build(BuildContext context) {
    final tablet = AtlasLayout.of(context).tablet;
    final intro = Text(
      labels.evidenceIntro,
      style: AppFonts.inter(
        fontSize: tablet ? 15 : 14,
        color: AtlasColors.introText,
        height: 1.55,
      ),
    );
    return Container(
      padding: const EdgeInsets.only(bottom: 24),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AtlasColors.rule)),
      ),
      child: tablet
          ? Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(child: _EvidenceIndexTitle(labels: labels)),
                const SizedBox(width: 48),
                SizedBox(width: introWidth, child: intro),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _EvidenceIndexTitle(labels: labels),
                const SizedBox(height: 18),
                intro,
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
        style: AtlasText.label(
          size: 10,
          color: AtlasColors.accent,
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
            fontSize: AtlasLayout.of(context).tablet ? 46 : 36,
            fontWeight: FontWeight.w700,
            color: AtlasColors.ink,
            height: 1,
            letterSpacing: -1.7,
          ),
        ),
      ),
    ],
  );
}
