import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:flutter_web_portfolio/app/core/constants/app_dimensions.dart';
import 'package:flutter_web_portfolio/app/core/constants/reading_focus.dart';
import 'package:flutter_web_portfolio/app/narrative/application/narrative_position.dart';
import 'package:flutter_web_portfolio/app/controllers/scroll/section_geometry_tracker.dart';

/// A reading position inside one chapter.
final class ReadingAnchor {
  const ReadingAnchor(
    this.sectionId,
    this.localOffset,
    this.localProgress,
    this.preserveLocalOffset,
  );

  final String sectionId;
  final double localOffset;
  final double localProgress;
  final bool preserveLocalOffset;
}

/// Keeps the reader in place inside a chapter while content above it reflows.
final class ReadingAnchorRestorer {
  ReadingAnchorRestorer(this.scrollController, this.geometry);

  final ScrollController scrollController;
  final SectionGeometryTracker geometry;
  ReadingAnchor? _held;

  bool get isHolding => _held != null;

  /// Pins the top of [sectionId] until [release] is called.
  void holdChapter(String sectionId) {
    _held = ReadingAnchor(sectionId, 0, 0, true);
  }

  void release() => _held = null;

  ReadingAnchor? capture(NarrativePosition position) {
    if (_held case final held?) return held;
    if (!scrollController.hasClients) return null;
    if (!scrollController.position.hasViewportDimension) return null;
    final section = geometry.sectionFor(position.activeSectionId);
    if (section == null || section.height <= 0) return null;
    final localOffset = (position.focalPoint - section.top)
        .clamp(0.0, section.height)
        .toDouble();
    final viewport = scrollController.position.viewportDimension;
    final focalOffset = _focalOffset(scrollController.offset, viewport);
    final usable = math.max(
      0.0,
      viewport -
          AppDimensions.appBarHeightForScrollOffset(scrollController.offset),
    );
    return ReadingAnchor(
      section.id,
      localOffset,
      localOffset / section.height,
      localOffset <= focalOffset + usable * 0.25,
    );
  }

  void restore(ReadingAnchor anchor) {
    if (!scrollController.hasClients) return;
    if (!scrollController.position.hasContentDimensions) return;
    final section = geometry.sectionFor(anchor.sectionId);
    if (section == null) return;
    if (identical(anchor, _held)) {
      _jumpTo(section.top);
      return;
    }
    final local = anchor.preserveLocalOffset
        ? anchor.localOffset.clamp(0.0, section.height).toDouble()
        : section.height * anchor.localProgress;
    final desiredFocal = section.top + local;
    final viewport = scrollController.position.viewportDimension;
    var target = scrollController.offset;
    for (var iteration = 0; iteration < 2; iteration += 1) {
      target = desiredFocal - _focalOffset(target, viewport);
    }
    _jumpTo(target);
  }

  void restoreHeld() {
    if (_held case final anchor?) restore(anchor);
  }

  void _jumpTo(double offset) {
    final target = offset
        .clamp(0.0, scrollController.position.maxScrollExtent)
        .toDouble();
    if ((target - scrollController.offset).abs() >= 0.5) {
      scrollController.jumpTo(target);
    }
  }

  double _focalOffset(double offset, double viewport) {
    final inset = AppDimensions.appBarHeightForScrollOffset(offset);
    return inset + math.max(0.0, viewport - inset) * ReadingFocus.ratio;
  }
}
