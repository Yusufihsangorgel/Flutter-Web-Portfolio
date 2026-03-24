import 'dart:ui' as ui;

import 'package:flutter/material.dart';

/// Configuration for a single parallax depth layer.
class ParallaxLayerConfig {
  const ParallaxLayerConfig({
    required this.child,
    this.depthFactor = 1.0,
    this.mouseParallaxMax = 12.0,
    this.opacity,
    this.blurSigma,
    this.scale,
  });

  /// The widget rendered on this layer.
  final Widget child;

  /// Depth multiplier: 0.0 = foreground (no movement), 1.0 = farthest back
  /// (maximum movement). Intermediate values create the parallax spread.
  final double depthFactor;

  /// Maximum mouse-parallax displacement in logical pixels.
  /// Layers with higher [depthFactor] move more. Range: 5-20px recommended.
  final double mouseParallaxMax;

  /// Override layer opacity. If null, computed from depth:
  /// `1.0 - depthFactor * 0.35` (farther layers are more transparent).
  final double? opacity;

  /// Override blur sigma. If null, computed from depth:
  /// `depthFactor * 1.5` (farther layers are slightly blurred).
  final double? blurSigma;

  /// Override scale. If null, computed from depth:
  /// `1.0 - depthFactor * 0.08` (farther layers are slightly smaller).
  final double? scale;
}

/// A 2.5D parallax depth system that stacks multiple layers, each moving at a
/// different rate based on scroll position and mouse cursor location.
///
/// Scroll parallax: each layer translates vertically at `scrollOffset * rate`.
/// Mouse parallax: each layer shifts based on cursor position relative to the
/// viewport center, with smooth interpolation (lerp) to avoid jitter.
///
/// All transforms use the [Transform] widget (GPU-composited, no relayout).
class ParallaxLayerSystem extends StatefulWidget {
  const ParallaxLayerSystem({
    super.key,
    required this.layers,
    this.scrollController,
    this.scrollParallaxStrength = 0.15,
    this.mouseLerpSpeed = 0.08,
  });

  /// Ordered back-to-front: index 0 is the deepest (farthest) layer.
  final List<ParallaxLayerConfig> layers;

  /// Optional external scroll controller. If provided, vertical scroll
  /// offset drives the scroll-parallax effect.
  final ScrollController? scrollController;

  /// Global multiplier for scroll-based parallax displacement.
  final double scrollParallaxStrength;

  /// Interpolation speed for mouse tracking (0-1). Lower = smoother/laggier.
  final double mouseLerpSpeed;

  @override
  State<ParallaxLayerSystem> createState() => _ParallaxLayerSystemState();
}

class _ParallaxLayerSystemState extends State<ParallaxLayerSystem>
    with SingleTickerProviderStateMixin {
  late AnimationController _ticker;

  /// Raw mouse position normalized to (-1, 1) relative to viewport center.
  Offset _rawMouse = Offset.zero;

  /// Smoothed (lerped) mouse offset used for rendering.
  Offset _smoothMouse = Offset.zero;

  /// Cached scroll offset from the scroll controller.
  double _scrollOffset = 0.0;

  bool _mouseInside = false;

  @override
  void initState() {
    super.initState();
    _ticker = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..addListener(_onTick);
    _ticker.repeat();

    widget.scrollController?.addListener(_onScroll);
  }

  @override
  void didUpdateWidget(ParallaxLayerSystem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.scrollController != widget.scrollController) {
      oldWidget.scrollController?.removeListener(_onScroll);
      widget.scrollController?.addListener(_onScroll);
      _scrollOffset =
          widget.scrollController?.hasClients == true
              ? widget.scrollController!.offset
              : 0.0;
    }
  }

  @override
  void dispose() {
    widget.scrollController?.removeListener(_onScroll);
    _ticker
      ..removeListener(_onTick)
      ..dispose();
    super.dispose();
  }

  void _onScroll() {
    if (widget.scrollController?.hasClients == true) {
      _scrollOffset = widget.scrollController!.offset;
    }
  }

  void _onTick() {
    // Smooth interpolation toward raw mouse position.
    final target = _mouseInside ? _rawMouse : Offset.zero;
    _smoothMouse = Offset(
      ui.lerpDouble(_smoothMouse.dx, target.dx, widget.mouseLerpSpeed)!,
      ui.lerpDouble(_smoothMouse.dy, target.dy, widget.mouseLerpSpeed)!,
    );
  }

  void _onPointerHover(PointerEvent event) {
    final size = context.size;
    if (size == null || size.isEmpty) return;
    _mouseInside = true;
    _rawMouse = Offset(
      (event.localPosition.dx / size.width - 0.5) * 2.0,
      (event.localPosition.dy / size.height - 0.5) * 2.0,
    );
  }

  void _onPointerExit(PointerEvent event) => _mouseInside = false;

  @override
  Widget build(BuildContext context) => Listener(
    onPointerHover: _onPointerHover,
    onPointerMove: _onPointerHover,
    behavior: HitTestBehavior.translucent,
    child: MouseRegion(
      onExit: _onPointerExit,
      hitTestBehavior: HitTestBehavior.translucent,
      child: IgnorePointer(
        child: AnimatedBuilder(
          animation: _ticker,
          builder: (context, _) => Stack(
            fit: StackFit.expand,
            children: [
              for (var i = 0; i < widget.layers.length; i++)
                _buildLayer(widget.layers[i]),
            ],
          ),
        ),
      ),
    ),
  );

  Widget _buildLayer(ParallaxLayerConfig config) {
    final depth = config.depthFactor.clamp(0.0, 1.0);

    // Scroll parallax: deeper layers move more relative to scroll.
    final scrollDy =
        _scrollOffset * depth * widget.scrollParallaxStrength;

    // Mouse parallax: deeper layers shift more.
    final mouseDx = _smoothMouse.dx * config.mouseParallaxMax * depth;
    final mouseDy = _smoothMouse.dy * config.mouseParallaxMax * depth;

    // Depth-based defaults.
    final opacity = (config.opacity ?? (1.0 - depth * 0.35)).clamp(0.0, 1.0);
    final blurSigma = config.blurSigma ?? (depth * 1.5);
    final scale = config.scale ?? (1.0 - depth * 0.08);

    var child = config.child;

    // Apply blur for distant layers (skip when sigma is negligible).
    if (blurSigma > 0.3) {
      child = ImageFiltered(
        imageFilter: ui.ImageFilter.blur(
          sigmaX: blurSigma,
          sigmaY: blurSigma,
          tileMode: TileMode.decal,
        ),
        child: child,
      );
    }

    // Opacity.
    if (opacity < 1.0) {
      child = Opacity(opacity: opacity, child: child);
    }

    // GPU-accelerated transform: translate + scale, no relayout.
    child = Transform(
      alignment: Alignment.center,
      transform: Matrix4.identity()
        ..translateByDouble(mouseDx, -scrollDy + mouseDy, 0, 0)
        ..scaleByDouble(scale, scale, 1, 1),
      child: child,
    );

    return RepaintBoundary(child: child);
  }
}
