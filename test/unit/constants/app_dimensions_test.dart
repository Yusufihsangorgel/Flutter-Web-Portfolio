import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_web_portfolio/app/core/constants/app_dimensions.dart';

void main() {
  group('AppDimensions', () {
    test('responsive section gutters widen with the viewport', () {
      expect(
        AppDimensions.sectionPaddingDesktop,
        greaterThan(AppDimensions.sectionPaddingTablet),
      );
      expect(
        AppDimensions.sectionPaddingTablet,
        greaterThan(AppDimensions.sectionPaddingMobile),
      );
      expect(
        AppDimensions.maxContentWidth,
        greaterThan(AppDimensions.sectionPaddingDesktop * 2),
      );
    });

    test('app bar collapse is continuous and clamps at both extents', () {
      final samples = [
        -20.0,
        0.0,
        50.0,
        100.0,
        150.0,
        200.0,
        800.0,
      ].map(AppDimensions.appBarHeightForScrollOffset).toList();

      expect(samples.first, AppDimensions.appBarHeight);
      expect(samples[1], AppDimensions.appBarHeight);
      expect(samples[3], 70);
      expect(samples[5], AppDimensions.appBarHeightMobile);
      expect(samples.last, AppDimensions.appBarHeightMobile);
      for (var index = 1; index < samples.length; index += 1) {
        expect(samples[index], lessThanOrEqualTo(samples[index - 1]));
      }
    });
  });
}
