import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:flutter_web_portfolio/app/controllers/language_controller.dart';
import 'package:flutter_web_portfolio/app/data/providers/assets_provider.dart';
import 'package:flutter_web_portfolio/app/data/providers/local_storage_provider.dart';
import 'package:flutter_web_portfolio/app/data/repositories/language_repository_impl.dart';
import 'package:flutter_web_portfolio/app/widgets/footer.dart';

void main() {
  group('PortfolioFooter', () {
    setUp(() {
      Get.testMode = true;
    });

    tearDown(Get.reset);

    testWidgets('renders copyright text with current year', (tester) async {
      final repo = LanguageRepositoryImpl(
        assetsProvider: AssetsProvider(),
        localStorageProvider: LocalStorageProvider(),
      );
      Get.put<LanguageController>(
        LanguageController(languageRepository: repo),
      );

      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: PortfolioFooter())),
      );
      await tester.pumpAndSettle();

      final year = DateTime.now().year.toString();
      expect(find.textContaining(year), findsOneWidget);
    });

    testWidgets('renders footer widget', (tester) async {
      final repo = LanguageRepositoryImpl(
        assetsProvider: AssetsProvider(),
        localStorageProvider: LocalStorageProvider(),
      );
      Get.put<LanguageController>(
        LanguageController(languageRepository: repo),
      );

      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: PortfolioFooter())),
      );
      await tester.pumpAndSettle();

      expect(find.byType(PortfolioFooter), findsOneWidget);
    });
  });
}
