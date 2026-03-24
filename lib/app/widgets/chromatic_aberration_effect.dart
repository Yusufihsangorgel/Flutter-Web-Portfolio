import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_web_portfolio/app/core/constants/cinematic_curves.dart';
import 'package:flutter_web_portfolio/app/core/constants/durations.dart';

/// Wraps a [child] widget with a real-time chromatic-aberration post-process
/// effect that reacts to pointer hover and/or external scroll velocity.
///
/// The effect is driven by a GLSL fragment shader
/// (`shaders/chromatic_aberration.frag`) which separates the R, G, B channels
/// along a direction vector.
///
/// ### Usage
/// ```dart
/// ChromaticAberrationEffect(
///   maxOffset: 6.0,
///   child: MyCard(),
/// )
/// ```
///
/// To drive the effect from scroll velocity instead of (or in addition to)
/// hover, call [ChromaticAberrationEffectState.applyScrollVelocity] via a
/// [GlobalKey].
class ChromaticAberrationEffect extends StatefulWidget {
  const ChromaticAberrationEffect({
    super.key,
    required this.child,
    this.maxOffset = 6.0,
    this.hoverEnabled = true,
    this.duration = AppDurations.normal,
    this.curve = CinematicCurves.hoverLift,
  });

  /// The widget to render beneath the aberration shader.
  final Widget child;

  /// Maximum pixel offset applied to the R and B channels.
  final double maxOffset;

  /// Whether pointer hover triggers the effect.
  final bool hoverEnabled;

  /// Duration of the offset animation (enter and exit).
  final Duration duration;

  /// Easing curve for the animation.
  final Curve curve;

  @override
  State<ChromaticAberrationEffect> createState() =>
      ChromaticAberrationEffectState();
}

class ChromaticAberrationEffectState extends State<ChromaticAberrationEffect>
    with SingleTickerProviderStateMixin {
  // ---------------------------------------------------------------------------
  // Shader
  // ---------------------------------------------------------------------------
  ui.FragmentShader? _shader;
  bool _shaderReady = false;

  // ---------------------------------------------------------------------------
  // Snapshot
  // ---------------------------------------------------------------------------
  final GlobalKey _childKey = GlobalKey();
  ui.Image? _childImage;
  Timer? _snapshotDebounce;

  // ---------------------------------------------------------------------------
  // Animation
  // ---------------------------------------------------------------------------
  late final AnimationController _controller;
  late final Animation<double> _offsetAnim;

  /// Current direction vector (normalised) for the aberration.
  Offset _direction = const Offset(1.0, 0.0);

  /// Additive offset injected by scroll velocity.
  double _scrollOffset = 0.0;

  // ---------------------------------------------------------------------------
  // Lifecycle
  // ---------------------------------------------------------------------------

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );

    _offsetAnim = Tween<double>(begin: 0.0, end: widget.maxOffset).animate(
      CurvedAnimation(parent: _controller, curve: widget.curve),
    );

    // Rebuild whenever the animation ticks so the painter repaints.
    _controller.addListener(_markDirty);

    _loadShader();
  }

  @override
  void dispose() {
    _controller
      ..removeListener(_markDirty)
      ..dispose();
    _childImage?.dispose();
    _snapshotDebounce?.cancel();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Shader loading
  // ---------------------------------------------------------------------------

  Future<void> _loadShader() async {
    try {
      final program = await ui.FragmentProgram.fromAsset(
        'shaders/chromatic_aberration.frag',
      );
      if (!mounted) return;
      _shader = program.fragmentShader();
      setState(() => _shaderReady = true);
      // Take an initial snapshot once the child has been laid out.
      WidgetsBinding.instance.addPostFrameCallback((_) => _captureChild());
    } catch (e) {
      // Shader compilation can fail on unsupported backends — fall back to
      // rendering the child without the effect.
      debugPrint('ChromaticAberrationEffect: shader load failed – $e');
    }
  }

  // ---------------------------------------------------------------------------
  // Child snapshot
  // ---------------------------------------------------------------------------

  /// Captures the child widget as a raster [ui.Image] so the shader can sample
  /// it as a texture.
  void _captureChild() {
    final boundary = _childKey.currentContext?.findRenderObject()
        as RenderRepaintBoundary?;
    if (boundary == null || !boundary.hasSize) return;

    // Debounce rapid rebuilds (e.g. during window resize).
    _snapshotDebounce?.cancel();
    _snapshotDebounce = Timer(const Duration(milliseconds: 16), () async {
      if (!mounted) return;
      try {
        final image = await boundary.toImage(
          pixelRatio: MediaQuery.devicePixelRatioOf(context),
        );
        _childImage?.dispose();
        _childImage = image;
        _markDirty();
      } catch (_) {
        // Snapshot can fail during tree mutations — silently ignore.
      }
    });
  }

  // ---------------------------------------------------------------------------
  // Hover / scroll API
  // ---------------------------------------------------------------------------

  void _onEnter(PointerEvent _) {
    if (!widget.hoverEnabled) return;
    _controller.forward();
  }

  void _onExit(PointerEvent _) {
    if (!widget.hoverEnabled) return;
    _direction = const Offset(1.0, 0.0);
    _controller.reverse();
  }

  void _onHover(PointerEvent event) {
    if (!widget.hoverEnabled) return;
    final box = context.findRenderObject() as RenderBox?;
    if (box == null) return;
    final size = box.size;
    // Direction from centre of widget to pointer.
    final dx = (event.localPosition.dx / size.width) - 0.5;
    final dy = (event.localPosition.dy / size.height) - 0.5;
    final d = Offset(dx, dy);
    _direction = d.distance > 0.001 ? d / d.distance : const Offset(1.0, 0.0);
    _markDirty();
  }

  /// Inject a scroll-velocity–driven offset. Call this from your scroll
  /// listener, passing the current velocity magnitude (pixels / second).
  /// The effect will decay automatically.
  void applyScrollVelocity(double velocityPxPerSec) {
    // Map velocity to a 0–maxOffset range.
    _scrollOffset =
        (velocityPxPerSec.abs() / 3000.0).clamp(0.0, 1.0) * widget.maxOffset;
    // Default scroll direction is vertical.
    _direction = const Offset(0.0, 1.0);
    _markDirty();

    // Decay the scroll offset.
    Future.delayed(const Duration(milliseconds: 100), () {
      if (!mounted) return;
      _scrollOffset *= 0.6;
      if (_scrollOffset < 0.2) _scrollOffset = 0.0;
      _markDirty();
    });
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  void _markDirty() {
    if (mounted) setState(() {});
  }

  double get _effectiveOffset => _offsetAnim.value + _scrollOffset;

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    // While the shader is loading (or failed), render the child directly.
    if (!_shaderReady || _shader == null) {
      return RepaintBoundary(
        key: _childKey,
        child: widget.child,
      );
    }

    return MouseRegion(
      onEnter: _onEnter,
      onExit: _onExit,
      onHover: _onHover,
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Re-capture when layout changes.
          WidgetsBinding.instance
              .addPostFrameCallback((_) => _captureChild());

          final size = Size(constraints.maxWidth, constraints.maxHeight);

          return Stack(
            children: [
              // Hidden child used only for snapshot capture.
              Opacity(
                opacity: _childImage != null && _effectiveOffset > 0.01
                    ? 0.0
                    : 1.0,
                child: RepaintBoundary(
                  key: _childKey,
                  child: widget.child,
                ),
              ),

              // Shader overlay — visible only when we have a captured image
              // and the offset is non-zero.
              if (_childImage != null && _effectiveOffset > 0.01)
                Positioned.fill(
                  child: CustomPaint(
                    painter: _ChromaticAberrationPainter(
                      shader: _shader!,
                      image: _childImage!,
                      offset: _effectiveOffset,
                      direction: _direction,
                      size: size,
                      time: _controller.lastElapsedDuration?.inMilliseconds
                              .toDouble() ??
                          0.0,
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// CustomPainter
// -----------------------------------------------------------------------------

class _ChromaticAberrationPainter extends CustomPainter {
  _ChromaticAberrationPainter({
    required this.shader,
    required this.image,
    required this.offset,
    required this.direction,
    required this.size,
    required this.time,
  });

  final ui.FragmentShader shader;
  final ui.Image image;
  final double offset;
  final Offset direction;
  final Size size;
  final double time;

  @override
  void paint(Canvas canvas, Size canvasSize) {
    // Uniform indices must match the order declared in the .frag file.
    // float  u_time        — index 0
    // vec2   u_resolution  — index 1, 2
    // float  u_offset      — index 3
    // vec2   u_direction   — index 4, 5
    shader
      ..setFloat(0, time / 1000.0)
      ..setFloat(1, size.width)
      ..setFloat(2, size.height)
      ..setFloat(3, offset)
      ..setFloat(4, direction.dx)
      ..setFloat(5, direction.dy)
      ..setImageSampler(0, image);

    canvas.drawRect(
      Offset.zero & canvasSize,
      Paint()..shader = shader,
    );
  }

  @override
  bool shouldRepaint(_ChromaticAberrationPainter oldDelegate) =>
      oldDelegate.offset != offset ||
      oldDelegate.direction != direction ||
      oldDelegate.time != time ||
      oldDelegate.image != image;
}
