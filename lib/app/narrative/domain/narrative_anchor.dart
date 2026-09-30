import 'package:flutter_web_portfolio/app/narrative/domain/narrative_document.dart';

/// A framework-free point.
final class NarrativePoint {
  const NarrativePoint(this.dx, this.dy);

  final double dx;
  final double dy;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NarrativePoint && dx == other.dx && dy == other.dy;

  @override
  int get hashCode => Object.hash(dx, dy);
}

/// A framework-free size.
final class NarrativeSize {
  const NarrativeSize(this.width, this.height);

  final double width;
  final double height;
  bool get isEmpty => width <= 0 || height <= 0;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NarrativeSize && width == other.width && height == other.height;

  @override
  int get hashCode => Object.hash(width, height);
}

/// Locates a chapter attachment point in document space.
final class NarrativeAnchorGeometry {
  const NarrativeAnchorGeometry({
    required this.sectionId,
    required this.motif,
    required this.documentCenter,
    required this.size,
  });

  final SectionId sectionId;
  final NarrativeMotif motif;
  final NarrativePoint documentCenter;
  final NarrativeSize size;

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

/// Anchors for every measured chapter, ordered from top to bottom.
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
      other is NarrativeAnchorSnapshot && _sameAnchors(anchors, other.anchors);

  @override
  int get hashCode => Object.hashAll(anchors);

  static bool _sameAnchors(
    List<NarrativeAnchorGeometry> a,
    List<NarrativeAnchorGeometry> b,
  ) {
    if (a.length != b.length) return false;
    for (var index = 0; index < a.length; index += 1) {
      if (a[index] != b[index]) return false;
    }
    return true;
  }
}
