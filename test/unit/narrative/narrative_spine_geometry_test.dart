import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_web_portfolio/app/narrative/domain/narrative_document.dart';
import 'package:flutter_web_portfolio/app/narrative/rendering/narrative_spine_geometry.dart';

void main() {
  const size = Size(1200, 800);

  NarrativeSpineShape shape(
    NarrativeMotif motif, {
    NarrativeMotif? next,
    double blend = 0,
    double globalProgress = 0.5,
  }) => NarrativeSpineGeometry.resolve(
    size: size,
    cue: NarrativeSpineCue(
      currentMotif: motif,
      nextMotif: next ?? motif,
      blend: blend,
      globalProgress: globalProgress,
    ),
  );

  group('NarrativeSpineGeometry', () {
    test('keeps one stable topology across every chapter motif', () {
      for (final motif in NarrativeMotif.values) {
        final result = shape(motif);

        expect(
          result.primary,
          hasLength(NarrativeSpineGeometry.primarySampleCount),
        );
        expect(result.branches, hasLength(NarrativeSpineGeometry.branchCount));
        for (final branch in result.branches) {
          expect(branch, hasLength(NarrativeSpineGeometry.branchSampleCount));
        }
      }
    });

    test('transition endpoints exactly match their chapter shapes', () {
      final timeline = shape(NarrativeMotif.timeline);
      final branches = shape(NarrativeMotif.branches);
      final atStart = shape(
        NarrativeMotif.timeline,
        next: NarrativeMotif.branches,
      );
      final atEnd = shape(
        NarrativeMotif.timeline,
        next: NarrativeMotif.branches,
        blend: 1,
      );

      expect(atStart.primary, timeline.primary);
      expect(atEnd.primary, branches.primary);
      expect(atStart.nodeVisibility, timeline.nodeVisibility);
      expect(atEnd.branchVisibility, branches.branchVisibility);
    });

    test('document reveal progress does not invalidate motif geometry', () {
      final start = shape(
        NarrativeMotif.timeline,
        next: NarrativeMotif.branches,
        blend: 0.42,
        globalProgress: 0,
      );
      final end = shape(
        NarrativeMotif.timeline,
        next: NarrativeMotif.branches,
        blend: 0.42,
        globalProgress: 1,
      );

      expect(end.primary, start.primary);
      expect(end.branches, start.branches);
      expect(end.nodes, start.nodes);
      expect(end.branchVisibility, start.branchVisibility);
      expect(end.nodeVisibility, start.nodeVisibility);
    });

    test('mid-transition samples remain finite and inside the viewport', () {
      final result = shape(
        NarrativeMotif.branches,
        next: NarrativeMotif.bracket,
        blend: 0.5,
      );

      for (final point in [
        ...result.primary,
        ...result.branches.expand((branch) => branch),
      ]) {
        expect(point.dx.isFinite && point.dy.isFinite, isTrue);
        expect(point.dx, inInclusiveRange(0, size.width));
        expect(point.dy, inInclusiveRange(0, size.height));
      }
    });

    test('only the contribution motif exposes full branches', () {
      expect(shape(NarrativeMotif.timeline).branchVisibility, 0);
      expect(shape(NarrativeMotif.branches).branchVisibility, 1);
      expect(shape(NarrativeMotif.bracket).branchVisibility, 0);
    });

    test('work motif stays open as an editorial bracket', () {
      final bracket = shape(NarrativeMotif.bracket).primary;

      expect((bracket.first - bracket.last).distance, greaterThan(100));
      expect(bracket.first.dx, closeTo(bracket.last.dx, 0.001));
    });
  });
}
