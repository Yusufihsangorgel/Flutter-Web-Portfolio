import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_web_portfolio/app/core/theme/locale_font_loader.dart';
import 'package:flutter_web_portfolio/app/features/language/application/language_cubit.dart';

import '../../../support/fake_language_browser.dart';
import '../../../support/fake_language_repository.dart';

final class _Fonts implements LocaleFontLoader {
  _Fonts({this.gate, this.error});

  final Completer<void>? gate;
  final Object? error;
  final List<String> requested = <String>[];

  @override
  Future<void> loadForLanguage(String languageCode) async {
    requested.add(languageCode);
    if (error != null) throw error!;
    await gate?.future;
  }
}

LanguageCubit _cubit(
  _Fonts fonts, {
  Duration timeout = const Duration(seconds: 3),
}) => LanguageCubit(
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
  fontLoadTimeout: timeout,
);

void main() {
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

  test('the new locale is not emitted until the font has loaded', () async {
    final gate = Completer<void>();
    final cubit = _cubit(_Fonts(gate: gate));
    addTearDown(cubit.close);

    final switching = cubit.changeLanguage('ar');
    await Future<void>.delayed(Duration.zero);
    expect(cubit.state.languageCode, isNot('ar'));

    gate.complete();
    await switching;
    expect(cubit.state.languageCode, 'ar');
    expect(cubit.state.status, LanguageStatus.ready);
  });

  test('a font that never arrives cannot block the switch', () async {
    final cubit = _cubit(
      _Fonts(gate: Completer<void>()),
      timeout: const Duration(milliseconds: 20),
    );
    addTearDown(cubit.close);

    await cubit.changeLanguage('ar');

    expect(cubit.state.languageCode, 'ar');
    expect(cubit.state.status, LanguageStatus.ready);
  });

  test('a font that throws does not crash the switch', () async {
    final cubit = _cubit(_Fonts(error: StateError('font fetch failed')));
    addTearDown(cubit.close);

    await cubit.changeLanguage('hi');

    expect(cubit.state.languageCode, 'hi');
    expect(cubit.state.status, LanguageStatus.ready);
  });
}
