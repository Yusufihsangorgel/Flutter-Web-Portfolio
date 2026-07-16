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

  /// Samples the same cubic used by [toPath] without allocating path metrics.
  Offset pointAt(double progress) {
    final t = progress.clamp(0.0, 1.0);
    final inverse = 1 - t;
    final inverse2 = inverse * inverse;
    final t2 = t * t;
    return Offset(
      inverse2 * inverse * start.dx +
          3 * inverse2 * t * controlStart.dx +
          3 * inverse * t2 * controlEnd.dx +
          t2 * t * end.dx,
      inverse2 * inverse * start.dy +
          3 * inverse2 * t * controlStart.dy +
          3 * inverse * t2 * controlEnd.dy +
          t2 * t * end.dy,
    );
  }
}

/// Direction-aware geometry for the chapter label and its progress rail.
///
/// In LTR the rail grows away from the label towards the right edge. In RTL
/// the label is right-aligned and the rail grows away from it towards the
/// left edge.
@immutable
final class NarrativeHandoffRailGeometry {
  const NarrativeHandoffRailGeometry({
    required this.labelOffset,
    required this.lineStart,
    required this.lineEnd,
  });

  final Offset labelOffset;
  final Offset lineStart;
  final Offset lineEnd;

  static NarrativeHandoffRailGeometry resolve({
    required Size size,
    required Size labelSize,
    required TextDirection textDirection,
    required double inset,
    required double labelY,
    required double lineY,
    double gap = 16,
  }) {
    if (!size.width.isFinite ||
        !size.height.isFinite ||
        size.width <= 0 ||
        size.height <= 0 ||
        !labelSize.width.isFinite ||
        !labelSize.height.isFinite ||
        labelSize.width < 0 ||
        labelSize.height < 0 ||
        !inset.isFinite ||
        inset < 0 ||
        !gap.isFinite ||
        gap < 0) {
      throw ArgumentError('Rail bounds must be finite and non-negative.');
    }

    final rtl = textDirection == TextDirection.rtl;
    final labelX = rtl ? size.width - inset - labelSize.width : inset;
    final nearLabel = rtl ? labelX - gap : labelX + labelSize.width + gap;
    return NarrativeHandoffRailGeometry(
      labelOffset: Offset(labelX, labelY),
      lineStart: Offset(nearLabel, lineY),
      lineEnd: Offset(rtl ? inset : size.width - inset, lineY),
    );
  }
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
