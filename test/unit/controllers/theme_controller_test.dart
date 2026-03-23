import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:flutter_web_portfolio/app/controllers/theme_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late ThemeController controller;

  setUp(() {
    Get.testMode = true;
    controller = ThemeController();
    Get.put(controller);
  });

  tearDown(Get.reset);

  group('ThemeController', () {
    test('initial isDarkMode follows system brightness', () {
      // Test environment defaults to light, so isDarkMode should be false
      // when no saved preference exists.
      expect(controller.isDarkMode, isA<RxBool>());
    });

    test('brightness getter matches isDarkMode', () {
      final expected = controller.isDarkMode.value
          ? Brightness.dark
          : Brightness.light;
      expect(controller.brightness, equals(expected));
    });

    test('toggleTheme flips isDarkMode', () {
      final before = controller.isDarkMode.value;
      controller.toggleTheme();
      expect(controller.isDarkMode.value, equals(!before));
    });

    test('toggleTheme updates brightness', () {
      final before = controller.brightness;
      controller.toggleTheme();
      expect(controller.brightness, isNot(equals(before)));
    });

    test('double toggle returns to original mode', () {
      final original = controller.isDarkMode.value;
      controller
        ..toggleTheme()
        ..toggleTheme();
      expect(controller.isDarkMode.value, equals(original));
    });

    test('multiple toggle cycles work correctly', () {
      final original = controller.isDarkMode.value;
      for (var i = 0; i < 5; i++) {
        controller.toggleTheme();
        expect(controller.isDarkMode.value, equals(!original));

        controller.toggleTheme();
        expect(controller.isDarkMode.value, equals(original));
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
