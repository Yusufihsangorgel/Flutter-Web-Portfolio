import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_web_portfolio/app/controllers/scene_director.dart';
import 'package:flutter_web_portfolio/app/core/constants/app_colors.dart';
import 'package:flutter_web_portfolio/app/core/constants/scene_configs.dart';
import 'package:flutter_web_portfolio/app/features/render_quality/application/render_quality_controller.dart';
import 'package:flutter_web_portfolio/app/features/render_quality/domain/render_quality.dart';
import 'package:flutter_web_portfolio/app/utils/motion_preference.dart';

/// A restrained ambient field beneath the content-anchored narrative stage.
///
/// This painter owns only atmosphere, vignette, and optional grain. The one
/// persistent engineering signal is measured from real content by
/// `NarrativeStage`, avoiding a second disconnected decorative path.
class CinematicBackground extends StatefulWidget {
  const CinematicBackground({super.key});

  @override
  State<CinematicBackground> createState() => _CinematicBackgroundState();
}

class _CinematicBackgroundState extends State<CinematicBackground> {
  late final _NarrativeFrame _frame;
  StreamSubscription<SceneState>? _sceneSubscription;
  StreamSubscription<RenderQualityState>? _qualitySubscription;
  SceneDirector? _sceneDirector;
  RenderQualityController? _qualityController;
  ui.Image? _grainTexture;
  bool _reduceMotion = false;

  @override
  void initState() {
    super.initState();
    _frame = _NarrativeFrame(SceneConfigs.hero, RenderQuality.balanced);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduceMotion = prefersReducedMotion(context);
    final qualityController = context.read<RenderQualityController>();
    if (!identical(qualityController, _qualityController)) {
      _qualitySubscription?.cancel();
      _qualityController = qualityController;
      qualityController.setReducedMotion(reduceMotion);
      _applyQuality(qualityController.state);
      _qualitySubscription = qualityController.stream.listen(_applyQuality);
    } else if (_reduceMotion != reduceMotion) {
      qualityController.setReducedMotion(reduceMotion);
    }

    _reduceMotion = reduceMotion;
    final director = context.read<SceneDirector>();
    if (!identical(director, _sceneDirector)) {
      _sceneSubscription?.cancel();
      _sceneDirector = director;
      _queueScene(director.state);
      _sceneSubscription = director.stream.listen(_queueScene);
    } else {
      _queueScene(director.state);
    }
  }

  @override
  void dispose() {
    _sceneSubscription?.cancel();
    _qualitySubscription?.cancel();
    _frame.dispose();
    _grainTexture?.dispose();
    super.dispose();
  }

  void _trackPointer(PointerEvent event) {
    if (_reduceMotion || !_frame.quality.profile.trackPointer) return;
    final size = context.size;
    if (size == null || size.isEmpty) return;
    _frame.queuePointer(
      Offset(
        (event.localPosition.dx / size.width - 0.5) * 2,
        (event.localPosition.dy / size.height - 0.5) * 2,
      ),
    );
  }

  void _queueScene(SceneState state) {
    final config = _reduceMotion
        ? SceneConfigs.scenes[state.currentSceneIndex]
        : state.blendedConfig;
    _frame.queueScene(config);
  }

  void _applyQuality(RenderQualityState state) {
    _frame.setQuality(state.quality);
    if (!state.quality.profile.trackPointer) {
      _frame.queuePointer(Offset.zero);
    }
    if (state.quality.profile.drawGrain && _grainTexture == null) {
      _grainTexture = _createGrainTexture();
      _frame.setGrainTexture(_grainTexture);
    }
  }

  ui.Image _createGrainTexture() {
    const side = 256.0;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final random = math.Random(2026);
    final paint = Paint();
    for (var index = 0; index < 160; index++) {
      paint.color = (index.isEven ? Colors.white : Colors.black).withValues(
        alpha: 0.018 + random.nextDouble() * 0.018,
      );
      canvas.drawCircle(
        Offset(random.nextDouble() * side, random.nextDouble() * side),
        0.35 + random.nextDouble() * 0.65,
        paint,
      );
    }
    final picture = recorder.endRecording();
    final texture = picture.toImageSync(side.toInt(), side.toInt());
    picture.dispose();
    return texture;
  }

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: Listener(
      behavior: HitTestBehavior.translucent,
      onPointerHover: _trackPointer,
      onPointerMove: _trackPointer,
      child: CustomPaint(
        painter: _NarrativeBackgroundPainter(frame: _frame),
        size: Size.infinite,
      ),
    ),
  );
}

final class _NarrativeBackgroundPainter extends CustomPainter {
  _NarrativeBackgroundPainter({required this.frame}) : super(repaint: frame);

  final _NarrativeFrame frame;

  static final _paint = Paint()..isAntiAlias = true;
  static final _grainPaint = Paint();

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final bounds = Offset.zero & size;
    _paint
      ..shader = null
      ..style = PaintingStyle.fill
      ..blendMode = BlendMode.srcOver
      ..color = AppColors.background;
    canvas.drawRect(bounds, _paint);

    if (frame.quality.profile.drawAmbientField) {
      _drawAmbientField(canvas, size, bounds);
    }
    _drawVignette(canvas, size, bounds);
    if (frame.quality.profile.drawGrain) _drawGrain(canvas, size);
  }

  void _drawAmbientField(Canvas canvas, Size size, Rect bounds) {
    final center = Offset(
      size.width * (0.62 + frame.pointer.dx * 0.018),
      size.height * (0.42 + frame.pointer.dy * 0.018),
    );
    _paint
      ..blendMode = BlendMode.screen
      ..shader = ui.Gradient.radial(
        center,
        size.longestSide * 0.72,
        [
          frame.config.gradient3.withValues(alpha: 0.09),
          frame.config.gradient2.withValues(alpha: 0.045),
          frame.config.gradient1.withValues(alpha: 0),
        ],
        const [0, 0.44, 1],
      );
    canvas.drawRect(bounds, _paint);
    _paint
      ..shader = null
      ..blendMode = BlendMode.srcOver;
  }

  void _drawVignette(Canvas canvas, Size size, Rect bounds) {
    _paint
      ..style = PaintingStyle.fill
      ..blendMode = BlendMode.srcOver
      ..shader = ui.Gradient.radial(
        Offset(size.width * 0.5, size.height * 0.48),
        size.longestSide * 0.68,
        [
          Colors.transparent,
          AppColors.backgroundDark.withValues(alpha: 0.2),
          AppColors.backgroundDark.withValues(
            alpha: frame.config.vignetteIntensity.clamp(0.0, 0.66),
          ),
        ],
        const [0.25, 0.72, 1],
      );
    canvas.drawRect(bounds, _paint);
    _paint.shader = null;
  }

  void _drawGrain(Canvas canvas, Size size) {
    final image = frame.grainTexture;
    if (image == null) return;
    const tile = 256.0;
    for (double x = 0; x < size.width; x += tile) {
      for (double y = 0; y < size.height; y += tile) {
        final width = math.min(tile, size.width - x);
        final height = math.min(tile, size.height - y);
        canvas.drawImageRect(
          image,
          Rect.fromLTWH(0, 0, width, height),
          Rect.fromLTWH(x, y, width, height),
          _grainPaint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(_NarrativeBackgroundPainter oldDelegate) =>
      !identical(frame, oldDelegate.frame);
}

/// Coalesces scroll, quality and pointer inputs into one paint notification.
final class _NarrativeFrame extends ChangeNotifier {
  _NarrativeFrame(this._config, this._quality);

  SceneConfig _config;
  RenderQuality _quality;
  Offset _pointer = Offset.zero;
  ui.Image? _grainTexture;

  SceneConfig? _pendingConfig;
  Offset? _pendingPointer;
  bool _notificationPending = false;
  bool _forceNotification = false;
  bool _disposed = false;

  SceneConfig get config => _config;
  RenderQuality get quality => _quality;
  Offset get pointer => _pointer;
  ui.Image? get grainTexture => _grainTexture;

  void queueScene(SceneConfig config) {
    _pendingConfig = config;
    _scheduleNotification();
  }

  void queuePointer(Offset value) {
    if (_pendingPointer == value ||
        (_pendingPointer == null && _pointer == value)) {
      return;
    }
    _pendingPointer = value;
    _scheduleNotification();
  }

  void setQuality(RenderQuality value) {
    if (_quality == value) return;
    _quality = value;
    _forceNotification = true;
    _scheduleNotification();
  }

  void setGrainTexture(ui.Image? value) {
    if (identical(_grainTexture, value)) return;
    _grainTexture = value;
    _forceNotification = true;
    _scheduleNotification();
  }

  void _scheduleNotification() {
    if (_disposed || _notificationPending) return;
    _notificationPending = true;
    SchedulerBinding.instance.scheduleFrameCallback((_) {
      if (_disposed) return;
      _notificationPending = false;
      var changed = _forceNotification;
      _forceNotification = false;
      final config = _pendingConfig;
      final pointer = _pendingPointer;
      _pendingConfig = null;
      _pendingPointer = null;

      if (config != null && !identical(config, _config)) {
        _config = config;
        changed = true;
      }
      if (pointer != null && pointer != _pointer) {
        _pointer = pointer;
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
