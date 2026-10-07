import 'package:flutter/material.dart';
import 'package:flutter_web_portfolio/app/controllers/scroll/section_geometry_tracker.dart';
import 'package:flutter_web_portfolio/app/core/constants/durations.dart';

/// Moves the scroll position to the top of a chapter.
final class SectionScroller {
  SectionScroller(this.scrollController, this.geometry);

  final ScrollController scrollController;
  final SectionGeometryTracker geometry;

  Future<void>? scrollTo(String sectionId, {required bool reduceMotion}) {
    if (!scrollController.hasClients) return null;
    if (!scrollController.position.hasContentDimensions) return null;
    final section = geometry.sectionFor(sectionId);
    if (section == null) return null;
    final offset = (sectionId == 'home' ? 0.0 : section.top)
        .clamp(0.0, scrollController.position.maxScrollExtent)
        .toDouble();
    if (reduceMotion) {
      scrollController.jumpTo(offset);
      return Future<void>.value();
    }
    return scrollController.animateTo(
      offset,
      duration: AppDurations.sectionScroll,
      curve: Curves.easeInOut,
    );
  }

  bool jumpTo(String sectionId) {
    if (!scrollController.hasClients) return false;
    if (!scrollController.position.hasContentDimensions) return false;
    final section = geometry.sectionFor(sectionId);
    if (section == null) return false;
    final offset = (sectionId == 'home' ? 0.0 : section.top)
        .clamp(0.0, scrollController.position.maxScrollExtent)
        .toDouble();
    scrollController.jumpTo(offset);
    return true;
  }
}
