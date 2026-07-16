import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_web_portfolio/app/core/constants/app_colors.dart';
import 'package:flutter_web_portfolio/app/core/constants/breakpoints.dart';
import 'package:flutter_web_portfolio/app/narrative/application/narrative_position.dart';
import 'package:flutter_web_portfolio/app/narrative/domain/narrative_document.dart';
import 'package:flutter_web_portfolio/app/narrative/rendering/narrative_handoff_geometry.dart';
import 'package:flutter_web_portfolio/app/utils/motion_preference.dart';

/// A decorative hairline carrying one chapter motif into the next.
///
/// It adds no copy, control or semantic node. Chapter names and numbering stay
/// with [NumberedSectionHeading], while this bridge only gives the continuous
/// document a visible handoff at its otherwise empty boundaries.
class NarrativeChapterHandoff extends StatelessWidget {
  const NarrativeChapterHandoff({
    super.key,
    required this.from,
    required this.to,
    required this.position,
  });

  final NarrativeChapter from;
  final NarrativeChapter to;
  final ValueListenable<NarrativePosition> position;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final height = width >= Breakpoints.tablet ? 112.0 : 72.0;
    final reducedMotion = prefersReducedMotion(context);
    final chapterOrder = context.read<NarrativeDocument>().chapters;

    return ExcludeSemantics(
      child: IgnorePointer(
        child: RepaintBoundary(
          child: SizedBox(
            key: ValueKey('handoff-${from.id.value}-${to.id.value}'),
            width: double.infinity,
            height: height,
            child: CustomPaint(
              painter: _NarrativeChapterHandoffPainter(
                from: from,
                to: to,
                position: position,
                chapterOrder: chapterOrder,
                textDirection: Directionality.of(context),
                reducedMotion: reducedMotion,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

final class _NarrativeChapterHandoffPainter extends CustomPainter {
  _NarrativeChapterHandoffPainter({
    required this.from,
    required this.to,
    required this.position,
    required this.chapterOrder,
    required this.textDirection,
    required this.reducedMotion,
  }) : super(repaint: reducedMotion ? null : position);

  final NarrativeChapter from;
  final NarrativeChapter to;
  final ValueListenable<NarrativePosition> position;
  final List<NarrativeChapter> chapterOrder;
  final TextDirection textDirection;
  final bool reducedMotion;

  static final Paint _trackPaint = Paint()
    ..isAntiAlias = true
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round
    ..strokeWidth = 0.75
    ..color = AppColors.documentAccent.withValues(alpha: 0.06);
  static final Paint _revealPaint = Paint()
    ..isAntiAlias = true
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round
    ..strokeWidth = 1.1
    ..color = AppColors.documentAccent.withValues(alpha: 0.22);

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final shape = NarrativeHandoffGeometry.resolve(
      size: size,
      from: from.motif,
      to: to.motif,
      textDirection: textDirection,
    );
    final path = shape.toPath();
    canvas.drawPath(path, _trackPaint);

    final reveal = NarrativeHandoffReveal.resolve(
      snapshot: position.value,
      chapterOrder: chapterOrder,
      from: from,
      to: to,
      reducedMotion: reducedMotion,
    );
    if (reveal <= 0) return;
    final eased = reveal * reveal * (3 - 2 * reveal);
    canvas
      ..save()
      ..clipRect(Rect.fromLTWH(0, 0, size.width, size.height * eased))
      ..drawPath(path, _revealPaint)
      ..restore();
  }

  @override
  bool shouldRepaint(_NarrativeChapterHandoffPainter oldDelegate) =>
      oldDelegate.from != from ||
      oldDelegate.to != to ||
      !identical(oldDelegate.position, position) ||
      !listEquals(oldDelegate.chapterOrder, chapterOrder) ||
      oldDelegate.textDirection != textDirection ||
      oldDelegate.reducedMotion != reducedMotion;
}

/// Resolves the persistent reveal state of one chapter boundary.
///
/// Only the currently active boundary interpolates. Boundaries earlier in the
/// configured narrative remain fully drawn, while later boundaries stay on
/// their quiet track until the reading position reaches them.
abstract final class NarrativeHandoffReveal {
  static double resolve({
    required NarrativePosition snapshot,
    required List<NarrativeChapter> chapterOrder,
    required NarrativeChapter from,
    required NarrativeChapter to,
    required bool reducedMotion,
  }) {
    if (reducedMotion) return 1;

    final fromIndex = chapterOrder.indexWhere(
      (chapter) => chapter.id == from.id,
    );
    final toIndex = chapterOrder.indexWhere((chapter) => chapter.id == to.id);
    assert(
      fromIndex >= 0 && toIndex == fromIndex + 1,
      'A handoff must connect adjacent chapters in narrative order.',
    );
    if (fromIndex < 0 || toIndex != fromIndex + 1) return 0;

    if (snapshot.currentSectionId == from.id.value &&
        snapshot.nextSectionId == to.id.value) {
      return snapshot.boundaryProgress.clamp(0.0, 1.0);
    }

    final currentIndex = chapterOrder.indexWhere(
      (chapter) => chapter.id.value == snapshot.currentSectionId,
    );
    if (currentIndex >= toIndex) return 1;

    final activeIndex = chapterOrder.indexWhere(
      (chapter) => chapter.id.value == snapshot.activeSectionId,
    );
    return activeIndex >= toIndex ? 1 : 0;
  }
}
