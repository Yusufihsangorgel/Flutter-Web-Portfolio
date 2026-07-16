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
          documentCenter: Offset(460 + shift, 220),
          size: const Size(280, 96),
        ),
        NarrativeAnchorGeometry(
          sectionId: SectionId.experience,
          motif: NarrativeMotif.timeline,
          documentCenter: Offset(180 + shift, 1180),
          size: const Size(8, 8),
        ),
        NarrativeAnchorGeometry(
          sectionId: SectionId.proof,
          motif: NarrativeMotif.branches,
          documentCenter: Offset(310 + shift, 2260),
          size: const Size(8, 8),
        ),
        NarrativeAnchorGeometry(
          sectionId: SectionId.projects,
          motif: NarrativeMotif.bracket,
          documentCenter: Offset(610 + shift, 3640),
          size: const Size(720, 540),
        ),
        NarrativeAnchorGeometry(
          sectionId: SectionId.about,
          motif: NarrativeMotif.thread,
          documentCenter: Offset(820 + shift, 5280),
          size: const Size(420, 180),
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
      expect(ltr.debugAnchorAt(index), anchors.anchors[index].documentCenter);
      expect(rtl.debugAnchorAt(index), anchors.anchors[index].documentCenter);
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
        anchor.documentCenter,
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
      documentCenter: Offset(100, 200),
      size: Size(20, 20),
    );
    expect(() => NarrativeAnchorSnapshot([home, home]), throwsArgumentError);
    expect(
      () => NarrativeAnchorSnapshot([
        home,
        const NarrativeAnchorGeometry(
          sectionId: SectionId.experience,
          motif: NarrativeMotif.timeline,
          documentCenter: Offset(100, 100),
          size: Size(20, 20),
        ),
      ]),
      throwsArgumentError,
    );
    expect(
      () => NarrativeAnchorSnapshot([
        const NarrativeAnchorGeometry(
          sectionId: SectionId.home,
          motif: NarrativeMotif.origin,
          documentCenter: Offset(double.nan, 100),
          size: Size(20, 20),
        ),
      ]),
      throwsArgumentError,
    );
  });
}
