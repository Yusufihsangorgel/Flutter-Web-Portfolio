import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:flutter_web_portfolio/app/controllers/loading_controller.dart';

void main() {
  late LoadingController controller;

  setUp(() {
    Get.testMode = true;
    controller = LoadingController();
    Get.put(controller);
  });

  tearDown(Get.reset);

  group('LoadingController', () {
    test('initial loading state is true', () {
      expect(controller.isLoading, isTrue);
    });

    test('setLoading(false) sets loading to false', () {
      controller.setLoading(false);
      expect(controller.isLoading, isFalse);
    });

    test('setLoading(true) sets loading back to true', () {
      controller.setLoading(false);
      expect(controller.isLoading, isFalse);

      controller.setLoading(true);
      expect(controller.isLoading, isTrue);
    });

    test('multiple toggle cycles work correctly', () {
      for (var i = 0; i < 5; i++) {
        controller.setLoading(false);
        expect(controller.isLoading, isFalse);
        controller.setLoading(true);
        expect(controller.isLoading, isTrue);
      }
    });

    test('controller is accessible via Get.find', () {
      final found = Get.find<LoadingController>();
      expect(found, same(controller));
    });
  });
}
