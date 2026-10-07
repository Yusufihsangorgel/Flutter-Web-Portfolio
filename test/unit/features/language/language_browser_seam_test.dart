import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_web_portfolio/app/features/language/application/language_cubit.dart';

import '../../../support/fake_language_browser.dart';
import '../../../support/fake_language_repository.dart';

FakeLanguageRepository _repository({Object? saveError}) =>
    FakeLanguageRepository(
      supportedLanguages: const {'en', 'tr'},
      documents: const {
        'en': {
          'nav': {'home': 'en'},
        },
        'tr': {
          'nav': {'home': 'tr'},
        },
      },
      behavior: FakeLanguageRepositoryBehavior(saveError: saveError),
    );

LanguageCubit _buildCubit(
  FakeLanguageRepository repository,
  FakeLanguageBrowser browser,
) {
  final cubit = LanguageCubit(languageRepository: repository, browser: browser);
  addTearDown(cubit.close);
  return cubit;
}

void main() {
  late FakeLanguageRepository repository;

  setUp(() => repository = _repository());

  test('a saved choice hands over to the browser reload', () async {
    final browser = FakeLanguageBrowser(reloads: true);
    final cubit = _buildCubit(repository, browser);
    await cubit.initialize();

    await cubit.selectLanguage('tr', preserveSection: 'about');

    expect(repository.savedLanguages, ['en', 'tr']);
    expect(browser.reloadedSections, ['about']);
    expect(cubit.state.languageCode, 'en');
    expect(browser.documentLanguages, ['en']);
  });

  test(
    'the language applies in place when the browser does not reload',
    () async {
      final browser = FakeLanguageBrowser();
      final cubit = _buildCubit(repository, browser);
      await cubit.initialize();

      await cubit.selectLanguage('tr');

      expect(browser.reloadedSections, [null]);
      expect(cubit.state.languageCode, 'tr');
      expect(cubit.strings.navHome, 'tr');
      expect(browser.documentLanguages, ['en', 'tr']);
    },
  );

  test(
    'a failed save skips the reload and keeps the language for the visit',
    () async {
      final browser = FakeLanguageBrowser(reloads: true);
      repository = _repository(saveError: StateError('storage blocked'));
      final cubit = _buildCubit(repository, browser);

      await cubit.selectLanguage('tr', preserveSection: 'about');

      expect(browser.reloadedSections, isEmpty);
      expect(cubit.state.languageCode, 'tr');
      expect(cubit.state.errorMessage, isNotNull);
      expect(browser.documentLanguages, ['tr']);
    },
  );

  test('the initial load never reloads the document', () async {
    final browser = FakeLanguageBrowser(reloads: true);
    final cubit = _buildCubit(repository, browser);

    await cubit.initialize();

    expect(browser.reloadedSections, isEmpty);
    expect(browser.documentLanguages, ['en']);
  });
}
