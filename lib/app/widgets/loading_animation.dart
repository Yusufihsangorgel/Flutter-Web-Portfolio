import 'package:flutter/material.dart';
import 'package:flutter_web_portfolio/app/controllers/language_controller.dart';
import 'package:flutter_web_portfolio/app/core/constants/app_colors.dart';
import 'package:flutter_web_portfolio/app/core/constants/durations.dart';
import 'package:get/get.dart';

/// Pulsing animation widget displayed while the app is loading.
class LoadingAnimation extends StatefulWidget {
  const LoadingAnimation({super.key});

  @override
  State<LoadingAnimation> createState() => _LoadingAnimationState();
}

class _LoadingAnimationState extends State<LoadingAnimation>
    with SingleTickerProviderStateMixin {
  final LanguageController _languageController = Get.find<LanguageController>();

  late AnimationController _animationController;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: AppDurations.loadingPulse,
    )..repeat(reverse: true);

    _opacityAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildLogoAnimation(),
            const SizedBox(height: 24),
            _LoadingText(
              text: _languageController.getText('portfolio_loading'),
              animationController: _animationController,
            ),
          ],
        ),
      ),
    );

  Widget _buildLogoAnimation() => FadeTransition(
      opacity: _opacityAnimation,
      child: Container(
        width: 120,
        height: 120,
        decoration: BoxDecoration(
          color: AppColors.accent.withAlpha(51),
          shape: BoxShape.circle,
        ),
        child: Center(
          child: Container(
            width: 80,
            height: 80,
            decoration: const BoxDecoration(
              color: AppColors.accent,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.person, color: Colors.white, size: 48),
          ),
        ),
      ),
    );
}

class _LoadingText extends StatelessWidget {

  const _LoadingText({
    required this.text,
    required this.animationController,
  });
  final String text;
  final AnimationController animationController;

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
      animation: animationController,
      builder: (context, child) => Opacity(
          opacity: animationController.value,
          child: Text(
            text,
            style: const TextStyle(
              color: AppColors.textBright,
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
    );
}
