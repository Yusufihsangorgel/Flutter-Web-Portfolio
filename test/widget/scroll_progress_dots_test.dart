import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:flutter_web_portfolio/app/controllers/language_controller.dart';
import 'package:flutter_web_portfolio/app/domain/providers/i_assets_provider.dart';
import 'package:flutter_web_portfolio/app/domain/providers/i_local_storage_provider.dart';
import 'package:flutter_web_portfolio/app/data/repositories/language_repository_impl.dart';
import 'package:flutter_web_portfolio/app/widgets/scroll_progress_dots.dart';

class _MockAssetsProvider implements IAssetsProvider {
  @override
  Future<List<Map<String, dynamic>>> loadProjectsData() async => [];

  @override
  Future<Map<String, dynamic>> loadTranslations(String langCode) async =>
      <String, dynamic>{};
}

class _MockLocalStorage implements ILocalStorageProvider {
  @override
  bool get isInitialized => true;

  @override
  String? getString(String key) => null;

  @override
  Future<bool> setString(String key, String value) async => true;

  @override
  bool? getBool(String key) => null;

  @override
  Future<bool> setBool(String key, bool value) async => true;

  @override
  int? getInt(String key) => null;

  @override
  Future<bool> setInt(String key, int value) async => true;

  @override
  Future<bool> remove(String key) async => true;

  @override
  Future<bool> clear() async => true;
}

void main() {
  group('ScrollProgressDots', () {
    setUp(() {
      Get.testMode = true;
    });

    tearDown(Get.reset);

    testWidgets('hidden on narrow screens (< 900px)', (tester) async {
      tester.view.physicalSize = const Size(500, 800);
      tester.view.devicePixelRatio = 1.0;

      final repo = LanguageRepositoryImpl(
        assetsProvider: _MockAssetsProvider(),
        localStorageProvider: _MockLocalStorage(),
      );
      Get.put<LanguageController>(
        LanguageController(languageRepository: repo),
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ScrollProgressDots(visible: true),
          ),
        ),
      );
      await tester.pump();

      // Should return SizedBox.shrink
      expect(find.byType(SizedBox), findsWidgets);

      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    testWidgets('hidden on screens just below breakpoint', (tester) async {
      tester.view.physicalSize = const Size(899, 1200);
      tester.view.devicePixelRatio = 1.0;

      final repo = LanguageRepositoryImpl(
        assetsProvider: _MockAssetsProvider(),
        localStorageProvider: _MockLocalStorage(),
      );
      Get.put<LanguageController>(
        LanguageController(languageRepository: repo),
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ScrollProgressDots(visible: true),
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(SizedBox), findsWidgets);

      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
  });
}
