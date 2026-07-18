import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_web_portfolio/app/domain/repositories/language_repository.dart';
import 'package:flutter_web_portfolio/app/features/language/application/language_cubit.dart';

final class _LanguageRepository implements LanguageRepository {
  _LanguageRepository({
    this.selectedLanguage = 'en',
    Map<String, Map<String, dynamic>>? documents,
    Map<String, Duration>? delays,
    Map<String, Duration>? saveDelays,
    this.saveError,
  }) : documents = documents ?? <String, Map<String, dynamic>>{},
       delays = delays ?? <String, Duration>{},
       saveDelays = saveDelays ?? <String, Duration>{};

  String selectedLanguage;
  final Map<String, Map<String, dynamic>> documents;
  final Map<String, Duration> delays;
  final Map<String, Duration> saveDelays;
  final Object? saveError;
  final List<String> savedLanguages = [];

  @override
  Set<String> get supportedLanguages => const {'en', 'tr', 'de'};

  @override
  Future<String> getSelectedLanguage() async => selectedLanguage;

  @override
  Future<Map<String, dynamic>> getTranslations(String languageCode) async {
    final delay = delays[languageCode];
    if (delay != null) await Future<void>.delayed(delay);
    return documents[languageCode] ?? const <String, dynamic>{};
  }

  @override
  Future<void> saveSelectedLanguage(String languageCode) async {
    final delay = saveDelays[languageCode];
    if (delay != null) await Future<void>.delayed(delay);
    final error = saveError;
    if (error != null) throw error;
    selectedLanguage = languageCode;
    savedLanguages.add(languageCode);
  }
}

void main() {
  group('LanguageCubit', () {
    test('starts with a deterministic English initial state', () async {
      final cubit = LanguageCubit(languageRepository: _LanguageRepository());
      addTearDown(cubit.close);

      expect(cubit.state.status, LanguageStatus.initial);
      expect(cubit.state.languageCode, 'en');
      expect(cubit.state.translations, isEmpty);
    });

    test('initialize loads and persists the selected language', () async {
      final repository = _LanguageRepository(
        selectedLanguage: 'tr',
        documents: {
          'tr': {
            'screen': {'label': 'Portföy'},
            'cv_data': {
              'personal_info': {'name': 'Test'},
            },
          },
        },
      );
      final cubit = LanguageCubit(languageRepository: repository);
      addTearDown(cubit.close);
      final stateExpectation = expectLater(
        cubit.stream.map((state) => state.status),
        emitsInOrder([LanguageStatus.loading, LanguageStatus.ready]),
      );

      await cubit.initialize();
      await stateExpectation;

      expect(cubit.currentLanguage, 'tr');
      expect(cubit.getText('screen.label'), 'Portföy');
      expect(repository.savedLanguages, ['tr']);
    });

    test('unsupported language is ignored without emitting state', () async {
      final cubit = LanguageCubit(languageRepository: _LanguageRepository());
      addTearDown(cubit.close);
      final states = <LanguageState>[];
      final subscription = cubit.stream.listen(states.add);
      addTearDown(subscription.cancel);

      await cubit.changeLanguage('ja');

      expect(states, isEmpty);
      expect(cubit.state, const LanguageState.initial());
    });

    test('an explicit language selection updates native targets', () async {
      final repository = _LanguageRepository(
        documents: {
          'en': {
            'screen': {'label': 'Portfolio'},
          },
          'de': {
            'screen': {'label': 'Portfolio auf Deutsch'},
          },
        },
      );
      final cubit = LanguageCubit(languageRepository: repository);
      addTearDown(cubit.close);
      await cubit.initialize();

      await cubit.selectLanguage('de');

      expect(cubit.state.status, LanguageStatus.ready);
      expect(cubit.currentLanguage, 'de');
      expect(cubit.getText('screen.label'), 'Portfolio auf Deutsch');
      expect(repository.savedLanguages, ['en', 'de']);
    });

    test(
      'applies a valid locale in-process when persistence is unavailable',
      () async {
        final repository = _LanguageRepository(
          documents: {
            'en': {
              'screen': {'label': 'Portfolio'},
            },
            'de': {
              'screen': {'label': 'Portfolio auf Deutsch'},
            },
          },
          saveError: StateError('storage blocked'),
        );
        final cubit = LanguageCubit(languageRepository: repository);
        addTearDown(cubit.close);
        await cubit.initialize();

        await cubit.selectLanguage('de');

        expect(cubit.state.status, LanguageStatus.ready);
        expect(cubit.currentLanguage, 'de');
        expect(cubit.getText('screen.label'), 'Portfolio auf Deutsch');
        expect(
          cubit.state.errorMessage,
          'Your language preference could not be saved. '
          'This language will remain active for this visit.',
        );
        expect(cubit.state.errorMessage, isNot(contains('storage blocked')));
        expect(repository.savedLanguages, isEmpty);
      },
    );

    test('uses a localized, non-technical persistence warning', () async {
      final repository = _LanguageRepository(
        selectedLanguage: 'de',
        documents: {
          'de': {
            'accessibility': {
              'language_not_saved':
                  'Die Sprachauswahl konnte nicht gespeichert werden.',
            },
          },
        },
        saveError: StateError('internal storage implementation detail'),
      );
      final cubit = LanguageCubit(languageRepository: repository);
      addTearDown(cubit.close);

      await cubit.initialize();

      expect(cubit.state.status, LanguageStatus.ready);
      expect(
        cubit.state.errorMessage,
        'Die Sprachauswahl konnte nicht gespeichert werden.',
      );
      expect(cubit.state.errorMessage, isNot(contains('internal storage')));
    });

    test(
      'empty translation document fails without replacing good data',
      () async {
        final repository = _LanguageRepository(
          documents: {
            'en': {
              'screen': {'label': 'Portfolio'},
            },
            'tr': <String, dynamic>{},
          },
        );
        final cubit = LanguageCubit(languageRepository: repository);
        addTearDown(cubit.close);
        await cubit.initialize();

        await cubit.changeLanguage('tr');

        expect(cubit.state.status, LanguageStatus.ready);
        expect(cubit.state.languageCode, 'en');
        expect(cubit.getText('screen.label'), 'Portfolio');
        expect(
          cubit.state.errorMessage,
          'That language could not be loaded. '
          'Your current language is still active.',
        );
        expect(repository.savedLanguages, ['en']);
      },
    );

    test(
      'rejects an incomplete matching-locale catalog before persistence',
      () async {
        final repository = _LanguageRepository(
          selectedLanguage: 'tr',
          documents: {
            'en': {
              'portfolio_content': {'required': 'present'},
            },
            'tr': {'locale': 'tr', 'portfolio_content': <String, dynamic>{}},
          },
        );
        final cubit = LanguageCubit(
          languageRepository: repository,
          validateTranslations: (translations) {
            final content = translations['portfolio_content'];
            if (content is! Map<String, dynamic> ||
                content['required'] != 'present') {
              throw const FormatException('incomplete portfolio overlay');
            }
          },
        );
        addTearDown(cubit.close);

        await cubit.initialize();

        expect(cubit.state.status, LanguageStatus.ready);
        expect(cubit.state.languageCode, 'en');
        expect(repository.selectedLanguage, 'en');
        expect(repository.savedLanguages, ['en']);
        expect(cubit.state.errorMessage, isNull);
      },
    );

    test(
      'a broken saved catalog deterministically falls back to English',
      () async {
        final repository = _LanguageRepository(
          selectedLanguage: 'tr',
          documents: {
            'en': {
              'screen': {'label': 'Portfolio'},
            },
            'tr': <String, dynamic>{},
          },
        );
        final cubit = LanguageCubit(languageRepository: repository);
        addTearDown(cubit.close);

        await cubit.initialize();

        expect(cubit.state.status, LanguageStatus.ready);
        expect(cubit.state.languageCode, 'en');
        expect(cubit.getText('screen.label'), 'Portfolio');
        expect(repository.selectedLanguage, 'en');
        expect(repository.savedLanguages, ['en']);
      },
    );

    test(
      'the latest language request wins even when responses reorder',
      () async {
        final repository = _LanguageRepository(
          documents: {
            'tr': {
              'screen': {'label': 'Türkçe'},
            },
            'de': {
              'screen': {'label': 'Deutsch'},
            },
          },
          delays: const {
            'tr': Duration(milliseconds: 20),
            'de': Duration(milliseconds: 1),
          },
        );
        final cubit = LanguageCubit(languageRepository: repository);
        addTearDown(cubit.close);

        final staleSelection = cubit.changeLanguage('tr');
        await Future<void>.delayed(Duration.zero);
        final latestSelection = cubit.changeLanguage('de');
        await Future.wait([staleSelection, latestSelection]);

        expect(cubit.state.status, LanguageStatus.ready);
        expect(cubit.currentLanguage, 'de');
        expect(cubit.getText('screen.label'), 'Deutsch');
        expect(repository.savedLanguages, ['de']);
      },
    );

    test(
      'persistence is ordered and a stale save cannot overwrite the latest choice',
      () async {
        final repository = _LanguageRepository(
          documents: {
            'tr': {
              'screen': {'label': 'Türkçe'},
            },
            'de': {
              'screen': {'label': 'Deutsch'},
            },
          },
          saveDelays: const {
            'tr': Duration(milliseconds: 20),
            'de': Duration(milliseconds: 1),
          },
        );
        final cubit = LanguageCubit(languageRepository: repository);
        addTearDown(cubit.close);

        final staleSelection = cubit.changeLanguage('tr');
        await Future<void>.delayed(Duration.zero);
        final latestSelection = cubit.changeLanguage('de');
        await Future.wait([staleSelection, latestSelection]);

        expect(repository.savedLanguages, ['tr', 'de']);
        expect(repository.selectedLanguage, 'de');
        expect(cubit.state.status, LanguageStatus.ready);
        expect(cubit.currentLanguage, 'de');
        expect(cubit.getText('screen.label'), 'Deutsch');
      },
    );

    test(
      'getText resolves nested values and uses its explicit fallback',
      () async {
        final repository = _LanguageRepository(
          documents: {
            'en': {
              'hero': {'title': 'Flutter Web'},
            },
          },
        );
        final cubit = LanguageCubit(languageRepository: repository);
        addTearDown(cubit.close);
        await cubit.initialize();

        expect(cubit.getText('hero.title'), 'Flutter Web');
        expect(
          cubit.getText('hero.missing', defaultValue: 'Fallback'),
          'Fallback',
        );
      },
    );

    group('language metadata', () {
      test('returns localized names for every supported public locale', () {
        expect(LanguageCubit.getLanguageName('tr'), 'Türkçe');
        expect(LanguageCubit.getLanguageName('en'), 'English');
        expect(LanguageCubit.getLanguageName('de'), 'Deutsch');
        expect(LanguageCubit.getLanguageName('fr'), 'Français');
        expect(LanguageCubit.getLanguageName('es'), 'Español');
        expect(LanguageCubit.getLanguageName('ar'), 'العربية');
        expect(LanguageCubit.getLanguageName('hi'), 'हिन्दी');
      });

      test('returns safe fallbacks for unknown locale codes', () {
        expect(LanguageCubit.getLanguageName('ja'), 'Unknown');
      });
    });
  });
}
