import 'package:flutter/material.dart';
import 'package:flutter_web_portfolio/app/controllers/language_controller.dart';
import 'package:flutter_web_portfolio/app/controllers/theme_controller.dart';
import 'package:get/get.dart';

/// Animation widget displayed while the app is loading
class LoadingAnimation extends StatefulWidget {
  const LoadingAnimation({super.key});

  @override
  State<LoadingAnimation> createState() => _LoadingAnimationState();
}

class _LoadingAnimationState extends State<LoadingAnimation>
    with SingleTickerProviderStateMixin {
  final ThemeController _themeController = Get.find<ThemeController>();
  final LanguageController _languageController = Get.find<LanguageController>();

  late AnimationController _animationController;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
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
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _themeController.backgroundColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildLogoAnimation(),
            const SizedBox(height: 24),
            _LoadingText(
              text: _languageController.getText('portfolio_loading'),
              themeController: _themeController,
              animationController: _animationController,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogoAnimation() {
    return FadeTransition(
      opacity: _opacityAnimation,
      child: Container(
        width: 120,
        height: 120,
        decoration: BoxDecoration(
          color: _themeController.primaryColor.withAlpha(51),
          shape: BoxShape.circle,
        ),
        child: Center(
          child: Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: _themeController.primaryColor,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.person, color: Colors.white, size: 48),
          ),
        ),
      ),
    );
  }
}

/// Loading text widget
class _LoadingText extends StatelessWidget {
  final String text;
  final ThemeController themeController;
  final AnimationController animationController;

  const _LoadingText({
    super.key,
    required this.text,
    required this.themeController,
    required this.animationController,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animationController,
      builder: (context, child) {
        return Opacity(
          opacity: animationController.value,
          child: Text(
            text,
            style: TextStyle(
              color: themeController.primaryTextColor,
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
        );
      },
    );
  }
}
