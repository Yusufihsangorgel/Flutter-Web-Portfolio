import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:flutter_web_portfolio/app/controllers/theme_controller.dart';

void main() {
  late ThemeController controller;

  setUp(() {
    Get.testMode = true;
    controller = ThemeController();
    Get.put(controller);
  });

  tearDown(Get.reset);

  group('ThemeController', () {
    test('initial isDarkMode is true', () {
      expect(controller.isDarkMode.value, isTrue);
    });

    test('initial brightness is dark', () {
      expect(controller.brightness, equals(Brightness.dark));
    });

    test('toggleTheme flips isDarkMode to false', () {
      controller.toggleTheme();
      expect(controller.isDarkMode.value, isFalse);
    });

    test('toggleTheme updates brightness to light', () {
      controller.toggleTheme();
      expect(controller.brightness, equals(Brightness.light));
    });

    test('double toggle returns to dark mode', () {
      controller
        ..toggleTheme()
        ..toggleTheme();
      expect(controller.isDarkMode.value, isTrue);
      expect(controller.brightness, equals(Brightness.dark));
    });

    test('multiple toggle cycles work correctly', () {
      for (var i = 0; i < 5; i++) {
        controller.toggleTheme();
        expect(controller.isDarkMode.value, isFalse);
        expect(controller.brightness, equals(Brightness.light));

        controller.toggleTheme();
        expect(controller.isDarkMode.value, isTrue);
        expect(controller.brightness, equals(Brightness.dark));
      }
    });

    test('isDarkMode is a reactive RxBool', () {
      expect(controller.isDarkMode, isA<RxBool>());
    });

    test('controller is accessible via Get.find', () {
      final found = Get.find<ThemeController>();
      expect(found, same(controller));
    });

    test('toggleTheme without storage provider does not throw', () {
      expect(() => controller.toggleTheme(), returnsNormally);
    });
  });
}
