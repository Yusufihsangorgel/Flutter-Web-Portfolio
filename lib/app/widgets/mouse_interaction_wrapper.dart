import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/theme_controller.dart';
import 'mouse_effects.dart';

/// Wrapper widget that manages mouse interactions
class MouseInteractionWrapper extends StatelessWidget {
  final Widget child;

  const MouseInteractionWrapper({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final ThemeController themeController = Get.find<ThemeController>();
    final Color lightColor = themeController.primaryColor;

    return MouseLight(
      lightColor: lightColor,
      lightSize: 300,
      intensity: 0.15,
      child: child,
    );
  }
}
