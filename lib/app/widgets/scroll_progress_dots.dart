import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:flutter_web_portfolio/app/controllers/scene_director.dart';
import 'package:flutter_web_portfolio/app/controllers/scroll_controller.dart';
import 'package:flutter_web_portfolio/app/core/constants/app_colors.dart';
import 'package:flutter_web_portfolio/app/core/constants/durations.dart';
import 'package:flutter_web_portfolio/app/features/language/application/language_cubit.dart';
import 'package:flutter_web_portfolio/app/widgets/cinematic_focusable.dart';

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

    return BlocBuilder<LanguageCubit, LanguageState>(
      buildWhen: (previous, current) =>
          previous.languageCode != current.languageCode ||
          !identical(previous.translations, current.translations),
      builder: (context, state) {
        final sections = context.read<LanguageCubit>().activeSections;
        return AnimatedOpacity(
          opacity: visible ? 1.0 : 0.0,
          duration: AppDurations.entrance,
          child: IgnorePointer(
            ignoring: !visible,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final section in sections) _Dot(sectionId: section),
              ],
            ),
          ),
        );
      },
    );
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
    final scrollController = context.read<AppScrollController>();

    return BlocBuilder<AppScrollController, AppScrollState>(
      buildWhen: (previous, current) =>
          previous.activeSection != current.activeSection,
      builder: (context, scrollState) {
        final isActive = scrollState.activeSection == widget.sectionId;
        final dotSize = isActive ? 8.0 : 4.0;
        final color = isActive ? AppColors.accent : AppColors.textSecondary;
        final languageController = context.read<LanguageCubit>();
        final sectionLabel = languageController.getText(
          'nav.${widget.sectionId}',
          defaultValue: widget.sectionId,
        );
        final semanticLabel = languageController
            .getText('command_palette.go_to', defaultValue: 'Go to {section}')
            .replaceAll('{section}', sectionLabel);

        return BlocSelector<SceneDirector, SceneState, double>(
          selector: (state) => state.sceneProgress,
          builder: (context, sceneProgress) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: CinematicFocusable(
              onTap: () => scrollController.scrollToSection(widget.sectionId),
              onHoverChanged: (hovered) => setState(() => _hovered = hovered),
              semanticLabel: semanticLabel,
              selected: isActive,
              borderRadius: BorderRadius.circular(10),
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
                      duration: _hovered
                          ? AppDurations.microFast
                          : AppDurations.medium,
                      curve: Curves.easeOutCubic,
                      width: _hovered && !isActive ? 6.0 : dotSize,
                      height: _hovered && !isActive ? 6.0 : dotSize,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: color,
                        boxShadow: isActive
                            ? [
                                BoxShadow(
                                  color: AppColors.accent.withValues(
                                    alpha: 0.5,
                                  ),
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
      },
    );
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
