import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_web_portfolio/app/core/constants/durations.dart';

void main() {
  test('direct feedback completes before document navigation', () {
    expect(AppDurations.microFast, lessThan(AppDurations.fast));
    expect(AppDurations.fast, lessThan(AppDurations.buttonHover));
    expect(AppDurations.buttonHover, lessThan(AppDurations.medium));
    expect(AppDurations.medium, lessThan(AppDurations.sectionScroll));
    expect(AppDurations.heroDebounce, lessThan(AppDurations.sectionScroll));
    expect(AppDurations.fadeIn, AppDurations.sectionScroll);
  });
}
