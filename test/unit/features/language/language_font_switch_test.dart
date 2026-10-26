import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_web_portfolio/app/core/theme/locale_font_loader.dart';
import 'package:flutter_web_portfolio/app/features/language/application/language_cubit.dart';

import '../../../support/fake_app_logger.dart';
import '../../../support/fake_language_browser.dart';
import '../../../support/fake_language_repository.dart';

final class _Fonts implements LocaleFontLoader {
  _Fonts({this.gate, this.error});

  final Completer<void>? gate;
  final Object? error;
  final List<String> requested = <String>[];
  final Completer<void> started = Completer<void>();

  @override
  Future<void> loadForLanguage(String languageCode) {
    requested.add(languageCode);
    if (!started.isCompleted) started.complete();
    if (error != null) return Future<void>.error(error!);
    return gate?.future ?? Future<void>.value();
  }
}

LanguageCubit _cubit(LocaleFontLoader fonts) => LanguageCubit(
  languageRepository: FakeLanguageRepository(
    supportedLanguages: const {'en', 'de', 'ar', 'hi'},
    documents: const {
      'en': {'language': 'en'},
      'de': {'language': 'de'},
      'ar': {'language': 'ar'},
      'hi': {'language': 'hi'},
    },
  ),
  browser: FakeLanguageBrowser(),
  fontLoader: fonts,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  _registerSuccessfulFontSwitch();
  _registerPendingFontSwitch();
  _registerFontDeadlines();
  _registerFailedFontSwitch();
  _registerRealFontCacheTests();
}

void _registerSuccessfulFontSwitch() {
  test('switching to Arabic and Hindi loads their fonts first', () async {
    final fonts = _Fonts();
    final cubit = _cubit(fonts);
    addTearDown(cubit.close);

    await cubit.changeLanguage('ar');
    expect(fonts.requested, ['ar']);
    expect(cubit.state.languageCode, 'ar');

    await cubit.changeLanguage('hi');
    expect(fonts.requested, ['ar', 'hi']);
    expect(cubit.state.languageCode, 'hi');
  });
}

void _registerPendingFontSwitch() {
  testWidgets('the new locale is not emitted until the font has loaded', (
    tester,
  ) async {
    final gate = Completer<void>();
    final fonts = _Fonts(gate: gate);
    final cubit = _cubit(fonts);
    final pending = <Future<void>>[];
    final errors = <(Object, StackTrace)>[];
    void record(Object error, StackTrace stack) => errors.add((error, stack));
    addTearDown(() async {
      if (!gate.isCompleted) gate.complete();
      await _closeAfterFonts(cubit, pending, errors);
    });
    pending.add(gate.future.then<void>((_) {}, onError: record));

    try {
      final switching = cubit
          .changeLanguage('ar')
          .then<void>((_) {}, onError: record);
      pending.add(switching);
      await tester.pump();
      expect(fonts.started.isCompleted, isTrue);
      await fonts.started.future;
      await tester.pump(const Duration(milliseconds: 2999));
      expect(cubit.state.languageCode, isNot('ar'));
      expect(cubit.state.status, LanguageStatus.loading);

      gate.complete();
      await tester.pump();
      await switching;
      expect(cubit.state.languageCode, 'ar');
      expect(cubit.state.status, LanguageStatus.ready);
    } finally {
      if (!gate.isCompleted) gate.complete();
      await tester.pump();
    }
  });
}

void _registerFontDeadlines() {
  testWidgets('a font that never arrives cannot block the switch', (tester) {
    return _expectFontDeadline(tester, 'ar');
  });
  testWidgets('Hindi uses the same bounded font wait', (tester) {
    return _expectFontDeadline(tester, 'hi');
  });
}

Future<void> _expectFontDeadline(WidgetTester tester, String languageCode) async {
  final gate = Completer<void>();
  final fonts = _Fonts(gate: gate);
  final cubit = _cubit(fonts);
  final pending = <Future<void>>[];
  final errors = <(Object, StackTrace)>[];
  void record(Object error, StackTrace stack) => errors.add((error, stack));
  addTearDown(() async {
    if (!gate.isCompleted) gate.complete();
    await _closeAfterFonts(cubit, pending, errors);
  });
  var fontCompleted = false;
  final fontCompletion = gate.future.then<void>((_) {
    fontCompleted = true;
  }, onError: record);
  pending.add(fontCompletion);
  try {
    final switching = cubit
        .changeLanguage(languageCode)
        .then<void>((_) {}, onError: record);
    pending.add(switching);
    await tester.pump();
    expect(fonts.started.isCompleted, isTrue);
    await fonts.started.future;

    await tester.pump(const Duration(milliseconds: 2999));
    expect(cubit.state.languageCode, isNot(languageCode));
    expect(fontCompleted, isFalse);
    await tester.pump(const Duration(milliseconds: 1));
    await switching;
    expect(cubit.state.languageCode, languageCode);
    expect(cubit.state.status, LanguageStatus.ready);
    expect(fontCompleted, isFalse);
    expect(gate.isCompleted, isFalse);
    final readyState = cubit.state;

    gate.complete();
    await tester.pump();
    await fontCompletion;
    expect(fontCompleted, isTrue);
    expect(cubit.state, same(readyState));
  } finally {
    if (!gate.isCompleted) gate.complete();
    await tester.pump();
  }
}

Future<void> _closeAfterFonts(
  LanguageCubit cubit,
  List<Future<void>> pending,
  List<(Object, StackTrace)> errors,
) async {
  try {
    await Future.wait(pending, eagerError: false);
  } finally {
    try {
      await cubit.close();
    } on Object catch (error, stack) {
      errors.add((error, stack));
    }
  }
  expect(errors, isEmpty);
}

void _registerFailedFontSwitch() {
  test('a font that throws does not crash the switch', () async {
    final cubit = _cubit(_Fonts(error: StateError('font fetch failed')));
    addTearDown(cubit.close);

    await cubit.changeLanguage('hi');

    expect(cubit.state.languageCode, 'hi');
    expect(cubit.state.status, LanguageStatus.ready);
  });
}

void _registerRealFontCacheTests() {
  for (final languageCode in ['ar', 'hi']) {
    test('pending $languageCode font cache waits for registration', () {
      return _expectPendingAssetFont(languageCode);
    });
    test('failed $languageCode asset load can retry and register', () {
      return _expectFailedAssetRetry(languageCode);
    });
  }
}

Future<void> _expectPendingAssetFont(String languageCode) async {
  final bundle = _GatedFontBundle(languageCode);
  final logger = FakeAppLogger();
  final loader = AssetLocaleFontLoader(logger: logger, bundle: bundle);
  final pending = <Future<void>>[];
  final errors = <(Object, StackTrace)>[];
  void record(Object error, StackTrace stack) => errors.add((error, stack));
  addTearDown(() async {
    bundle.release();
    await Future.wait(pending, eagerError: false);
    expect(errors, isEmpty);
  });
  var registered = false;
  final first = loader.loadForLanguage(languageCode);
  final firstCompletion = first.then<void>((_) {
    registered = true;
  }, onError: record);
  pending.add(firstCompletion);
  expect(bundle.started.isCompleted, isTrue);
  await bundle.started.future;
  final repeated = loader.loadForLanguage(languageCode);
  pending.add(repeated.then<void>((_) {}, onError: record));
  expect(repeated, same(first));
  expect(bundle.requests, hasLength(1));
  await Future<void>(() {});
  expect(registered, isFalse);

  bundle.release();
  await firstCompletion;
  expect(registered, isTrue);
  final cached = loader.loadForLanguage(languageCode);
  final cachedCompletion = cached.then<void>((_) {}, onError: record);
  pending.add(cachedCompletion);
  expect(cached, same(first));
  await cachedCompletion;
  expect(bundle.requests, hasLength(1));
  expect(logger.errors, isEmpty);
}

Future<void> _expectFailedAssetRetry(String languageCode) async {
  final bundle = _GatedFontBundle(languageCode);
  final logger = FakeAppLogger();
  final loader = AssetLocaleFontLoader(logger: logger, bundle: bundle);
  final pending = <Future<void>>[];
  final errors = <(Object, StackTrace)>[];
  void record(Object error, StackTrace stack) => errors.add((error, stack));
  addTearDown(() async {
    bundle.release();
    await Future.wait(pending, eagerError: false);
    expect(errors, isEmpty);
  });
  final first = loader.loadForLanguage(languageCode);
  final firstCompletion = first.then<void>((_) {}, onError: record);
  pending.add(firstCompletion);
  expect(bundle.started.isCompleted, isTrue);
  await bundle.started.future;
  bundle.requests.single.completeError(StateError('font fetch failed'));
  await firstCompletion;
  expect(logger.errors, hasLength(1));

  final retry = loader.loadForLanguage(languageCode);
  final retryCompletion = retry.then<void>((_) {}, onError: record);
  pending.add(retryCompletion);
  expect(retry, isNot(same(first)));
  expect(bundle.requests, hasLength(2));
  bundle.release();
  await retryCompletion;
  final cached = loader.loadForLanguage(languageCode);
  final cachedCompletion = cached.then<void>((_) {}, onError: record);
  pending.add(cachedCompletion);
  expect(cached, same(retry));
  await cachedCompletion;
  expect(bundle.requests, hasLength(2));
  expect(logger.errors, hasLength(1));
}

final class _GatedFontBundle extends CachingAssetBundle {
  _GatedFontBundle(String languageCode)
    : assetPath = switch (languageCode) {
        'ar' => 'assets/fonts/noto_sans_arabic/NotoSansArabic-Variable.ttf',
        'hi' => 'assets/fonts/noto_sans_devanagari/NotoSansDevanagari-Variable.ttf',
        _ => throw ArgumentError.value(languageCode),
      };

  final String assetPath;
  final Completer<void> started = Completer<void>();
  final List<Completer<ByteData>> requests = [];

  @override
  Future<ByteData> load(String key) {
    if (key != assetPath) {
      return Future<ByteData>.error(StateError('Unexpected font asset request'));
    }
    final request = Completer<ByteData>();
    requests.add(request);
    if (!started.isCompleted) started.complete();
    return request.future;
  }

  void release() {
    for (final request in requests) {
      if (request.isCompleted) continue;
      try {
        request.complete(ByteData.sublistView(File(assetPath).readAsBytesSync()));
      } on Object catch (error, stack) {
        request.completeError(error, stack);
      }
    }
  }
}
