import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:get/get.dart';

import 'package:flutter_web_portfolio/app/controllers/cursor_controller.dart';
import 'package:flutter_web_portfolio/app/controllers/scene_director.dart';

// ---------------------------------------------------------------------------
// CursorState – the six visual modes the cursor can adopt
// ---------------------------------------------------------------------------

/// Visual states for the advanced cursor system.
enum CursorState {
  /// Small dot + outer ring (default idle state).
  default_,

  /// Expanded ring with accent fill (links / buttons).
  hover,

  /// I-beam text-selection shape.
  text,

  /// Ring with "View" label inside (images / cards).
  image,

  /// Grab-hand visual (draggable elements).
  drag,

  /// Cursor hidden entirely.
  hidden,
}

// ---------------------------------------------------------------------------
// _TrailPoint – single point along the cursor ribbon
// ---------------------------------------------------------------------------

class _TrailPoint {
  _TrailPoint(this.position, this.timestamp);
  Offset position;
  double timestamp; // elapsed seconds from ticker
}

// ---------------------------------------------------------------------------
// _SpringSimulation – simple critically-damped spring for smooth follow
// ---------------------------------------------------------------------------

class _Spring {
  _Spring({
    required this.value,
    required this.target,
    this.stiffness = 180.0,
    this.damping = 22.0,
  });

  double value;
  double target;
  double velocity = 0.0;

  /// Stiffness and damping tuned for 60 fps cursor follow.
  final double stiffness;
  final double damping;

  /// Advance one frame (dt in seconds). Returns new value.
  double step(double dt) {
    final displacement = value - target;
    final springForce = -stiffness * displacement;
    final dampingForce = -damping * velocity;
    final acceleration = springForce + dampingForce;
    velocity += acceleration * dt;
    value += velocity * dt;
    return value;
  }
}

// ---------------------------------------------------------------------------
// AdvancedCursorController – extended reactive cursor state
// ---------------------------------------------------------------------------

/// Extended cursor controller that stores [CursorState], label text,
/// and magnetic-snap target. Drop-in companion to [CursorController].
class AdvancedCursorController extends GetxController {
  final state = CursorState.default_.obs;
  final label = RxnString();
  final magnetTarget = Rxn<Offset>();

  /// Convenience setter – updates state + optional label in one call.
  void setCursor(CursorState s, {String? text}) {
    state.value = s;
    label.value = text;
  }

  void reset() {
    state.value = CursorState.default_;
    label.value = null;
    magnetTarget.value = null;
  }
}

// ---------------------------------------------------------------------------
// AdvancedCursor – top-level overlay widget
// ---------------------------------------------------------------------------

/// Ultra-premium custom cursor system.
///
/// Wrap the entire app (or page scaffold) with this widget.
/// Only activates on web + desktop viewports wider than 900 px.
///
/// Features:
/// * Morphing dot + ring with spring physics
/// * 12-point bezier-curve trailing ribbon
/// * Magnetic snap toward interactive elements
/// * Radial spotlight glow
/// * Contextual text label
class AdvancedCursor extends StatefulWidget {
  const AdvancedCursor({super.key, required this.child});
  final Widget child;

  @override
  State<AdvancedCursor> createState() => _AdvancedCursorState();
}

class _AdvancedCursorState extends State<AdvancedCursor>
    with SingleTickerProviderStateMixin {
  // ---- raw pointer position ----
  Offset _rawPosition = Offset.zero;
  bool _visible = false;

  // ---- spring-driven smoothed position ----
  late _Spring _springX;
  late _Spring _springY;
  Offset _smoothPosition = Offset.zero;

  // ---- trail ----
  static const int _maxTrailPoints = 12;
  final List<_TrailPoint> _trail = [];

  // ---- velocity tracking ----
  Offset _prevPosition = Offset.zero;
  double _velocity = 0.0;

  // ---- morphing ring / dot sizes (spring-driven) ----
  late _Spring _ringSpring;
  late _Spring _dotSpring;
  late _Spring _fillOpacitySpring;

  // ---- label opacity ----
  late _Spring _labelOpacitySpring;

  // ---- ticker ----
  late Ticker _ticker;
  Duration _lastTick = Duration.zero;
  double _elapsed = 0.0;

  // ---- accent color cache ----
  Color _accentColor = Colors.white;

  // ---- constants (default sizes in logical pixels) ----
  static const double _dotDefault = 8.0;
  static const double _dotHover = 6.0;
  static const double _dotText = 2.0;

  static const double _ringDefault = 32.0;
  static const double _ringHover = 64.0;
  static const double _ringImage = 64.0;

  static const double _spotlightRadius = 200.0;

  // ---- desktop threshold ----
  static const double _desktopMinWidth = 900.0;

  // ---- controllers ----
  late final AdvancedCursorController _advCtrl;
  late final Worker _stateWorker;
  late final Worker _accentWorker;

  @override
  void initState() {
    super.initState();

    // Ensure the advanced controller is registered
    if (!Get.isRegistered<AdvancedCursorController>()) {
      Get.put(AdvancedCursorController());
    }
    _advCtrl = Get.find<AdvancedCursorController>();

    // Springs
    _springX = _Spring(value: 0, target: 0, stiffness: 200, damping: 24);
    _springY = _Spring(value: 0, target: 0, stiffness: 200, damping: 24);
    _ringSpring = _Spring(
      value: _ringDefault,
      target: _ringDefault,
      stiffness: 300,
      damping: 22,
    );
    _dotSpring = _Spring(
      value: _dotDefault,
      target: _dotDefault,
      stiffness: 300,
      damping: 22,
    );
    _fillOpacitySpring = _Spring(
      value: 0,
      target: 0,
      stiffness: 250,
      damping: 20,
    );
    _labelOpacitySpring = _Spring(
      value: 0,
      target: 0,
      stiffness: 250,
      damping: 20,
    );

    // Ticker for 60 fps updates — starts only when pointer enters
    _ticker = createTicker(_onTick);

    // React to cursor state changes
    _stateWorker = ever(_advCtrl.state, _onStateChanged);

    // React to scene accent changes
    _accentColor = Get.find<SceneDirector>().currentAccent.value;
    _accentWorker = ever(Get.find<SceneDirector>().currentAccent, (Color c) {
      _accentColor = c;
    });
  }

  @override
  void dispose() {
    _ticker.dispose();
    _stateWorker.dispose();
    _accentWorker.dispose();
    super.dispose();
  }

  // ------------------------------------------------------------------
  // State transitions – update spring targets
  // ------------------------------------------------------------------

  void _onStateChanged(CursorState s) {
    switch (s) {
      case CursorState.default_:
        _ringSpring.target = _ringDefault;
        _dotSpring.target = _dotDefault;
        _fillOpacitySpring.target = 0;
        _labelOpacitySpring.target = 0;

      case CursorState.hover:
        _ringSpring.target = _ringHover;
        _dotSpring.target = _dotHover;
        _fillOpacitySpring.target = 0.10;
        _labelOpacitySpring.target = 0;

      case CursorState.text:
        _ringSpring.target = 0; // ring hidden
        _dotSpring.target = _dotText;
        _fillOpacitySpring.target = 0;
        _labelOpacitySpring.target = 0;

      case CursorState.image:
        _ringSpring.target = _ringImage;
        _dotSpring.target = 0;
        _fillOpacitySpring.target = 0.12;
        _labelOpacitySpring.target = 1.0;

      case CursorState.drag:
        _ringSpring.target = 44;
        _dotSpring.target = 0;
        _fillOpacitySpring.target = 0.08;
        _labelOpacitySpring.target = 0;

      case CursorState.hidden:
        _ringSpring.target = 0;
        _dotSpring.target = 0;
        _fillOpacitySpring.target = 0;
        _labelOpacitySpring.target = 0;
    }

    // Update label spring target if label text present
    if (_advCtrl.label.value != null &&
        s != CursorState.hidden &&
        s != CursorState.default_) {
      _labelOpacitySpring.target = 1.0;
    }
  }

  // ------------------------------------------------------------------
  // Ticker callback – physics simulation at display refresh rate
  // ------------------------------------------------------------------

  void _onTick(Duration elapsed) {
    if (!_visible) {
      _lastTick = Duration.zero;
      return;
    }

    final dt = _lastTick == Duration.zero
        ? 1 / 60
        : (elapsed - _lastTick).inMicroseconds / 1e6;
    _lastTick = elapsed;
    _elapsed = elapsed.inMicroseconds / 1e6;

    // Clamp dt to avoid explosion on tab switch
    final safeDt = dt.clamp(0.0, 0.05);

    // ---- Magnetic snap ----
    var targetPos = _rawPosition;
    final magnetTarget = _advCtrl.magnetTarget.value;
    if (magnetTarget != null) {
      final dist = (targetPos - magnetTarget).distance;
      if (dist < 100) {
        // Interpolate toward magnet with strength inversely proportional
        // to distance
        final t = math.pow(1.0 - (dist / 100.0), 2).toDouble();
        targetPos = Offset.lerp(targetPos, magnetTarget, t * 0.35)!;
      }
    }

    _springX.target = targetPos.dx;
    _springY.target = targetPos.dy;

    _springX.step(safeDt);
    _springY.step(safeDt);
    _smoothPosition = Offset(_springX.value, _springY.value);

    // Velocity
    _velocity = (_smoothPosition - _prevPosition).distance / safeDt;
    _prevPosition = _smoothPosition;

    // Update morphing springs
    _ringSpring.step(safeDt);
    _dotSpring.step(safeDt);
    _fillOpacitySpring.step(safeDt);
    _labelOpacitySpring.step(safeDt);

    // Trail
    _trail.insert(0, _TrailPoint(Offset(_smoothPosition.dx, _smoothPosition.dy), _elapsed));
    while (_trail.length > _maxTrailPoints) {
      _trail.removeLast();
    }

    // Trigger repaint via setState – the CustomPaint layers use
    // the mutable fields directly so this is cheap.
    if (mounted) setState(() {});
  }

  // ------------------------------------------------------------------
  // Pointer handlers
  // ------------------------------------------------------------------

  void _onPointerMove(PointerEvent event) {
    _rawPosition = event.position;
    if (!_visible) {
      _visible = true;
      _springX.value = _rawPosition.dx;
      _springY.value = _rawPosition.dy;
      _smoothPosition = _rawPosition;
      _prevPosition = _rawPosition;
      // Resume ticker only when pointer enters
      if (!_ticker.isTicking) _ticker.start();
    }
  }

  void _onPointerExit(PointerEvent event) {
    _visible = false;
    _trail.clear();
    _lastTick = Duration.zero;
    // Stop ticker when pointer leaves — saves 60 rebuilds/sec
    if (_ticker.isTicking) _ticker.stop();
    if (mounted) setState(() {});
  }

  // ------------------------------------------------------------------
  // Build
  // ------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    // Only activate on web + desktop viewport
    if (!kIsWeb) return widget.child;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= _desktopMinWidth;
        if (!isDesktop) return widget.child;

        return MouseRegion(
          cursor: SystemMouseCursors.none,
          onHover: _onPointerMove,
          onExit: _onPointerExit,
          child: Listener(
            onPointerMove: _onPointerMove,
            child: Stack(
              children: [
                widget.child,
                if (_visible) ...[
                  // Spotlight glow
                  Positioned.fill(
                    child: IgnorePointer(
                      child: CustomPaint(
                        painter: _SpotlightPainter(
                          position: _smoothPosition,
                          radius: _spotlightRadius,
                          color: _accentColor,
                        ),
                      ),
                    ),
                  ),
                  // Trail ribbon
                  Positioned.fill(
                    child: IgnorePointer(
                      child: CustomPaint(
                        painter: _TrailPainter(
                          points: List.of(_trail),
                          color: _accentColor,
                          velocity: _velocity,
                        ),
                      ),
                    ),
                  ),
                  // Cursor dot + ring + label
                  Positioned.fill(
                    child: IgnorePointer(
                      child: CustomPaint(
                        painter: _CursorMorphPainter(
                          position: _smoothPosition,
                          ringSize: _ringSpring.value,
                          dotSize: _dotSpring.value,
                          fillOpacity: _fillOpacitySpring.value
                              .clamp(0.0, 1.0),
                          accentColor: _accentColor,
                          state: _advCtrl.state.value,
                          labelText: _advCtrl.label.value,
                          labelOpacity: _labelOpacitySpring.value
                              .clamp(0.0, 1.0),
                          velocity: _velocity,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

// ===========================================================================
// CustomPainters
// ===========================================================================

// ---------------------------------------------------------------------------
// 1. Cursor morph painter – dot, ring, I-beam, grab icon, label
// ---------------------------------------------------------------------------

class _CursorMorphPainter extends CustomPainter {
  _CursorMorphPainter({
    required this.position,
    required this.ringSize,
    required this.dotSize,
    required this.fillOpacity,
    required this.accentColor,
    required this.state,
    required this.velocity,
    this.labelText,
    this.labelOpacity = 0.0,
  });

  final Offset position;
  final double ringSize;
  final double dotSize;
  final double fillOpacity;
  final Color accentColor;
  final CursorState state;
  final double velocity;
  final String? labelText;
  final double labelOpacity;

  @override
  void paint(Canvas canvas, Size size) {
    // ---- Ring ----
    if (ringSize > 1) {
      final ringRadius = ringSize / 2;

      // Filled background (hover / image states)
      if (fillOpacity > 0.001) {
        final fillPaint = Paint()
          ..color = accentColor.withValues(alpha: fillOpacity)
          ..style = PaintingStyle.fill;
        canvas.drawCircle(position, ringRadius, fillPaint);
      }

      // Stroke ring
      final ringPaint = Paint()
        ..color = Colors.white.withValues(alpha: 0.35)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;
      canvas.drawCircle(position, ringRadius, ringPaint);
    }

    // ---- Dot ----
    if (dotSize > 0.5) {
      final dotPaint = Paint()
        ..color = accentColor
        ..style = PaintingStyle.fill;
      canvas.drawCircle(position, dotSize / 2, dotPaint);
    }

    // ---- I-beam (text state) ----
    if (state == CursorState.text) {
      _drawIBeam(canvas);
    }

    // ---- Grab hand (drag state) ----
    if (state == CursorState.drag) {
      _drawGrabHand(canvas);
    }

    // ---- Label text ----
    if (labelOpacity > 0.01) {
      _drawLabel(canvas);
    }

    // ---- "View" text inside ring for image state ----
    if (state == CursorState.image && ringSize > 20) {
      _drawCenteredText(canvas, 'View', ringSize);
    }
  }

  void _drawIBeam(Canvas canvas) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.9)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;

    const halfHeight = 10.0;
    const serifWidth = 4.0;

    // Vertical bar, top serif, bottom serif
    canvas
      ..drawLine(
        position.translate(0, -halfHeight),
        position.translate(0, halfHeight),
        paint,
      )
      ..drawLine(
        position.translate(-serifWidth, -halfHeight),
        position.translate(serifWidth, -halfHeight),
        paint,
      )
      ..drawLine(
        position.translate(-serifWidth, halfHeight),
        position.translate(serifWidth, halfHeight),
        paint,
      );
  }

  void _drawGrabHand(Canvas canvas) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.85)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // Simplified grab-hand icon (open palm outline)
    final cx = position.dx;
    final cy = position.dy;
    final path = Path()
      // Palm base arc
      ..moveTo(cx - 8, cy + 4)
      ..quadraticBezierTo(cx - 8, cy + 10, cx, cy + 10)
      ..quadraticBezierTo(cx + 8, cy + 10, cx + 8, cy + 4);

    // Fingers (four short lines from top of palm)
    for (var i = -1.5; i <= 1.5; i += 1.0) {
      final fx = cx + i * 4;
      path
        ..moveTo(fx, cy + 2)
        ..lineTo(fx, cy - 6)
        // Fingertip cap
        ..addArc(
          Rect.fromCircle(center: Offset(fx, cy - 6), radius: 1.2),
          math.pi,
          math.pi,
        );
    }

    canvas.drawPath(path, paint);
  }

  void _drawLabel(Canvas canvas) {
    final text = labelText;
    if (text == null || text.isEmpty) return;

    final paragraphBuilder = ui.ParagraphBuilder(
      ui.ParagraphStyle(
        textAlign: TextAlign.left,
        fontSize: 12,
        fontWeight: FontWeight.w500,
      ),
    )
      ..pushStyle(ui.TextStyle(
        color: Colors.white.withValues(alpha: labelOpacity * 0.9),
        letterSpacing: 1.2,
      ))
      ..addText(text.toUpperCase());

    final paragraph = paragraphBuilder.build()
      ..layout(const ui.ParagraphConstraints(width: 200));

    final offset = Offset(
      position.dx + (ringSize / 2) + 12,
      position.dy - paragraph.height / 2,
    );

    canvas.drawParagraph(paragraph, offset);
  }

  void _drawCenteredText(Canvas canvas, String text, double ringSize) {
    final paragraphBuilder = ui.ParagraphBuilder(
      ui.ParagraphStyle(
        textAlign: TextAlign.center,
        fontSize: 11,
        fontWeight: FontWeight.w600,
      ),
    )
      ..pushStyle(ui.TextStyle(
        color: Colors.white.withValues(alpha: 0.9),
        letterSpacing: 2.0,
      ))
      ..addText(text.toUpperCase());

    final paragraph = paragraphBuilder.build()
      ..layout(ui.ParagraphConstraints(width: ringSize));

    final offset = Offset(
      position.dx - ringSize / 2,
      position.dy - paragraph.height / 2,
    );

    canvas.drawParagraph(paragraph, offset);
  }

  @override
  bool shouldRepaint(_CursorMorphPainter old) => true; // driven by ticker
}

// ---------------------------------------------------------------------------
// 2. Trail painter – smooth bezier ribbon
// ---------------------------------------------------------------------------

class _TrailPainter extends CustomPainter {
  _TrailPainter({
    required this.points,
    required this.color,
    required this.velocity,
  });

  final List<_TrailPoint> points;
  final Color color;
  final double velocity;

  @override
  void paint(Canvas canvas, Size size) {
    if (points.length < 3) return;

    // Velocity-responsive stroke width
    final baseWidth = (velocity / 800.0).clamp(0.5, 4.0);

    // Draw the ribbon as a series of segments with decreasing opacity
    for (var i = 0; i < points.length - 2; i++) {
      final t = i / (points.length - 1); // 0 at head, 1 at tail
      final opacity = (1.0 - t) * 0.35; // fade toward tail
      final width = baseWidth * (1.0 - t * 0.7); // thin toward tail

      if (opacity < 0.005 || width < 0.1) continue;

      final p0 = points[i].position;
      final p1 = points[i + 1].position;
      final p2 = points[i + 2].position;

      // Quadratic bezier through three consecutive points
      final controlPoint = p1;
      final endPoint = Offset(
        (p1.dx + p2.dx) / 2,
        (p1.dy + p2.dy) / 2,
      );

      final path = Path()
        ..moveTo(
          i == 0 ? p0.dx : (points[i - 1].position.dx + p0.dx) / 2,
          i == 0 ? p0.dy : (points[i - 1].position.dy + p0.dy) / 2,
        )
        ..quadraticBezierTo(
          controlPoint.dx,
          controlPoint.dy,
          endPoint.dx,
          endPoint.dy,
        );

      final paint = Paint()
        ..color = color.withValues(alpha: opacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = width
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;

      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(_TrailPainter old) => true;
}

// ---------------------------------------------------------------------------
// 3. Spotlight painter – radial gradient glow
// ---------------------------------------------------------------------------

class _SpotlightPainter extends CustomPainter {
  _SpotlightPainter({
    required this.position,
    required this.radius,
    required this.color,
  });

  final Offset position;
  final double radius;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = RadialGradient(
        colors: [
          color.withValues(alpha: 0.065),
          color.withValues(alpha: 0.025),
          color.withValues(alpha: 0.0),
        ],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(
        Rect.fromCircle(center: position, radius: radius),
      )
      ..blendMode = BlendMode.screen;

    canvas.drawCircle(position, radius, paint);
  }

  @override
  bool shouldRepaint(_SpotlightPainter old) =>
      position != old.position || color != old.color;
}

// ===========================================================================
// CursorHoverRegion – convenience wrapper for interactive elements
// ===========================================================================

/// Wrap any widget to automatically set the cursor state on mouse enter/exit.
///
/// ```dart
/// CursorHoverRegion(
///   state: CursorState.hover,
///   label: 'Click',
///   magneticSnap: true,
///   child: MyButton(),
/// )
/// ```
class CursorHoverRegion extends StatefulWidget {
  const CursorHoverRegion({
    super.key,
    required this.child,
    this.state = CursorState.hover,
    this.label,
    this.magneticSnap = false,
    this.magneticRadius = 100.0,
    this.maxDisplacement = 8.0,
  });

  final Widget child;
  final CursorState state;
  final String? label;

  /// When true, the cursor snaps toward the element center and the element
  /// itself displaces slightly toward the cursor.
  final bool magneticSnap;
  final double magneticRadius;
  final double maxDisplacement;

  @override
  State<CursorHoverRegion> createState() => _CursorHoverRegionState();
}

class _CursorHoverRegionState extends State<CursorHoverRegion> {
  final _key = GlobalKey();
  Offset _displacement = Offset.zero;

  AdvancedCursorController? get _ctrl {
    if (Get.isRegistered<AdvancedCursorController>()) {
      return Get.find<AdvancedCursorController>();
    }
    return null;
  }

  Offset? _elementCenter() {
    final box = _key.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return null;
    return box.localToGlobal(box.size.center(Offset.zero));
  }

  void _onEnter(PointerEvent _) {
    final ctrl = _ctrl;
    if (ctrl == null) return;
    ctrl.setCursor(widget.state, text: widget.label);

    // Also update legacy CursorController for backward compat
    if (Get.isRegistered<CursorController>()) {
      Get.find<CursorController>().isHovering.value = true;
    }
  }

  void _onHover(PointerEvent event) {
    if (!widget.magneticSnap) return;
    final center = _elementCenter();
    if (center == null) return;

    // Set magnetic target for the cursor
    _ctrl?.magnetTarget.value = center;

    // Element displacement toward cursor
    final box = _key.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return;

    final localCenter = box.size.center(Offset.zero);
    final localPos = event.localPosition;
    final dx = localPos.dx - localCenter.dx;
    final dy = localPos.dy - localCenter.dy;
    final dist = Offset(dx, dy).distance;

    if (dist < widget.magneticRadius) {
      final factor = 1.0 - (dist / widget.magneticRadius);
      final newDisp = Offset(
        dx * factor * widget.maxDisplacement / widget.magneticRadius,
        dy * factor * widget.maxDisplacement / widget.magneticRadius,
      );
      if ((_displacement - newDisp).distance > 1.0) {
        setState(() => _displacement = newDisp);
      }
    }
  }

  void _onExit(PointerEvent _) {
    _ctrl?.reset();
    _ctrl?.magnetTarget.value = null;

    if (Get.isRegistered<CursorController>()) {
      Get.find<CursorController>().isHovering.value = false;
    }

    if (widget.magneticSnap) {
      setState(() => _displacement = Offset.zero);
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget child = MouseRegion(
      key: _key,
      onEnter: _onEnter,
      onHover: _onHover,
      onExit: _onExit,
      cursor: SystemMouseCursors.none,
      child: widget.child,
    );

    if (widget.magneticSnap) {
      child = AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: const Cubic(0.25, 0.46, 0.45, 0.94), // magneticPull
        transform: Matrix4.translationValues(
          _displacement.dx,
          _displacement.dy,
          0,
        ),
        child: child,
      );
    }

    return child;
  }
}
