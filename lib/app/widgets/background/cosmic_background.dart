import 'package:flutter/material.dart';
import 'package:flutter_web_portfolio/app/controllers/shared_background_controller.dart';

import 'painters/star_field_painter.dart';
import 'painters/deep_space_painter.dart';
import 'painters/moon_surface_painter.dart';

class CosmicBackground extends StatefulWidget {
  const CosmicBackground({
    super.key,
    this.scrollController,
    this.pageHeight = 0,
    this.animationController,
  });

  final ScrollController? scrollController;
  final double pageHeight;
  final AnimationController? animationController;

  @override
  State<CosmicBackground> createState() => _CosmicBackgroundState();
}

class _CosmicBackgroundState extends State<CosmicBackground> {
  @override
  Widget build(BuildContext context) {
    final animController =
        widget.animationController ?? SharedBackgroundController.animationController;

    if (animController == null) {
      return const DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF000510), Color(0xFF00101F)],
          ),
        ),
      );
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        // Static gradient — no rebuilds
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF000510), Color(0xFF000D1A), Color(0xFF001429)],
            ),
          ),
        ),

        // Deep space nebulae — slow animation, wrapped in RepaintBoundary
        RepaintBoundary(
          child: AnimatedBuilder(
            animation: animController,
            builder: (_, __) => CustomPaint(
              painter: DeepSpacePainter(time: animController.value),
              size: Size.infinite,
            ),
          ),
        ),

        // Star field — slow twinkling
        RepaintBoundary(
          child: AnimatedBuilder(
            animation: animController,
            builder: (_, __) => CustomPaint(
              size: Size.infinite,
              painter: StarFieldPainter(
                animController: animController,
                scrollOffset: widget.scrollController?.offset ?? 0,
              ),
            ),
          ),
        ),

        // Moon — static position, subtle glow
        Positioned(
          top: 80,
          right: 100,
          child: _Moon(),
        ),
      ],
    );
  }
}

class _Moon extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
    width: 60,
    height: 60,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      gradient: const RadialGradient(
        center: Alignment(-0.2, -0.2),
        radius: 0.9,
        colors: [Color(0xFFF5F5F5), Color(0xFFE0E0E0), Color(0xFFBDBDBD), Color(0xFFAAAAAA)],
        stops: [0.0, 0.3, 0.7, 1.0],
      ),
      boxShadow: [
        BoxShadow(color: Colors.white.withValues(alpha: 0.08), blurRadius: 30, spreadRadius: 5),
      ],
    ),
    child: ClipOval(
      child: CustomPaint(painter: MoonSurfacePainter(), size: const Size(60, 60)),
    ),
  );
}
