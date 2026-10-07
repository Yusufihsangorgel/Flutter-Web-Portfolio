import 'package:flutter/material.dart';
import 'package:flutter_web_portfolio/app/core/theme/app_fonts.dart';
import 'package:flutter_web_portfolio/app/domain/models/portfolio_document.dart';
import 'package:flutter_web_portfolio/app/modules/home/sections/projects/widgets/artifact_picture.dart';
import 'package:flutter_web_portfolio/app/modules/home/sections/projects/widgets/artifact_view.dart';
import 'package:flutter_web_portfolio/app/modules/home/sections/projects/widgets/atlas_style.dart';
import 'package:flutter_web_portfolio/app/modules/home/sections/projects/widgets/project_palette.dart';

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
        child: rendering.paintImage
            ? ArtifactPicture(
                view: view,
                image: ResizeImage.resizeIfNeeded(
                  rendering.cacheWidth,
                  null,
                  AssetImage(view.asset),
                ),
              )
            : Semantics(
                image: true,
                label: view.alt,
                excludeSemantics: true,
                child: const SizedBox.expand(),
              ),
      ),
    ),
  );
}
