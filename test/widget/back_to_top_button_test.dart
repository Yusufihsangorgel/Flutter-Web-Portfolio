import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:flutter_web_portfolio/app/controllers/scroll_controller.dart';
import 'package:flutter_web_portfolio/app/widgets/back_to_top_button.dart';

void main() {
  group('BackToTopButton', () {
    setUp(() {
      Get.testMode = true;
    });

    tearDown(Get.reset);

    testWidgets('renders widget', (tester) async {
      Get.put(AppScrollController());

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Stack(children: [BackToTopButton()]),
          ),
        ),
      );

      expect(find.byType(BackToTopButton), findsOneWidget);

      // Dispose widget tree and flush pending timers
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 1));
    });

    testWidgets('is initially hidden with opacity 0', (tester) async {
      Get.put(AppScrollController());

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Stack(children: [BackToTopButton()]),
          ),
        ),
      );

      // At scroll offset 0 the button should be invisible (opacity 0)
      final opacity = tester.widget<AnimatedOpacity>(
        find.byType(AnimatedOpacity),
      );
      expect(opacity.opacity, 0.0);

      // Dispose widget tree and flush pending timers
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 1));
    });
  });
}
