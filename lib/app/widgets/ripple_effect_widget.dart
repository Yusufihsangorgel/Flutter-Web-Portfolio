import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';

// ─── Ripple slot ───────────────────────────────────────────────────────────────

/// Represents a single ripple instance within the ring buffer.
class _RippleSlot {
  _RippleSlot();

  /// Normalised origin (0..1, 0..1) of the ripple within the widget.
  Offset origin = Offset.zero;

  /// Elapsed time (in seconds) at which the ripple was spawned, relative to
  /// the widget's internal ticker.  A value of `-1` marks the slot as inactive.
  double startTime = -1;

  bool get isActive => startTime >= 0;
}

// ─── Widget ────────────────────────────────────────────────────────────────────

/// A widget that renders an interactive water-ripple distortion effect over its
/// [child].  Tapping or clicking anywhere inside the widget spawns a concentric
/// ripple that radiates outward and fades over time.
///
/// Up to [maxRipples] (default 3) ripples may be active simultaneously; new
/// taps evict the oldest ripple in a ring-buffer fashion.
///
/// The effect is driven by a GLSL fragment shader (`shaders/ripple_effect.frag`)
/// which displaces the child's pixels along radial vectors.
///
/// ```dart
/// RippleEffectWidget(
///   amplitude: 0.025,
///   child: MyContentWidget(),
/// )
/// ```
class RippleEffectWidget extends StatefulWidget {
  const RippleEffectWidget({
    super.key,
    required this.child,
    this.amplitude = 0.03,
    this.frequency = 12.0,
    this.decayRate = 3.0,
    this.tint = const Color(0x180088FF),
    this.maxRipples = 3,
    this.rippleLifetime = const Duration(seconds: 3),
  }) : assert(maxRipples > 0 && maxRipples <= 3);

  /// The widget whose rendered output is distorted by the ripple effect.
  final Widget child;

  /// Maximum UV displacement per ripple (normalised; 0.03 = 3 % of width).
  final double amplitude;

  /// Number of concentric wave oscillations per unit distance.
  final double frequency;

  /// Exponential decay rate -- higher values make ripples fade faster.
  final double decayRate;

  /// Optional colour tint blended into ripple highlights.
  final Color tint;

  /// Maximum number of concurrent ripples (1-3).
  final int maxRipples;

  /// Duration after which a ripple slot is automatically recycled.
  final Duration rippleLifetime;

  @override
  State<RippleEffectWidget> createState() => _RippleEffectWidgetState();
}

// ─── State ─────────────────────────────────────────────────────────────────────

class _RippleEffectWidgetState extends State<RippleEffectWidget>
    with SingleTickerProviderStateMixin {
  /// Pre-compiled fragment shader program (loaded once, cached).
  static ui.FragmentProgram? _cachedProgram;
  static Future<ui.FragmentProgram>? _programFuture;

  ui.FragmentShader? _shader;
  late final List<_RippleSlot> _slots;
  int _nextSlot = 0;
  bool _hasActiveRipples = false;

  /// Wall-clock elapsed seconds driven by a [Ticker].
  double _elapsed = 0;
  Ticker? _ticker;
  final GlobalKey _boundaryKey = GlobalKey();
  ui.Image? _childImage;

  @override
  void initState() {
    super.initState();
    _slots = List.generate(widget.maxRipples, (_) => _RippleSlot());
    _loadShader();
  }

  Future<void> _loadShader() async {
    // Reuse the compiled program across all widget instances.
    _programFuture ??=
        ui.FragmentProgram.fromAsset('shaders/ripple_effect.frag');
    _cachedProgram ??= await _programFuture;
    if (!mounted) return;

    _shader = _cachedProgram!.fragmentShader();
    setState(() {});
  }

  @override
  void dispose() {
    _ticker?.dispose();
    _shader?.dispose();
    _childImage?.dispose();
    super.dispose();
  }

  // ── Ticker management ────────────────────────────────────────────────────

  void _ensureTickerRunning() {
    if (_ticker != null && _ticker!.isActive) return;
    _ticker?.dispose();
    _ticker = createTicker(_onTick)..start();
  }

  void _onTick(Duration elapsed) {
    _elapsed = elapsed.inMicroseconds / Duration.microsecondsPerSecond;

    // Expire old ripples.
    final lifetimeSec =
        widget.rippleLifetime.inMicroseconds / Duration.microsecondsPerSecond;
    _hasActiveRipples = false;
    for (final slot in _slots) {
      if (slot.isActive && (_elapsed - slot.startTime) > lifetimeSec) {
        slot.startTime = -1;
      }
      if (slot.isActive) _hasActiveRipples = true;
    }

    if (!_hasActiveRipples) {
      _ticker?.stop();
      _childImage?.dispose();
      _childImage = null;
      setState(() {});
      return;
    }

    _captureChild();
    setState(() {});
  }

  // ── Child rasterisation ──────────────────────────────────────────────────

  Future<void> _captureChild() async {
    final boundary = _boundaryKey.currentContext?.findRenderObject()
        as RenderRepaintBoundary?;
    if (boundary == null || !boundary.hasSize) return;

    try {
      final image = await boundary.toImage(
        pixelRatio: MediaQuery.devicePixelRatioOf(context),
      );
      _childImage?.dispose();
      _childImage = image;
    } catch (_) {
      // Boundary not ready yet -- skip this frame.
    }
  }

  // ── Interaction ──────────────────────────────────────────────────────────

  void _onTapDown(TapDownDetails details) {
    final box = context.findRenderObject() as RenderBox?;
    if (box == null || _shader == null) return;

    final local = details.localPosition;
    final size = box.size;
    final normalised = Offset(local.dx / size.width, local.dy / size.height);

    // Ring-buffer: overwrite the oldest slot.
    final slot = _slots[_nextSlot % widget.maxRipples];
    slot
      ..origin = normalised
      ..startTime = _elapsed;
    _nextSlot++;

    _hasActiveRipples = true;
    _ensureTickerRunning();

    // Capture immediately so the first frame has a texture to sample.
    _captureChild();
  }

  // ── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final childWidget = RepaintBoundary(
      key: _boundaryKey,
      child: widget.child,
    );

    // Until the shader is compiled or no ripples are active, render the child
    // directly without the shader overhead.
    if (_shader == null || !_hasActiveRipples || _childImage == null) {
      return GestureDetector(
        onTapDown: _onTapDown,
        behavior: HitTestBehavior.translucent,
        child: childWidget,
      );
    }

    return GestureDetector(
      onTapDown: _onTapDown,
      behavior: HitTestBehavior.translucent,
      child: Stack(
        children: [
          // Keep the child in the tree (hidden) so it remains interactive and
          // the RepaintBoundary stays valid for future captures.
          Opacity(opacity: 0, child: childWidget),
          // Paint the shader-distorted version on top.
          CustomPaint(
            painter: _RipplePainter(
              shader: _shader!,
              elapsed: _elapsed,
              amplitude: widget.amplitude,
              frequency: widget.frequency,
              decayRate: widget.decayRate,
              tint: widget.tint,
              slots: _slots,
              childImage: _childImage!,
            ),
            size: Size.infinite,
          ),
        ],
      ),
    );
  }
}

// ─── CustomPainter ─────────────────────────────────────────────────────────────

class _RipplePainter extends CustomPainter {
  _RipplePainter({
    required this.shader,
    required this.elapsed,
    required this.amplitude,
    required this.frequency,
    required this.decayRate,
    required this.tint,
    required this.slots,
    required this.childImage,
  });

  final ui.FragmentShader shader;
  final double elapsed;
  final double amplitude;
  final double frequency;
  final double decayRate;
  final Color tint;
  final List<_RippleSlot> slots;
  final ui.Image childImage;

  @override
  void paint(Canvas canvas, Size size) {
    // ── Float uniforms (indices must match the shader declaration order) ──
    var idx = 0;
    shader.setFloat(idx++, elapsed);          // u_time
    shader.setFloat(idx++, size.width);       // u_resolution.x
    shader.setFloat(idx++, size.height);      // u_resolution.y
    shader.setFloat(idx++, amplitude);        // u_amplitude
    shader.setFloat(idx++, frequency);        // u_frequency
    shader.setFloat(idx++, decayRate);        // u_decay

    // Slot 0.
    final s0 = slots.isNotEmpty ? slots[0] : _RippleSlot();
    shader.setFloat(idx++, s0.origin.dx);     // u_origin0.x
    shader.setFloat(idx++, s0.origin.dy);     // u_origin0.y
    shader.setFloat(idx++, s0.startTime);     // u_start0

    // Slot 1.
    final s1 = slots.length > 1 ? slots[1] : _RippleSlot();
    shader.setFloat(idx++, s1.origin.dx);     // u_origin1.x
    shader.setFloat(idx++, s1.origin.dy);     // u_origin1.y
    shader.setFloat(idx++, s1.startTime);     // u_start1

    // Slot 2.
    final s2 = slots.length > 2 ? slots[2] : _RippleSlot();
    shader.setFloat(idx++, s2.origin.dx);     // u_origin2.x
    shader.setFloat(idx++, s2.origin.dy);     // u_origin2.y
    shader.setFloat(idx++, s2.startTime);     // u_start2

    // Tint colour (premultiplied alpha).
    final a = tint.a;
    shader.setFloat(idx++, tint.r * a);       // u_tint.r
    shader.setFloat(idx++, tint.g * a);       // u_tint.g
    shader.setFloat(idx++, tint.b * a);       // u_tint.b
    shader.setFloat(idx++, a);                // u_tint.a

    // ── Sampler uniform ────────────────────────────────────────────────────
    shader.setImageSampler(0, childImage);

    // Draw the shader across the full widget area.
    canvas.drawRect(
      Offset.zero & size,
      Paint()..shader = shader,
    );
  }

  @override
  bool shouldRepaint(_RipplePainter oldDelegate) => true;
}
