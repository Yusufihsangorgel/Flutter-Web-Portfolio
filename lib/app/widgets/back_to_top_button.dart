import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_web_portfolio/app/controllers/scroll_controller.dart';
import 'package:flutter_web_portfolio/app/core/constants/app_colors.dart';
import 'package:flutter_web_portfolio/app/core/constants/durations.dart';

/// Floating back-to-top button — appears when scroll offset > 500px.
///
/// Positioned at bottom-right corner with a subtle fade in/out animation.
class BackToTopButton extends StatefulWidget {
  const BackToTopButton({super.key});

  @override
  State<BackToTopButton> createState() => _BackToTopButtonState();
}

class _BackToTopButtonState extends State<BackToTopButton> {
  bool _visible = false;
  bool _hovered = false;

  @override
  void initState() {
    super.initState();
    Get.find<AppScrollController>().scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    final offset = Get.find<AppScrollController>().scrollController.offset;
    final shouldShow = offset > 500;
    if (shouldShow != _visible) {
      setState(() => _visible = shouldShow);
    }
  }

  @override
  void dispose() {
    if (Get.isRegistered<AppScrollController>()) {
      Get.find<AppScrollController>()
          .scrollController
          .removeListener(_onScroll);
    }
    super.dispose();
  }

  void _scrollToTop() {
    Get.find<AppScrollController>().scrollController.animateTo(
      0,
      duration: AppDurations.sectionScroll,
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) => Positioned(
    bottom: 32,
    right: 32,
    child: AnimatedOpacity(
      opacity: _visible ? 1.0 : 0.0,
      duration: AppDurations.medium,
      child: IgnorePointer(
        ignoring: !_visible,
        child: MouseRegion(
          onEnter: (_) => setState(() => _hovered = true),
          onExit: (_) => setState(() => _hovered = false),
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            onTap: _scrollToTop,
            child: Semantics(
              button: true,
              label: 'Back to top',
              child: AnimatedContainer(
                duration: AppDurations.buttonHover,
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _hovered
                      ? AppColors.accent.withValues(alpha: 0.2)
                      : AppColors.backgroundLight.withValues(alpha: 0.6),
                  border: Border.all(
                    color: _hovered
                        ? AppColors.accent.withValues(alpha: 0.6)
                        : (Theme.of(context).brightness == Brightness.dark
                            ? Colors.white : Colors.black).withValues(alpha: 0.12),
                    width: 1,
                  ),
                ),
                child: Icon(
                  Icons.arrow_upward_rounded,
                  size: 22,
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
  );
}
