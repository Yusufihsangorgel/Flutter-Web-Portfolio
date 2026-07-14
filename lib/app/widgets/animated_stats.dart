import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_web_portfolio/app/core/theme/app_fonts.dart';

import 'package:flutter_web_portfolio/app/core/constants/app_colors.dart';
import 'package:flutter_web_portfolio/app/core/constants/cinematic_curves.dart';
import 'package:flutter_web_portfolio/app/core/theme/app_typography.dart';

/// A single, evidence-backed portfolio stat that animates once when visible.
///
/// The caller owns the value and label. This widget deliberately has no
/// fallback metrics, so unverifiable social-proof numbers cannot appear by
/// accident.
class AnimatedStatCard extends StatefulWidget {
  const AnimatedStatCard({
    required this.value,
    this.suffix = '',
    this.label = '',
    this.duration = const Duration(milliseconds: 1200),
    this.curve = CinematicCurves.revealDecel,
    this.accentColor,
    this.delay = Duration.zero,
    super.key,
  });

  final int value;
  final String suffix;
  final String label;
  final Duration duration;
  final Curve curve;
  final Color? accentColor;
  final Duration delay;

  @override
  State<AnimatedStatCard> createState() => _AnimatedStatCardState();
}

class _AnimatedStatCardState extends State<AnimatedStatCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _countAnimation;
  late final Animation<double> _opacityAnimation;
  late final Animation<double> _scaleAnimation;
  ScrollPosition? _scrollPosition;
  Timer? _delayTimer;
  bool _triggered = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);
    _countAnimation = Tween<double>(
      begin: 0,
      end: widget.value.toDouble(),
    ).animate(CurvedAnimation(parent: _controller, curve: widget.curve));
    _opacityAnimation = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0, 0.3, curve: Curves.easeOut),
    );
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0, 0.5, curve: Curves.easeOutCubic),
      ),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkVisibility());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _scrollPosition?.removeListener(_checkVisibility);

    if (MediaQuery.disableAnimationsOf(context)) {
      _triggered = true;
      _delayTimer?.cancel();
      _controller.value = 1;
      _scrollPosition = null;
      return;
    }

    _scrollPosition = Scrollable.maybeOf(context)?.position;
    _scrollPosition?.addListener(_checkVisibility);
  }

  void _checkVisibility() {
    if (_triggered || !mounted) return;
    final renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null || !renderBox.hasSize) return;

    final position = renderBox.localToGlobal(Offset.zero);
    final viewportHeight = MediaQuery.sizeOf(context).height;
    final isVisible =
        position.dy < viewportHeight * 0.85 &&
        position.dy > -renderBox.size.height;
    if (!isVisible) return;

    _triggered = true;
    _scrollPosition?.removeListener(_checkVisibility);
    if (widget.delay == Duration.zero) {
      _controller.forward();
    } else {
      _delayTimer = Timer(widget.delay, () {
        if (mounted) _controller.forward();
      });
    }
  }

  @override
  void dispose() {
    _delayTimer?.cancel();
    _scrollPosition?.removeListener(_checkVisibility);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accent = widget.accentColor ?? AppColors.heroAccent;
    final semanticLabel = [
      '${widget.value}${widget.suffix}',
      if (widget.label.isNotEmpty) widget.label,
    ].join(' ');

    return Semantics(
      label: semanticLabel,
      excludeSemantics: true,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (_, _) => Opacity(
          opacity: _opacityAnimation.value,
          child: Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
              decoration: BoxDecoration(
                color: AppColors.backgroundLight.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: accent.withValues(alpha: 0.1)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: _formatNumber(_countAnimation.value.toInt()),
                          style: AppFonts.spaceGrotesk(
                            fontSize: 36,
                            fontWeight: FontWeight.w800,
                            color: accent,
                            shadows: [
                              Shadow(
                                color: accent.withValues(alpha: 0.5),
                                blurRadius: 12,
                              ),
                            ],
                          ),
                        ),
                        if (widget.suffix.isNotEmpty)
                          TextSpan(
                            text: widget.suffix,
                            style: AppFonts.spaceGrotesk(
                              fontSize: 24,
                              fontWeight: FontWeight.w600,
                              color: accent.withValues(alpha: 0.7),
                            ),
                          ),
                      ],
                    ),
                    textAlign: TextAlign.center,
                  ),
                  if (widget.label.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      widget.label,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: AppTypography.caption.copyWith(
                        color: AppColors.textPrimary,
                        fontSize: 12,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _formatNumber(int number) {
    if (number < 1000) return '$number';
    final digits = number.toString();
    final buffer = StringBuffer();
    for (var index = 0; index < digits.length; index++) {
      if (index > 0 && (digits.length - index) % 3 == 0) buffer.write(',');
      buffer.write(digits[index]);
    }
    return buffer.toString();
  }
}
