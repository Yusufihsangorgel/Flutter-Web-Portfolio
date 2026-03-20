import 'package:flutter/material.dart';
import 'package:flutter_web_portfolio/app/core/constants/durations.dart';

/// Animates child widget when it first scrolls into the viewport.
class ScrollFadeIn extends StatefulWidget {
  const ScrollFadeIn({
    super.key,
    required this.child,
    this.offset = 30.0,
    this.duration = AppDurations.entrance,
    this.delay = Duration.zero,
    this.curve = Curves.easeOutCubic,
    this.enableScale = false,
  });

  final Widget child;
  final double offset;
  final Duration duration;
  final Duration delay;
  final Curve curve;

  /// When true, the widget also scales from 0.95 to 1.0 alongside
  /// the existing opacity + translate animations.
  final bool enableScale;

  @override
  State<ScrollFadeIn> createState() => _ScrollFadeInState();
}

class _ScrollFadeInState extends State<ScrollFadeIn>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacity;
  late Animation<Offset> _slide;
  late Animation<double> _scale;
  bool _triggered = false;
  ScrollPosition? _scrollPosition;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);

    _opacity = CurvedAnimation(parent: _controller, curve: widget.curve);
    _slide = Tween<Offset>(
      begin: Offset(0, widget.offset),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: widget.curve));
    _scale = widget.enableScale
        ? Tween<double>(begin: 0.95, end: 1.0)
            .animate(CurvedAnimation(parent: _controller, curve: widget.curve))
        : const AlwaysStoppedAnimation<double>(1.0);

    WidgetsBinding.instance.addPostFrameCallback((_) => _checkVisibility());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Listen to the nearest scroll controller
    _scrollPosition?.removeListener(_checkVisibility);
    _scrollPosition = Scrollable.maybeOf(context)?.position;
    _scrollPosition?.addListener(_checkVisibility);
  }

  @override
  void dispose() {
    _scrollPosition?.removeListener(_checkVisibility);
    _controller.dispose();
    super.dispose();
  }

  void _checkVisibility() {
    if (_triggered || !mounted) return;

    final renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null || !renderBox.hasSize) return;

    final position = renderBox.localToGlobal(Offset.zero);
    final screenHeight = MediaQuery.sizeOf(context).height;

    if (position.dy < screenHeight * 0.9 && position.dy > -renderBox.size.height) {
      _triggered = true;
      _scrollPosition?.removeListener(_checkVisibility);

      if (widget.delay == Duration.zero) {
        _controller.forward();
      } else {
        Future.delayed(widget.delay, () {
          if (mounted) _controller.forward();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _controller,
    builder: (_, child) {
      Widget result = Transform.translate(offset: _slide.value, child: child);
      if (widget.enableScale) {
        result = Transform.scale(scale: _scale.value, child: result);
      }
      return Opacity(opacity: _opacity.value, child: result);
    },
    child: widget.child,
  );
}
