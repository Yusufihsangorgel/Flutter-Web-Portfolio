typedef PortfolioSystemArtifactTranslation = ({
  String label,
  String alt,
  String caption,
  PortfolioArtifactVariant? compact,
});

typedef PortfolioSystemArtifactFields = ({
  String label,
  String asset,
  String alt,
  String caption,
  int width,
  int height,
  PortfolioArtifactFit fit,
  PortfolioArtifactAlignment alignment,
  PortfolioArtifactComposition composition,
  PortfolioArtifactVariant? compact,
});

/// Content-authored media for a work record. Rendering never branches on
/// project ids, names, or technologies.
final class PortfolioSystemArtifact {
  PortfolioSystemArtifact(PortfolioSystemArtifactFields fields)
    : label = fields.label,
      asset = fields.asset,
      alt = fields.alt,
      caption = fields.caption,
      width = fields.width,
      height = fields.height,
      fit = fields.fit,
      alignment = fields.alignment,
      composition = fields.composition,
      compact = fields.compact;

  PortfolioSystemArtifact copyWith(
    PortfolioSystemArtifactTranslation changes,
  ) => PortfolioSystemArtifact((
    label: changes.label,
    asset: asset,
    alt: changes.alt,
    caption: changes.caption,
    width: width,
    height: height,
    fit: fit,
    alignment: alignment,
    composition: composition,
    compact: changes.compact,
  ));

  Map<String, Object?> toJson() => {
    'label': label,
    'asset': asset,
    'alt': alt,
    'caption': caption,
    'width': width,
    'height': height,
    'fit': fit.wireValue,
    'alignment': alignment.wireValue,
    'composition': composition.wireValue,
    'compact': compact?.toJson(),
  };

  final String label;
  final String asset;
  final String alt;
  final String caption;
  final int width;
  final int height;
  final PortfolioArtifactFit fit;
  final PortfolioArtifactAlignment alignment;
  final PortfolioArtifactComposition composition;
  final PortfolioArtifactVariant? compact;
}

typedef PortfolioArtifactVariantTranslation = ({String alt, String caption});

typedef PortfolioArtifactVariantFields = ({
  String asset,
  String alt,
  String caption,
  int width,
  int height,
  PortfolioArtifactFit fit,
  PortfolioArtifactAlignment alignment,
});

/// Optional portrait media for compact project stages, with its own accessible
/// copy and intrinsic dimensions.
final class PortfolioArtifactVariant {
  PortfolioArtifactVariant(PortfolioArtifactVariantFields fields)
    : asset = fields.asset,
      alt = fields.alt,
      caption = fields.caption,
      width = fields.width,
      height = fields.height,
      fit = fields.fit,
      alignment = fields.alignment;

  PortfolioArtifactVariant copyWith(
    PortfolioArtifactVariantTranslation changes,
  ) => PortfolioArtifactVariant((
    asset: asset,
    alt: changes.alt,
    caption: changes.caption,
    width: width,
    height: height,
    fit: fit,
    alignment: alignment,
  ));

  Map<String, Object?> toJson() => {
    'asset': asset,
    'alt': alt,
    'caption': caption,
    'width': width,
    'height': height,
    'fit': fit.wireValue,
    'alignment': alignment.wireValue,
  };

  final String asset;
  final String alt;
  final String caption;
  final int width;
  final int height;
  final PortfolioArtifactFit fit;
  final PortfolioArtifactAlignment alignment;
}

enum PortfolioArtifactFit {
  contain('contain'),
  cover('cover');

  const PortfolioArtifactFit(this.wireValue);
  final String wireValue;

  static PortfolioArtifactFit parse(String value) => values.firstWhere(
    (entry) => entry.wireValue == value,
    orElse: () => throw FormatException('Unsupported artifact fit: $value'),
  );
}

enum PortfolioArtifactAlignment {
  start('start'),
  center('center'),
  end('end');

  const PortfolioArtifactAlignment(this.wireValue);
  final String wireValue;

  static PortfolioArtifactAlignment parse(String value) => values.firstWhere(
    (entry) => entry.wireValue == value,
    orElse: () =>
        throw FormatException('Unsupported artifact alignment: $value'),
  );
}

enum PortfolioArtifactComposition {
  portraitSplit('portrait_split'),
  evidenceStack('evidence_stack');

  const PortfolioArtifactComposition(this.wireValue);
  final String wireValue;

  static PortfolioArtifactComposition parse(String value) => values.firstWhere(
    (entry) => entry.wireValue == value,
    orElse: () =>
        throw FormatException('Unsupported artifact composition: $value'),
  );
}
