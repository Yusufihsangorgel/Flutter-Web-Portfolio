import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_web_portfolio/app/core/constants/cinematic_curves.dart';
import 'package:flutter_web_portfolio/app/core/constants/durations.dart';

/// Applies a real-time liquid / water distortion shader over its [child].
///
/// The effect responds to the pointer position and animates intensity
/// up on hover, down on exit — producing an organic, tactile feel.
class LiquidDistortionEffect extends StatefulWidget {
  const LiquidDistortionEffect({
    super.key,
    required this.child,
    this.intensity = 1.0,
    this.hoverDuration = AppDurations.normal,
    this.enabled = true,
  });

  /// The widget to distort.
  final Widget child;

  /// Peak distortion intensity when hovered (0.0–1.0).
  final double intensity;

  /// Duration of the hover-in / hover-out intensity tween.
  final Duration hoverDuration;

  /// Set to `false` to bypass the shader entirely (useful on low-end devices).
  final bool enabled;

  @override
  State<LiquidDistortionEffect> createState() =>
      _LiquidDistortionEffectState();
}

class _LiquidDistortionEffectState extends State<LiquidDistortionEffect>
    with TickerProviderStateMixin {
  // ── Shader program ──────────────────────────────────────────────────────
  ui.FragmentProgram? _program;
  bool _shaderFailed = false;

  // ── Animation controllers ──────────────────────────────────────────────
  late final AnimationController _timeController;
  late final AnimationController _intensityController;
  late final Animation<double> _intensityCurved;

  // ── Pointer state ──────────────────────────────────────────────────────
  Offset _mousePosition = Offset.zero;

  // ── Elapsed time accumulator ───────────────────────────────────────────
  double _elapsedSeconds = 0;
  Duration _lastTick = Duration.zero;

  @override
  void initState() {
    super.initState();
    _loadShader();

    // Continuously ticking controller (drives u_time).
    _timeController = AnimationController.unbounded(vsync: this)
      ..addListener(_onTick)
      ..animateTo(
        // Effectively runs forever.
        double.maxFinite,
        duration: const Duration(days: 365 * 100),
      );

    // Intensity tween for hover transitions.
    _intensityController = AnimationController(
      vsync: this,
      duration: widget.hoverDuration,
    );
    _intensityCurved = CurvedAnimation(
      parent: _intensityController,
      curve: CinematicCurves.hoverLift,
      reverseCurve: CinematicCurves.easeInOutCinematic,
    );
  }

  Future<void> _loadShader() async {
    try {
      final program = await ui.FragmentProgram.fromAsset(
        'shaders/liquid_distortion.frag',
      );
      if (mounted) {
        setState(() => _program = program);
      }
    } catch (e) {
      debugPrint('LiquidDistortionEffect: shader load failed – $e');
      if (mounted) {
        setState(() => _shaderFailed = true);
      }
    }
  }

  void _onTick() {
    final now = _timeController.lastElapsedDuration ?? Duration.zero;
    final delta = now - _lastTick;
    _lastTick = now;
    _elapsedSeconds += delta.inMicroseconds / 1e6;
  }

  @override
  void didUpdateWidget(covariant LiquidDistortionEffect oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.hoverDuration != oldWidget.hoverDuration) {
      _intensityController.duration = widget.hoverDuration;
    }
  }

  @override
  void dispose() {
    _timeController.dispose();
    _intensityController.dispose();
    super.dispose();
  }

  // ── Pointer callbacks ─────────────────────────────────────────────────
  void _onPointerEnter(PointerEvent _) => _intensityController.forward();

  void _onPointerExit(PointerEvent _) => _intensityController.reverse();

  void _onPointerHover(PointerEvent event) {
    _mousePosition = event.localPosition;
  }

  @override
  Widget build(BuildContext context) {
    // Bypass when disabled or shader unavailable.
    if (!widget.enabled || _shaderFailed || _program == null) {
      return widget.child;
    }

    return MouseRegion(
      onEnter: _onPointerEnter,
      onExit: _onPointerExit,
      onHover: _onPointerHover,
      child: AnimatedBuilder(
        animation: Listenable.merge([_timeController, _intensityCurved]),
        builder: (context, child) => CustomPaint(
          foregroundPainter: _LiquidDistortionPainter(
            program: _program!,
            time: _elapsedSeconds,
            mouse: _mousePosition,
            intensity: _intensityCurved.value * widget.intensity,
          ),
          child: child,
        ),
        child: widget.child,
      ),
    );
  }
}

// ─── Custom painter ─────────────────────────────────────────────────────────

class _LiquidDistortionPainter extends CustomPainter {
  _LiquidDistortionPainter({
    required this.program,
    required this.time,
    required this.mouse,
    required this.intensity,
  });

  final ui.FragmentProgram program;
  final double time;
  final Offset mouse;
  final double intensity;

  @override
  void paint(Canvas canvas, Size size) {
    final shader = program.fragmentShader()
      ..setFloat(0, time)                // u_time
      ..setFloat(1, size.width)          // u_resolution.x
      ..setFloat(2, size.height)         // u_resolution.y
      ..setFloat(3, mouse.dx)            // u_mouse.x
      ..setFloat(4, mouse.dy)            // u_mouse.y
      ..setFloat(5, intensity);          // u_intensity

    final paint = Paint()..shader = shader;
    canvas.drawRect(Offset.zero & size, paint);
  }

  @override
  bool shouldRepaint(covariant _LiquidDistortionPainter oldDelegate) =>
      time != oldDelegate.time ||
      mouse != oldDelegate.mouse ||
      intensity != oldDelegate.intensity;
}
