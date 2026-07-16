import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_web_portfolio/app/narrative/domain/narrative_document.dart';
import 'package:flutter_web_portfolio/app/narrative/rendering/narrative_spine_geometry.dart';

void main() {
  const size = Size(1200, 800);

  NarrativeSpineCue cue(
    NarrativeMotif current, {
    NarrativeMotif? next,
    double blend = 0,
    double progress = 0.5,
  }) => NarrativeSpineCue(
    currentMotif: current,
    nextMotif: next ?? current,
    blend: blend,
    globalProgress: progress,
  );

  double pathLength(Path path) =>
      path.computeMetrics().fold(0, (length, metric) => length + metric.length);

  group('NarrativeSpineRenderKernel', () {
    test('matches the legacy geometry across every motif transition', () {
      final kernel = NarrativeSpineRenderKernel();

      for (final current in NarrativeMotif.values) {
        for (final next in NarrativeMotif.values) {
          for (final blend in [-1.0, 0.0, 0.13, 0.42, 1.0, 2.0]) {
            final input = cue(current, next: next, blend: blend);
            final legacy = NarrativeSpineGeometry.resolve(
              size: size,
              cue: input,
            );
            kernel.update(size: size, cue: input);

            for (
              var index = 0;
              index < NarrativeSpineGeometry.primarySampleCount;
              index += 1
            ) {
              expect(
                (kernel.debugPrimaryPointAt(index) - legacy.primary[index])
                    .distance,
                lessThan(0.000001),
                reason: '$current → $next at blend $blend, point $index',
              );
            }

            for (
              var branch = 0;
              branch < NarrativeSpineGeometry.branchCount;
              branch += 1
            ) {
              for (
                var index = 0;
                index < NarrativeSpineGeometry.branchSampleCount;
                index += 1
              ) {
                expect(
                  (kernel.debugBranchPointAt(branch, index) -
                          legacy.branches[branch][index])
                      .distance,
                  lessThan(0.000001),
                  reason:
                      '$current → $next at blend $blend, '
                      'branch $branch point $index',
                );
              }
            }

            expect(
              kernel.branchVisibility,
              closeTo(legacy.branchVisibility, 0.000001),
            );
            expect(
              kernel.nodeVisibility,
              closeTo(legacy.nodeVisibility, 0.000001),
            );
            for (var index = 0; index < kernel.nodeCount; index += 1) {
              expect(
                (Offset(kernel.nodeXAt(index), kernel.nodeYAt(index)) -
                        legacy.nodes[index])
                    .distance,
                lessThan(0.000001),
              );
            }
          }
        }
      }
    });

    test('reuses every path and typed buffer across scroll updates', () {
      final kernel = NarrativeSpineRenderKernel()
        ..update(size: size, cue: cue(NarrativeMotif.origin));
      final primaryPath = kernel.primaryPath;
      final revealPath = kernel.revealPath;
      final primaryBuffer = kernel.debugPrimaryBufferIdentityHash;
      final lengthBuffer = kernel.debugLengthBufferIdentityHash;
      final branchBuffer = kernel.debugBranchBufferIdentityHash;
      final branchPaths = [
        for (var index = 0; index < kernel.branchPathCount; index += 1)
          kernel.branchPathAt(index),
      ];

      for (var frame = 0; frame < 1000; frame += 1) {
        final current =
            NarrativeMotif.values[frame % NarrativeMotif.values.length];
        final next =
            NarrativeMotif.values[(frame + 1) % NarrativeMotif.values.length];
        kernel.update(
          size: size,
          cue: cue(
            current,
            next: next,
            blend: (frame % 101) / 100,
            progress: (frame % 97) / 96,
          ),
        );

        expect(identical(kernel.primaryPath, primaryPath), isTrue);
        expect(identical(kernel.revealPath, revealPath), isTrue);
        expect(kernel.debugPrimaryBufferIdentityHash, primaryBuffer);
        expect(kernel.debugLengthBufferIdentityHash, lengthBuffer);
        expect(kernel.debugBranchBufferIdentityHash, branchBuffer);
        for (var index = 0; index < branchPaths.length; index += 1) {
          expect(
            identical(kernel.branchPathAt(index), branchPaths[index]),
            isTrue,
          );
        }
      }
    });

    test('invalidates reveal independently from motif geometry', () {
      final kernel = NarrativeSpineRenderKernel();
      final geometry = cue(
        NarrativeMotif.timeline,
        next: NarrativeMotif.branches,
        blend: 0.42,
        progress: 0.1,
      );
      kernel.update(size: size, cue: geometry);
      final geometryRevision = kernel.debugGeometryRevision;
      final revealRevision = kernel.debugRevealRevision;

      kernel.update(
        size: size,
        cue: cue(
          NarrativeMotif.timeline,
          next: NarrativeMotif.branches,
          blend: 0.42,
          progress: 0.8,
        ),
      );

      expect(kernel.debugGeometryRevision, geometryRevision);
      expect(kernel.debugRevealRevision, revealRevision + 1);

      final stableRevealRevision = kernel.debugRevealRevision;
      kernel.update(
        size: size,
        cue: cue(
          NarrativeMotif.timeline,
          next: NarrativeMotif.branches,
          blend: 0.42,
          progress: 0.8,
        ),
      );
      expect(kernel.debugGeometryRevision, geometryRevision);
      expect(kernel.debugRevealRevision, stableRevealRevision);
    });

    test('matches physical reveal length across chapters and transitions', () {
      final kernel = NarrativeSpineRenderKernel();

      final cases = [
        for (final motif in NarrativeMotif.values) (motif, motif, 0.0),
        (NarrativeMotif.origin, NarrativeMotif.thread, 0.25),
        (NarrativeMotif.timeline, NarrativeMotif.branches, 0.5),
        (NarrativeMotif.branches, NarrativeMotif.bracket, 0.75),
      ];
      for (final viewport in [
        const Size(360, 800),
        size,
        const Size(1600, 500),
      ]) {
        for (final (current, next, blend) in cases) {
          for (final progress in [0.0, 0.1, 0.5, 0.9, 1.0]) {
            kernel.update(
              size: viewport,
              cue: cue(current, next: next, blend: blend, progress: progress),
            );
            final expectedFraction = 0.16 + progress * 0.84;
            expect(
              pathLength(kernel.revealPath),
              closeTo(pathLength(kernel.primaryPath) * expectedFraction, 0.01),
              reason:
                  '$current → $next at blend $blend, '
                  '$viewport and progress $progress',
            );
          }
        }
      }
    });

    test('clears every reusable path for an empty viewport', () {
      final kernel = NarrativeSpineRenderKernel()
        ..update(size: size, cue: cue(NarrativeMotif.branches))
        ..update(size: Size.zero, cue: cue(NarrativeMotif.branches));

      expect(kernel.isEmpty, isTrue);
      expect(kernel.primaryPath.computeMetrics(), isEmpty);
      expect(kernel.revealPath.computeMetrics(), isEmpty);
      for (var index = 0; index < kernel.branchPathCount; index += 1) {
        expect(kernel.branchPathAt(index).computeMetrics(), isEmpty);
      }
      expect(kernel.branchVisibility, 0);
      expect(kernel.nodeVisibility, 0);
    });
  });
}
