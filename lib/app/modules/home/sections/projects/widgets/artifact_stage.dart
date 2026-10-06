import 'package:flutter/material.dart';
import 'package:flutter_web_portfolio/app/core/theme/app_fonts.dart';
import 'package:flutter_web_portfolio/app/domain/models/portfolio_document.dart';
import 'package:flutter_web_portfolio/app/modules/home/sections/projects/widgets/atlas_style.dart';
import 'package:flutter_web_portfolio/app/modules/home/sections/projects/widgets/project_palette.dart';
import 'package:flutter_web_portfolio/app/modules/home/sections/projects/widgets/viewport_proximity_gate.dart';

/// How an [ArtifactStage] paints its image.
@immutable
final class ArtifactRendering {
  const ArtifactRendering({
    this.prominent = false,
    this.paintImage = true,
    this.cacheWidth,
  });

  /// The larger frame used by featured case studies.
  static const featured = ArtifactRendering(prominent: true);

  /// Reserves the exact geometry without requesting the image.
  static const measureOnly = ArtifactRendering(paintImage: false);

  final bool prominent;
  final bool paintImage;
  final int? cacheWidth;
}

/// The landscape board or its portrait crop, resolved for one viewport.
@immutable
final class ArtifactView {
  const ArtifactView._(this._artifact, this._variant);

  /// Uses the portrait crop when [compact] and the content provides one.
  factory ArtifactView.resolve(
    PortfolioSystemArtifact artifact, {
    required bool compact,
  }) => ArtifactView._(artifact, compact ? artifact.compact : null);

  final PortfolioSystemArtifact _artifact;
  final PortfolioArtifactVariant? _variant;

  String get asset => _variant?.asset ?? _artifact.asset;
  String get alt => _variant?.alt ?? _artifact.alt;
  String get caption => _variant?.caption ?? _artifact.caption;

  double get aspectRatio =>
      (_variant?.width ?? _artifact.width) /
      (_variant?.height ?? _artifact.height);

  BoxFit get fit => switch (_variant?.fit ?? _artifact.fit) {
    PortfolioArtifactFit.contain => BoxFit.contain,
    PortfolioArtifactFit.cover => BoxFit.cover,
  };

  AlignmentGeometry get alignment =>
      switch (_variant?.alignment ?? _artifact.alignment) {
        PortfolioArtifactAlignment.start => AlignmentDirectional.centerStart,
        PortfolioArtifactAlignment.center => Alignment.center,
        PortfolioArtifactAlignment.end => AlignmentDirectional.centerEnd,
      };
}

/// A labelled, framed project artifact with its caption.
final class ArtifactStage extends StatelessWidget {
  const ArtifactStage({
    super.key,
    required this.system,
    required this.palette,
    this.rendering = const ArtifactRendering(),
  });

  final PortfolioSystem system;
  final ProjectPalette palette;
  final ArtifactRendering rendering;

  @override
  Widget build(BuildContext context) {
    final view = ArtifactView.resolve(
      system.artifact,
      compact: AtlasLayout.of(context).usesCompactArtifacts,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                system.artifact.label,
                style: AtlasText.label(
                  size: 10,
                  color: palette.ink(AtlasAlpha.label),
                  letterSpacing: 0.75,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 13),
        _ArtifactFrame(view: view, palette: palette, rendering: rendering),
        const SizedBox(height: 12),
        Text(
          view.caption,
          style: AppFonts.inter(
            fontSize: 11,
            color: palette.ink(AtlasAlpha.caption),
            height: 1.45,
          ),
        ),
      ],
    );
  }
}

final class _ArtifactFrame extends StatelessWidget {
  const _ArtifactFrame({
    required this.view,
    required this.palette,
    required this.rendering,
  });

  final ArtifactView view;
  final ProjectPalette palette;
  final ArtifactRendering rendering;

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: palette.ink(AtlasAlpha.surface),
      border: Border.all(color: palette.ink(AtlasAlpha.rule)),
    ),
    child: AspectRatio(
      aspectRatio: view.aspectRatio,
      child: Padding(
        padding: EdgeInsets.all(rendering.prominent ? 10 : 8),
        child: Semantics(
          image: true,
          label: view.alt,
          excludeSemantics: true,
          child: ExcludeSemantics(
            child: rendering.paintImage
                ? ViewportProximityGate(builder: _buildImage)
                : const SizedBox.expand(),
          ),
        ),
      ),
    ),
  );

  Widget _buildImage(BuildContext context) => Image.asset(
    view.asset,
    fit: view.fit,
    alignment: view.alignment,
    filterQuality: FilterQuality.high,
    cacheWidth: rendering.cacheWidth,
  );
}
