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

    test('has no fabricated section geometry before layout', () {
      expect(controller.sectionGeometries, isEmpty);
    });

    test(
      'skips absent optional chapters when detecting the active section',
      () {
        final section = AppScrollController.sectionAtFocalPoint(
          sectionIds: const [
            'home',
            'about',
            'experience',
            'proof',
            'projects',
          ],
          offsets: const {'home': 0, 'about': 800, 'projects': 2200},
          focalPoint: 2400,
        );

        expect(section, 'projects');
      },
    );

    test('stops at the last mounted chapter before the focal point', () {
      final section = AppScrollController.sectionAtFocalPoint(
        sectionIds: const ['home', 'about', 'projects'],
        offsets: const {'home': 0, 'about': 800, 'projects': 2200},
        focalPoint: 1500,
      );

      expect(section, 'about');
    });
  });
}
