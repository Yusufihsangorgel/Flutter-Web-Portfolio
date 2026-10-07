import 'dart:async' show unawaited;
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_web_portfolio/app/core/theme/app_fonts.dart';
import 'package:flutter_web_portfolio/app/domain/models/portfolio_document.dart';
import 'package:flutter_web_portfolio/app/modules/home/sections/projects/widgets/artifact_stage.dart';
import 'package:flutter_web_portfolio/app/modules/home/sections/projects/widgets/atlas_labels.dart';
import 'package:flutter_web_portfolio/app/modules/home/sections/projects/widgets/atlas_parts.dart';
import 'package:flutter_web_portfolio/app/modules/home/sections/projects/widgets/atlas_style.dart';
import 'package:flutter_web_portfolio/app/modules/home/sections/projects/widgets/evidence_index_model.dart';
import 'package:flutter_web_portfolio/app/modules/home/sections/projects/widgets/project_palette.dart';

/// Desktop preview pane sized for the tallest supporting system, so changing
/// the selection never moves the index rows beside it.
///
/// Once [warm] (the pointer reached the index), every preview image is
/// decoded ahead of time so hover swaps paint without a blank frame.
final class DesktopSelectedEvidenceStage extends StatefulWidget {
  const DesktopSelectedEvidenceStage({
    super.key,
    required this.model,
    required this.warm,
  });

  final EvidenceIndexModel model;
  final bool warm;

  @override
  State<DesktopSelectedEvidenceStage> createState() =>
      _DesktopSelectedEvidenceStageState();
}

final class _DesktopSelectedEvidenceStageState
    extends State<DesktopSelectedEvidenceStage> {
  final Set<int> _scheduledCacheWidths = <int>{};

  int _cacheWidthFor(PortfolioSupportingSystem system, int requestedWidth) =>
      math.min(system.artifact.width, requestedWidth);

  void _scheduleArtifactPrecache(int requestedWidth) {
    if (!_scheduledCacheWidths.add(requestedWidth)) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      for (final system in widget.model.systems) {
        final provider = ResizeImage.resizeIfNeeded(
          _cacheWidthFor(system, requestedWidth),
          null,
          AssetImage(system.artifact.asset),
        );
        unawaited(precacheImage(provider, context));
      }
    });
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final requestedCacheWidth = math.max(
        1,
        (constraints.maxWidth * MediaQuery.devicePixelRatioOf(context)).ceil(),
      );
      if (widget.warm) _scheduleArtifactPrecache(requestedCacheWidth);
      final model = widget.model;

      // Transparent, non-interactive copies establish the tallest panel for
      // the current locale and viewport without constructing image widgets.
      return Stack(
        children: [
          for (final system in model.systems)
            IgnorePointer(
              child: ExcludeSemantics(
                child: Opacity(
                  opacity: 0,
                  child: SelectedEvidenceStage(
                    system: system,
                    labels: model.labels,
                    rendering: ArtifactRendering.measureOnly,
                  ),
                ),
              ),
            ),
          Positioned.fill(
            child: SelectedEvidenceStage(
              system: model.selected,
              labels: model.labels,
              rendering: ArtifactRendering(
                cacheWidth: _cacheWidthFor(model.selected, requestedCacheWidth),
              ),
            ),
          ),
        ],
      );
    },
  );
}

/// One supporting system's preview on its content-authored palette.
final class SelectedEvidenceStage extends StatelessWidget {
  const SelectedEvidenceStage({
    super.key,
    required this.system,
    required this.labels,
    this.rendering = const ArtifactRendering(),
  });

  final PortfolioSupportingSystem system;
  final ProjectAtlasLabels labels;
  final ArtifactRendering rendering;

  // Selection swaps are atomic: cross-fading two panels overlaps their text,
  // and animating height can move the row under a stationary pointer.
  @override
  Widget build(BuildContext context) => ColoredBox(
    color: hexColor(system.presentation.background),
    child: Padding(
      padding: EdgeInsets.all(AtlasLayout.of(context).tablet ? 28 : 20),
      child: SelectedEvidenceContent(
        key: rendering.paintImage
            ? ValueKey('selected-evidence-${system.id}')
            : null,
        system: system,
        labels: labels,
        rendering: rendering,
      ),
    ),
  );
}

/// Kind, name, spotlight, artifact, ownership, decision, and links.
final class SelectedEvidenceContent extends StatelessWidget {
  const SelectedEvidenceContent({
    super.key,
    required this.system,
    required this.labels,
    required this.rendering,
  });

  final PortfolioSupportingSystem system;
  final ProjectAtlasLabels labels;
  final ArtifactRendering rendering;

  @override
  Widget build(BuildContext context) {
    final palette = ProjectPalette.from(system.presentation);
    final tablet = AtlasLayout.of(context).tablet;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        _SelectedEvidenceMeta(system: system, palette: palette),
        const SizedBox(height: 22),
        Semantics(
          header: true,
          headingLevel: 4,
          child: Text(
            system.name,
            style: AppFonts.spaceGrotesk(
              fontSize: tablet ? 34 : 27,
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
            color: palette.ink(AtlasAlpha.spotlight),
            height: 1.52,
          ),
        ),
        const SizedBox(height: 28),
        ArtifactStage(system: system, palette: palette, rendering: rendering),
        const SizedBox(height: 28),
        NarrativeBeat(
          label: labels.ownership,
          value: system.ownership,
          palette: palette,
        ),
        const SizedBox(height: 22),
        NarrativeBeat(
          label: labels.decision,
          value: system.decision,
          palette: palette,
        ),
        const SizedBox(height: 26),
        EvidenceLinks(
          system: system,
          openLabel: labels.openEvidence,
          palette: palette,
        ),
      ],
    );
  }
}

final class _SelectedEvidenceMeta extends StatelessWidget {
  const _SelectedEvidenceMeta({required this.system, required this.palette});

  final PortfolioSupportingSystem system;
  final ProjectPalette palette;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: Text(
          system.kind.toUpperCase(),
          style: AtlasText.label(
            size: 10,
            color: palette.foreground,
            letterSpacing: 0.75,
          ),
        ),
      ),
      Text(
        system.year,
        style: AtlasText.label(
          size: 10,
          weight: FontWeight.w700,
          color: palette.ink(AtlasAlpha.secondary),
        ),
      ),
    ],
  );
}
