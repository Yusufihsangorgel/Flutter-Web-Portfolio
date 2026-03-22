import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:flutter_web_portfolio/app/controllers/language_controller.dart';
import 'package:flutter_web_portfolio/app/controllers/scroll_controller.dart';
import 'package:flutter_web_portfolio/app/data/providers/assets_provider.dart';
import 'package:flutter_web_portfolio/app/data/providers/local_storage_provider.dart';
import 'package:flutter_web_portfolio/app/data/repositories/language_repository_impl.dart';
import 'package:flutter_web_portfolio/app/widgets/command_palette.dart';

void main() {
  group('CommandPalette', () {
    setUp(() {
      Get.testMode = true;
    });

    tearDown(Get.reset);

    testWidgets('CommandPalette renders and shows search field',
        (tester) async {
      // Build the widget tree first, so WidgetsBinding is in idle phase.
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: SizedBox()),
        ),
      );

      // Now register controllers — AppScrollController.onInit uses
      // WidgetsBinding.addPostFrameCallback which requires idle scheduler.
      final repo = LanguageRepositoryImpl(
        assetsProvider: AssetsProvider(),
        localStorageProvider: LocalStorageProvider(),
      );
      Get
        ..put<LanguageController>(
          LanguageController(languageRepository: repo),
        )
        ..put<AppScrollController>(AppScrollController());

      // Flush post-frame callbacks from AppScrollController.onInit
      await tester.pump();

      // Now render the CommandPalette
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CommandPalette(),
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(CommandPalette), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('Go to Home'), findsOneWidget);
    });

    testWidgets('search filtering shows matching commands', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: SizedBox()),
        ),
      );

      final repo = LanguageRepositoryImpl(
        assetsProvider: AssetsProvider(),
        localStorageProvider: LocalStorageProvider(),
      );
      Get
        ..put<LanguageController>(
          LanguageController(languageRepository: repo),
        )
        ..put<AppScrollController>(AppScrollController());

      await tester.pump();

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CommandPalette(),
          ),
        ),
      );
      await tester.pump();

      // Type "contact" into the search field
      await tester.enterText(find.byType(TextField), 'contact');
      await tester.pump();

      // Should show the "Go to Contact" navigation command
      expect(find.text('Go to Contact'), findsOneWidget);

      // Non-matching commands should be filtered out
      expect(find.text('Go to Home'), findsNothing);
    });
  });
}
