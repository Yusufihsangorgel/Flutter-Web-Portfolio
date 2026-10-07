import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_web_portfolio/app/domain/models/portfolio_document.dart';

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
