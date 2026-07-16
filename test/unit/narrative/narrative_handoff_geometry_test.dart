import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_web_portfolio/app/narrative/domain/narrative_document.dart';
import 'package:flutter_web_portfolio/app/narrative/rendering/narrative_handoff_geometry.dart';
import 'package:flutter_web_portfolio/app/narrative/rendering/narrative_spine_geometry.dart';

void main() {
  group('NarrativeHandoffGeometry', () {
    test('keeps every motif pair finite and inside each responsive size', () {
      const sizes = [Size(280, 220), Size(900, 280), Size(1440, 360)];

      for (final size in sizes) {
        for (final from in NarrativeMotif.values) {
          for (final to in NarrativeMotif.values) {
            final shape = NarrativeHandoffGeometry.resolve(
              size: size,
              from: from,
              to: to,
              textDirection: TextDirection.ltr,
            );
            for (final point in [
              shape.start,
              shape.controlStart,
              shape.controlEnd,
              shape.end,
            ]) {
              expect(point.dx.isFinite && point.dy.isFinite, isTrue);
              expect(point.dx, inInclusiveRange(0, size.width));
              expect(point.dy, inInclusiveRange(0, size.height));
            }
          }
        }
      }
    });

    test('uses the ambient spine endpoints as its only anchors', () {
      const size = Size(1000, 280);
      final shape = NarrativeHandoffGeometry.resolve(
        size: size,
        from: NarrativeMotif.origin,
        to: NarrativeMotif.timeline,
        textDirection: TextDirection.ltr,
      );

      expect(
        shape.start.dx,
        NarrativeSpineGeometry.normalizedAnchor(
              NarrativeMotif.origin,
              NarrativeSpineEdge.exit,
            ).dx *
            size.width,
      );
      expect(
        shape.end.dx,
        NarrativeSpineGeometry.normalizedAnchor(
              NarrativeMotif.timeline,
              NarrativeSpineEdge.entry,
            ).dx *
            size.width,
      );
    });

    test('mirrors every control point exactly in RTL', () {
      const size = Size(1200, 360);

      for (final from in NarrativeMotif.values) {
        for (final to in NarrativeMotif.values) {
          final ltr = NarrativeHandoffGeometry.resolve(
            size: size,
            from: from,
            to: to,
            textDirection: TextDirection.ltr,
          );
          final rtl = NarrativeHandoffGeometry.resolve(
            size: size,
            from: from,
            to: to,
            textDirection: TextDirection.rtl,
          );
          final ltrPoints = [
            ltr.start,
            ltr.controlStart,
            ltr.controlEnd,
            ltr.end,
          ];
          final rtlPoints = [
            rtl.start,
            rtl.controlStart,
            rtl.controlEnd,
            rtl.end,
          ];
          for (var index = 0; index < ltrPoints.length; index += 1) {
            expect(
              rtlPoints[index].dx,
              closeTo(size.width - ltrPoints[index].dx, 1e-9),
            );
            expect(rtlPoints[index].dy, ltrPoints[index].dy);
          }
        }
      }
    });

    test('progress rail grows away from its label in both directions', () {
      const size = Size(320, 220);
      const labelSize = Size(112, 14);

      final ltr = NarrativeHandoffRailGeometry.resolve(
        size: size,
        labelSize: labelSize,
        textDirection: TextDirection.ltr,
        inset: 20,
        labelY: 18,
        lineY: 26,
      );
      expect(ltr.labelOffset, const Offset(20, 18));
      expect(ltr.lineStart.dx, greaterThan(ltr.labelOffset.dx));
      expect(ltr.lineEnd.dx, greaterThan(ltr.lineStart.dx));

      final rtl = NarrativeHandoffRailGeometry.resolve(
        size: size,
        labelSize: labelSize,
        textDirection: TextDirection.rtl,
        inset: 20,
        labelY: 18,
        lineY: 26,
      );
      expect(rtl.labelOffset, const Offset(188, 18));
      expect(rtl.lineStart.dx, lessThan(rtl.labelOffset.dx));
      expect(rtl.lineEnd.dx, lessThan(rtl.lineStart.dx));
    });

    test('samples the cubic at exact endpoints and finite interior points', () {
      const size = Size(1440, 360);
      final shape = NarrativeHandoffGeometry.resolve(
        size: size,
        from: NarrativeMotif.origin,
        to: NarrativeMotif.timeline,
        textDirection: TextDirection.ltr,
      );

      expect(shape.pointAt(-1), shape.start);
      expect(shape.pointAt(0), shape.start);
      expect(shape.pointAt(1), shape.end);
      expect(shape.pointAt(2), shape.end);

      for (var sample = 1; sample < 10; sample += 1) {
        final point = shape.pointAt(sample / 10);
        expect(point.dx.isFinite && point.dy.isFinite, isTrue);
        expect(point.dx, inInclusiveRange(0, size.width));
        expect(point.dy, inInclusiveRange(0, size.height));
      }
    });

    test('rejects empty or non-finite paint bounds', () {
      for (final size in const [
        Size.zero,
        Size(double.nan, 100),
        Size(100, double.infinity),
      ]) {
        expect(
          () => NarrativeHandoffGeometry.resolve(
            size: size,
            from: NarrativeMotif.origin,
            to: NarrativeMotif.timeline,
            textDirection: TextDirection.ltr,
          ),
          throwsArgumentError,
        );
      }
    });
  });
}
