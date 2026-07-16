import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter_web_portfolio/app/narrative/domain/narrative_anchor.dart';

/// Allocation-bounded path joining measured content anchors in document space.
///
/// The path leaves each content anchor, travels through a quiet page-margin
/// corridor, and returns to the next real anchor. Scrolling only translates
/// the canvas; path geometry is rebuilt exclusively after responsive layout or
/// locale changes.
final class NarrativeAnchorPathKernel {
  Path get path => _path;
  bool get isEmpty => _isEmpty;
  double get corridorX => _corridorX;
  int get anchorCount => _anchorCount;

  final Path _path = Path();
  Float64List _coordinates = Float64List(0);
  Float64List _shoulders = Float64List(0);
  NarrativeAnchorSnapshot? _snapshot;
  Size? _viewportSize;
  TextDirection? _textDirection;
  bool _isEmpty = true;
  double _corridorX = 0;
  int _anchorCount = 0;
  int _geometryRevision = 0;

  @visibleForTesting
  int get debugGeometryRevision => _geometryRevision;

  @visibleForTesting
  int get debugCoordinateBufferIdentityHash => identityHashCode(_coordinates);

  @visibleForTesting
  Offset debugAnchorAt(int index) {
    RangeError.checkValidIndex(index, _coordinates, 'index', _anchorCount);
    return Offset(_coordinates[index * 2], _coordinates[index * 2 + 1]);
  }

  void update({
    required NarrativeAnchorSnapshot snapshot,
    required Size viewportSize,
    required TextDirection textDirection,
  }) {
    if (identical(snapshot, _snapshot) &&
        viewportSize == _viewportSize &&
        textDirection == _textDirection) {
      return;
    }
    if (!viewportSize.width.isFinite ||
        !viewportSize.height.isFinite ||
        viewportSize.isEmpty) {
      throw ArgumentError.value(
        viewportSize,
        'viewportSize',
        'must be finite and non-empty',
      );
    }

    _snapshot = snapshot;
    _viewportSize = viewportSize;
    _textDirection = textDirection;
    _rebuild(snapshot, viewportSize, textDirection);
    _geometryRevision += 1;
  }

  void _rebuild(
    NarrativeAnchorSnapshot snapshot,
    Size viewportSize,
    TextDirection textDirection,
  ) {
    _path.reset();
    _anchorCount = snapshot.anchors.length;
    _corridorX = textDirection == TextDirection.rtl
        ? viewportSize.width - _corridorInset(viewportSize.width)
        : _corridorInset(viewportSize.width);
    if (_coordinates.length != _anchorCount * 2) {
      _coordinates = Float64List(_anchorCount * 2);
    }
    final segmentCount = math.max(0, _anchorCount - 1);
    if (_shoulders.length != segmentCount) {
      _shoulders = Float64List(segmentCount);
    }
    for (var index = 0; index < _anchorCount; index += 1) {
      final center = snapshot.anchors[index].documentCenter;
      _coordinates[index * 2] = center.dx;
      _coordinates[index * 2 + 1] = center.dy;
    }

    if (_anchorCount == 0) {
      _isEmpty = true;
      return;
    }
    _isEmpty = false;
    _path.moveTo(_coordinates[0], _coordinates[1]);
    for (var index = 1; index < _anchorCount; index += 1) {
      final previousX = _coordinates[(index - 1) * 2];
      final previousY = _coordinates[(index - 1) * 2 + 1];
      final nextX = _coordinates[index * 2];
      final nextY = _coordinates[index * 2 + 1];
      final distance = math.max(1.0, nextY - previousY);
      final shoulder = math.min(
        distance * 0.42,
        (distance * 0.12).clamp(32.0, 96.0).toDouble(),
      );
      _shoulders[index - 1] = shoulder;
      final exitY = previousY + shoulder;
      final entryY = nextY - shoulder;

      _path
        ..cubicTo(
          previousX,
          previousY + shoulder / 3,
          _corridorX,
          previousY + shoulder * 2 / 3,
          _corridorX,
          exitY,
        )
        ..lineTo(_corridorX, entryY)
        ..cubicTo(
          _corridorX,
          entryY + shoulder / 3,
          nextX,
          entryY + shoulder * 2 / 3,
          nextX,
          nextY,
        );
    }
  }

  /// Resolves the cursor on the exact closed-form curve used by [path].
  ///
  /// Each segment eases from its source anchor into the margin corridor,
  /// remains vertical through the reading field, then eases into the next
  /// anchor. No path metrics, samples, or per-frame allocations are required.
  Offset activePoint(double focalPoint) {
    if (_isEmpty || !focalPoint.isFinite) {
      return Offset(_corridorX, focalPoint.isFinite ? focalPoint : 0);
    }
    final first = Offset(_coordinates[0], _coordinates[1]);
    if (focalPoint <= first.dy || _anchorCount == 1) return first;
    final lastIndex = _anchorCount - 1;
    final last = Offset(
      _coordinates[lastIndex * 2],
      _coordinates[lastIndex * 2 + 1],
    );
    if (focalPoint >= last.dy) return last;

    for (var index = 0; index < lastIndex; index += 1) {
      final sourceX = _coordinates[index * 2];
      final sourceY = _coordinates[index * 2 + 1];
      final targetX = _coordinates[(index + 1) * 2];
      final targetY = _coordinates[(index + 1) * 2 + 1];
      if (focalPoint > targetY) continue;

      final shoulder = _shoulders[index];
      final exitY = sourceY + shoulder;
      final entryY = targetY - shoulder;
      if (focalPoint < exitY) {
        final progress = ((focalPoint - sourceY) / shoulder)
            .clamp(0.0, 1.0)
            .toDouble();
        return Offset(
          _mix(sourceX, _corridorX, _smoothStep(progress)),
          focalPoint,
        );
      }
      if (focalPoint <= entryY) return Offset(_corridorX, focalPoint);

      final progress = ((focalPoint - entryY) / shoulder)
          .clamp(0.0, 1.0)
          .toDouble();
      return Offset(
        _mix(_corridorX, targetX, _smoothStep(progress)),
        focalPoint,
      );
    }
    return last;
  }

  static double _mix(double a, double b, double progress) =>
      a + (b - a) * progress;

  static double _smoothStep(double value) => value * value * (3 - 2 * value);

  static double _corridorInset(double width) =>
      width >= 1200 ? 36 : (width >= 900 ? 28 : 18);
}
