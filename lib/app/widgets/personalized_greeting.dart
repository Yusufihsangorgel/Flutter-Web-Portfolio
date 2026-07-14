import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:flutter_web_portfolio/app/controllers/personalization_controller.dart';
import 'package:flutter_web_portfolio/app/core/constants/durations.dart';

/// Displays a local-only greeting adapted to visitor familiarity.
class PersonalizedGreeting extends StatefulWidget {
  const PersonalizedGreeting({
    super.key,
    this.showVisitCount = false,
    this.style,
    this.timeGreetingStyle,
    this.visitCountStyle,
  });

  final bool showVisitCount;
  final TextStyle? style;
  final TextStyle? timeGreetingStyle;
  final TextStyle? visitCountStyle;

  @override
  State<PersonalizedGreeting> createState() => _PersonalizedGreetingState();
}

class _PersonalizedGreetingState extends State<PersonalizedGreeting>
    with TickerProviderStateMixin {
  late final AnimationController _fadeController;
  late final AnimationController _slideController;
  late final AnimationController _scaleController;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    final controller = context.read<PersonalizationController>();
    final isFirst = controller.isFirstVisit;
    final isFrequent = controller.isFrequentVisitor;
    final fadeDuration = isFirst
        ? AppDurations.slow
        : isFrequent
        ? AppDurations.fast
        : AppDurations.entrance;
    final delay = isFirst
        ? const Duration(milliseconds: 300)
        : isFrequent
        ? Duration.zero
        : const Duration(milliseconds: 150);

    _fadeController = AnimationController(vsync: this, duration: fadeDuration);
    _slideController = AnimationController(vsync: this, duration: fadeDuration);
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );
    _slideAnimation =
        Tween<Offset>(
          begin: isFirst ? const Offset(0, 0.15) : Offset.zero,
          end: Offset.zero,
        ).animate(
          CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
        );
    _scaleAnimation = Tween<double>(begin: isFirst ? 1 : 0.92, end: 1).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.elasticOut),
    );

    Future<void>.delayed(delay, () {
      if (!mounted) return;
      _fadeController.forward();
      _slideController.forward();
      _scaleController.forward();
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FadeTransition(
    opacity: _fadeAnimation,
    child: SlideTransition(
      position: _slideAnimation,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: BlocBuilder<PersonalizationController, PersonalizationState>(
          builder: (context, state) => _GreetingContent(
            state: state,
            showVisitCount: widget.showVisitCount,
            style: widget.style,
            timeGreetingStyle: widget.timeGreetingStyle,
            visitCountStyle: widget.visitCountStyle,
          ),
        ),
      ),
    ),
  );
}

class _GreetingContent extends StatelessWidget {
  const _GreetingContent({
    required this.state,
    required this.showVisitCount,
    this.style,
    this.timeGreetingStyle,
    this.visitCountStyle,
  });

  final PersonalizationState state;
  final bool showVisitCount;
  final TextStyle? style;
  final TextStyle? timeGreetingStyle;
  final TextStyle? visitCountStyle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (state.timeGreeting.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(
              state.timeGreeting,
              style:
                  timeGreetingStyle ??
                  theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.primary.withValues(alpha: 0.8),
                    fontWeight: FontWeight.w500,
                  ),
            ),
          ),
        Text(
          state.greeting,
          style:
              style ??
              theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        if (state.introText.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              state.introText,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
          ),
        if (showVisitCount && state.visitCount > 1)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                'Visit #${state.visitCount}',
                style:
                    visitCountStyle ??
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
