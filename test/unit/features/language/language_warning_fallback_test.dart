import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_web_portfolio/app/core/l10n/app_strings.g.dart';
import 'package:flutter_web_portfolio/app/features/language/application/language_cubit.dart';

import '../../../support/fake_language_repository.dart';

const _invalidWarnings = <Object>[
  42,
  <String, Object>{'message': 'invalid'},
  <String>['invalid'],
  '   ',
];
const _english = AppStrings({});

void main() {
  test('invalid persistence warning uses the English fallback', () async {
    for (final warning in _invalidWarnings) {
      final cubit = _cubit(warning, failPersistence: true);
      addTearDown(cubit.close);

      await cubit.initialize();

      expect(cubit.state.status, LanguageStatus.ready);
      expect(cubit.state.errorMessage, _english.accessibilityLanguageNotSaved);
    }
  });

  test('invalid load warning uses the English fallback', () async {
    for (final warning in _invalidWarnings) {
      final cubit = _cubit(warning);
      addTearDown(cubit.close);
      await cubit.initialize();

      await cubit.changeLanguage('tr');

      expect(cubit.state.languageCode, 'en');
      expect(
        cubit.state.errorMessage,
        _english.accessibilityLanguageChangeFailed,
      );
    }
  });
}

LanguageCubit _cubit(Object warning, {bool failPersistence = false}) =>
    LanguageCubit(
      languageRepository: FakeLanguageRepository(
        supportedLanguages: const {'en', 'tr'},
        documents: {
          'en': {
            'nav': {'home': 'Home'},
            'accessibility': {
              'language_not_saved': warning,
              'language_change_failed': warning,
            },
          },
          'tr': {},
        },
        behavior: FakeLanguageRepositoryBehavior(
          saveError: failPersistence ? StateError('storage blocked') : null,
        ),
      ),
    );
