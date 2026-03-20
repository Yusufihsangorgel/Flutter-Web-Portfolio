import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:get/get.dart';
import 'package:flutter_web_portfolio/app/controllers/cursor_controller.dart';
import 'package:flutter_web_portfolio/app/controllers/scene_director.dart';
import 'package:flutter_web_portfolio/app/core/constants/cinematic_curves.dart';
import 'package:flutter_web_portfolio/app/core/constants/durations.dart';

/// Custom cursor overlay — outer ring + inner dot.
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
  late Color _sceneAccent;
  late Worker _accentWorker;
  late Worker _hoverWorker;

  @override
  void initState() {
    super.initState();
    _expandController = AnimationController(
      vsync: this,
      duration: AppDurations.fast,
    );
    _ringSize = Tween<double>(begin: 20, end: 40).animate(
      CurvedAnimation(
          parent: _expandController, curve: CinematicCurves.hoverLift),
    );
    _dotSize = Tween<double>(begin: 4, end: 6).animate(
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
            builder: (_, position, __) => AnimatedBuilder(
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
                    ),
                  );
                },
              ),
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
  });

  final Offset position;
  final double ringSize;
  final double dotSize;
  final Color? accentColor;

  static final _ringPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1;

  static final _dotPaint = Paint();

  @override
  void paint(Canvas canvas, Size size) {
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
