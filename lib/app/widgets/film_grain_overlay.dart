import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

/// Full-screen procedural film grain overlay rendered via a GLSL fragment
/// shader (`shaders/film_grain.frag`).
///
/// Drop this widget into a [Stack] on top of your content. It uses
/// [IgnorePointer] so it never intercepts events, and wraps itself in a
/// [RepaintBoundary] to avoid dirtying sibling layers.
///
/// Example:
/// ```dart
/// Stack(
///   children: [
///     // … page content …
///     const FilmGrainOverlay(),
///   ],
/// )
/// ```
class FilmGrainOverlay extends StatefulWidget {
  const FilmGrainOverlay({
    super.key,
    this.intensity = 0.06,
    this.grainSize = 1.5,
    this.fps = 24,
    this.enabled = true,
  })  : assert(intensity >= 0.0 && intensity <= 1.0),
        assert(grainSize >= 1.0),
        assert(fps > 0 && fps <= 60);

  /// Grain opacity multiplier. `0.0` = invisible, `1.0` = maximum.
  /// Typical cinematic values are 0.04 – 0.10.
  final double intensity;

  /// Pixel size of individual grain particles. `1.0` = fine (pixel-level),
  /// `3.0`+ = coarse / blocky.
  final double grainSize;

  /// Target update rate in frames per second. Lower values (e.g. 24) give a
  /// more filmic cadence and save GPU budget. The grain still animates via
  /// the shader's time uniform; this only controls how often the widget
  /// repaints.
  final int fps;

  /// Master kill-switch. When `false` the overlay paints nothing and the
  /// animation ticker is stopped.
  final bool enabled;

  @override
  State<FilmGrainOverlay> createState() => _FilmGrainOverlayState();
}

class _FilmGrainOverlayState extends State<FilmGrainOverlay>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  /// The compiled fragment shader program — loaded once.
  static Future<ui.FragmentProgram>? _programFuture;

  ui.FragmentShader? _shader;
  late Ticker _ticker;

  /// Elapsed seconds fed to the shader's `u_time` uniform.
  double _elapsed = 0.0;

  /// Throttle: minimum microseconds between repaints.
  late int _frameBudgetUs;

  /// Tracks the last repaint time for throttling.
  int _lastPaintUs = 0;

  /// Incremented to signal the painter that a new frame is ready.
  int _generation = 0;

  // -------------------------------------------------------------------------
  // Lifecycle
  // -------------------------------------------------------------------------

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _frameBudgetUs = (1000000 / widget.fps).round();

    _ticker = createTicker(_onTick);

    // Load the shader asynchronously. The future is cached statically so
    // multiple instances share the same program.
    _programFuture ??= ui.FragmentProgram.fromAsset('shaders/film_grain.frag');
    _programFuture!.then((program) {
      if (!mounted) return;
      _shader = program.fragmentShader();
      if (widget.enabled) _ticker.start();
      // Trigger a first paint now that the shader is ready.
      setState(() {});
    });
  }

  @override
  void didUpdateWidget(FilmGrainOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.fps != oldWidget.fps) {
      _frameBudgetUs = (1000000 / widget.fps).round();
    }

    if (widget.enabled && !_ticker.isActive && _shader != null) {
      _ticker.start();
    } else if (!widget.enabled && _ticker.isActive) {
      _ticker.stop();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!widget.enabled || _shader == null) return;
    switch (state) {
      case AppLifecycleState.resumed:
        if (!_ticker.isActive) _ticker.start();
      case AppLifecycleState.hidden:
      case AppLifecycleState.paused:
        if (_ticker.isActive) _ticker.stop();
      default:
        break;
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _ticker.dispose();
    _shader?.dispose();
    super.dispose();
  }

  // -------------------------------------------------------------------------
  // Tick / throttle
  // -------------------------------------------------------------------------

  void _onTick(Duration elapsed) {
    final nowUs = elapsed.inMicroseconds;
    if (nowUs - _lastPaintUs < _frameBudgetUs) return;
    _lastPaintUs = nowUs;
    _elapsed = elapsed.inMicroseconds / 1000000.0;
    _generation++;
    // Manual markNeedsPaint via setState — the painter checks _generation.
    setState(() {});
  }

  // -------------------------------------------------------------------------
  // Build
  // -------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    if (_shader == null || !widget.enabled) {
      return const SizedBox.shrink();
    }

    return Positioned.fill(
      child: IgnorePointer(
        child: ExcludeSemantics(
          child: RepaintBoundary(
            child: CustomPaint(
              painter: _FilmGrainPainter(
                shader: _shader!,
                elapsed: _elapsed,
                intensity: widget.intensity,
                grainSize: widget.grainSize,
                generation: _generation,
              ),
              // Expand to fill the available space.
              size: Size.infinite,
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// CustomPainter
// ---------------------------------------------------------------------------

class _FilmGrainPainter extends CustomPainter {
  _FilmGrainPainter({
    required this.shader,
    required this.elapsed,
    required this.intensity,
    required this.grainSize,
    required this.generation,
  });

  final ui.FragmentShader shader;
  final double elapsed;
  final double intensity;
  final double grainSize;
  final int generation;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;

    // Uniform indices must match the order declared in the .frag file.
    // 0: u_time
    shader.setFloat(0, elapsed);
    // 1-2: u_resolution (vec2 occupies two float slots)
    shader.setFloat(1, size.width);
    shader.setFloat(2, size.height);
    // 3: u_intensity
    shader.setFloat(3, intensity);
    // 4: u_grain_size
    shader.setFloat(4, grainSize);

    canvas.drawRect(
      Offset.zero & size,
      Paint()..shader = shader,
    );
  }

  @override
  bool shouldRepaint(_FilmGrainPainter old) => generation != old.generation;
}
