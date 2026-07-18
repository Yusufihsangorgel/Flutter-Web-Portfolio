import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_web_portfolio/app/core/constants/breakpoints.dart';

void main() {
  test('responsive thresholds progress from compact to desktop', () {
    expect(Breakpoints.mobile, lessThan(Breakpoints.tablet));
    expect(Breakpoints.tablet, lessThan(Breakpoints.desktop));
  });
}
