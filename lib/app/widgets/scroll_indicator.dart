import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_web_portfolio/app/core/constants/app_colors.dart';
import 'package:flutter_web_portfolio/app/core/constants/durations.dart';
import 'package:flutter_web_portfolio/app/core/constants/motion_curves.dart';
import 'package:flutter_web_portfolio/app/utils/motion_preference.dart';

/// Decorative reading cue that fades in and moves along a vertical track.
class ScrollIndicator extends StatefulWidget {
  const ScrollIndicator({super.key, required this.delay});
  final Duration delay;

  @override
  State<ScrollIndicator> createState() => _ScrollIndicatorState();
}

class _ScrollIndicatorState extends State<ScrollIndicator>
    with TickerProviderStateMixin {
  late AnimationController _fadeCtrl;
  late AnimationController _dotCtrl;
  late Animation<double> _dotY;
  ScrollPosition? _scrollPosition;
  Timer? _entranceTimer;
  bool _reduceMotion = false;
  bool _isVisible = false;
  bool _delayElapsed = false;
  bool _visibilityCheckScheduled = false;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(vsync: this, duration: AppDurations.fadeIn);
    _dotCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    _dotY = Tween<double>(
      begin: 0,
      end: 40,
    ).animate(CurvedAnimation(parent: _dotCtrl, curve: MotionCurves.standard));

    _startEntranceTimer();
  }

  void _startEntranceTimer() {
    _entranceTimer?.cancel();
    _delayElapsed = false;
    _entranceTimer = Timer(widget.delay, () {
      _delayElapsed = true;
      _updateAnimations();
    });
  }

  @override
  void didUpdateWidget(ScrollIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.delay != widget.delay) _startEntranceTimer();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduceMotion = prefersReducedMotion(context);
    _reduceMotion = reduceMotion;
    final scrollPosition = Scrollable.maybeOf(context)?.position;
    if (!identical(scrollPosition, _scrollPosition)) {
      _scrollPosition?.removeListener(_scheduleVisibilityCheck);
      _scrollPosition = scrollPosition;
      _scrollPosition?.addListener(_scheduleVisibilityCheck);
    }
    _scheduleVisibilityCheck();
    _updateAnimations();
  }

  void _scheduleVisibilityCheck() {
    if (_visibilityCheckScheduled) return;
    _visibilityCheckScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _visibilityCheckScheduled = false;
      if (mounted) _updateVisibility();
    });
  }

  void _updateVisibility() {
    final renderObject = context.findRenderObject();
    if (renderObject is! RenderBox || !renderObject.hasSize) {
      _setVisible(false);
      return;
    }
    final bounds = renderObject.localToGlobal(Offset.zero) & renderObject.size;
    final screen = Offset.zero & MediaQuery.sizeOf(context);
    if (!bounds.overlaps(screen)) {
      _setVisible(false);
      return;
    }
    final viewport = RenderAbstractViewport.maybeOf(renderObject);
    final position = _scrollPosition;
    if (viewport != null && position != null) {
      final offset = viewport.getOffsetToReveal(renderObject, 0).offset;
      final bottom = offset + renderObject.size.height;
      _setVisible(
        offset < position.pixels + position.viewportDimension &&
            bottom > position.pixels,
      );
      return;
    }
    _setVisible(true);
  }

  void _setVisible(bool isVisible) {
    if (_isVisible == isVisible) return;
    _isVisible = isVisible;
    _updateAnimations();
  }

  void _updateAnimations() {
    if (_reduceMotion) {
      _dotCtrl
        ..stop()
        ..value = 0.5;
      if (_delayElapsed) _fadeCtrl.value = 1;
      return;
    }
    if (!_isVisible) {
      _dotCtrl.stop();
      if (_fadeCtrl.isAnimating) _fadeCtrl.stop();
      return;
    }
    if (!_dotCtrl.isAnimating) _dotCtrl.repeat();
    if (_delayElapsed && !_fadeCtrl.isCompleted) _fadeCtrl.forward();
  }

  @override
  void dispose() {
    _entranceTimer?.cancel();
    _scrollPosition?.removeListener(_scheduleVisibilityCheck);
    _fadeCtrl.dispose();
    _dotCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: AnimatedBuilder(
      animation: _fadeCtrl,
      builder: (_, _) => Opacity(
        opacity: _fadeCtrl.value,
        child: Center(
          child: RepaintBoundary(
            child: SizedBox(
              height: 60,
              width: 2,
              child: Stack(
                alignment: Alignment.topCenter,
                children: [
                  Container(
                    width: 1,
                    height: 60,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          AppColors.textBright.withValues(alpha: 0.3),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                  AnimatedBuilder(
                    animation: _dotY,
                    builder: (_, _) => Positioned(
                      top: _dotY.value,
                      child: Container(
                        width: 3,
                        height: 3,
                        decoration: BoxDecoration(
                          color: AppColors.textBright.withValues(alpha: 0.8),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.textBright.withValues(
                                alpha: 0.4,
                              ),
                              blurRadius: 6,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
