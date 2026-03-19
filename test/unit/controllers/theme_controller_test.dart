import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:flutter_web_portfolio/app/controllers/theme_controller.dart';
import 'package:flutter_web_portfolio/app/core/constants/app_colors.dart';

void main() {
  late ThemeController controller;

  setUp(() {
    Get.testMode = true;
    controller = ThemeController();
    Get.put(controller);
    controller.onInit();
  });

  tearDown(Get.reset);

  group('ThemeController', () {
    test('isDarkMode always returns true', () {
      expect(controller.isDarkMode, isTrue);
    });

    test('provides consistent color palette', () {
      expect(controller.backgroundColor, equals(AppColors.background));
      expect(controller.primaryColor, equals(AppColors.primary));
      expect(controller.cardColor, equals(AppColors.surface));
    });

    test('darkTheme is a valid ThemeData', () {
      final theme = controller.darkTheme;
      expect(theme, isA<ThemeData>());
      expect(theme.brightness, equals(Brightness.dark));
      expect(theme.useMaterial3, isTrue);
    });

    test('darkTheme uses Poppins font family', () {
      final theme = controller.darkTheme;
      expect(theme.textTheme.bodyLarge?.fontFamily, contains('Poppins'));
    });

    test('singleton accessor works via Get.find', () {
      final found = ThemeController.to;
      expect(found, same(controller));
    });
  });
}
