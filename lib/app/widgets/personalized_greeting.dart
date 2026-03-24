import 'dart:developer' as dev;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_web_portfolio/app/controllers/personalization_controller.dart';
import 'package:flutter_web_portfolio/app/core/constants/durations.dart';

/// Displays a personalised welcome message in the hero section.
///
/// The animation style adapts to visitor familiarity:
/// - First visit: slow, dramatic fade-in with upward slide.
/// - Return visit: quicker entrance with a subtle scale pop.
/// - Frequent visitor: snappy entrance, minimal fanfare.
///
/// Optionally shows the visit count badge and a time-appropriate greeting.
class PersonalizedGreeting extends StatefulWidget {
  const PersonalizedGreeting({
    super.key,
    this.showVisitCount = false,
    this.style,
    this.timeGreetingStyle,
    this.visitCountStyle,
  });

  /// Whether to show a small visit-count indicator.
  final bool showVisitCount;

  /// Override style for the main greeting text.
  final TextStyle? style;

  /// Override style for the time greeting (Good morning / afternoon / evening).
  final TextStyle? timeGreetingStyle;

  /// Override style for the visit count badge.
  final TextStyle? visitCountStyle;

  @override
  State<PersonalizedGreeting> createState() => _PersonalizedGreetingState();
}

class _PersonalizedGreetingState extends State<PersonalizedGreeting>
    with TickerProviderStateMixin {
  late final AnimationController _fadeController;
  late final AnimationController _slideController;
  late final AnimationController _scaleController;

  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;
  late Animation<double> _scaleAnim;

  PersonalizationController? _pc;

  // Animation parameters vary by visitor type.
  late final Duration _fadeDuration;
  late final Duration _slideDuration;
  late final Duration _delay;

  @override
  void initState() {
    super.initState();

    _pc = _findController();
    final isFirst = _pc?.isFirstVisit ?? true;
    final isFrequent = _pc?.isFrequentVisitor ?? false;

    // Tune durations to visitor familiarity.
    if (isFirst) {
      _fadeDuration = AppDurations.slow;
      _slideDuration = AppDurations.slow;
      _delay = const Duration(milliseconds: 300);
    } else if (isFrequent) {
      _fadeDuration = AppDurations.fast;
      _slideDuration = AppDurations.fast;
      _delay = Duration.zero;
    } else {
      _fadeDuration = AppDurations.entrance;
      _slideDuration = AppDurations.entrance;
      _delay = const Duration(milliseconds: 150);
    }

    // Fade.
    _fadeController = AnimationController(vsync: this, duration: _fadeDuration);
    _fadeAnim = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );

    // Slide (first visit: slide up; return: no slide).
    _slideController =
        AnimationController(vsync: this, duration: _slideDuration);
    _slideAnim = Tween<Offset>(
      begin: isFirst ? const Offset(0, 0.15) : Offset.zero,
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
    );

    // Subtle scale pop for returning visitors.
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _scaleAnim = Tween<double>(
      begin: isFirst ? 1.0 : 0.92,
      end: 1.0,
    ).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.elasticOut),
    );

    _startAnimation();
  }

  PersonalizationController? _findController() {
    try {
      if (Get.isRegistered<PersonalizationController>()) {
        return Get.find<PersonalizationController>();
      }
    } catch (e) {
      dev.log('Failed to find PersonalizationController', name: 'PersonalizedGreeting', error: e);
    }
    return null;
  }

  void _startAnimation() {
    if (_delay == Duration.zero) {
      _fadeController.forward();
      _slideController.forward();
      _scaleController.forward();
    } else {
      Future.delayed(_delay, () {
        if (!mounted) return;
        _fadeController.forward();
        _slideController.forward();
        _scaleController.forward();
      });
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // If the controller is not registered, show a sensible default.
    if (_pc == null) {
      return _buildStatic(theme);
    }

    return FadeTransition(
      opacity: _fadeAnim,
      child: SlideTransition(
        position: _slideAnim,
        child: ScaleTransition(
          scale: _scaleAnim,
          child: Obx(() => _buildContent(theme)),
        ),
      ),
    );
  }

  Widget _buildStatic(ThemeData theme) => Text(
    'Welcome',
    style: widget.style ??
        theme.textTheme.headlineMedium?.copyWith(
          fontWeight: FontWeight.w600,
        ),
  );

  Widget _buildContent(ThemeData theme) {
    final pc = _pc!;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Time-appropriate greeting.
        if (pc.timeGreeting.value.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(
              pc.timeGreeting.value,
              style: widget.timeGreetingStyle ??
                  theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.primary.withValues(alpha: 0.8),
                    fontWeight: FontWeight.w500,
                  ),
            ),
          ),

        // Main greeting.
        Text(
          pc.greeting.value,
          style: widget.style ??
              theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),

        // Intro text.
        if (pc.introText.value.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              pc.introText.value,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
          ),

        // Optional visit count badge.
        if (widget.showVisitCount && pc.visitCount.value > 1)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                'Visit #${pc.visitCount.value}',
                style: widget.visitCountStyle ??
                    theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ),
          ),
      ],
    );
  }
}
