import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter_web_portfolio/app/narrative/domain/narrative_document.dart';

/// Scroll snapshot consumed by the continuous editorial trace.
@immutable
final class NarrativeSpineCue {
  const NarrativeSpineCue({
    required this.currentMotif,
    required this.nextMotif,
    required this.blend,
    required this.globalProgress,
  });

  const NarrativeSpineCue.origin()
    : currentMotif = NarrativeMotif.origin,
      nextMotif = NarrativeMotif.origin,
      blend = 0,
      globalProgress = 0;

  final NarrativeMotif currentMotif;
  final NarrativeMotif nextMotif;
  final double blend;
  final double globalProgress;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NarrativeSpineCue &&
          currentMotif == other.currentMotif &&
          nextMotif == other.nextMotif &&
          blend == other.blend &&
          globalProgress == other.globalProgress;

  @override
  int get hashCode =>
      Object.hash(currentMotif, nextMotif, blend, globalProgress);
}

/// Sampled geometry shared by every render-quality tier.
@immutable
final class NarrativeSpineShape {
  NarrativeSpineShape({
    required List<Offset> primary,
    required List<List<Offset>> branches,
    required List<Offset> nodes,
    required this.branchVisibility,
    required this.nodeVisibility,
  }) : primary = List.unmodifiable(primary),
       branches = List.unmodifiable(branches.map(List<Offset>.unmodifiable)),
       nodes = List.unmodifiable(nodes);

  final List<Offset> primary;
  final List<List<Offset>> branches;
  final List<Offset> nodes;
  final double branchVisibility;
  final double nodeVisibility;
}

/// Stateful, allocation-bounded renderer for the continuous editorial trace.
///
/// Motif samples are immutable, while the pixel buffers and [Path] instances
/// live for the lifetime of the painter. Scroll updates therefore rebuild the
/// same objects instead of materialising point collections, path metrics and
/// extracted paths on every frame.
final class NarrativeSpineRenderKernel {
  NarrativeSpineRenderKernel()
    : _primaryCoordinates = Float64List(
        NarrativeSpineGeometry.primarySampleCount * 2,
      ),
      _cumulativeLengths = Float64List(
        NarrativeSpineGeometry.primarySampleCount,
      ),
      _branchCoordinates = Float64List(
        NarrativeSpineGeometry.branchCount *
            NarrativeSpineGeometry.branchSampleCount *
            2,
      ),
      _nodeCoordinates = Float64List(
        NarrativeSpineGeometry._nodeIndices.length * 2,
      ),
      _branchPaths = List<Path>.generate(
        NarrativeSpineGeometry.branchCount,
        (_) => Path(),
        growable: false,
      );

  final Float64List _primaryCoordinates;
  final Float64List _cumulativeLengths;
  final Float64List _branchCoordinates;
  final Float64List _nodeCoordinates;
  final List<Path> _branchPaths;
  final Path _primaryPath = Path();
  final Path _revealPath = Path();

  Size? _size;
  NarrativeMotif? _currentMotif;
  NarrativeMotif? _nextMotif;
  double? _blend;
  double? _reveal;
  bool _isEmpty = true;
  double _branchVisibility = 0;
  double _nodeVisibility = 0;
  int _geometryRevision = 0;
  int _revealRevision = 0;

  Path get primaryPath => _primaryPath;
  Path get revealPath => _revealPath;
  int get branchPathCount => _branchPaths.length;
  int get nodeCount => NarrativeSpineGeometry._nodeIndices.length;
  bool get isEmpty => _isEmpty;
  double get branchVisibility => _branchVisibility;
  double get nodeVisibility => _nodeVisibility;

  Path branchPathAt(int index) => _branchPaths[index];
  double nodeXAt(int index) => _nodeCoordinates[index * 2];
  double nodeYAt(int index) => _nodeCoordinates[index * 2 + 1];

  @visibleForTesting
  int get debugGeometryRevision => _geometryRevision;

  @visibleForTesting
  int get debugRevealRevision => _revealRevision;

  @visibleForTesting
  int get debugPrimaryBufferIdentityHash =>
      identityHashCode(_primaryCoordinates);

  @visibleForTesting
  int get debugLengthBufferIdentityHash => identityHashCode(_cumulativeLengths);

  @visibleForTesting
  int get debugBranchBufferIdentityHash => identityHashCode(_branchCoordinates);

  @visibleForTesting
  Offset debugPrimaryPointAt(int index) => Offset(
    _primaryCoordinates[index * 2],
    _primaryCoordinates[index * 2 + 1],
  );

  @visibleForTesting
  Offset debugBranchPointAt(int branch, int index) {
    final coordinateIndex =
        (branch * NarrativeSpineGeometry.branchSampleCount + index) * 2;
    return Offset(
      _branchCoordinates[coordinateIndex],
      _branchCoordinates[coordinateIndex + 1],
    );
  }

  /// Updates geometry and reveal independently.
  ///
  /// [NarrativeSpineCue.blend] intentionally receives the same second
  /// smooth-step as the legacy geometry resolver. The scene director already
  /// eases chapter travel; preserving that composition keeps visual parity.
  void update({required Size size, required NarrativeSpineCue cue}) {
    final blend = cue.currentMotif == cue.nextMotif
        ? 0.0
        : NarrativeSpineGeometry._smoothStep(cue.blend.clamp(0.0, 1.0));
    final reveal = (0.16 + cue.globalProgress * 0.84).clamp(0.0, 1.0);
    final geometryChanged =
        _size != size ||
        _currentMotif != cue.currentMotif ||
        _nextMotif != cue.nextMotif ||
        _blend != blend;

    if (geometryChanged) {
      _size = size;
      _currentMotif = cue.currentMotif;
      _nextMotif = cue.nextMotif;
      _blend = blend;
      _rebuildGeometry(size, cue.currentMotif, cue.nextMotif, blend);
      _geometryRevision += 1;
      _reveal = null;
    }

    if (_reveal != reveal) {
      _rebuildReveal(reveal);
      _reveal = reveal;
      _revealRevision += 1;
    }
  }

  void _rebuildGeometry(
    Size size,
    NarrativeMotif currentMotif,
    NarrativeMotif nextMotif,
    double blend,
  ) {
    _primaryPath.reset();
    _revealPath.reset();
    for (var branch = 0; branch < _branchPaths.length; branch += 1) {
      _branchPaths[branch].reset();
    }

    if (size.isEmpty) {
      _isEmpty = true;
      _branchVisibility = 0;
      _nodeVisibility = 0;
      _cumulativeLengths.fillRange(0, _cumulativeLengths.length, 0);
      _branchCoordinates.fillRange(0, _branchCoordinates.length, 0);
      _nodeCoordinates.fillRange(0, _nodeCoordinates.length, 0);
      return;
    }

    _isEmpty = false;
    final from = NarrativeSpineGeometry._motifSamples[currentMotif.index];
    final to = NarrativeSpineGeometry._motifSamples[nextMotif.index];
    var previousX = 0.0;
    var previousY = 0.0;
    var cumulativeLength = 0.0;

    for (
      var index = 0;
      index < NarrativeSpineGeometry.primarySampleCount;
      index += 1
    ) {
      final source = from.primary[index];
      final target = to.primary[index];
      final x =
          NarrativeSpineGeometry._mix(source.dx, target.dx, blend) * size.width;
      final y =
          NarrativeSpineGeometry._mix(source.dy, target.dy, blend) *
          size.height;
      final coordinateIndex = index * 2;
      _primaryCoordinates[coordinateIndex] = x;
      _primaryCoordinates[coordinateIndex + 1] = y;

      if (index == 0) {
        _primaryPath.moveTo(x, y);
        _cumulativeLengths[index] = 0;
      } else {
        _primaryPath.lineTo(x, y);
        final dx = x - previousX;
        final dy = y - previousY;
        cumulativeLength += math.sqrt(dx * dx + dy * dy);
        _cumulativeLengths[index] = cumulativeLength;
      }
      previousX = x;
      previousY = y;
    }

    for (var branch = 0; branch < _branchPaths.length; branch += 1) {
      final branchPath = _branchPaths[branch];
      final sourceBranch = from.branches[branch];
      final targetBranch = to.branches[branch];
      for (
        var index = 0;
        index < NarrativeSpineGeometry.branchSampleCount;
        index += 1
      ) {
        final source = sourceBranch[index];
        final target = targetBranch[index];
        final x =
            NarrativeSpineGeometry._mix(source.dx, target.dx, blend) *
            size.width;
        final y =
            NarrativeSpineGeometry._mix(source.dy, target.dy, blend) *
            size.height;
        final coordinateIndex =
            (branch * NarrativeSpineGeometry.branchSampleCount + index) * 2;
        _branchCoordinates[coordinateIndex] = x;
        _branchCoordinates[coordinateIndex + 1] = y;
        if (index == 0) {
          branchPath.moveTo(x, y);
        } else {
          branchPath.lineTo(x, y);
        }
      }
    }

    for (
      var index = 0;
      index < NarrativeSpineGeometry._nodeIndices.length;
      index += 1
    ) {
      final sourceIndex = NarrativeSpineGeometry._nodeIndices[index] * 2;
      final targetIndex = index * 2;
      _nodeCoordinates[targetIndex] = _primaryCoordinates[sourceIndex];
      _nodeCoordinates[targetIndex + 1] = _primaryCoordinates[sourceIndex + 1];
    }

    _branchVisibility = NarrativeSpineGeometry._mix(
      NarrativeSpineGeometry._branchWeight(currentMotif),
      NarrativeSpineGeometry._branchWeight(nextMotif),
      blend,
    );
    _nodeVisibility = NarrativeSpineGeometry._mix(
      NarrativeSpineGeometry._nodeWeight(currentMotif),
      NarrativeSpineGeometry._nodeWeight(nextMotif),
      blend,
    );
  }

  void _rebuildReveal(double reveal) {
    _revealPath.reset();
    if (_isEmpty) return;

    final totalLength = _cumulativeLengths.last;
    final firstX = _primaryCoordinates[0];
    final firstY = _primaryCoordinates[1];
    _revealPath.moveTo(firstX, firstY);
    if (totalLength <= 0) return;

    final targetLength = totalLength * reveal;
    for (
      var index = 1;
      index < NarrativeSpineGeometry.primarySampleCount;
      index += 1
    ) {
      final coordinateIndex = index * 2;
      final x = _primaryCoordinates[coordinateIndex];
      final y = _primaryCoordinates[coordinateIndex + 1];
      final segmentEnd = _cumulativeLengths[index];
      if (segmentEnd <= targetLength) {
        _revealPath.lineTo(x, y);
        continue;
      }

      final segmentStart = _cumulativeLengths[index - 1];
      final segmentLength = segmentEnd - segmentStart;
      if (segmentLength > 0) {
        final t = ((targetLength - segmentStart) / segmentLength).clamp(
          0.0,
          1.0,
        );
        final previousCoordinateIndex = coordinateIndex - 2;
        _revealPath.lineTo(
          NarrativeSpineGeometry._mix(
            _primaryCoordinates[previousCoordinateIndex],
            x,
            t,
          ),
          NarrativeSpineGeometry._mix(
            _primaryCoordinates[previousCoordinateIndex + 1],
            y,
            t,
          ),
        );
      }
      break;
    }
  }
}

/// Produces one stable line that changes role as the document advances.
///
/// Every motif has exactly the same number of samples. Interpolating matching
/// samples therefore cannot tear or replace the trace during a scene change.
abstract final class NarrativeSpineGeometry {
  static const int primarySampleCount = 64;
  static const int branchSampleCount = 18;
  static const int branchCount = 3;
  static const _nodeIndices = [15, 32, 48];

  // Motif curves are invariant. Sampling them once removes trigonometry and
  // Bezier construction from the scroll-frame hot path; resolve only performs
  // the interpolation and viewport scaling that actually change per frame.
  static final List<_NormalizedSpineShape> _motifSamples = List.unmodifiable(
    NarrativeMotif.values.map(_sampleMotif),
  );

  static NarrativeSpineShape resolve({
    required Size size,
    required NarrativeSpineCue cue,
  }) {
    if (size.isEmpty) {
      return NarrativeSpineShape(
        primary: const [],
        branches: const [],
        nodes: const [],
        branchVisibility: 0,
        nodeVisibility: 0,
      );
    }

    final blend = cue.currentMotif == cue.nextMotif
        ? 0.0
        : _smoothStep(cue.blend.clamp(0.0, 1.0));
    final from = _motifSamples[cue.currentMotif.index];
    final to = _motifSamples[cue.nextMotif.index];
    final primary = List<Offset>.generate(
      primarySampleCount,
      (index) => _interpolateToPixels(
        from.primary[index],
        to.primary[index],
        blend,
        size,
      ),
      growable: false,
    );
    final branches = List<List<Offset>>.generate(
      branchCount,
      (branch) => List<Offset>.generate(
        branchSampleCount,
        (index) => _interpolateToPixels(
          from.branches[branch][index],
          to.branches[branch][index],
          blend,
          size,
        ),
        growable: false,
      ),
      growable: false,
    );

    return NarrativeSpineShape(
      primary: primary,
      branches: branches,
      nodes: [for (final index in _nodeIndices) primary[index]],
      branchVisibility: _mix(
        _branchWeight(cue.currentMotif),
        _branchWeight(cue.nextMotif),
        blend,
      ),
      nodeVisibility: _mix(
        _nodeWeight(cue.currentMotif),
        _nodeWeight(cue.nextMotif),
        blend,
      ),
    );
  }

  static _NormalizedSpineShape _sampleMotif(NarrativeMotif motif) =>
      _NormalizedSpineShape(
        primary: List<Offset>.generate(
          primarySampleCount,
          (index) => _pointFor(motif, index / (primarySampleCount - 1)),
          growable: false,
        ),
        branches: List<List<Offset>>.generate(
          branchCount,
          (branch) => List<Offset>.generate(
            branchSampleCount,
            (index) =>
                _branchPoint(motif, branch, index / (branchSampleCount - 1)),
            growable: false,
          ),
          growable: false,
        ),
      );

  static Offset _pointFor(NarrativeMotif motif, double t) => switch (motif) {
    NarrativeMotif.origin => Offset(
      0.08 + t * 0.74,
      0.95 - math.sin(t * math.pi) * 0.012,
    ),
    NarrativeMotif.thread => Offset(
      0.025 + math.sin(t * math.pi) * 0.004,
      0.08 + t * 0.84,
    ),
    NarrativeMotif.timeline => Offset(
      0.025 + math.sin(t * math.pi * 3) * 0.003,
      0.06 + t * 0.88,
    ),
    NarrativeMotif.branches => Offset(
      0.02 + t * 0.004 + math.sin(t * math.pi) * 0.006,
      0.1 + t * 0.78 - math.sin(t * math.pi) * 0.08,
    ),
    NarrativeMotif.bracket => _bracketPoint(t),
  };

  static Offset _bracketPoint(double t) {
    const capFraction = 0.14;
    if (t < capFraction) {
      return Offset(0.012 + (t / capFraction) * 0.023, 0.16);
    }
    if (t > 1 - capFraction) {
      return Offset(
        0.035 - ((t - (1 - capFraction)) / capFraction) * 0.023,
        0.84,
      );
    }
    final vertical = (t - capFraction) / (1 - capFraction * 2);
    return Offset(
      0.035 + math.sin(vertical * math.pi) * 0.004,
      0.16 + vertical * 0.68,
    );
  }

  static Offset _branchPoint(NarrativeMotif motif, int branch, double t) {
    final anchorFraction = 0.28 + branch * 0.2;
    final anchor = _pointFor(motif, anchorFraction);
    if (motif != NarrativeMotif.branches) return anchor;

    final direction = branch.isEven ? -1.0 : 1.0;
    final horizontalDirection = branch.isEven ? -1.0 : 1.0;
    final destination = Offset(
      (anchor.dx + horizontalDirection * (0.018 + branch * 0.003)).clamp(
        0.008,
        0.04,
      ),
      (anchor.dy + direction * (0.12 + branch * 0.018)).clamp(0.08, 0.92),
    );
    final control = Offset(
      anchor.dx + (destination.dx - anchor.dx) * 0.48,
      anchor.dy + direction * 0.025,
    );
    final inverse = 1 - t;
    return Offset(
      inverse * inverse * anchor.dx +
          2 * inverse * t * control.dx +
          t * t * destination.dx,
      inverse * inverse * anchor.dy +
          2 * inverse * t * control.dy +
          t * t * destination.dy,
    );
  }

  static double _branchWeight(NarrativeMotif motif) =>
      motif == NarrativeMotif.branches ? 1 : 0;

  static double _nodeWeight(NarrativeMotif motif) => switch (motif) {
    NarrativeMotif.timeline => 1,
    NarrativeMotif.branches => 0.42,
    _ => 0,
  };

  static Offset _interpolateToPixels(
    Offset from,
    Offset to,
    double blend,
    Size size,
  ) {
    if (blend <= 0) {
      return Offset(from.dx * size.width, from.dy * size.height);
    }
    if (blend >= 1) {
      return Offset(to.dx * size.width, to.dy * size.height);
    }
    return Offset(
      _mix(from.dx, to.dx, blend) * size.width,
      _mix(from.dy, to.dy, blend) * size.height,
    );
  }

  static double _mix(double from, double to, double t) =>
      from + (to - from) * t;

  static double _smoothStep(double value) => value * value * (3 - 2 * value);
}

final class _NormalizedSpineShape {
  const _NormalizedSpineShape({required this.primary, required this.branches});

  final List<Offset> primary;
  final List<List<Offset>> branches;
}
