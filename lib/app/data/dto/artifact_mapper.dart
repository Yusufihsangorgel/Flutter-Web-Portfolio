import 'package:flutter_web_portfolio/app/data/dto/json_fields.dart';
import 'package:flutter_web_portfolio/app/domain/models/artifact.dart';

typedef _ArtifactMedia = ({
  String asset,
  String alt,
  String caption,
  int width,
  int height,
});

PortfolioSystemArtifact parsePortfolioSystemArtifact(
  Map<String, dynamic> json,
) {
  final media = _parseArtifactMedia(json);
  final artifact = PortfolioSystemArtifact((
    label: requiredString(json, 'label'),
    asset: media.asset,
    alt: media.alt,
    caption: media.caption,
    width: media.width,
    height: media.height,
    fit: PortfolioArtifactFit.parse(requiredString(json, 'fit')),
    alignment: PortfolioArtifactAlignment.parse(
      requiredString(json, 'alignment'),
    ),
    composition: PortfolioArtifactComposition.parse(
      requiredString(json, 'composition'),
    ),
    compact: switch (optionalObject(json, 'compact')) {
      final value? => _parsePortfolioArtifactVariant(value),
      null => null,
    },
  ));
  if ((artifact.composition == PortfolioArtifactComposition.portraitSplit &&
          artifact.width >= artifact.height) ||
      (artifact.composition == PortfolioArtifactComposition.evidenceStack &&
          artifact.width < artifact.height)) {
    throw const FormatException(
      'Project artifact composition must match its intrinsic orientation.',
    );
  }
  return artifact;
}

PortfolioArtifactVariant _parsePortfolioArtifactVariant(
  Map<String, dynamic> json,
) {
  final media = _parseArtifactMedia(json);
  if (media.width >= media.height) {
    throw const FormatException(
      'Compact project artifacts must use a portrait asset.',
    );
  }
  return PortfolioArtifactVariant((
    asset: media.asset,
    alt: media.alt,
    caption: media.caption,
    width: media.width,
    height: media.height,
    fit: PortfolioArtifactFit.parse(requiredString(json, 'fit')),
    alignment: PortfolioArtifactAlignment.parse(
      requiredString(json, 'alignment'),
    ),
  ));
}

_ArtifactMedia _parseArtifactMedia(Map<String, dynamic> json) {
  final media = (
    asset: requiredString(json, 'asset'),
    alt: requiredString(json, 'alt'),
    caption: requiredString(json, 'caption'),
    width: requiredInt(json, 'width'),
    height: requiredInt(json, 'height'),
  );
  if (!media.asset.startsWith('assets/work/') ||
      media.asset.contains('..') ||
      !const ['.png', '.jpg', '.jpeg', '.webp'].any(media.asset.endsWith) ||
      media.width <= 0 ||
      media.height <= 0 ||
      media.alt == media.caption) {
    throw const FormatException(
      'Project artifacts require a supported local asset, positive dimensions, and distinct accessible copy.',
    );
  }
  return media;
}
