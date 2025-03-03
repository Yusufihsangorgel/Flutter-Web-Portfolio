import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/theme_controller.dart';
import 'mouse_effects.dart';

/// Fare etkileşimlerini yöneten wrapper widget
class MouseInteractionWrapper extends StatelessWidget {
  final Widget child;

  const MouseInteractionWrapper({Key? key, required this.child})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Tema kontrolcüsü
    final ThemeController themeController = Get.find<ThemeController>();

    // Fare ışığı rengi
    final Color lightColor = themeController.primaryColor;

    // Fare takip eden ışık efekti
    return MouseLight(
      lightColor: lightColor,
      lightSize: 300, // Işık boyutu
      intensity: 0.15, // Işık yoğunluğu
      child: child,
    );
  }
}
