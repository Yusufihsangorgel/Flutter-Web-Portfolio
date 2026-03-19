import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_web_portfolio/app/controllers/theme_controller.dart';
import 'package:flutter_web_portfolio/app/widgets/animated_entrance.dart';

/// Consistent section title widget used across all sections
class SectionTitle extends StatelessWidget {

  const SectionTitle({
    super.key,
    required this.title,
    this.subtitle,
    this.titleStyle,
    this.subtitleStyle,
    this.padding = const EdgeInsets.only(bottom: 20),
    this.alignment = CrossAxisAlignment.start,
    this.useGlow = true,
  });
  final String title;
  final String? subtitle;
  final TextStyle? titleStyle;
  final TextStyle? subtitleStyle;
  final EdgeInsetsGeometry padding;
  final CrossAxisAlignment alignment;
  final bool useGlow;

  @override
  Widget build(BuildContext context) {
    final themeController = Get.find<ThemeController>();

    return Padding(
      padding: padding,
      child: Column(
        crossAxisAlignment: alignment,
        children: [
          AnimatedEntrance.fadeInDown(
            duration: const Duration(milliseconds: 600),
            child: Text(
              title,
              style:
                  titleStyle ??
                  TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    color: themeController.primaryColor,
                    shadows:
                        useGlow
                            ? [
                              Shadow(
                                color: themeController.primaryColor.withValues(alpha:
                                  0.5,
                                ),
                                blurRadius: 10,
                              ),
                            ]
                            : null,
                  ),
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 16),
            AnimatedEntrance.fadeInDown(
              duration: const Duration(milliseconds: 700),
              child: Text(
                subtitle!,
                style:
                    subtitleStyle ??
                    TextStyle(
                      fontSize: 18,
                      color:
                          themeController.isDarkMode
                              ? Colors.white70
                              : Colors.black87,
                    ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
