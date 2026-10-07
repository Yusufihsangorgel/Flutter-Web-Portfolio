import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_web_portfolio/app/controllers/scene_director.dart';
import 'package:flutter_web_portfolio/app/controllers/scroll_controller.dart';
import 'package:flutter_web_portfolio/app/core/constants/app_colors.dart';
import 'package:flutter_web_portfolio/app/core/constants/app_dimensions.dart';
import 'package:flutter_web_portfolio/app/core/constants/breakpoints.dart';
import 'package:flutter_web_portfolio/app/narrative/domain/narrative_anchor.dart';
import 'package:flutter_web_portfolio/app/narrative/domain/narrative_document.dart';
import 'package:flutter_web_portfolio/app/narrative/rendering/frame_coalescer.dart';
import 'package:flutter_web_portfolio/app/narrative/rendering/narrative_anchor_path.dart';
import 'package:flutter_web_portfolio/app/utils/motion_preference.dart';

/// Draws one decorative trace through chapter anchors.
final class NarrativeStage extends StatefulWidget {
  const NarrativeStage({super.key});

  @override
  State<NarrativeStage> createState() => _NarrativeStageState();
}

final class _NarrativeStageState extends State<NarrativeStage> {
  final NarrativeAnchorPathKernel _kernel = NarrativeAnchorPathKernel();
  final _NarrativeStageFrame _frame = _NarrativeStageFrame();
  AppScrollController? _scrollController;
  SceneDirector? _sceneDirector;
  StreamSubscription<SceneState>? _sceneSubscription;
  Color _accent = AppColors.accent;
  bool _reducedMotion = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reducedMotion = prefersReducedMotion(context);
    final scrollController = context.read<AppScrollController>();
    if (!identical(scrollController, _scrollController)) {
      _detachScrollController();
      _scrollController = scrollController;
      scrollController.narrativePosition.addListener(_queueFrame);
      scrollController.narrativeAnchors.addListener(_queueFrame);
    }

    final sceneDirector = context.read<SceneDirector>();
    if (!identical(sceneDirector, _sceneDirector)) {
      unawaited(_sceneSubscription?.cancel());
      _sceneDirector = sceneDirector;
      _accent = sceneDirector.state.blendedConfig.accent;
      _sceneSubscription = sceneDirector.stream.listen((state) {
        _accent = state.blendedConfig.accent;
        _queueFrame();
      });
    }

    _reducedMotion = reducedMotion;
    _queueFrame();
  }

  void _detachScrollController() {
    final controller = _scrollController;
    if (controller == null) return;
    controller.narrativePosition.removeListener(_queueFrame);
    controller.narrativeAnchors.removeListener(_queueFrame);
  }

  void _queueFrame() {
    final controller = _scrollController;
    if (controller == null) return;
    final snapshot = controller.narrativeAnchors.value;
    final position = controller.narrativePosition.value;
    final scrollOffset = controller.scrollController.hasClients
        ? controller.scrollController.offset
        : 0.0;
    final focalPoint = _reducedMotion && snapshot.anchors.isNotEmpty
        ? snapshot.anchors.last.documentCenter.dy
        : position.focalPoint;
    _frame.queue((
      anchors: snapshot,
      scrollOffset: scrollOffset,
      focalPoint: focalPoint,
      accent: _accent,
      reducedMotion: _reducedMotion,
    ));
  }

  @override
  void dispose() {
    _detachScrollController();
    unawaited(_sceneSubscription?.cancel());
    _frame.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Positioned.fill(
    child: ExcludeSemantics(
      child: IgnorePointer(
        child: RepaintBoundary(
          child: ClipRect(
            clipper: NarrativeStageClipper(Directionality.of(context)),
            child: CustomPaint(
              key: const ValueKey('narrative-stage'),
              painter: _NarrativeStagePainter(
                frame: _frame,
                kernel: _kernel,
                textDirection: Directionality.of(context),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

/// Clips narrow-screen traces to the page gutter.
final class NarrativeStageClipper extends CustomClipper<Rect> {
  const NarrativeStageClipper(this.textDirection);

  final TextDirection textDirection;

  @override
  Rect getClip(Size size) {
    if (size.width >= Breakpoints.mobile) return Offset.zero & size;
    const gutter = AppDimensions.sectionPaddingMobile;
    return Rect.fromLTWH(
      textDirection == TextDirection.rtl ? size.width - gutter : 0,
      0,
      gutter,
      size.height,
    );
  }

  @override
  bool shouldReclip(NarrativeStageClipper oldClipper) =>
      oldClipper.textDirection != textDirection;
}

final class _NarrativeStagePainter extends CustomPainter {
  _NarrativeStagePainter({
    required this.frame,
    required this.kernel,
    required this.textDirection,
  }) : super(repaint: frame);

  final _NarrativeStageFrame frame;
  final NarrativeAnchorPathKernel kernel;
  final TextDirection textDirection;

  final Paint _trackPaint = Paint()
    ..isAntiAlias = true
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round;
  final Paint _fillPaint = Paint()..isAntiAlias = true;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty || frame.anchors.anchors.length < 2) return;
    kernel.update(
      snapshot: frame.anchors,
      viewportSize: size,
      textDirection: textDirection,
    );
    if (kernel.isEmpty) return;

    final topInset = AppDimensions.appBarHeightForScrollOffset(
      frame.scrollOffset,
    );
    canvas
      ..save()
      ..clipRect(Rect.fromLTWH(0, topInset, size.width, size.height - topInset))
      ..translate(0, -frame.scrollOffset);

    _drawTrace(canvas, size);

    for (final anchor in frame.anchors.anchors) {
      _drawAnchorGlyph(
        canvas,
        anchor,
        completed: anchor.documentCenter.dy <= frame.focalPoint,
      );
    }

    if (!frame.reducedMotion) {
      _drawCursor(canvas, kernel.activePoint(frame.focalPoint));
    }
    canvas.restore();
  }

  void _drawTrace(Canvas canvas, Size size) {
    _trackPaint
      ..strokeWidth = 0.85
      ..color = AppColors.textBright.withValues(
        alpha: frame.reducedMotion ? 0.13 : 0.08,
      );
    canvas.drawPath(kernel.path, _trackPaint);

    if (frame.reducedMotion) return;
    _trackPaint
      ..strokeWidth = 1.35
      ..color = frame.accent.withValues(alpha: 0.52);
    canvas
      ..save()
      ..clipRect(Rect.fromLTRB(0, 0, size.width, frame.focalPoint))
      ..drawPath(kernel.path, _trackPaint)
      ..restore();
  }

  void _drawAnchorGlyph(
    Canvas canvas,
    NarrativeAnchorGeometry anchor, {
    required bool completed,
  }) {
    final point = anchor.documentCenter;
    final center = Offset(point.dx, point.dy);
    final opacity = frame.reducedMotion ? 0.36 : (completed ? 0.72 : 0.24);
    _trackPaint
      ..strokeWidth = completed ? 1.25 : 0.9
      ..color = frame.accent.withValues(alpha: opacity);
    _fillPaint
      ..style = PaintingStyle.fill
      ..color = AppColors.paper.withValues(
        alpha: frame.reducedMotion ? 0.78 : (completed ? 0.92 : 0.7),
      );

    canvas.drawCircle(center, completed ? 5.2 : 4.2, _fillPaint);
    _drawMotif(canvas, anchor.motif, center);
  }

  void _drawMotif(Canvas canvas, NarrativeMotif motif, Offset center) {
    switch (motif) {
      case NarrativeMotif.origin:
        canvas.drawRect(
          Rect.fromCenter(center: center, width: 9, height: 9),
          _trackPaint,
        );
      case NarrativeMotif.timeline:
        canvas
          ..drawLine(center - const Offset(0, 10), center, _trackPaint)
          ..drawCircle(center, 4.8, _trackPaint);
      case NarrativeMotif.branches:
        for (final dy in const [-7.0, 0.0, 7.0]) {
          canvas.drawLine(
            center,
            center + Offset(textDirection == TextDirection.rtl ? -11 : 11, dy),
            _trackPaint,
          );
        }
        canvas.drawCircle(center, 3.8, _trackPaint);
      case NarrativeMotif.bracket:
        final direction = textDirection == TextDirection.rtl ? -1.0 : 1.0;
        final edge = center + Offset(direction * 9, 0);
        canvas
          ..drawLine(
            center - const Offset(0, 8),
            center + const Offset(0, 8),
            _trackPaint,
          )
          ..drawLine(
            center - const Offset(0, 8),
            edge - const Offset(0, 8),
            _trackPaint,
          )
          ..drawLine(
            center + const Offset(0, 8),
            edge + const Offset(0, 8),
            _trackPaint,
          );
      case NarrativeMotif.thread:
        canvas
          ..drawLine(
            center - const Offset(12, 0),
            center + const Offset(12, 0),
            _trackPaint,
          )
          ..drawCircle(center, 3.6, _trackPaint);
    }
  }

  void _drawCursor(Canvas canvas, Offset point) {
    final pulse = 0.5 + 0.5 * math.sin(frame.focalPoint * 0.018);
    _fillPaint
      ..style = PaintingStyle.fill
      ..color = frame.accent;
    canvas.drawCircle(point, 3.6, _fillPaint);
    _trackPaint
      ..strokeWidth = 1
      ..color = frame.accent.withValues(alpha: 0.28 + pulse * 0.16);
    canvas.drawCircle(point, 8 + pulse * 2, _trackPaint);
  }

  @override
  bool shouldRepaint(_NarrativeStagePainter oldDelegate) =>
      !identical(frame, oldDelegate.frame) ||
      !identical(kernel, oldDelegate.kernel) ||
      textDirection != oldDelegate.textDirection;
}

final class _NarrativeStageFrame extends FrameCoalescer {
  NarrativeAnchorSnapshot _anchors = const NarrativeAnchorSnapshot.empty();
  double _scrollOffset = 0;
  double _focalPoint = 0;
  Color _accent = AppColors.accent;
  bool _reducedMotion = false;

  NarrativeAnchorSnapshot? _pendingAnchors;
  double? _pendingScrollOffset;
  double? _pendingFocalPoint;
  Color? _pendingAccent;
  bool? _pendingReducedMotion;

  NarrativeAnchorSnapshot get anchors => _anchors;
  double get scrollOffset => _scrollOffset;
  double get focalPoint => _focalPoint;
  Color get accent => _accent;
  bool get reducedMotion => _reducedMotion;

  void queue(
    ({
      NarrativeAnchorSnapshot anchors,
      double scrollOffset,
      double focalPoint,
      Color accent,
      bool reducedMotion,
    })
    input,
  ) {
    _pendingAnchors = input.anchors;
    _pendingScrollOffset = input.scrollOffset;
    _pendingFocalPoint = input.focalPoint;
    _pendingAccent = input.accent;
    _pendingReducedMotion = input.reducedMotion;
    scheduleFrameUpdate(() {
      var changed = false;
      final anchors = _pendingAnchors;
      final scrollOffset = _pendingScrollOffset;
      final focalPoint = _pendingFocalPoint;
      final accent = _pendingAccent;
      final reducedMotion = _pendingReducedMotion;
      _pendingAnchors = null;
      _pendingScrollOffset = null;
      _pendingFocalPoint = null;
      _pendingAccent = null;
      _pendingReducedMotion = null;

      if (anchors != null && anchors != _anchors) {
        _anchors = anchors;
        changed = true;
      }
      if (scrollOffset != null && scrollOffset != _scrollOffset) {
        _scrollOffset = scrollOffset;
        changed = true;
      }
      if (focalPoint != null && focalPoint != _focalPoint) {
        _focalPoint = focalPoint;
        changed = true;
      }
      if (accent != null && accent != _accent) {
        _accent = accent;
        changed = true;
      }
      if (reducedMotion != null && reducedMotion != _reducedMotion) {
        _reducedMotion = reducedMotion;
        changed = true;
      }
      return changed;
    });
  }
}
