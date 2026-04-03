import 'package:flutter/material.dart';
import 'package:flutter_web_portfolio/app/core/constants/cinematic_curves.dart';
import 'package:flutter_web_portfolio/app/core/constants/durations.dart';

/// Scroll indicator — vertical line + floating dot
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

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
      vsync: this,
      duration: AppDurations.fadeIn,
    );
    _dotCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
    _dotY = Tween<double>(begin: 0, end: 40).animate(
      CurvedAnimation(parent: _dotCtrl, curve: CinematicCurves.easeInOutCinematic),
    );

    Future.delayed(widget.delay, () {
      if (mounted) _fadeCtrl.forward();
    });
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    _dotCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _fadeCtrl,
    builder: (_, __) => Opacity(
      opacity: _fadeCtrl.value,
      child: Center(
        child: SizedBox(
          height: 60,
          width: 2,
          child: Stack(
            alignment: Alignment.topCenter,
            children: [
              // Vertical line
              Container(
                width: 1,
                height: 60,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.white.withValues(alpha: 0.3),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
              // Floating dot
              AnimatedBuilder(
                animation: _dotY,
                builder: (_, __) => Positioned(
                  top: _dotY.value,
                  child: Container(
                    width: 3,
                    height: 3,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.8),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: (Theme.of(context).brightness == Brightness.dark
                              ? Colors.white : Colors.black).withValues(alpha: 0.4),
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
  );
}
