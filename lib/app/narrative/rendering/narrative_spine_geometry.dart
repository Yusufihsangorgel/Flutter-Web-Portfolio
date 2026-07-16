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
