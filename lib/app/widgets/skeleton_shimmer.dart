import 'package:flutter/material.dart';

import 'package:flutter_web_portfolio/app/core/constants/app_colors.dart';

/// A shimmer placeholder widget for loading states.
///
/// Renders a dark rectangle with a lighter diagonal sweep that
/// continuously animates from left to right, matching the cinematic
/// dark theme of the portfolio.
class SkeletonShimmer extends StatefulWidget {
  const SkeletonShimmer({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius = 8.0,
  });

  final double width;
  final double height;
  final double borderRadius;

  @override
  State<SkeletonShimmer> createState() => _SkeletonShimmerState();
}

class _SkeletonShimmerState extends State<SkeletonShimmer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _controller,
    builder: (_, __) => Container(
      width: widget.width,
      height: widget.height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(widget.borderRadius),
        gradient: LinearGradient(
          begin: Alignment(-1.0 + 2.0 * _controller.value, 0),
          end: Alignment(1.0 + 2.0 * _controller.value, 0),
          colors: const [
                  AppColors.backgroundLight,
                  Color(0xFF1A1145),
                  AppColors.backgroundLight,
                ],
          stops: const [0.0, 0.5, 1.0],
        ),
      ),
    ),
  );
}
