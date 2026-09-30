import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_web_portfolio/app/domain/repositories/language_repository.dart';
import 'package:flutter_web_portfolio/app/features/language/application/language_cubit.dart';
import 'package:flutter_web_portfolio/app/utils/language_browser.dart';

final class _Repository implements LanguageRepository {
  _Repository({this.saveError});

  final Object? saveError;
  final saved = <String>[];

  @override
  Set<String> get supportedLanguages => const {'en', 'tr'};

  @override
  Future<String> getSelectedLanguage() async => 'en';

  @override
  Future<Map<String, dynamic>> getTranslations(String languageCode) async => {
    'nav': {'home': languageCode},
  };

  @override
  Future<void> saveSelectedLanguage(String languageCode) async {
    final error = saveError;
    if (error != null) throw error;
    saved.add(languageCode);
  }
}

final class _Browser implements LanguageBrowser {
  _Browser({required this.reloads});

  final bool reloads;
  final reloadedSections = <String?>[];
  final documentLanguages = <String>[];

  @override
  bool reloadForLanguageChange({String? preserveSection}) {
    reloadedSections.add(preserveSection);
    return reloads;
  }

  @override
  void setDocumentLanguage(String languageCode) =>
      documentLanguages.add(languageCode);
}

void main() {
  late _Repository repository;

  LanguageCubit buildCubit(_Browser browser) {
    final cubit = LanguageCubit(
      languageRepository: repository,
      browser: browser,
    );
    addTearDown(cubit.close);
    return cubit;
  }

  setUp(() => repository = _Repository());

  test('a saved choice hands over to the browser reload', () async {
    final browser = _Browser(reloads: true);
    final cubit = buildCubit(browser);
    await cubit.initialize();

    await cubit.selectLanguage('tr', preserveSection: 'about');

    expect(repository.saved, ['en', 'tr']);
    expect(browser.reloadedSections, ['about']);
    expect(cubit.state.languageCode, 'en');
    expect(browser.documentLanguages, ['en']);
  });

  test(
    'the language applies in place when the browser does not reload',
    () async {
      final browser = _Browser(reloads: false);
      final cubit = buildCubit(browser);
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
      final browser = _Browser(reloads: true);
      repository = _Repository(saveError: StateError('storage blocked'));
      final cubit = buildCubit(browser);

      await cubit.selectLanguage('tr', preserveSection: 'about');

      expect(browser.reloadedSections, isEmpty);
      expect(cubit.state.languageCode, 'tr');
      expect(cubit.state.errorMessage, isNotNull);
      expect(browser.documentLanguages, ['tr']);
    },
  );

  test('the initial load never reloads the document', () async {
    final browser = _Browser(reloads: true);
    final cubit = buildCubit(browser);

    await cubit.initialize();

    expect(browser.reloadedSections, isEmpty);
    expect(browser.documentLanguages, ['en']);
  });
}
