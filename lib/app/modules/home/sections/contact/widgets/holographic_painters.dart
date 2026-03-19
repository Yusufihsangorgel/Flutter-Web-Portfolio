import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:get/get.dart';
import 'package:flutter_web_portfolio/app/controllers/theme_controller.dart';

/// Holographic Background
///
/// A background composed of a gradient, a holographic grid,
/// and holographic particles.
class HolographicBackground extends StatelessWidget {
  final Color baseColor;

  const HolographicBackground({super.key, required this.baseColor});

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Gradient background
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [const Color(0xFF0A0A1E), const Color(0xFF070720)],
            ),
          ),
        ),

        // Holographic grid
        CustomPaint(painter: HolographicGridPainter(baseColor: baseColor)),

        // Holographic particles
        CustomPaint(painter: HolographicParticlesPainter(baseColor: baseColor)),
      ],
    );
  }
}

/// Holographic Grid Painter
///
/// Draws a grid of lines that glow brighter near the center of the canvas,
/// creating a holographic effect.
class HolographicGridPainter extends CustomPainter {
  final Color baseColor;

  HolographicGridPainter({required this.baseColor});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    // Grid line spacing
    final gridSize = 40.0;

    final paint =
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.5;

    // Horizontal lines
    for (double y = 0; y < size.height; y += gridSize) {
      final distanceRatio = 1 - ((y - center.dy).abs() / (size.height / 2));

      paint.color = baseColor.withOpacity(
        0.1 + (distanceRatio * 0.2) + (math.sin(math.pi + y * 0.01) * 0.05),
      );

      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }

    // Vertical lines
    for (double x = 0; x < size.width; x += gridSize) {
      final distanceRatio = 1 - ((x - center.dx).abs() / (size.width / 2));

      paint.color = baseColor.withOpacity(
        0.1 + (distanceRatio * 0.2) + (math.sin(math.pi + x * 0.01) * 0.05),
      );

      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
  }

  @override
  bool shouldRepaint(covariant HolographicGridPainter oldDelegate) {
    return oldDelegate.baseColor != baseColor;
  }
}

/// Holographic Particles Painter
///
/// Draws randomly positioned particles with a subtle shimmer effect.
class HolographicParticlesPainter extends CustomPainter {
  final Color baseColor;

  HolographicParticlesPainter({required this.baseColor});

  @override
  void paint(Canvas canvas, Size size) {
    final random = math.Random(42); // Fixed seed for deterministic output
    final particleCount = 100;

    for (int i = 0; i < particleCount; i++) {
      // Random position and size for each particle
      final x = random.nextDouble() * size.width;
      final y = random.nextDouble() * size.height;
      final particleSize = 1.0 + (random.nextDouble() * 3.0);

      // Offset for animation
      final xOffset = math.sin(math.pi + i * 0.1) * 5.0;
      final yOffset = math.cos(math.pi + i * 0.1) * 5.0;

      // Particle opacity (blinking effect)
      final opacity = 0.3 + (math.sin(math.pi + i * 0.2) * 0.2);

      final paint =
          Paint()
            ..color = baseColor.withOpacity(opacity)
            ..style = PaintingStyle.fill;

      canvas.drawCircle(Offset(x + xOffset, y + yOffset), particleSize, paint);
    }
  }

  @override
  bool shouldRepaint(covariant HolographicParticlesPainter oldDelegate) {
    return oldDelegate.baseColor != baseColor;
  }
}

/// Holographic Container
///
/// A styled container with a dark semi-transparent background,
/// rounded corners, a subtle border, and a blue glow shadow.
class HolographicContainer extends StatelessWidget {
  final Widget child;

  const HolographicContainer({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.2), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.1),
            blurRadius: 20,
            spreadRadius: 5,
          ),
        ],
      ),
      child: child,
    );
  }
}

/// Holographic Button
///
/// A button that glows and changes color on hover, styled with the
/// current theme's primary color.
class HolographicButton extends StatefulWidget {
  final VoidCallback? onPressed;
  final Widget child;

  const HolographicButton({
    super.key,
    required this.onPressed,
    required this.child,
  });

  @override
  State<HolographicButton> createState() => _HolographicButtonState();
}

class _HolographicButtonState extends State<HolographicButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final themeController = Get.find<ThemeController>();

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onPressed,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color:
                _isHovered
                    ? themeController.primaryColor
                    : themeController.primaryColor.withOpacity(0.7),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withOpacity(0.3), width: 1),
            boxShadow:
                _isHovered
                    ? [
                      BoxShadow(
                        color: themeController.primaryColor.withOpacity(0.5),
                        blurRadius: 10,
                        spreadRadius: 2,
                      ),
                    ]
                    : [],
          ),
          child: widget.child,
        ),
      ),
    );
  }
}

/// Shimmering Text
///
/// Text that displays a sliding gradient shimmer animation.
class ShimmeringText extends StatefulWidget {
  final String text;
  final Color baseColor;
  final Color highlightColor;
  final TextStyle style;

  const ShimmeringText({
    super.key,
    required this.text,
    required this.baseColor,
    required this.highlightColor,
    required this.style,
  });

  @override
  State<ShimmeringText> createState() => _ShimmeringTextState();
}

class _ShimmeringTextState extends State<ShimmeringText>
    with SingleTickerProviderStateMixin {
  late AnimationController _shimmerController;

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _shimmerController,
      builder: (context, child) {
        return ShaderMask(
          blendMode: BlendMode.srcIn,
          shaderCallback: (bounds) {
            return LinearGradient(
              colors: [
                widget.baseColor,
                widget.highlightColor,
                widget.baseColor,
              ],
              stops: const [0.0, 0.5, 1.0],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              transform: _SlidingGradientTransform(
                slidePercent: _shimmerController.value,
              ),
            ).createShader(bounds);
          },
          child: Text(widget.text, style: widget.style),
        );
      },
    );
  }
}

/// Sliding Gradient Transform
///
/// A [GradientTransform] that slides the gradient horizontally
/// based on a percentage value, used by [ShimmeringText].
class _SlidingGradientTransform extends GradientTransform {
  final double slidePercent;

  const _SlidingGradientTransform({required this.slidePercent});

  @override
  Matrix4? transform(Rect bounds, {TextDirection? textDirection}) {
    return Matrix4.translationValues(
      bounds.width * (slidePercent * 3 - 1.0),
      0.0,
      0.0,
    );
  }
}
