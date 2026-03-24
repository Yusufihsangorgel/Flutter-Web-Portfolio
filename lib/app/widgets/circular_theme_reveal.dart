import 'dart:math';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:flutter_web_portfolio/app/controllers/theme_controller.dart';
import 'package:flutter_web_portfolio/app/core/constants/app_colors.dart';

/// A circular reveal transition effect for theme switching.
///
/// When toggled, a circle expands from the toggle button position, revealing
/// the new theme underneath. This creates a satisfying, cinematic transition
/// inspired by the View Transitions API.
///
/// Usage:
/// ```dart
/// CircularThemeReveal(
///   child: Scaffold(...),
/// )
/// ```
class CircularThemeReveal extends StatefulWidget {
  const CircularThemeReveal({
    super.key,
    required this.child,
  });

  final Widget child;

  /// Global key to trigger the reveal from a specific position.
  static Offset? _triggerOrigin;

  /// Call this from the theme toggle button to set the reveal origin,
  /// then toggle the theme.
  static void toggleWithReveal(BuildContext context) {
    final box = context.findRenderObject() as RenderBox?;
    if (box != null) {
      final position = box.localToGlobal(
        Offset(box.size.width / 2, box.size.height / 2),
      );
      _triggerOrigin = position;
    }
    Get.find<ThemeController>().toggleTheme();
  }

  @override
  State<CircularThemeReveal> createState() => _CircularThemeRevealState();
}

class _CircularThemeRevealState extends State<CircularThemeReveal>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  bool _isAnimating = false;
  bool? _previousIsDark;
  Widget? _oldChild;
  Offset _origin = Offset.zero;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() {
          _isAnimating = false;
          _oldChild = null;
        });
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final themeController = Get.find<ThemeController>();
      final isDark = themeController.isDarkMode.value;

      // Detect theme change
      if (_previousIsDark != null && _previousIsDark != isDark && !_isAnimating) {
        _oldChild = _buildContent(context, !isDark);
        _origin = CircularThemeReveal._triggerOrigin ??
            Offset(
              MediaQuery.sizeOf(context).width - 60,
              40,
            );
        CircularThemeReveal._triggerOrigin = null;
        _isAnimating = true;
        _controller.forward(from: 0.0);
      }
      _previousIsDark = isDark;

      if (!_isAnimating || _oldChild == null) {
        return widget.child;
      }

      return Stack(
        children: [
          // Old theme underneath
          _oldChild!,
          // New theme with circular clip expanding
          AnimatedBuilder(
            animation: _animation,
            builder: (context, child) {
              return ClipPath(
                clipper: _CircularRevealClipper(
                  fraction: _animation.value,
                  center: _origin,
                ),
                child: child,
              );
            },
            child: widget.child,
          ),
        ],
      );
    });
  }

  Widget _buildContent(BuildContext context, bool isDark) {
    return Container(
      color: isDark ? AppColors.background : AppColors.lightBackground,
      child: widget.child,
    );
  }
}

class _CircularRevealClipper extends CustomClipper<Path> {
  _CircularRevealClipper({
    required this.fraction,
    required this.center,
  });

  final double fraction;
  final Offset center;

  @override
  Path getClip(Size size) {
    final maxRadius = sqrt(
      pow(max(center.dx, size.width - center.dx), 2) +
          pow(max(center.dy, size.height - center.dy), 2),
    );

    return Path()
      ..addOval(
        Rect.fromCircle(
          center: center,
          radius: maxRadius * fraction,
        ),
      );
  }

  @override
  bool shouldReclip(_CircularRevealClipper oldClipper) =>
      fraction != oldClipper.fraction || center != oldClipper.center;
}
