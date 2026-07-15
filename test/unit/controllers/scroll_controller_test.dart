import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_web_portfolio/app/controllers/scroll_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppScrollController controller;

  setUp(() {
    controller = AppScrollController();
    addTearDown(controller.close);
  });

  group('AppScrollController', () {
    test('starts at the home section', () {
      expect(controller.state, const AppScrollState());
      expect(controller.activeSection, 'home');
    });

    test('owns a Flutter scroll controller', () {
      expect(controller.scrollController, isA<ScrollController>());
      expect(controller.scrollController.hasClients, isFalse);
    });

    test('initializes a distinct key for every section', () {
      final keys = {
        controller.homeKey,
        controller.aboutKey,
        controller.experienceKey,
        controller.proofKey,
        controller.projectsKey,
      };

      expect(keys, hasLength(5));
    });

    test('ignores unknown or detached sections safely', () {
      expect(() => controller.scrollToSection('nonexistent'), returnsNormally);
      expect(() => controller.scrollToSection('about'), returnsNormally);
      expect(controller.activeSection, 'home');
    });

    test('exposes immutable state through a typed stream', () {
      expect(controller.stream, isA<Stream<AppScrollState>>());
      expect(controller.state.activeSection, 'home');
    });
  });
}
