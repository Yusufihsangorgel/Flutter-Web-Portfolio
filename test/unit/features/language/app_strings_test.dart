import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_web_portfolio/app/features/language/application/language_cubit.dart';

import '../../../support/fake_language_browser.dart';
import '../../../support/fake_language_repository.dart';

void main() {
  test('typed strings use active translations and English fallbacks', () async {
    final browser = FakeLanguageBrowser();
    final cubit = LanguageCubit(
      languageRepository: FakeLanguageRepository(
        supportedLanguages: const {'en', 'tr'},
        documents: const {
          'en': {
            'nav': {'home': 'Home'},
            'command_palette': {'go_to': 'Go to {section}'},
          },
          'tr': {
            'nav': {'home': 'Ana sayfa'},
            'command_palette': {'go_to': 'Go to {section}'},
          },
        },
      ),
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
    expect(cubit.strings.navHome, 'Ana sayfa');
    expect(browser.documentLanguages, ['tr']);
  });
}
