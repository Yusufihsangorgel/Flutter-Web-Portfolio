import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter_web_portfolio/app/narrative/domain/narrative_document.dart';
import 'package:flutter_web_portfolio/app/narrative/rendering/narrative_spine_geometry.dart';

/// Four points describing the quiet cubic bridge between two chapters.
@immutable
final class NarrativeHandoffShape {
  const NarrativeHandoffShape({
    required this.start,
    required this.controlStart,
    required this.controlEnd,
    required this.end,
  });

  final Offset start;
  final Offset controlStart;
  final Offset controlEnd;
  final Offset end;

  Path toPath() => Path()
    ..moveTo(start.dx, start.dy)
    ..cubicTo(
      controlStart.dx,
      controlStart.dy,
      controlEnd.dx,
      controlEnd.dy,
      end.dx,
      end.dy,
    );
}

/// Resolves a motif-to-motif bridge without inventing new anchor positions.
abstract final class NarrativeHandoffGeometry {
  static NarrativeHandoffShape resolve({
    required Size size,
    required NarrativeMotif from,
    required NarrativeMotif to,
    required TextDirection textDirection,
  }) {
    if (!size.width.isFinite ||
        !size.height.isFinite ||
        size.width <= 0 ||
        size.height <= 0) {
      throw ArgumentError.value(size, 'size', 'must be finite and positive');
    }

    final fromAnchor = NarrativeSpineGeometry.normalizedAnchor(
      from,
      NarrativeSpineEdge.exit,
    );
    final toAnchor = NarrativeSpineGeometry.normalizedAnchor(
      to,
      NarrativeSpineEdge.entry,
    );
    final rtl = textDirection == TextDirection.rtl;
    final startX = (rtl ? 1 - fromAnchor.dx : fromAnchor.dx) * size.width;
    final endX = (rtl ? 1 - toAnchor.dx : toAnchor.dx) * size.width;

    return NarrativeHandoffShape(
      start: Offset(startX, 0),
      controlStart: Offset(startX, size.height * 0.34),
      controlEnd: Offset(endX, size.height * 0.66),
      end: Offset(endX, size.height),
    );
  }
}
