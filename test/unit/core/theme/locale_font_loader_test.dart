import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_web_portfolio/app/core/theme/locale_font_loader.dart';

import '../../../support/fake_app_logger.dart';

const _arabicAsset =
    'assets/fonts/noto_sans_arabic/NotoSansArabic-Variable.ttf';
const _devanagariAsset =
    'assets/fonts/noto_sans_devanagari/NotoSansDevanagari-Variable.ttf';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late List<String> requestedAssets;
  late FakeAppLogger logger;
  late AssetLocaleFontLoader loader;

  setUp(() {
    requestedAssets = <String>[];
    logger = FakeAppLogger();
    loader = AssetLocaleFontLoader(logger: logger);
    addTearDown(() {
      _messenger.setMockMessageHandler('flutter/assets', null);
    });
  });

  void serveAssets({required bool found}) {
    _messenger.setMockMessageHandler('flutter/assets', (message) async {
      final key = utf8.decode(
        message!.buffer.asUint8List(
          message.offsetInBytes,
          message.lengthInBytes,
        ),
      );
      requestedAssets.add(key);
      return found ? ByteData.sublistView(File(key).readAsBytesSync()) : null;
    });
  }

  group('LocaleFontLoader', () {
    test('requests no font asset for languages on the eager fonts', () async {
      serveAssets(found: true);

      for (final languageCode in ['en', 'tr', 'de', 'fr', 'es', '']) {
        await loader.loadForLanguage(languageCode);
      }

      expect(requestedAssets, isEmpty);
      expect(logger.errors, isEmpty);
    });

    test('loads the Arabic font for ar only', () async {
      serveAssets(found: true);

      await loader.loadForLanguage('ar');

      expect(requestedAssets, [_arabicAsset]);
      expect(logger.errors, isEmpty);
    });

    test('loads the Devanagari font for hi only', () async {
      serveAssets(found: true);

      await loader.loadForLanguage('hi');

      expect(requestedAssets, [_devanagariAsset]);
      expect(logger.errors, isEmpty);
    });

    test('loads each family once', () async {
      serveAssets(found: true);

      await loader.loadForLanguage('ar');
      await loader.loadForLanguage('ar');
      await Future.wait([
        loader.loadForLanguage('hi'),
        loader.loadForLanguage('hi'),
      ]);

      expect(requestedAssets, [_arabicAsset, _devanagariAsset]);
    });

    test('logs a failed load, completes and retries next time', () async {
      serveAssets(found: false);

      await loader.loadForLanguage('ar');
      await loader.loadForLanguage('ar');

      expect(requestedAssets, [_arabicAsset, _arabicAsset]);
      expect(logger.errors, [
        'Failed to load the Noto Sans Arabic font',
        'Failed to load the Noto Sans Arabic font',
      ]);
    });
  });
}

TestDefaultBinaryMessenger get _messenger =>
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
