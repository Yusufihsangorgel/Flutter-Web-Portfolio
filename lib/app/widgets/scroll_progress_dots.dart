import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:flutter_web_portfolio/app/controllers/language_controller.dart';
import 'package:flutter_web_portfolio/app/controllers/scene_director.dart';
import 'package:flutter_web_portfolio/app/controllers/scroll_controller.dart';
import 'package:flutter_web_portfolio/app/core/constants/app_colors.dart';
import 'package:flutter_web_portfolio/app/core/constants/durations.dart';

/// Vertical column of dots fixed on the right side of the viewport.
///
/// Each dot represents a portfolio section. The active section's dot is larger,
/// accent-colored, and has a subtle glow. Clicking a dot smooth-scrolls to that
/// section. Hidden on viewports narrower than 900 px.
class ScrollProgressDots extends StatelessWidget {
  const ScrollProgressDots({super.key, required this.visible});

  /// Whether the dots should be visible (tied to entrance animation).
  final bool visible;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    if (screenWidth < 900) return const SizedBox.shrink();

    return Obx(() {
      final sections = Get.find<LanguageController>().activeSections;
      return AnimatedOpacity(
        opacity: visible ? 1.0 : 0.0,
        duration: AppDurations.entrance,
        child: IgnorePointer(
          ignoring: !visible,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final section in sections)
                _Dot(sectionId: section),
            ],
          ),
        ),
      );
    });
  }
}

// ---------------------------------------------------------------------------
// Individual dot — animates size, color, and glow based on active state.
// ---------------------------------------------------------------------------
class _Dot extends StatefulWidget {
  const _Dot({required this.sectionId});
  final String sectionId;

  @override
  State<_Dot> createState() => _DotState();
}

class _DotState extends State<_Dot> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final scrollController = Get.find<AppScrollController>();

    return Obx(() {
      final isActive = scrollController.activeSection.value == widget.sectionId;
      final dotSize = isActive ? 8.0 : 4.0;
      final color = isActive ? AppColors.accent : AppColors.textSecondary;
      final sceneProgress = Get.find<SceneDirector>().sceneProgress.value;

      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: MouseRegion(
          onEnter: (_) => setState(() => _hovered = true),
          onExit: (_) => setState(() => _hovered = false),
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            onTap: () => scrollController.scrollToSection(widget.sectionId),
            behavior: HitTestBehavior.opaque,
            child: SizedBox(
              width: 20,
              height: 20,
              child: CustomPaint(
                painter: isActive
                    ? _ProgressArcPainter(
                        progress: sceneProgress,
                        color: AppColors.accent.withValues(alpha: 0.6),
                      )
                    : null,
                child: Center(
                  child: AnimatedContainer(
                    duration: _hovered ? AppDurations.microFast : AppDurations.medium,
                    curve: Curves.easeOutCubic,
                    width: _hovered && !isActive ? 6.0 : dotSize,
                    height: _hovered && !isActive ? 6.0 : dotSize,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: color,
                      boxShadow: isActive
                          ? [
                              BoxShadow(
                                color: AppColors.accent.withValues(alpha: 0.5),
                                blurRadius: 8,
                                spreadRadius: 1,
                              ),
                            ]
                          : null,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    });
  }
}

// ---------------------------------------------------------------------------
// Arc painter — draws a progress arc around the active dot.
// ---------------------------------------------------------------------------
class _ProgressArcPainter extends CustomPainter {
  _ProgressArcPainter({required this.progress, required this.color});

  final double progress;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;

    final center = size.center(Offset.zero);
    final radius = size.width / 2;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2, // Start from top
      progress * 2 * math.pi, // Sweep angle
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(_ProgressArcPainter old) =>
      progress != old.progress || color != old.color;
}
