import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_web_portfolio/app/core/constants/app_config.dart';

import '../../helpers/portfolio_fixture.dart';

void main() {
  test('uses the configured navigation identity without parsing the name', () {
    final portfolio = loadPortfolioFixture(
      mutate: (json) {
        final profile = json['profile']! as Map<String, dynamic>;
        final site = json['site']! as Map<String, dynamic>;
        profile['name'] = 'Canonical Name With Different Word Order';
        profile['display_name'] = <String, dynamic>{
          'primary': 'PRIMARY',
          'accent': 'Accent',
          'navigation': 'Navigation From Content',
          'accessible': 'Accessible Name From Content',
        };
        site['title'] =
            'Canonical Name With Different Word Order — Software Engineer';
      },
    );

    expect(
      AppConfig.name(portfolio),
      'Canonical Name With Different Word Order',
    );
    expect(AppConfig.navigationName(portfolio), 'Navigation From Content');
    expect(AppConfig.tagline(portfolio), portfolio.profile.headline);
  });
}
