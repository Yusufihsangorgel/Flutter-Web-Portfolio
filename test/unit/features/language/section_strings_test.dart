import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_web_portfolio/app/core/l10n/app_strings.g.dart';
import 'package:flutter_web_portfolio/app/core/l10n/section_strings.dart';

void main() {
  test('navigation labels use all seven typed keys', () {
    const strings = AppStrings({
      'nav': {
        'home': 'Start',
        'about': 'Profile',
        'experience': 'Career',
        'proof': 'Evidence',
        'projects': 'Cases',
        'packages': 'Libraries',
        'writing': 'Articles',
      },
    });

    expect(
      {
        for (final section in const [
          'home',
          'about',
          'experience',
          'proof',
          'projects',
          'packages',
          'writing',
        ])
          section: strings.navigationLabel(section),
      },
      {
        'home': 'Start',
        'about': 'Profile',
        'experience': 'Career',
        'proof': 'Evidence',
        'projects': 'Cases',
        'packages': 'Libraries',
        'writing': 'Articles',
      },
    );
  });

  test('unknown navigation labels require or use an explicit fallback', () {
    const strings = AppStrings({});

    expect(strings.navigationLabel('contact', fallback: 'Contact'), 'Contact');
    expect(
      () => strings.navigationLabel('contact'),
      throwsA(isA<StateError>()),
    );
  });
}
