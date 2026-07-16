import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter_web_portfolio/app/narrative/domain/narrative_document.dart';

/// One measured visual attachment point inside the portfolio document.
///
/// The vertical coordinate lives in document space so the render layer can
/// translate the complete path with one scroll offset. The horizontal
/// coordinate is viewport-relative and is refreshed whenever layout changes.
@immutable
final class NarrativeAnchorGeometry {
  const NarrativeAnchorGeometry({
    required this.sectionId,
    required this.motif,
    required this.documentCenter,
    required this.size,
  });

  final SectionId sectionId;
  final NarrativeMotif motif;
  final Offset documentCenter;
  final Size size;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NarrativeAnchorGeometry &&
          sectionId == other.sectionId &&
          motif == other.motif &&
          documentCenter == other.documentCenter &&
          size == other.size;

  @override
  int get hashCode => Object.hash(sectionId, motif, documentCenter, size);
}

/// Immutable anchor geometry shared by scroll, rendering, and regression tests.
@immutable
final class NarrativeAnchorSnapshot {
  NarrativeAnchorSnapshot(Iterable<NarrativeAnchorGeometry> anchors)
    : anchors = List<NarrativeAnchorGeometry>.unmodifiable(anchors) {
    final ids = <SectionId>{};
    var previousY = double.negativeInfinity;
    for (final anchor in this.anchors) {
      if (!ids.add(anchor.sectionId)) {
        throw ArgumentError.value(
          anchor.sectionId.value,
          'anchors',
          'section ids must be unique',
        );
      }
      if (!anchor.documentCenter.dx.isFinite ||
          !anchor.documentCenter.dy.isFinite ||
          !anchor.size.width.isFinite ||
          !anchor.size.height.isFinite ||
          anchor.size.isEmpty) {
        throw ArgumentError.value(
          anchor,
          'anchors',
          'geometry must be finite and non-empty',
        );
      }
      if (anchor.documentCenter.dy <= previousY) {
        throw ArgumentError.value(
          anchor,
          'anchors',
          'document coordinates must be strictly ordered',
        );
      }
      previousY = anchor.documentCenter.dy;
    }
  }

  const NarrativeAnchorSnapshot.empty()
    : anchors = const <NarrativeAnchorGeometry>[];

  final List<NarrativeAnchorGeometry> anchors;

  bool get isEmpty => anchors.isEmpty;

  NarrativeAnchorGeometry? anchorFor(SectionId sectionId) {
    for (final anchor in anchors) {
      if (anchor.sectionId == sectionId) return anchor;
    }
    return null;
  }

  bool covers(Iterable<SectionId> sectionIds) {
    for (final sectionId in sectionIds) {
      if (anchorFor(sectionId) == null) return false;
    }
    return true;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NarrativeAnchorSnapshot && listEquals(anchors, other.anchors);

  @override
  int get hashCode => Object.hashAll(anchors);
}
