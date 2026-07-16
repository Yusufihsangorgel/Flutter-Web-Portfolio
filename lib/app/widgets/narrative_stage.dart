import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_web_portfolio/app/controllers/scene_director.dart';
import 'package:flutter_web_portfolio/app/controllers/scroll_controller.dart';
import 'package:flutter_web_portfolio/app/core/constants/app_colors.dart';
import 'package:flutter_web_portfolio/app/core/constants/app_dimensions.dart';
import 'package:flutter_web_portfolio/app/narrative/domain/narrative_anchor.dart';
import 'package:flutter_web_portfolio/app/narrative/domain/narrative_document.dart';
import 'package:flutter_web_portfolio/app/narrative/rendering/narrative_anchor_path.dart';
import 'package:flutter_web_portfolio/app/utils/motion_preference.dart';

/// One persistent, content-anchored trace spanning the complete portfolio.
///
/// Unlike a boundary interstitial, this stage never restarts. It measures a
/// meaningful widget inside every chapter, joins those anchors in document
/// space, and moves one cursor through the same path as the reader scrolls.
/// The layer is decorative, pointer-transparent, and absent from semantics.
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
  Color _accent = AppColors.heroAccent;
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
      _sceneSubscription?.cancel();
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
    _frame.queue(
      anchors: snapshot,
      scrollOffset: scrollOffset,
      focalPoint: focalPoint,
      accent: _accent,
      reducedMotion: _reducedMotion,
    );
  }

  @override
  void dispose() {
    _detachScrollController();
    _sceneSubscription?.cancel();
    _frame.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Positioned.fill(
    child: ExcludeSemantics(
      child: IgnorePointer(
        child: RepaintBoundary(
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
  );
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

    _trackPaint
      ..strokeWidth = 0.85
      ..color = AppColors.textBright.withValues(
        alpha: frame.reducedMotion ? 0.13 : 0.08,
      );
    canvas.drawPath(kernel.path, _trackPaint);

    if (!frame.reducedMotion) {
      _trackPaint
        ..strokeWidth = 1.35
        ..color = frame.accent.withValues(alpha: 0.52);
      canvas
        ..save()
        ..clipRect(Rect.fromLTRB(0, 0, size.width, frame.focalPoint))
        ..drawPath(kernel.path, _trackPaint)
        ..restore();
    }

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

  void _drawAnchorGlyph(
    Canvas canvas,
    NarrativeAnchorGeometry anchor, {
    required bool completed,
  }) {
    final center = anchor.documentCenter;
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
    switch (anchor.motif) {
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
        canvas.drawLine(
          center - const Offset(12, 0),
          center + const Offset(12, 0),
          _trackPaint,
        );
        canvas.drawCircle(center, 3.6, _trackPaint);
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

/// Coalesces scene, layout, and scroll updates into one paint notification.
final class _NarrativeStageFrame extends ChangeNotifier {
  NarrativeAnchorSnapshot _anchors = const NarrativeAnchorSnapshot.empty();
  double _scrollOffset = 0;
  double _focalPoint = 0;
  Color _accent = AppColors.heroAccent;
  bool _reducedMotion = false;

  NarrativeAnchorSnapshot? _pendingAnchors;
  double? _pendingScrollOffset;
  double? _pendingFocalPoint;
  Color? _pendingAccent;
  bool? _pendingReducedMotion;
  bool _notificationPending = false;
  bool _disposed = false;

  NarrativeAnchorSnapshot get anchors => _anchors;
  double get scrollOffset => _scrollOffset;
  double get focalPoint => _focalPoint;
  Color get accent => _accent;
  bool get reducedMotion => _reducedMotion;

  void queue({
    required NarrativeAnchorSnapshot anchors,
    required double scrollOffset,
    required double focalPoint,
    required Color accent,
    required bool reducedMotion,
  }) {
    _pendingAnchors = anchors;
    _pendingScrollOffset = scrollOffset;
    _pendingFocalPoint = focalPoint;
    _pendingAccent = accent;
    _pendingReducedMotion = reducedMotion;
    if (_disposed || _notificationPending) return;
    _notificationPending = true;
    SchedulerBinding.instance.scheduleFrameCallback((_) {
      if (_disposed) return;
      _notificationPending = false;
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
      if (changed) notifyListeners();
    });
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
