import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_web_portfolio/app/domain/repositories/i_language_repository.dart';
import 'package:flutter_web_portfolio/app/features/language/application/language_cubit.dart';

final class _LanguageRepository implements ILanguageRepository {
  _LanguageRepository({
    this.selectedLanguage = 'en',
    Map<String, Map<String, dynamic>>? documents,
    Map<String, Duration>? delays,
  }) : documents = documents ?? <String, Map<String, dynamic>>{},
       delays = delays ?? <String, Duration>{};

  String selectedLanguage;
  final Map<String, Map<String, dynamic>> documents;
  final Map<String, Duration> delays;
  final List<String> savedLanguages = [];

  @override
  Map<String, String> getSupportedLanguages() => const {
    'en': 'EN',
    'tr': 'TR',
    'de': 'DE',
  };

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
            'app_name': 'Portföy',
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
      expect(cubit.appName, 'Portföy');
      expect(cubit.activeSections, contains('about'));
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

    test(
      'empty translation document fails without replacing good data',
      () async {
        final repository = _LanguageRepository(
          documents: {
            'en': {'app_name': 'Portfolio'},
            'tr': <String, dynamic>{},
          },
        );
        final cubit = LanguageCubit(languageRepository: repository);
        addTearDown(cubit.close);
        await cubit.initialize();

        await cubit.changeLanguage('tr');

        expect(cubit.state.status, LanguageStatus.failure);
        expect(cubit.state.languageCode, 'en');
        expect(cubit.appName, 'Portfolio');
        expect(repository.savedLanguages, ['en']);
      },
    );

    test(
      'the latest language request wins even when responses reorder',
      () async {
        final repository = _LanguageRepository(
          documents: {
            'tr': {'app_name': 'Türkçe'},
            'de': {'app_name': 'Deutsch'},
          },
          delays: const {
            'tr': Duration(milliseconds: 20),
            'de': Duration(milliseconds: 1),
          },
        );
        final cubit = LanguageCubit(languageRepository: repository);
        addTearDown(cubit.close);

        await Future.wait([
          cubit.changeLanguage('tr'),
          cubit.changeLanguage('de'),
        ]);

        expect(cubit.state.status, LanguageStatus.ready);
        expect(cubit.currentLanguage, 'de');
        expect(cubit.appName, 'Deutsch');
        expect(repository.savedLanguages, ['de']);
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
        expect(LanguageCubit.getLanguageFlag('xx'), isNotEmpty);
      });
    });
  });
}
