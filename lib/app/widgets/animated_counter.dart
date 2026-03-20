import 'package:flutter/material.dart';
import 'package:flutter_web_portfolio/app/core/constants/cinematic_curves.dart';

/// Animates an integer value counting up from 0 to [endValue].
///
/// Uses [CinematicCurves.revealDecel] for a fast start / slow finish feel.
class AnimatedCounter extends StatefulWidget {
  const AnimatedCounter({
    super.key,
    required this.endValue,
    this.duration = const Duration(milliseconds: 1200),
    this.style,
  });

  final int endValue;
  final Duration duration;
  final TextStyle? style;

  @override
  State<AnimatedCounter> createState() => _AnimatedCounterState();
}

class _AnimatedCounterState extends State<AnimatedCounter>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);
    _animation = Tween<double>(begin: 0, end: widget.endValue.toDouble())
        .animate(CurvedAnimation(
      parent: _controller,
      curve: CinematicCurves.revealDecel,
    ));
    _controller.forward();
  }

  @override
  void didUpdateWidget(AnimatedCounter oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.endValue != widget.endValue) {
      _animation = Tween<double>(begin: 0, end: widget.endValue.toDouble())
          .animate(CurvedAnimation(
        parent: _controller,
        curve: CinematicCurves.revealDecel,
      ));
      _controller
        ..reset()
        ..forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: _animation,
        builder: (_, __) => Text(
          '${_animation.value.toInt()}',
          style: widget.style,
        ),
      );
}
