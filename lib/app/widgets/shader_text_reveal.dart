import 'package:flutter/material.dart';
import 'package:flutter_web_portfolio/app/core/constants/cinematic_curves.dart';
import 'package:flutter_web_portfolio/app/core/constants/durations.dart';

/// ShaderMask-based text reveal — light sweeps left-to-right.
class ShaderTextReveal extends StatefulWidget {
  const ShaderTextReveal({
    super.key,
    required this.text,
    required this.style,
    this.delay = Duration.zero,
    this.duration = AppDurations.fadeIn,
    this.textAlign,
  });

  final String text;
  final TextStyle style;
  final Duration delay;
  final Duration duration;
  final TextAlign? textAlign;

  @override
  State<ShaderTextReveal> createState() => _ShaderTextRevealState();
}

class _ShaderTextRevealState extends State<ShaderTextReveal>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _reveal;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );
    _reveal = CurvedAnimation(
      parent: _controller,
      curve: CinematicCurves.textReveal,
    );

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
    animation: _reveal,
    builder: (_, __) => ShaderMask(
      blendMode: BlendMode.dstIn,
      shaderCallback: (bounds) => LinearGradient(
        colors: const [Colors.white, Colors.white, Colors.transparent],
        stops: [0.0, _reveal.value, (_reveal.value + 0.1).clamp(0.0, 1.0)],
      ).createShader(bounds),
      child: Text(
        widget.text,
        style: widget.style,
        textAlign: widget.textAlign,
      ),
    ),
  );
}
