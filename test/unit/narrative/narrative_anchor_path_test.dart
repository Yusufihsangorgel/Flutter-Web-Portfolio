import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_web_portfolio/app/narrative/domain/narrative_anchor.dart';
import 'package:flutter_web_portfolio/app/narrative/domain/narrative_document.dart';
import 'package:flutter_web_portfolio/app/narrative/rendering/narrative_anchor_path.dart';

void main() {
  const viewport = Size(1200, 800);

  NarrativeAnchorSnapshot snapshot({double shift = 0}) =>
      NarrativeAnchorSnapshot([
        NarrativeAnchorGeometry(
          sectionId: SectionId.home,
          motif: NarrativeMotif.origin,
          documentCenter: NarrativePoint(460 + shift, 220),
          size: const NarrativeSize(280, 96),
        ),
        NarrativeAnchorGeometry(
          sectionId: SectionId.experience,
          motif: NarrativeMotif.timeline,
          documentCenter: NarrativePoint(180 + shift, 1180),
          size: const NarrativeSize(8, 8),
        ),
        NarrativeAnchorGeometry(
          sectionId: SectionId.proof,
          motif: NarrativeMotif.branches,
          documentCenter: NarrativePoint(310 + shift, 2260),
          size: const NarrativeSize(8, 8),
        ),
        NarrativeAnchorGeometry(
          sectionId: SectionId.projects,
          motif: NarrativeMotif.bracket,
          documentCenter: NarrativePoint(610 + shift, 3640),
          size: const NarrativeSize(720, 540),
        ),
        NarrativeAnchorGeometry(
          sectionId: SectionId.about,
          motif: NarrativeMotif.thread,
          documentCenter: NarrativePoint(820 + shift, 5280),
          size: const NarrativeSize(420, 180),
        ),
      ]);

  test('builds one finite path through all measured anchors', () {
    final kernel = NarrativeAnchorPathKernel()
      ..update(
        snapshot: snapshot(),
        viewportSize: viewport,
        textDirection: TextDirection.ltr,
      );

    expect(kernel.isEmpty, isFalse);
    expect(kernel.anchorCount, 5);
    expect(kernel.corridorX, 36);
    expect(kernel.path.computeMetrics().length, 1);
    final bounds = kernel.path.getBounds();
    expect(bounds.left.isFinite && bounds.top.isFinite, isTrue);
    expect(bounds.right.isFinite && bounds.bottom.isFinite, isTrue);
    expect(bounds.top, 220);
    expect(bounds.bottom, 5280);
  });

  test('mirrors the quiet corridor in RTL without moving real anchors', () {
    final anchors = snapshot();
    final ltr = NarrativeAnchorPathKernel()
      ..update(
        snapshot: anchors,
        viewportSize: viewport,
        textDirection: TextDirection.ltr,
      );
    final rtl = NarrativeAnchorPathKernel()
      ..update(
        snapshot: anchors,
        viewportSize: viewport,
        textDirection: TextDirection.rtl,
      );

    expect(ltr.corridorX, 36);
    expect(rtl.corridorX, viewport.width - 36);
    for (var index = 0; index < anchors.anchors.length; index += 1) {
      final point = anchors.anchors[index].documentCenter;
      expect(ltr.debugAnchorAt(index), Offset(point.dx, point.dy));
      expect(rtl.debugAnchorAt(index), Offset(point.dx, point.dy));
    }
  });

  test('reuses storage and skips identical geometry updates', () {
    final anchors = snapshot();
    final kernel = NarrativeAnchorPathKernel()
      ..update(
        snapshot: anchors,
        viewportSize: viewport,
        textDirection: TextDirection.ltr,
      );
    final firstRevision = kernel.debugGeometryRevision;
    final firstBuffer = kernel.debugCoordinateBufferIdentityHash;

    kernel.update(
      snapshot: anchors,
      viewportSize: viewport,
      textDirection: TextDirection.ltr,
    );
    expect(kernel.debugGeometryRevision, firstRevision);

    kernel.update(
      snapshot: snapshot(shift: 12),
      viewportSize: viewport,
      textDirection: TextDirection.ltr,
    );
    expect(kernel.debugGeometryRevision, firstRevision + 1);
    expect(kernel.debugCoordinateBufferIdentityHash, firstBuffer);
  });

  test('compares anchor geometry by value', () {
    final first = snapshot();
    final second = snapshot();

    expect(first, second);
    expect(first.hashCode, second.hashCode);
    expect(
      first.anchors.first.documentCenter,
      second.anchors.first.documentCenter,
    );
  });

  test('keeps the cursor on the same closed-form path as the trace', () {
    final anchors = snapshot();
    final kernel = NarrativeAnchorPathKernel()
      ..update(
        snapshot: anchors,
        viewportSize: viewport,
        textDirection: TextDirection.ltr,
      );

    for (final anchor in anchors.anchors) {
      expect(
        kernel.activePoint(anchor.documentCenter.dy),
        Offset(anchor.documentCenter.dx, anchor.documentCenter.dy),
      );
    }
    expect(kernel.activePoint(700).dx, kernel.corridorX);
    expect(kernel.activePoint(268), const Offset(248, 268));
    expect(kernel.activePoint(1132), const Offset(108, 1132));
  });

  test('handles an empty document and rejects invalid viewports', () {
    final kernel = NarrativeAnchorPathKernel()
      ..update(
        snapshot: const NarrativeAnchorSnapshot.empty(),
        viewportSize: viewport,
        textDirection: TextDirection.ltr,
      );
    expect(kernel.isEmpty, isTrue);
    expect(kernel.activePoint(200), const Offset(36, 200));

    for (final size in const [
      Size.zero,
      Size(double.nan, 100),
      Size(100, double.infinity),
    ]) {
      expect(
        () => kernel.update(
          snapshot: const NarrativeAnchorSnapshot.empty(),
          viewportSize: size,
          textDirection: TextDirection.ltr,
        ),
        throwsArgumentError,
      );
    }
  });

  test('rejects duplicate, invalid, or out-of-order anchor geometry', () {
    const home = NarrativeAnchorGeometry(
      sectionId: SectionId.home,
      motif: NarrativeMotif.origin,
      documentCenter: NarrativePoint(100, 200),
      size: NarrativeSize(20, 20),
    );
    expect(() => NarrativeAnchorSnapshot([home, home]), throwsArgumentError);
    expect(
      () => NarrativeAnchorSnapshot([
        home,
        const NarrativeAnchorGeometry(
          sectionId: SectionId.experience,
          motif: NarrativeMotif.timeline,
          documentCenter: NarrativePoint(100, 100),
          size: NarrativeSize(20, 20),
        ),
      ]),
      throwsArgumentError,
    );
    expect(
      () => NarrativeAnchorSnapshot([
        const NarrativeAnchorGeometry(
          sectionId: SectionId.home,
          motif: NarrativeMotif.origin,
          documentCenter: NarrativePoint(double.nan, 100),
          size: NarrativeSize(20, 20),
        ),
      ]),
      throwsArgumentError,
    );
  });
}
