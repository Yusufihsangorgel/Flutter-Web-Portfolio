import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:flutter_web_portfolio/app/controllers/scroll_controller.dart';

void main() {
  late AppScrollController controller;

  setUp(() {
    Get.testMode = true;
    controller = AppScrollController();
    Get.put(controller);
  });

  tearDown(Get.reset);

  group('AppScrollController', () {
    test('initial activeSection is home', () {
      expect(controller.activeSection.value, 'home');
    });

    test('scrollController is not null after creation', () {
      expect(controller.scrollController, isNotNull);
      expect(controller.scrollController, isA<ScrollController>());
    });

    test('all 5 global keys are initialized', () {
      expect(controller.homeKey, isA<GlobalKey>());
      expect(controller.aboutKey, isA<GlobalKey>());
      expect(controller.experienceKey, isA<GlobalKey>());
      expect(controller.projectsKey, isA<GlobalKey>());
      expect(controller.contactKey, isA<GlobalKey>());
    });

    test('all global keys are distinct', () {
      final keys = {
        controller.homeKey,
        controller.aboutKey,
        controller.experienceKey,
        controller.projectsKey,
        controller.contactKey,
      };
      expect(keys.length, 5);
    });

    test('scrollToSection with unknown section returns early', () {
      // Calling with an invalid section name should not throw
      expect(() => controller.scrollToSection('nonexistent'), returnsNormally);
      // activeSection should remain unchanged
      expect(controller.activeSection.value, 'home');
    });

    test('scrollToSection with valid name but no attached context returns early', () {
      // Keys exist but have no currentContext (no widget tree)
      expect(() => controller.scrollToSection('about'), returnsNormally);
      // activeSection stays 'home' because scrollController has no clients
      expect(controller.activeSection.value, 'home');
    });

    test('activeSection is a reactive RxString', () {
      expect(controller.activeSection, isA<RxString>());
      controller.activeSection.value = 'projects';
      expect(controller.activeSection.value, 'projects');
    });
  });
}
