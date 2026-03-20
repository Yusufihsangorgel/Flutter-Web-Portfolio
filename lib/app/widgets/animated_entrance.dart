import 'package:flutter/material.dart';
import 'package:flutter_web_portfolio/app/core/constants/durations.dart';

/// Drop-in animate_do replacement without debug print spam.
/// Named constructors: fadeInDown, fadeInUp, fadeInLeft, fadeInRight.
class AnimatedEntrance extends StatefulWidget {
  const AnimatedEntrance({
    super.key,
    required this.child,
    this.offset = const Offset(0, -30),
    this.duration = AppDurations.entrance,
    this.delay = Duration.zero,
    this.curve = Curves.easeOutCubic,
  });

  /// Slide down from above
  const AnimatedEntrance.fadeInDown({
    super.key,
    required this.child,
    this.duration = AppDurations.entrance,
    this.delay = Duration.zero,
    this.curve = Curves.easeOutCubic,
  }) : offset = const Offset(0, -30);

  /// Slide up from below
  const AnimatedEntrance.fadeInUp({
    super.key,
    required this.child,
    this.duration = AppDurations.entrance,
    this.delay = Duration.zero,
    this.curve = Curves.easeOutCubic,
  }) : offset = const Offset(0, 30);

  /// Slide in from left
  const AnimatedEntrance.fadeInLeft({
    super.key,
    required this.child,
    this.duration = AppDurations.entrance,
    this.delay = Duration.zero,
    this.curve = Curves.easeOutCubic,
  }) : offset = const Offset(-30, 0);

  /// Slide in from right
  const AnimatedEntrance.fadeInRight({
    super.key,
    required this.child,
    this.duration = AppDurations.entrance,
    this.delay = Duration.zero,
    this.curve = Curves.easeOutCubic,
  }) : offset = const Offset(30, 0);

  final Widget child;
  final Offset offset;
  final Duration duration;
  final Duration delay;
  final Curve curve;

  @override
  State<AnimatedEntrance> createState() => _AnimatedEntranceState();
}

class _AnimatedEntranceState extends State<AnimatedEntrance>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacity;
  late Animation<Offset> _position;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);

    final curved = CurvedAnimation(parent: _controller, curve: widget.curve);
    _opacity = Tween<double>(begin: 0, end: 1).animate(curved);
    _position = Tween<Offset>(begin: widget.offset, end: Offset.zero).animate(curved);

    if (widget.delay == Duration.zero) {
      _controller.forward();
    } else {
      Future.delayed(widget.delay, () {
        if (mounted) _controller.forward();
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _controller,
    builder: (_, child) => Opacity(
      opacity: _opacity.value,
      child: Transform.translate(offset: _position.value, child: child),
    ),
    child: widget.child,
  );
}
