import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_web_portfolio/app/narrative/domain/narrative_anchor.dart';
import 'package:flutter_web_portfolio/app/narrative/domain/narrative_document.dart';
import 'package:flutter_web_portfolio/app/narrative/domain/section_geometry.dart';

/// Measures chapter and anchor bounds in document space.
final class SectionGeometryTracker {
  SectionGeometryTracker(this.narrative);

  final NarrativeDocument narrative;
  late final Map<SectionId, GlobalKey> _sectionKeys = {
    for (final chapter in narrative.chapters) chapter.id: GlobalKey(),
  };
  late final Map<SectionId, GlobalKey> _anchorKeys = {
    for (final chapter in narrative.chapters) chapter.id: GlobalKey(),
  };
  final ValueNotifier<NarrativeAnchorSnapshot> anchors = ValueNotifier(
    const NarrativeAnchorSnapshot.empty(),
  );
  List<SectionGeometry> _sections = const [];

  List<SectionGeometry> get sections => _sections;

  GlobalKey keyFor(SectionId id) => _keyFor(_sectionKeys, id);
  GlobalKey anchorKeyFor(SectionId id) => _keyFor(_anchorKeys, id);

  GlobalKey _keyFor(Map<SectionId, GlobalKey> keys, SectionId id) {
    final key = keys[id];
    if (key == null) {
      throw ArgumentError.value(
        id.value,
        'sectionId',
        'is not in the narrative',
      );
    }
    return key;
  }

  SectionGeometry? sectionFor(String id) {
    for (final section in _sections) {
      if (section.id == id) return section;
    }
    return null;
  }

  void measure(double scrollOffset) {
    final next = <SectionGeometry>[];
    for (final chapter in narrative.chapters) {
      final box = keyFor(chapter.id).currentContext?.findRenderObject();
      if (box is! RenderBox || !box.hasSize) continue;
      final viewport = RenderAbstractViewport.maybeOf(box);
      if (viewport == null) continue;
      next.add(
        SectionGeometry(
          id: chapter.id.value,
          top: viewport.getOffsetToReveal(box, 0).offset,
          height: box.size.height,
        ),
      );
    }
    final changed = !listEquals(_sections, next);
    if (changed) _sections = List.unmodifiable(next);
    _measureAnchors(scrollOffset);
  }

  void _measureAnchors(double scrollOffset) {
    final next = <NarrativeAnchorGeometry>[];
    for (final chapter in narrative.chapters) {
      final box = anchorKeyFor(chapter.id).currentContext?.findRenderObject();
      if (box is! RenderBox || !box.hasSize) continue;
      final center = box.localToGlobal(box.size.center(Offset.zero));
      next.add(
        NarrativeAnchorGeometry(
          sectionId: chapter.id,
          motif: chapter.motif,
          documentCenter: NarrativePoint(center.dx, center.dy + scrollOffset),
          size: NarrativeSize(box.size.width, box.size.height),
        ),
      );
    }
    final snapshot = NarrativeAnchorSnapshot(next);
    if (anchors.value != snapshot) anchors.value = snapshot;
  }

  void dispose() => anchors.dispose();
}
