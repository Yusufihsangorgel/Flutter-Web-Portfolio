import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_web_portfolio/app/core/logging/app_logger.dart';
import 'package:flutter_web_portfolio/app/data/providers/bundle_asset_loader.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('narrative asset failure is logged and propagated', () async {
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          ..setMockMessageHandler('flutter/assets', (_) async => null);
    addTearDown(() => messenger.setMockMessageHandler('flutter/assets', null));
    final logger = _FakeLogger();
    final loader = BundleAssetLoader(logger: logger);

    await expectLater(loader.loadNarrative(), throwsA(isA<FlutterError>()));
    expect(logger.message, contains('assets/presentation/narrative.json'));
    expect(logger.errorValue, isA<FlutterError>());
    expect(logger.stackTrace, isNotNull);
  });

  test(
    'missing locale asset logs its path and preserves empty fallback',
    () async {
      final logger = _FakeLogger();
      final loader = BundleAssetLoader(logger: logger);

      expect(await loader.loadTranslations('missing_locale'), isEmpty);
      expect(logger.message, contains('assets/i18n/missing_locale.json'));
      expect(logger.errorValue, isNotNull);
      expect(logger.stackTrace, isNotNull);
    },
  );
}

final class _FakeLogger implements AppLogger {
  String? message;
  Object? errorValue;
  StackTrace? stackTrace;

  @override
  void info(String message, {Object? error, StackTrace? stackTrace}) {}

  @override
  void warning(String message, {Object? error, StackTrace? stackTrace}) {}

  @override
  void error(String message, {Object? error, StackTrace? stackTrace}) {
    this.message = message;
    errorValue = error;
    this.stackTrace = stackTrace;
  }
}
