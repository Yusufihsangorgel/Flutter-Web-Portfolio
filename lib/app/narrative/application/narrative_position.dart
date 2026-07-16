import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter_web_portfolio/app/narrative/domain/section_geometry.dart';

/// One resolved reading position in the measured portfolio narrative.
///
/// The active chapter is suitable for navigation state. [currentSectionId],
/// [nextSectionId], and [boundaryProgress] describe the boundary-local visual
/// handoff consumed by the scene layer.
@immutable
final class NarrativePosition {
  const NarrativePosition({
    required this.activeSectionId,
    required this.currentSectionId,
    required this.nextSectionId,
    required this.focalPoint,
    required this.boundaryProgress,
    required this.documentProgress,
  });

  const NarrativePosition.initial()
    : activeSectionId = 'home',
      currentSectionId = 'home',
      nextSectionId = 'home',
      focalPoint = 0,
      boundaryProgress = 0,
      documentProgress = 0;

  final String activeSectionId;
  final String currentSectionId;
  final String nextSectionId;
  final double focalPoint;
  final double boundaryProgress;
  final double documentProgress;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NarrativePosition &&
          activeSectionId == other.activeSectionId &&
          currentSectionId == other.currentSectionId &&
          nextSectionId == other.nextSectionId &&
          focalPoint == other.focalPoint &&
          boundaryProgress == other.boundaryProgress &&
          documentProgress == other.documentProgress;

  @override
  int get hashCode => Object.hash(
    activeSectionId,
    currentSectionId,
    nextSectionId,
    focalPoint,
    boundaryProgress,
    documentProgress,
  );
}

/// Resolves scroll coordinates into a chapter and a short boundary handoff.
///
/// Section heights do not influence transition duration. Every handoff is
/// centred on the next section's measured top and occupies the same physical
/// viewport-relative window.
abstract final class NarrativePositionResolver {
  static NarrativePosition resolve({
    required double offset,
    required double viewportDimension,
    required double topInset,
    required List<SectionGeometry> sections,
  }) {
    _validateInputs(
      offset: offset,
      viewportDimension: viewportDimension,
      topInset: topInset,
      sections: sections,
    );
    if (sections.isEmpty) return const NarrativePosition.initial();

    final usableViewport = math.max(0.0, viewportDimension - topInset);
    final focalPoint = offset + topInset + usableViewport * 0.28;
    final firstTop = sections.first.top;
    final lastBottom = sections.last.bottom;
    final documentProgress = ((focalPoint - firstTop) / (lastBottom - firstTop))
        .clamp(0.0, 1.0)
        .toDouble();

    if (sections.length == 1) {
      final sectionId = sections.single.id;
      return NarrativePosition(
        activeSectionId: sectionId,
        currentSectionId: sectionId,
        nextSectionId: sectionId,
        focalPoint: focalPoint,
        boundaryProgress: 0,
        documentProgress: documentProgress,
      );
    }

    final transitionExtent = (viewportDimension * 0.32)
        .clamp(160.0, 320.0)
        .toDouble();
    final halfTransitionExtent = transitionExtent / 2;

    for (var index = 1; index < sections.length; index += 1) {
      final current = sections[index - 1];
      final next = sections[index];
      final windowStart = next.top - halfTransitionExtent;
      final windowEnd = next.top + halfTransitionExtent;

      if (focalPoint < windowStart) {
        return _stablePosition(
          sectionId: current.id,
          focalPoint: focalPoint,
          documentProgress: documentProgress,
        );
      }
      if (focalPoint <= windowEnd) {
        final boundaryProgress = ((focalPoint - windowStart) / transitionExtent)
            .clamp(0.0, 1.0)
            .toDouble();
        return NarrativePosition(
          activeSectionId: boundaryProgress < 0.5 ? current.id : next.id,
          currentSectionId: current.id,
          nextSectionId: next.id,
          focalPoint: focalPoint,
          boundaryProgress: boundaryProgress,
          documentProgress: documentProgress,
        );
      }
    }

    return _stablePosition(
      sectionId: sections.last.id,
      focalPoint: focalPoint,
      documentProgress: documentProgress,
    );
  }

  static NarrativePosition _stablePosition({
    required String sectionId,
    required double focalPoint,
    required double documentProgress,
  }) => NarrativePosition(
    activeSectionId: sectionId,
    currentSectionId: sectionId,
    nextSectionId: sectionId,
    focalPoint: focalPoint,
    boundaryProgress: 0,
    documentProgress: documentProgress,
  );

  static void _validateInputs({
    required double offset,
    required double viewportDimension,
    required double topInset,
    required List<SectionGeometry> sections,
  }) {
    if (!offset.isFinite) {
      throw ArgumentError.value(offset, 'offset', 'must be finite');
    }
    if (!viewportDimension.isFinite || viewportDimension <= 0) {
      throw ArgumentError.value(
        viewportDimension,
        'viewportDimension',
        'must be finite and positive',
      );
    }
    if (!topInset.isFinite || topInset < 0) {
      throw ArgumentError.value(
        topInset,
        'topInset',
        'must be finite and non-negative',
      );
    }

    final seenIds = <String>{};
    SectionGeometry? previous;
    for (final section in sections) {
      if (section.id.trim().isEmpty) {
        throw ArgumentError.value(
          section.id,
          'sections',
          'id must not be empty',
        );
      }
      if (!seenIds.add(section.id)) {
        throw ArgumentError.value(section.id, 'sections', 'ids must be unique');
      }
      if (!section.top.isFinite || section.top < 0) {
        throw ArgumentError.value(
          section.top,
          'sections',
          'top must be finite and non-negative',
        );
      }
      if (!section.height.isFinite || section.height <= 0) {
        throw ArgumentError.value(
          section.height,
          'sections',
          'height must be finite and positive',
        );
      }
      if (previous != null && section.top < previous.bottom) {
        throw ArgumentError.value(
          section.top,
          'sections',
          'sections must be ordered and must not overlap',
        );
      }
      previous = section;
    }
  }
}
