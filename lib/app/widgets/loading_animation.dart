import 'package:flutter/material.dart';
import 'package:flutter_web_portfolio/app/controllers/language_controller.dart';
import 'package:flutter_web_portfolio/app/core/constants/app_colors.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:get/get.dart';

/// Stepped counter loading animation: counts 0% to 100% with a progress bar.
class LoadingAnimation extends StatefulWidget {
  const LoadingAnimation({super.key});

  @override
  State<LoadingAnimation> createState() => _LoadingAnimationState();
}

class _LoadingAnimationState extends State<LoadingAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  int _counter = 0;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    // Update counter in discrete steps (~every 50ms => 30 steps over 1500ms)
    _controller
      ..addListener(() {
        final newValue = (_controller.value * 100).round();
        if (newValue != _counter) {
          setState(() => _counter = newValue);
        }
      })
      ..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Large monospace counter
              Text(
                '$_counter%',
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 56,
                  fontWeight: FontWeight.w700,
                  color: AppColors.accent,
                  letterSpacing: -2,
                ),
              ),
              const SizedBox(height: 24),
              // Thin progress bar
              SizedBox(
                width: 200,
                height: 2,
                child: AnimatedBuilder(
                  animation: _controller,
                  builder: (_, __) => CustomPaint(
                    painter: _ProgressBarPainter(
                      progress: _controller.value,
                      color: AppColors.accent,
                      trackColor: AppColors.accent.withValues(alpha: 0.15),
                    ),
                    size: const Size(200, 2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // "Loading..." text with fade pulse
              AnimatedBuilder(
                animation: _controller,
                builder: (_, __) {
                  // Pulse opacity between 0.4 and 1.0 while loading
                  final pulse = _controller.value < 1.0
                      ? 0.4 + 0.6 * (((_controller.value * 6) % 1.0) < 0.5
                          ? (_controller.value * 6) % 1.0 * 2
                          : 2.0 - (_controller.value * 6) % 1.0 * 2)
                      : 1.0;
                  return Opacity(
                    opacity: pulse,
                    child: Text(
                      Get.find<LanguageController>().getText('portfolio_loading'),
                      style: GoogleFonts.spaceGrotesk(
                        color: AppColors.textBright,
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        letterSpacing: 2,
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      );
}

/// Paints a thin horizontal progress bar.
class _ProgressBarPainter extends CustomPainter {
  const _ProgressBarPainter({
    required this.progress,
    required this.color,
    required this.trackColor,
  });

  final double progress;
  final Color color;
  final Color trackColor;

  @override
  void paint(Canvas canvas, Size size) {
    final trackPaint = Paint()..color = trackColor;
    final fillPaint = Paint()..color = color;

    // Track
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.width, size.height),
        const Radius.circular(1),
      ),
      trackPaint,
    );

    // Fill
    if (progress > 0) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(0, 0, size.width * progress, size.height),
          const Radius.circular(1),
        ),
        fillPaint,
      );
    }
  }

  @override
  bool shouldRepaint(_ProgressBarPainter oldDelegate) =>
      progress != oldDelegate.progress || color != oldDelegate.color;
}
