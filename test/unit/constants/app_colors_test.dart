import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_web_portfolio/app/core/constants/app_colors.dart';

void main() {
  group('AppColors', () {
    test('document surfaces preserve their luminance hierarchy', () {
      expect(
        AppColors.backgroundDark.computeLuminance(),
        lessThan(AppColors.background.computeLuminance()),
      );
      expect(
        AppColors.background.computeLuminance(),
        lessThan(AppColors.backgroundLight.computeLuminance()),
      );
    });

    test('ambient gradient has three distinct stops and one signal color', () {
      expect({
        AppColors.sceneGradientStart,
        AppColors.sceneGradientMiddle,
        AppColors.sceneGradientEnd,
      }, hasLength(3));
      expect(AppColors.sceneGradientEnd, AppColors.accent);
    });
  });
}
