import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_web_portfolio/app/core/theme/locale_font_loader.dart';

const _arabicAsset =
    'assets/fonts/noto_sans_arabic/NotoSansArabic-Variable.ttf';
const _devanagariAsset =
    'assets/fonts/noto_sans_devanagari/NotoSansDevanagari-Variable.ttf';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late List<String> requestedAssets;
  late List<FlutterErrorDetails> reportedErrors;

  setUp(() {
    requestedAssets = <String>[];
    reportedErrors = <FlutterErrorDetails>[];
    final previousHandler = FlutterError.onError;
    FlutterError.onError = reportedErrors.add;
    addTearDown(() {
      FlutterError.onError = previousHandler;
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
        await LocaleFontLoader.loadForLanguage(languageCode);
      }

      expect(requestedAssets, isEmpty);
      expect(reportedErrors, isEmpty);
    });

    test('loads the Arabic font for ar only', () async {
      serveAssets(found: true);

      await LocaleFontLoader.loadForLanguage('ar');

      expect(requestedAssets, [_arabicAsset]);
      expect(reportedErrors, isEmpty);
    });

    test('loads the Devanagari font for hi only', () async {
      serveAssets(found: true);

      await LocaleFontLoader.loadForLanguage('hi');

      expect(requestedAssets, [_devanagariAsset]);
      expect(reportedErrors, isEmpty);
    });

    test('reports a failed load and still completes', () async {
      serveAssets(found: false);

      await LocaleFontLoader.loadForLanguage('ar');

      expect(requestedAssets, [_arabicAsset]);
      expect(reportedErrors, hasLength(1));
      expect(reportedErrors.single.library, 'locale font loader');
      expect(reportedErrors.single.exception, isA<FlutterError>());
      expect(
        reportedErrors.single.context.toString(),
        'while loading the Noto Sans Arabic font',
      );
    });
  });
}

TestDefaultBinaryMessenger get _messenger =>
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
