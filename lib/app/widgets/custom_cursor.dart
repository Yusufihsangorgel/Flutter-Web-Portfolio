import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:get/get.dart';
import 'package:flutter_web_portfolio/app/controllers/cursor_controller.dart';
import 'package:flutter_web_portfolio/app/controllers/scene_director.dart';
import 'package:flutter_web_portfolio/app/core/constants/cinematic_curves.dart';
import 'package:flutter_web_portfolio/app/core/constants/durations.dart';

/// Custom cursor overlay — outer ring + inner dot + spotlight glow.
/// Expands on interactive element hover.
class CustomCursor extends StatefulWidget {
  const CustomCursor({super.key, required this.child});
  final Widget child;

  @override
  State<CustomCursor> createState() => _CustomCursorState();
}

class _CustomCursorState extends State<CustomCursor> {
  final _position = ValueNotifier<Offset>(Offset.zero);
  final _visible = ValueNotifier<bool>(false);

  @override
  void dispose() {
    _position.dispose();
    _visible.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!kIsWeb) return widget.child;
    return MouseRegion(
      cursor: SystemMouseCursors.none,
      onHover: (e) {
        _position.value = e.position;
        _visible.value = true;
      },
      onExit: (_) => _visible.value = false,
      child: Stack(
        children: [
          widget.child,
          _SpotlightLayer(position: _position, visible: _visible),
          _CursorOverlay(position: _position, visible: _visible),
        ],
      ),
    );
  }
}

class _CursorOverlay extends StatefulWidget {
  const _CursorOverlay({
    required this.position,
    required this.visible,
  });

  final ValueNotifier<Offset> position;
  final ValueNotifier<bool> visible;

  @override
  State<_CursorOverlay> createState() => _CursorOverlayState();
}

class _CursorOverlayState extends State<_CursorOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _expandController;
  late Animation<double> _ringSize;
  late Animation<double> _dotSize;

  static const double _ringMin = 20.0;
  static const double _ringMax = 40.0;
  static const double _dotMin = 4.0;
  static const double _dotMax = 6.0;
  late Color _sceneAccent;
  late Worker _accentWorker;
  late Worker _hoverWorker;
  final List<Offset> _trail = [];

  @override
  void initState() {
    super.initState();
    _expandController = AnimationController(
      vsync: this,
      duration: AppDurations.fast,
    );
    _ringSize = Tween<double>(begin: _ringMin, end: _ringMax).animate(
      CurvedAnimation(
          parent: _expandController, curve: CinematicCurves.hoverLift),
    );
    _dotSize = Tween<double>(begin: _dotMin, end: _dotMax).animate(
      CurvedAnimation(
          parent: _expandController, curve: CinematicCurves.hoverLift),
    );

    final cursorCtrl = Get.find<CursorController>();
    _hoverWorker = ever(cursorCtrl.isHovering, (bool hovering) {
      if (hovering) {
        _expandController.forward();
      } else {
        _expandController.reverse();
      }
    });

    _sceneAccent = Get.find<SceneDirector>().currentAccent.value;
    _accentWorker =
        ever(Get.find<SceneDirector>().currentAccent, (Color color) {
      _sceneAccent = color;
    });
  }

  @override
  void dispose() {
    _hoverWorker.dispose();
    _accentWorker.dispose();
    _expandController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      ValueListenableBuilder<bool>(
      valueListenable: widget.visible,
      builder: (_, visible, child) {
        if (!visible) return const SizedBox.shrink();
        return child!;
      },
      child: Positioned.fill(
        child: IgnorePointer(
          child: ValueListenableBuilder<Offset>(
            valueListenable: widget.position,
            builder: (_, position, __) {
              // Update trail history
              if (_trail.isEmpty || (_trail.first - position).distance > 4) {
                _trail.insert(0, position);
                if (_trail.length > 8) _trail.removeLast();
              }
              return AnimatedBuilder(
                animation: _expandController,
                builder: (_, __) {
                  final cursorCtrl = Get.find<CursorController>();
                  return CustomPaint(
                    painter: _CursorPainter(
                      position: position,
                      ringSize: _ringSize.value,
                      dotSize: _dotSize.value,
                      accentColor:
                          cursorCtrl.hoverAccent.value ?? _sceneAccent,
                      trail: List.of(_trail.skip(1)),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ),
    );
}

class _CursorPainter extends CustomPainter {
  _CursorPainter({
    required this.position,
    required this.ringSize,
    required this.dotSize,
    this.accentColor,
    this.trail = const [],
  });

  final Offset position;
  final double ringSize;
  final double dotSize;
  final Color? accentColor;
  final List<Offset> trail;

  static final _ringPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1;

  static final _dotPaint = Paint();
  static final _trailPaint = Paint();

  static const _maxTrailDots = 8;

  @override
  void paint(Canvas canvas, Size size) {
    // Trail dots — older positions fade and shrink
    final trailColor = accentColor ?? Colors.white;
    for (var i = 0; i < trail.length && i < _maxTrailDots; i++) {
      final t = 1.0 - (i / _maxTrailDots);
      _trailPaint.color = trailColor.withValues(alpha: t * 0.15);
      canvas.drawCircle(trail[i], dotSize * t * 0.4, _trailPaint);
    }

    _ringPaint.color = Colors.white.withValues(alpha: 0.3);
    canvas.drawCircle(position, ringSize / 2, _ringPaint);

    _dotPaint.color = accentColor ?? Colors.white.withValues(alpha: 0.8);
    canvas.drawCircle(position, dotSize / 2, _dotPaint);
  }

  @override
  bool shouldRepaint(_CursorPainter old) =>
      position != old.position ||
      ringSize != old.ringSize ||
      dotSize != old.dotSize ||
      accentColor != old.accentColor;
}

// ---------------------------------------------------------------------------
// Spotlight layer — subtle radial gradient glow following the cursor
// ---------------------------------------------------------------------------

class _SpotlightLayer extends StatelessWidget {
  const _SpotlightLayer({
    required this.position,
    required this.visible,
  });

  final ValueNotifier<Offset> position;
  final ValueNotifier<bool> visible;

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<bool>(
        valueListenable: visible,
        builder: (_, isVisible, child) {
          if (!isVisible) return const SizedBox.shrink();
          return child!;
        },
        child: Positioned.fill(
          child: IgnorePointer(
            child: ValueListenableBuilder<Offset>(
              valueListenable: position,
              builder: (_, pos, __) {
                final accent =
                    Get.find<SceneDirector>().currentAccent.value;
                return CustomPaint(
                  painter: _SpotlightPainter(
                    position: pos,
                    accentColor: accent,
                  ),
                );
              },
            ),
          ),
        ),
      );
}

class _SpotlightPainter extends CustomPainter {
  _SpotlightPainter({
    required this.position,
    required this.accentColor,
  });

  final Offset position;
  final Color accentColor;

  static const double _radius = 300.0;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = RadialGradient(
        colors: [
          accentColor.withValues(alpha: 0.045),
          accentColor.withValues(alpha: 0.0),
        ],
        stops: const [0.0, 1.0],
      ).createShader(
        Rect.fromCircle(center: position, radius: _radius),
      );
    canvas.drawCircle(position, _radius, paint);
  }

  @override
  bool shouldRepaint(_SpotlightPainter old) =>
      position != old.position || accentColor != old.accentColor;
}
