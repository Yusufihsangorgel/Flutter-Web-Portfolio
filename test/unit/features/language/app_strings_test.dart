import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_web_portfolio/app/domain/repositories/language_repository.dart';
import 'package:flutter_web_portfolio/app/features/language/application/language_cubit.dart';
import 'package:flutter_web_portfolio/app/utils/language_browser.dart';

final class _Repository implements LanguageRepository {
  @override
  Set<String> get supportedLanguages => const {'en', 'tr'};

  @override
  Future<String> getSelectedLanguage() async => 'en';

  @override
  Future<Map<String, dynamic>> getTranslations(String languageCode) async => {
    'nav': {'home': languageCode == 'tr' ? 'Ana sayfa' : 'Home'},
    'command_palette': {'go_to': 'Go to {section}'},
  };

  @override
  Future<void> saveSelectedLanguage(String languageCode) async {}
}

final class _Browser implements LanguageBrowser {
  final languages = <String>[];

  @override
  bool reloadForLanguageChange({String? preserveSection}) => false;

  @override
  void setDocumentLanguage(String languageCode) => languages.add(languageCode);
}

void main() {
  test('typed strings use active translations and English fallbacks', () async {
    final browser = _Browser();
    final cubit = LanguageCubit(
      languageRepository: _Repository(),
      browser: browser,
    );
    addTearDown(cubit.close);

    expect(cubit.strings.navHome, 'Home');
    await cubit.changeLanguage('tr');
    expect(cubit.strings.navHome, 'Ana sayfa');
    expect(cubit.strings.accessibilityRetry, 'Retry');
    expect(cubit.strings.commandPaletteGoTo(section: 'Work'), 'Go to Work');
    expect(
      cubit.strings.packagesSectionSubtitle(count: '{perfect}', perfect: '5'),
      startsWith('{perfect} packages live'),
    );
    expect(cubit.getText('nav.home'), 'Ana sayfa');
    expect(browser.languages, ['tr']);
  });
}
