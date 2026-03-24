import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

// ---------------------------------------------------------------------------
// 1. Perspective3DCard — Full 3D mouse-tracking tilt card
// ---------------------------------------------------------------------------

/// A card that tilts toward the mouse cursor on both X and Y axes, applying
/// perspective projection, a holographic glare overlay, directional edge glow,
/// and a shadow that shifts opposite to the tilt direction.
///
/// Desktop-only: touch devices receive no tilt effect.
class Perspective3DCard extends StatefulWidget {
  const Perspective3DCard({
    super.key,
    required this.child,
    this.maxTiltDegrees = 15.0,
    this.glareOpacity = 0.12,
    this.borderRadius = 16.0,
    this.liftScale = 1.05,
    this.shadowColor,
    this.edgeGlowColor,
    this.backgroundColor,
    this.padding = EdgeInsets.zero,
  });

  final Widget child;

  /// Maximum tilt angle in degrees on each axis.
  final double maxTiltDegrees;

  /// Peak opacity of the holographic glare overlay.
  final double glareOpacity;

  /// Border radius of the card.
  final double borderRadius;

  /// Scale factor when the card is hovered (lift effect).
  final double liftScale;

  /// Shadow base color. Falls back to black at 25 % opacity.
  final Color? shadowColor;

  /// Edge highlight color. Falls back to white.
  final Color? edgeGlowColor;

  /// Card background color.
  final Color? backgroundColor;

  /// Inner padding.
  final EdgeInsets padding;

  @override
  State<Perspective3DCard> createState() => _Perspective3DCardState();
}

class _Perspective3DCardState extends State<Perspective3DCard>
    with SingleTickerProviderStateMixin {
  // Normalised mouse position in [-1, 1] range.
  double _normalX = 0;
  double _normalY = 0;

  // Spring-interpolated tilt values written each frame.
  double _tiltX = 0;
  double _tiltY = 0;
  double _hover = 0; // 0 = idle, 1 = fully hovered

  late final AnimationController _spring;
  late final Animation<double> _hoverCurve;

  @override
  void initState() {
    super.initState();
    _spring = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..addListener(_interpolate);

    _hoverCurve = CurvedAnimation(
      parent: _spring,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );
  }

  void _interpolate() {
    setState(() {
      final t = _hoverCurve.value;
      final maxRad = widget.maxTiltDegrees * (math.pi / 180);
      _tiltX = -_normalY * maxRad * t;
      _tiltY = _normalX * maxRad * t;
      _hover = t;
    });
  }

  @override
  void dispose() {
    _spring.dispose();
    super.dispose();
  }

  void _onEnter(PointerEnterEvent e) {
    if (e.kind == PointerDeviceKind.touch) return;
    _spring.forward();
  }

  void _onHover(PointerHoverEvent e) {
    if (e.kind == PointerDeviceKind.touch) return;
    final box = context.findRenderObject() as RenderBox?;
    if (box == null) return;
    final size = box.size;
    if (size.isEmpty) return;
    _normalX = (e.localPosition.dx / size.width - 0.5) * 2;
    _normalY = (e.localPosition.dy / size.height - 0.5) * 2;
  }

  void _onExit(PointerExitEvent e) {
    _normalX = 0;
    _normalY = 0;
    _spring.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final shadowBase =
        widget.shadowColor ?? Colors.black.withValues(alpha: 0.25);
    final edgeGlow = widget.edgeGlowColor ?? Colors.white;
    final scale = 1.0 + (_hover * (widget.liftScale - 1.0));

    // Perspective transform.
    final transform = Matrix4.identity()
      ..setEntry(3, 2, 0.001)
      ..rotateX(_tiltX)
      ..rotateY(_tiltY)
      ..scaleByDouble(scale, scale, scale, 1.0);

    // Shadow offset shifts opposite to tilt.
    final shadowOffsetX = -_tiltY * 30;
    final shadowOffsetY = _tiltX * 30;
    final shadowBlur = 16.0 + _hover * 24.0;

    // Glare center follows the mouse (normalised -> Alignment).
    final glareAlignment = Alignment(
      _normalX * _hover,
      _normalY * _hover,
    );

    // Edge glow direction: the edge closest to the cursor is brightest.
    final edgeAlignment = Alignment(
      _normalX * _hover,
      _normalY * _hover,
    );

    return MouseRegion(
      onEnter: _onEnter,
      onHover: _onHover,
      onExit: _onExit,
      child: Transform(
        transform: transform,
        alignment: Alignment.center,
        child: Container(
          padding: widget.padding,
          decoration: BoxDecoration(
            color: widget.backgroundColor ??
                const Color(0xFF0F0A2A).withValues(alpha: 0.85),
            borderRadius: BorderRadius.circular(widget.borderRadius),
            boxShadow: [
              BoxShadow(
                color: shadowBase.withValues(alpha: 0.15 + _hover * 0.2),
                blurRadius: shadowBlur,
                offset: Offset(shadowOffsetX, shadowOffsetY),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            child: Stack(
              children: [
                // Content
                widget.child,

                // Holographic glare overlay
                if (_hover > 0.01)
                  Positioned.fill(
                    child: IgnorePointer(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          borderRadius:
                              BorderRadius.circular(widget.borderRadius),
                          gradient: RadialGradient(
                            center: glareAlignment,
                            radius: 0.85,
                            colors: [
                              Colors.white
                                  .withValues(alpha: widget.glareOpacity * _hover),
                              Colors.white.withValues(
                                  alpha: widget.glareOpacity * 0.3 * _hover),
                              Colors.transparent,
                            ],
                            stops: const [0.0, 0.45, 1.0],
                          ),
                        ),
                      ),
                    ),
                  ),

                // Edge highlight overlay
                if (_hover > 0.01)
                  Positioned.fill(
                    child: IgnorePointer(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          borderRadius:
                              BorderRadius.circular(widget.borderRadius),
                          gradient: LinearGradient(
                            begin: edgeAlignment,
                            end: Alignment(-edgeAlignment.x, -edgeAlignment.y),
                            colors: [
                              edgeGlow.withValues(alpha: 0.08 * _hover),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 2. FlipCard3D — Enhanced card flip with perspective
// ---------------------------------------------------------------------------

/// A card that flips between [front] and [back] faces with Y-axis rotation,
/// perspective projection, lift effect, and optional flip indicator icon.
///
/// Can be triggered on hover or tap via [flipTrigger].
class FlipCard3D extends StatefulWidget {
  const FlipCard3D({
    super.key,
    required this.front,
    required this.back,
    this.flipTrigger = FlipTrigger.hover,
    this.duration = const Duration(milliseconds: 600),
    this.showIndicator = true,
    this.indicatorColor,
    this.borderRadius = 16.0,
  });

  final Widget front;
  final Widget back;
  final FlipTrigger flipTrigger;
  final Duration duration;

  /// Whether to show a small flip indicator icon in the corner.
  final bool showIndicator;
  final Color? indicatorColor;
  final double borderRadius;

  @override
  State<FlipCard3D> createState() => _FlipCard3DState();
}

enum FlipTrigger { hover, tap, both }

class _FlipCard3DState extends State<FlipCard3D>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _flipAnim;
  bool _isFlipped = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );

    // Spring-like curve for natural feel.
    _flipAnim = CurvedAnimation(
      parent: _controller,
      curve: const _SpringCurve(damping: 12, stiffness: 120),
      reverseCurve: const _SpringCurve(damping: 12, stiffness: 120),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _flip() {
    if (_isFlipped) {
      _controller.reverse();
    } else {
      _controller.forward();
    }
    _isFlipped = !_isFlipped;
  }

  void _onEnter(PointerEnterEvent _) {
    if (widget.flipTrigger == FlipTrigger.hover ||
        widget.flipTrigger == FlipTrigger.both) {
      if (!_isFlipped) _flip();
    }
  }

  void _onExit(PointerExitEvent _) {
    if (widget.flipTrigger == FlipTrigger.hover ||
        widget.flipTrigger == FlipTrigger.both) {
      if (_isFlipped) _flip();
    }
  }

  void _onTap() {
    if (widget.flipTrigger == FlipTrigger.tap ||
        widget.flipTrigger == FlipTrigger.both) {
      _flip();
    }
  }

  @override
  Widget build(BuildContext context) {
    final indicatorColor =
        widget.indicatorColor ?? Colors.white.withValues(alpha: 0.5);

    return MouseRegion(
      onEnter: _onEnter,
      onExit: _onExit,
      child: GestureDetector(
        onTap: _onTap,
        child: AnimatedBuilder(
          animation: _flipAnim,
          builder: (context, _) {
            final angle = _flipAnim.value * math.pi;
            final isFront = angle < math.pi / 2;

            // Lift effect peaks at 90 degrees.
            final liftProgress = math.sin(angle);
            final scale = 1.0 + liftProgress * 0.04;
            final shadowBlur = 8.0 + liftProgress * 24.0;

            final transform = Matrix4.identity()
              ..setEntry(3, 2, 0.0015)
              ..rotateY(angle)
              ..scaleByDouble(scale, scale, scale, 1.0);

            // For the back face, flip an additional pi so text isn't mirrored.
            final backTransform = Matrix4.identity()
              ..setEntry(3, 2, 0.0015)
              ..rotateY(angle + math.pi)
              ..scaleByDouble(scale, scale, scale, 1.0);

            return Transform(
              transform: isFront ? transform : backTransform,
              alignment: Alignment.center,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(widget.borderRadius),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1 + liftProgress * 0.15),
                      blurRadius: shadowBlur,
                      offset: Offset(0, 4 + liftProgress * 8),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(widget.borderRadius),
                  child: Stack(
                    children: [
                      if (isFront) widget.front else widget.back,

                      // Flip indicator icon
                      if (widget.showIndicator && isFront)
                        Positioned(
                          top: 8,
                          right: 8,
                          child: Icon(
                            Icons.flip,
                            size: 16,
                            color: indicatorColor,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 3. FoldCard — Paper fold / letter-open effect
// ---------------------------------------------------------------------------

/// A card that "unfolds" on hover like opening a letter. The top half
/// folds forward to reveal hidden content underneath.
class FoldCard extends StatefulWidget {
  const FoldCard({
    super.key,
    required this.frontTop,
    required this.frontBottom,
    required this.revealContent,
    this.foldDuration = const Duration(milliseconds: 700),
    this.borderRadius = 16.0,
    this.backgroundColor,
    this.shadowColor,
  });

  /// Widget displayed on the top half of the card (the flap).
  final Widget frontTop;

  /// Widget displayed on the bottom half of the card (always visible).
  final Widget frontBottom;

  /// Widget revealed beneath the fold when opened.
  final Widget revealContent;

  final Duration foldDuration;
  final double borderRadius;
  final Color? backgroundColor;
  final Color? shadowColor;

  @override
  State<FoldCard> createState() => _FoldCardState();
}

class _FoldCardState extends State<FoldCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _foldAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.foldDuration,
    );

    _foldAnim = CurvedAnimation(
      parent: _controller,
      curve: const _SpringCurve(damping: 14, stiffness: 100),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onEnter(PointerEnterEvent e) {
    if (e.kind == PointerDeviceKind.touch) return;
    _controller.forward();
  }

  void _onExit(PointerExitEvent e) {
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final bg =
        widget.backgroundColor ?? const Color(0xFF0F0A2A).withValues(alpha: 0.85);
    final shadowCol =
        widget.shadowColor ?? Colors.black.withValues(alpha: 0.3);

    return MouseRegion(
      onEnter: _onEnter,
      onExit: _onExit,
      child: AnimatedBuilder(
        animation: _foldAnim,
        builder: (context, _) {
          // Fold angle: 0 = flat, -pi/2 = fully folded forward (open).
          final foldAngle = -_foldAnim.value * (math.pi * 0.45);
          final foldShadowOpacity = _foldAnim.value * 0.3;

          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Top flap with fold transform — pivots at its bottom edge.
              Transform(
                transform: Matrix4.identity()
                  ..setEntry(3, 2, 0.002)
                  ..rotateX(foldAngle),
                alignment: Alignment.bottomCenter,
                child: Container(
                  decoration: BoxDecoration(
                    color: bg,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(widget.borderRadius),
                      topRight: Radius.circular(widget.borderRadius),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: shadowCol.withValues(alpha: foldShadowOpacity),
                        blurRadius: 12 * _foldAnim.value,
                        offset: Offset(0, 6 * _foldAnim.value),
                      ),
                    ],
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: widget.frontTop,
                ),
              ),

              // Revealed content underneath the fold.
              ClipRect(
                child: Align(
                  alignment: Alignment.topCenter,
                  heightFactor: _foldAnim.value.clamp(0.0, 1.0),
                  child: Opacity(
                    opacity: _foldAnim.value.clamp(0.0, 1.0),
                    child: Container(
                      decoration: BoxDecoration(color: bg),
                      child: widget.revealContent,
                    ),
                  ),
                ),
              ),

              // Bottom half — always visible.
              Container(
                decoration: BoxDecoration(
                  color: bg,
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(widget.borderRadius),
                    bottomRight: Radius.circular(widget.borderRadius),
                  ),
                ),
                clipBehavior: Clip.antiAlias,
                child: widget.frontBottom,
              ),
            ],
          );
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 4. StackCard — Stacked card deck with fan-out effect
// ---------------------------------------------------------------------------

/// A deck of stacked cards that fan out on hover and cycle through on tap.
///
/// Provide [cards] as a list of widgets. The top card is fully visible;
/// the others peek out behind with a slight offset and rotation.
class StackCard extends StatefulWidget {
  const StackCard({
    super.key,
    required this.cards,
    this.maxRotationDegrees = 6.0,
    this.spreadOffset = 28.0,
    this.duration = const Duration(milliseconds: 500),
    this.borderRadius = 16.0,
    this.backgroundColor,
  });

  /// The list of card content widgets. Minimum 2 recommended.
  final List<Widget> cards;

  /// Maximum rotation per card when fanned out (degrees).
  final double maxRotationDegrees;

  /// How far apart cards spread on hover (pixels).
  final double spreadOffset;

  final Duration duration;
  final double borderRadius;
  final Color? backgroundColor;

  @override
  State<StackCard> createState() => _StackCardState();
}

class _StackCardState extends State<StackCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _spreadController;
  late final Animation<double> _spreadAnim;
  int _topIndex = 0;

  @override
  void initState() {
    super.initState();
    _spreadController = AnimationController(
      vsync: this,
      duration: widget.duration,
    );

    _spreadAnim = CurvedAnimation(
      parent: _spreadController,
      curve: const _SpringCurve(damping: 14, stiffness: 130),
    );
  }

  @override
  void dispose() {
    _spreadController.dispose();
    super.dispose();
  }

  void _onEnter(PointerEnterEvent e) {
    if (e.kind == PointerDeviceKind.touch) return;
    _spreadController.forward();
  }

  void _onExit(PointerExitEvent e) {
    _spreadController.reverse();
  }

  void _cycleCard() {
    setState(() {
      _topIndex = (_topIndex + 1) % widget.cards.length;
    });
  }

  @override
  Widget build(BuildContext context) {
    final count = widget.cards.length;
    if (count == 0) return const SizedBox.shrink();

    final bg =
        widget.backgroundColor ?? const Color(0xFF0F0A2A).withValues(alpha: 0.85);

    return MouseRegion(
      onEnter: _onEnter,
      onExit: _onExit,
      child: GestureDetector(
        onTap: _cycleCard,
        child: AnimatedBuilder(
          animation: _spreadAnim,
          builder: (context, _) {
            // Build card data sorted back-to-front (highest depth first).
            final indices = List.generate(count, (i) => i)
              ..sort((a, b) {
              final depthA = ((a - _topIndex) % count).toDouble();
              final depthB = ((b - _topIndex) % count).toDouble();
              return depthB.compareTo(depthA); // back-to-front
            });

            return Stack(
              clipBehavior: Clip.none,
              children: indices.map((i) {
                final visualIndex = (i - _topIndex) % count;
                final depth = visualIndex.toDouble();

                // Cards further back get more offset and rotation.
                final maxRot =
                    widget.maxRotationDegrees * (math.pi / 180);
                final rotationTarget =
                    (depth - (count - 1) / 2) * maxRot * 0.6;
                final rotation = rotationTarget * _spreadAnim.value;

                final offsetX =
                    (depth - (count - 1) / 2) *
                    widget.spreadOffset *
                    _spreadAnim.value;
                final offsetY =
                    depth * 3 * (1 - _spreadAnim.value); // idle stacking

                final clampedScale =
                    (1.0 - depth * 0.03 * (1 - _spreadAnim.value * 0.5))
                        .clamp(0.85, 1.0);
                final opacity = 1.0 - depth * 0.12;

                final transform = Matrix4.identity()
                  ..setEntry(3, 2, 0.001)
                  ..translateByDouble(offsetX, offsetY, 0.0, 0.0)
                  ..rotateZ(rotation)
                  ..scaleByDouble(clampedScale, clampedScale, clampedScale, 1.0);

                return Transform(
                  transform: transform,
                  alignment: Alignment.center,
                  child: Opacity(
                    opacity: opacity.clamp(0.4, 1.0),
                    child: Container(
                      decoration: BoxDecoration(
                        color: bg,
                        borderRadius:
                            BorderRadius.circular(widget.borderRadius),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(
                                alpha: 0.08 + depth * 0.04),
                            blurRadius: 8 + depth * 4,
                            offset: Offset(0, 2 + depth * 2),
                          ),
                        ],
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: widget.cards[i],
                    ),
                  ),
                );
              }).toList(),
            );
          },
        ),
      ),
    );
  }

}

// ---------------------------------------------------------------------------
// Shared: simple spring curve approximation via damped sine
// ---------------------------------------------------------------------------

/// A [Curve] that approximates spring physics with configurable
/// [damping] and [stiffness]. Produces slight overshoot for natural feel.
class _SpringCurve extends Curve {
  const _SpringCurve({
    this.damping = 12.0,
    this.stiffness = 100.0,
  });

  final double damping;
  final double stiffness;

  @override
  double transformInternal(double t) {
    // Critically / over-damped spring approximation.
    final omega = math.sqrt(stiffness);
    final zeta = damping / (2 * omega);

    if (zeta >= 1.0) {
      // Over-damped / critically damped — smooth with no overshoot.
      return 1.0 - (1.0 + (omega * t)) * math.exp(-omega * t);
    } else {
      // Under-damped — slight overshoot for bouncy feel.
      final dampedOmega = omega * math.sqrt(1.0 - zeta * zeta);
      return 1.0 -
          math.exp(-zeta * omega * t) *
              (math.cos(dampedOmega * t) +
                  (zeta / math.sqrt(1.0 - zeta * zeta)) *
                      math.sin(dampedOmega * t));
    }
  }
}
