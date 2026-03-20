import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:flutter_web_portfolio/app/controllers/cursor_controller.dart';

void main() {
  late CursorController controller;

  setUp(() {
    Get.testMode = true;
    controller = CursorController();
    Get.put(controller);
  });

  tearDown(Get.reset);

  group('CursorController', () {
    test('initial isHovering is false', () {
      expect(controller.isHovering.value, isFalse);
    });

    test('initial hoverAccent is null', () {
      expect(controller.hoverAccent.value, isNull);
    });

    test('isHovering toggles to true and back', () {
      controller.isHovering.value = true;
      expect(controller.isHovering.value, isTrue);

      controller.isHovering.value = false;
      expect(controller.isHovering.value, isFalse);
    });

    test('hoverAccent accepts a color and clears to null', () {
      controller.hoverAccent.value = Colors.cyan;
      expect(controller.hoverAccent.value, equals(Colors.cyan));

      controller.hoverAccent.value = null;
      expect(controller.hoverAccent.value, isNull);
    });

    test('hoverAccent can be changed to different colors', () {
      controller.hoverAccent.value = Colors.red;
      expect(controller.hoverAccent.value, equals(Colors.red));

      controller.hoverAccent.value = Colors.blue;
      expect(controller.hoverAccent.value, equals(Colors.blue));
    });

    test('isHovering is a reactive RxBool', () {
      expect(controller.isHovering, isA<RxBool>());
    });

    test('hoverAccent is a reactive Rxn<Color>', () {
      expect(controller.hoverAccent, isA<Rxn<Color>>());
    });

    test('controller is accessible via Get.find', () {
      final found = Get.find<CursorController>();
      expect(found, same(controller));
    });
  });
}
