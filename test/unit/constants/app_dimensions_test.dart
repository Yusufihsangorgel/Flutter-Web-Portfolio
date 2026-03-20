import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_web_portfolio/app/core/constants/app_dimensions.dart';

void main() {
  group('AppDimensions', () {
    test('all dimension values are positive', () {
      expect(AppDimensions.appBarHeight, greaterThan(0));
      expect(AppDimensions.appBarHeightMobile, greaterThan(0));
      expect(AppDimensions.appBarHeightTablet, greaterThan(0));
      expect(AppDimensions.sectionPaddingDesktop, greaterThan(0));
      expect(AppDimensions.sectionPaddingTablet, greaterThan(0));
      expect(AppDimensions.sectionPaddingMobile, greaterThan(0));
      expect(AppDimensions.maxContentWidth, greaterThan(0));
    });

    test('appBarHeight > appBarHeightMobile', () {
      expect(
        AppDimensions.appBarHeight,
        greaterThan(AppDimensions.appBarHeightMobile),
      );
    });

    test('appBarHeight > appBarHeightTablet', () {
      expect(
        AppDimensions.appBarHeight,
        greaterThan(AppDimensions.appBarHeightTablet),
      );
    });

    test('appBarHeightTablet > appBarHeightMobile', () {
      expect(
        AppDimensions.appBarHeightTablet,
        greaterThan(AppDimensions.appBarHeightMobile),
      );
    });

    test('sectionPaddingDesktop > sectionPaddingTablet > sectionPaddingMobile', () {
      expect(
        AppDimensions.sectionPaddingDesktop,
        greaterThan(AppDimensions.sectionPaddingTablet),
      );
      expect(
        AppDimensions.sectionPaddingTablet,
        greaterThan(AppDimensions.sectionPaddingMobile),
      );
    });

    test('maxContentWidth is a reasonable desktop value', () {
      expect(AppDimensions.maxContentWidth, greaterThanOrEqualTo(1200));
      expect(AppDimensions.maxContentWidth, lessThanOrEqualTo(1920));
    });

    test('dimension values match expected constants', () {
      expect(AppDimensions.appBarHeight, 80.0);
      expect(AppDimensions.appBarHeightMobile, 60.0);
      expect(AppDimensions.appBarHeightTablet, 70.0);
      expect(AppDimensions.sectionPaddingDesktop, 160.0);
      expect(AppDimensions.sectionPaddingTablet, 80.0);
      expect(AppDimensions.sectionPaddingMobile, 24.0);
      expect(AppDimensions.maxContentWidth, 1400.0);
    });
  });
}
