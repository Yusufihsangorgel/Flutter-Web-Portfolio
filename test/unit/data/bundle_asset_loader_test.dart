import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_web_portfolio/app/data/providers/bundle_asset_loader.dart';

void main() {
  group('BundleAssetLoader locale boundary', () {
    test('merges matching interface and professional catalogs', () {
      final merged = BundleAssetLoader.mergeCatalogs(
        languageCode: 'tr',
        interfaceCatalog: const {
          'nav': {'home': 'Ana Sayfa'},
        },
        portfolioLocalization: const {'schema_version': 1, 'locale': 'tr'},
      );

      expect(merged['nav'], {'home': 'Ana Sayfa'});
      expect(merged['portfolio_content'], {
        'schema_version': 1,
        'locale': 'tr',
      });
    });

    test('rejects a professional catalog stored under the wrong locale', () {
      expect(
        () => BundleAssetLoader.mergeCatalogs(
          languageCode: 'tr',
          interfaceCatalog: const <String, dynamic>{},
          portfolioLocalization: const {'schema_version': 1, 'locale': 'de'},
        ),
        throwsFormatException,
      );
    });
  });
}
