import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_web_portfolio/app/controllers/scroll_controller.dart';
import 'package:flutter_web_portfolio/app/core/constants/app_colors.dart';
import 'package:flutter_web_portfolio/app/core/constants/breakpoints.dart';
import 'package:flutter_web_portfolio/app/core/constants/motion_curves.dart';
import 'package:flutter_web_portfolio/app/core/constants/durations.dart';
import 'package:flutter_web_portfolio/app/features/language/application/language_cubit.dart';
import 'package:flutter_web_portfolio/app/utils/motion_preference.dart';
import 'package:flutter_web_portfolio/app/widgets/accessible_action.dart';

/// Floating back-to-top control with a live document-scroll progress arc.
class BackToTopButton extends StatefulWidget {
  const BackToTopButton({super.key, this.focusNode});

  final FocusNode? focusNode;

  @override
  State<BackToTopButton> createState() => _BackToTopButtonState();
}

class _BackToTopButtonState extends State<BackToTopButton>
    with SingleTickerProviderStateMixin {
  bool _visible = false;
  bool _hovered = false;
  bool _reduceMotion = false;
  double _scrollProgress = 0;
  late final AppScrollController _scrollController;
  late final AnimationController _entranceController;
  late final Animation<double> _entranceAnimation;

  @override
  void initState() {
    super.initState();
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _entranceAnimation = CurvedAnimation(
      parent: _entranceController,
      curve: MotionCurves.emphasizedDecelerate,
    );
    _scrollController = context.read<AppScrollController>();
    _scrollController.scrollController.addListener(_onScroll);
    _scrollController.narrativePosition.addListener(_onNarrativePosition);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduceMotion = prefersReducedMotion(context);
    if (_reduceMotion == reduceMotion) return;
    _reduceMotion = reduceMotion;
    if (reduceMotion) {
      _entranceController.value = _visible ? 1 : 0;
    }
  }

  void _onScroll() {
    final controller = _scrollController.scrollController;
    if (!controller.hasClients) return;

    final shouldShow = controller.offset > 500;
    if (shouldShow != _visible) {
      setState(() => _visible = shouldShow);
      if (_reduceMotion) {
        _entranceController.value = shouldShow ? 1 : 0;
      } else if (shouldShow) {
        _entranceController.forward();
      } else {
        _entranceController.reverse();
      }
    }
  }

  void _onNarrativePosition() {
    final progress = _scrollController.narrativePosition.value.documentProgress;
    if ((progress - _scrollProgress).abs() > 0.005) {
      setState(() => _scrollProgress = progress);
    }
  }

  @override
  void dispose() {
    _scrollController.scrollController.removeListener(_onScroll);
    _scrollController.narrativePosition.removeListener(_onNarrativePosition);
    _entranceController.dispose();
    super.dispose();
  }

  void _scrollToTop() {
    _scrollController.scrollToSection('home');
  }

  @override
  Widget build(BuildContext context) {
    final useCompactControl =
        MediaQuery.sizeOf(context).width < Breakpoints.tablet;
    final buttonSize = useCompactControl ? 36.0 : 48.0;

    return Positioned(
      bottom: useCompactControl ? 14 : 32,
      right: useCompactControl ? 10 : 32,
      child: AnimatedBuilder(
        animation: _entranceAnimation,
        builder: (_, _) {
          final value = _entranceAnimation.value;
          return Opacity(
            opacity: value,
            child: Transform.translate(
              offset: Offset(0, 20 * (1 - value)),
              child: Transform.scale(
                scale: 0.6 + 0.4 * value,
                child: ExcludeFocus(
                  excluding: !_visible,
                  child: ExcludeSemantics(
                    excluding: !_visible,
                    child: IgnorePointer(
                      ignoring: !_visible,
                      child: AccessibleAction(
                        key: const ValueKey('back-to-top-action'),
                        onTap: _scrollToTop,
                        focusNode: widget.focusNode,
                        onHoverChanged: (hovered) {
                          if (_hovered != hovered) {
                            setState(() => _hovered = hovered);
                          }
                        },
                        semanticLabel: context.read<LanguageCubit>().getText(
                          'accessibility.back_to_top',
                          defaultValue: 'Back to top',
                        ),
                        borderRadius: BorderRadius.circular(buttonSize / 2),
                        focusColor: AppColors.accent,
                        child: SizedBox.square(
                          dimension: buttonSize,
                          child: CustomPaint(
                            painter: _ScrollProgressPainter(
                              progress: _scrollProgress,
                              hovered: _hovered,
                            ),
                            child: Center(
                              child: AnimatedScale(
                                scale: _hovered ? 1.15 : 1,
                                duration: _reduceMotion
                                    ? Duration.zero
                                    : AppDurations.fast,
                                child: Icon(
                                  Icons.arrow_upward_rounded,
                                  size: useCompactControl ? 18 : 22,
                                  color: _hovered
                                      ? AppColors.accent
                                      : AppColors.textPrimary,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ScrollProgressPainter extends CustomPainter {
  const _ScrollProgressPainter({required this.progress, required this.hovered});

  final double progress;
  final bool hovered;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 3;
    final strokeWidth = hovered ? 2.5 : 2.0;

    canvas
      ..drawCircle(
        center,
        radius + 1,
        Paint()
          ..color = AppColors.backgroundLight.withValues(
            alpha: hovered ? 0.8 : 0.6,
          )
          ..style = PaintingStyle.fill,
      )
      ..drawCircle(
        center,
        radius,
        Paint()
          ..color = Colors.white.withValues(alpha: hovered ? 0.15 : 0.08)
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth,
      );

    if (progress <= 0.01) return;
    final bounds = Rect.fromCircle(center: center, radius: radius);
    if (hovered) {
      canvas.drawArc(
        bounds,
        -math.pi / 2,
        2 * math.pi * progress,
        false,
        Paint()
          ..color = AppColors.accent.withValues(alpha: 0.3)
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth + 4
          ..strokeCap = StrokeCap.round
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
      );
    }
    canvas.drawArc(
      bounds,
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      Paint()
        ..color = AppColors.accent.withValues(alpha: hovered ? 1 : 0.7)
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_ScrollProgressPainter oldDelegate) =>
      progress != oldDelegate.progress || hovered != oldDelegate.hovered;
}
