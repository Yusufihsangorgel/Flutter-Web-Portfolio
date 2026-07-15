import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_web_portfolio/app/controllers/scene_director.dart';
import 'package:flutter_web_portfolio/app/core/constants/app_colors.dart';
import 'package:flutter_web_portfolio/app/core/constants/scene_configs.dart';

/// A single procedural stage shared by every portfolio chapter.
///
/// The scene unfolds from orbiting interface planes to an atlas, a tunnel,
/// stacked principles, and finally a product archive. It is drawn entirely by
/// Flutter, responds gently to the pointer, and follows the measured scroll
/// geometry exposed by [SceneDirector].
class CinematicBackground extends StatefulWidget {
  const CinematicBackground({super.key});

  @override
  State<CinematicBackground> createState() => _CinematicBackgroundState();
}

class _CinematicBackgroundState extends State<CinematicBackground>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  static const _ambientFrameCount = 30 * 36;

  late final AnimationController _animation;
  late SceneConfig _config;
  StreamSubscription<SceneState>? _sceneSubscription;
  SceneDirector? _sceneDirector;
  ui.Image? _grainTexture;
  Offset _pointer = Offset.zero;
  bool _reduceMotion = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _animation = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 36),
    )..repeat();
    _config = SceneConfigs.hero;
    _grainTexture = _createGrainTexture();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final director = context.read<SceneDirector>();
    if (!identical(director, _sceneDirector)) {
      _sceneSubscription?.cancel();
      _sceneDirector = director;
      _config = director.state.blendedConfig;
      _sceneSubscription = director.stream.listen((state) {
        _config = state.blendedConfig;
        if (_reduceMotion && mounted) setState(() {});
      });
    }

    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    if (_reduceMotion == reduceMotion) return;
    _reduceMotion = reduceMotion;
    if (reduceMotion) {
      _animation.stop();
      _pointer = Offset.zero;
    } else if (!_animation.isAnimating) {
      _animation.repeat();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.hidden ||
        state == AppLifecycleState.paused) {
      _animation.stop();
    } else if (state == AppLifecycleState.resumed && !_reduceMotion) {
      _animation.repeat();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _sceneSubscription?.cancel();
    _animation.dispose();
    _grainTexture?.dispose();
    super.dispose();
  }

  void _trackPointer(PointerEvent event) {
    if (_reduceMotion) return;
    final size = context.size;
    if (size == null || size.isEmpty) return;
    _pointer = Offset(
      (event.localPosition.dx / size.width - 0.5) * 2,
      (event.localPosition.dy / size.height - 0.5) * 2,
    );
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
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, _) {
          final frame = (_animation.value * _ambientFrameCount).floor();
          final time = frame / _ambientFrameCount;
          return CustomPaint(
            painter: _RenderAtlasPainter(
              time: time,
              config: _config,
              pointer: _pointer,
              grainImage: _grainTexture,
            ),
            size: Size.infinite,
          );
        },
      ),
    ),
  );
}

class _RenderAtlasPainter extends CustomPainter {
  _RenderAtlasPainter({
    required this.time,
    required this.config,
    required this.pointer,
    required this.grainImage,
  });

  final double time;
  final SceneConfig config;
  final Offset pointer;
  final ui.Image? grainImage;

  static final _paint = Paint()..isAntiAlias = true;
  static final _linePaint = Paint()
    ..isAntiAlias = true
    ..style = PaintingStyle.stroke;
  static final _grainPaint = Paint();

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final bounds = Offset.zero & size;
    _paint
      ..shader = null
      ..blendMode = BlendMode.srcOver
      ..color = AppColors.background;
    canvas.drawRect(bounds, _paint);

    _drawAmbientField(canvas, size, bounds);
    _drawPerspectiveGrid(canvas, size);
    _drawAtlas(canvas, size);
    _drawRegistrationMarks(canvas, size);
    _drawVignette(canvas, size, bounds);
    _drawGrain(canvas, size);
  }

  void _drawAmbientField(Canvas canvas, Size size, Rect bounds) {
    final pulse = 0.02 * math.sin(time * math.pi * 2);
    final center = Offset(
      size.width * (0.62 + pointer.dx * 0.025),
      size.height * (0.42 + pointer.dy * 0.025),
    );
    _paint
      ..blendMode = BlendMode.screen
      ..shader = ui.Gradient.radial(
        center,
        size.longestSide * 0.7,
        [
          config.gradient3.withValues(alpha: 0.105 + pulse),
          config.gradient2.withValues(alpha: 0.055),
          config.gradient1.withValues(alpha: 0),
        ],
        const [0, 0.42, 1],
      );
    canvas.drawRect(bounds, _paint);
    _paint
      ..shader = null
      ..blendMode = BlendMode.srcOver;
  }

  void _drawPerspectiveGrid(Canvas canvas, Size size) {
    final morph = config.atlasMorph;
    final horizon = size.height * (0.56 + math.sin(morph * 0.8) * 0.025);
    final vanishingPoint = Offset(
      size.width * (0.58 - morph * 0.025 + pointer.dx * 0.012),
      horizon + pointer.dy * 4,
    );
    _linePaint
      ..strokeWidth = 0.75
      ..color = config.accent.withValues(alpha: 0.085);

    for (var index = -10; index <= 10; index++) {
      final bottomX = vanishingPoint.dx + index * size.width * 0.115;
      canvas.drawLine(
        vanishingPoint,
        Offset(bottomX, size.height + 2),
        _linePaint,
      );
    }

    for (var index = 1; index <= 13; index++) {
      final depth = index / 13;
      final y = horizon + math.pow(depth, 1.85) * (size.height - horizon);
      final alpha = 0.035 + depth * 0.07;
      _linePaint.color = config.accent.withValues(alpha: alpha);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), _linePaint);
    }

    _linePaint
      ..strokeWidth = 1
      ..color = config.accent.withValues(alpha: 0.18);
    canvas.drawLine(
      Offset(0, horizon),
      Offset(size.width, horizon),
      _linePaint,
    );
  }

  void _drawAtlas(Canvas canvas, Size size) {
    final morph = config.atlasMorph.clamp(0.0, 4.0);
    final stage = morph.floor();
    final nextStage = math.min(stage + 1, 4);
    final stageT = _smoothStep(morph - stage);
    final planes = <_DrawablePlane>[];

    for (var index = 0; index < 8; index++) {
      final from = _poseFor(stage, index);
      final to = _poseFor(nextStage, index);
      final pose = _PlanePose.lerp(from, to, stageT);
      planes.add(_DrawablePlane(index: index, pose: pose));
    }
    planes.sort((a, b) => a.pose.scale.compareTo(b.pose.scale));

    Offset? previousCenter;
    for (final plane in planes) {
      final center = _planeCenter(size, plane.pose, plane.index);
      if (previousCenter != null && (morph < 1.25 || morph > 3.5)) {
        _linePaint
          ..strokeWidth = 0.65
          ..color = config.accent.withValues(alpha: 0.09);
        canvas.drawLine(previousCenter, center, _linePaint);
      }
      previousCenter = center;
      _drawPlane(canvas, size, plane.index, plane.pose, center);
    }
  }

  Offset _planeCenter(Size size, _PlanePose pose, int index) => Offset(
    pose.x * size.width + pointer.dx * (3 + index % 3),
    pose.y * size.height + pointer.dy * (2 + (index + 1) % 3),
  );

  void _drawPlane(
    Canvas canvas,
    Size size,
    int index,
    _PlanePose pose,
    Offset center,
  ) {
    final unit = math.min(size.width, size.height);
    final width = unit * pose.scale * pose.aspect;
    final height = unit * pose.scale;
    final skew = width * pose.tilt * 0.22;
    final points = <Offset>[
      Offset(-width / 2 + skew, -height / 2),
      Offset(width / 2 + skew, -height / 2),
      Offset(width / 2 - skew, height / 2),
      Offset(-width / 2 - skew, height / 2),
    ].map((point) => center + _rotate(point, pose.rotation)).toList();

    final path = Path()
      ..moveTo(points[0].dx, points[0].dy)
      ..lineTo(points[1].dx, points[1].dy)
      ..lineTo(points[2].dx, points[2].dy)
      ..lineTo(points[3].dx, points[3].dy)
      ..close();
    final pulse = (math.sin(time * math.pi * 2 + index * 0.9) + 1) / 2;
    _paint
      ..shader = null
      ..style = PaintingStyle.fill
      ..color = config.accent.withValues(alpha: 0.018 + pulse * 0.035);
    canvas.drawPath(path, _paint);

    _linePaint
      ..strokeWidth = index == 0 ? 1.4 : 0.8
      ..color = config.accent.withValues(
        alpha: (index == 0 ? 0.38 : 0.16) + pulse * 0.08,
      );
    canvas.drawPath(path, _linePaint);

    final topMid = Offset.lerp(points[0], points[1], 0.5)!;
    final bottomMid = Offset.lerp(points[3], points[2], 0.5)!;
    final leftThird = Offset.lerp(points[0], points[3], 0.32)!;
    final rightThird = Offset.lerp(points[1], points[2], 0.32)!;
    _linePaint
      ..strokeWidth = 0.55
      ..color = config.accent.withValues(alpha: 0.11);
    canvas
      ..drawLine(topMid, bottomMid, _linePaint)
      ..drawLine(leftThird, rightThird, _linePaint);

    _paint.color = config.accent.withValues(alpha: 0.55);
    canvas.drawCircle(points[index % points.length], 1.5, _paint);
  }

  _PlanePose _poseFor(int stage, int index) {
    final phase = time * math.pi * 2;
    switch (stage) {
      case 0:
        final angle = index / 8 * math.pi * 2 + phase * 0.11;
        final radius = 0.17 + (index.isOdd ? 0.055 : 0);
        return _PlanePose(
          x: 0.67 + math.cos(angle) * radius,
          y: 0.45 + math.sin(angle) * radius * 0.72,
          scale: 0.105 + (index % 3) * 0.018,
          aspect: 1.55,
          rotation: angle + math.pi / 2,
          tilt: math.sin(angle) * 0.55,
        );
      case 1:
        final column = index % 4;
        final row = index ~/ 4;
        return _PlanePose(
          x: 0.18 + column * 0.22,
          y: 0.34 + row * 0.25,
          scale: 0.115 + row * 0.012,
          aspect: 1.72,
          rotation: (column - 1.5) * 0.025,
          tilt: (column - 1.5) * 0.12,
        );
      case 2:
        final depth = index / 7;
        return _PlanePose(
          x: 0.5 + math.sin(index * 1.7 + phase * 0.08) * 0.018,
          y: 0.49,
          scale: 0.07 + depth * 0.37,
          aspect: 1.5,
          rotation: (index.isEven ? -1 : 1) * 0.012,
          tilt: math.sin(index * 0.7) * 0.18,
        );
      case 3:
        return _PlanePose(
          x: 0.22 + index * 0.075,
          y: 0.72 - index * 0.055,
          scale: 0.125 + index * 0.01,
          aspect: 2.15,
          rotation: -0.19,
          tilt: -0.22,
        );
      default:
        final column = index % 2;
        final row = index ~/ 2;
        return _PlanePose(
          x: 0.26 + column * 0.49,
          y: 0.22 + row * 0.19,
          scale: 0.13 + (row % 2) * 0.012,
          aspect: 2.05,
          rotation: column == 0 ? -0.018 : 0.018,
          tilt: column == 0 ? -0.15 : 0.15,
        );
    }
  }

  void _drawRegistrationMarks(Canvas canvas, Size size) {
    final accent = config.accent.withValues(alpha: 0.34);
    _linePaint
      ..color = accent
      ..strokeWidth = 0.8;
    const inset = 22.0;
    const length = 14.0;
    for (final origin in [
      const Offset(inset, inset),
      Offset(size.width - inset, inset),
      Offset(inset, size.height - inset),
      Offset(size.width - inset, size.height - inset),
    ]) {
      final xDirection = origin.dx < size.width / 2 ? 1.0 : -1.0;
      final yDirection = origin.dy < size.height / 2 ? 1.0 : -1.0;
      canvas
        ..drawLine(origin, origin + Offset(length * xDirection, 0), _linePaint)
        ..drawLine(origin, origin + Offset(0, length * yDirection), _linePaint);
    }
  }

  void _drawVignette(Canvas canvas, Size size, Rect bounds) {
    _paint
      ..blendMode = BlendMode.srcOver
      ..shader = ui.Gradient.radial(
        Offset(size.width * 0.5, size.height * 0.48),
        size.longestSide * 0.68,
        [
          Colors.transparent,
          AppColors.backgroundDark.withValues(alpha: 0.24),
          AppColors.backgroundDark.withValues(
            alpha: config.vignetteIntensity.clamp(0.0, 0.72),
          ),
        ],
        const [0.25, 0.72, 1],
      );
    canvas.drawRect(bounds, _paint);
    _paint.shader = null;
  }

  void _drawGrain(Canvas canvas, Size size) {
    final image = grainImage;
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

  static Offset _rotate(Offset point, double radians) {
    final cosine = math.cos(radians);
    final sine = math.sin(radians);
    return Offset(
      point.dx * cosine - point.dy * sine,
      point.dx * sine + point.dy * cosine,
    );
  }

  static double _smoothStep(double value) => value * value * (3 - 2 * value);

  @override
  bool shouldRepaint(_RenderAtlasPainter oldDelegate) =>
      time != oldDelegate.time ||
      config != oldDelegate.config ||
      pointer != oldDelegate.pointer ||
      grainImage != oldDelegate.grainImage;
}

class _DrawablePlane {
  const _DrawablePlane({required this.index, required this.pose});
  final int index;
  final _PlanePose pose;
}

class _PlanePose {
  const _PlanePose({
    required this.x,
    required this.y,
    required this.scale,
    required this.aspect,
    required this.rotation,
    required this.tilt,
  });

  final double x;
  final double y;
  final double scale;
  final double aspect;
  final double rotation;
  final double tilt;

  static _PlanePose lerp(_PlanePose from, _PlanePose to, double t) =>
      _PlanePose(
        x: ui.lerpDouble(from.x, to.x, t)!,
        y: ui.lerpDouble(from.y, to.y, t)!,
        scale: ui.lerpDouble(from.scale, to.scale, t)!,
        aspect: ui.lerpDouble(from.aspect, to.aspect, t)!,
        rotation: ui.lerpDouble(from.rotation, to.rotation, t)!,
        tilt: ui.lerpDouble(from.tilt, to.tilt, t)!,
      );
}
