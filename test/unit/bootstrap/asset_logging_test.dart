import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_web_portfolio/app/data/providers/bundle_asset_loader.dart';

import '../../support/fake_app_logger.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('narrative asset failure is logged and propagated', () async {
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          ..setMockMessageHandler('flutter/assets', (_) async => null);
    addTearDown(() => messenger.setMockMessageHandler('flutter/assets', null));
    final logger = FakeAppLogger();
    final loader = BundleAssetLoader(logger: logger);

    await expectLater(loader.loadNarrative(), throwsA(isA<FlutterError>()));
    expect(logger.message, contains('assets/presentation/narrative.json'));
    expect(logger.errorValue, isA<FlutterError>());
    expect(logger.stackTrace, isNotNull);
  });

  test(
    'missing locale asset logs its path and preserves empty fallback',
    () async {
      final logger = FakeAppLogger();
      final loader = BundleAssetLoader(logger: logger);

      expect(await loader.loadTranslations('missing_locale'), isEmpty);
      expect(logger.message, contains('assets/i18n/missing_locale.json'));
      expect(logger.errorValue, isNotNull);
      expect(logger.stackTrace, isNotNull);
    },
  );
}
