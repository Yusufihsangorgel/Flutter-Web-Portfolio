import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_web_portfolio/app/core/constants/breakpoints.dart';

void main() {
  group('Breakpoints', () {
    test('all breakpoint values are positive', () {
      expect(Breakpoints.mobile, greaterThan(0));
      expect(Breakpoints.tablet, greaterThan(0));
      expect(Breakpoints.desktop, greaterThan(0));
      expect(Breakpoints.wide, greaterThan(0));
    });

    test('mobile < tablet < desktop < wide', () {
      expect(Breakpoints.mobile, lessThan(Breakpoints.tablet));
      expect(Breakpoints.tablet, lessThan(Breakpoints.desktop));
      expect(Breakpoints.desktop, lessThan(Breakpoints.wide));
    });

    test('all breakpoints are double values', () {
      expect(Breakpoints.mobile, isA<double>());
      expect(Breakpoints.tablet, isA<double>());
      expect(Breakpoints.desktop, isA<double>());
      expect(Breakpoints.wide, isA<double>());
    });

    test('breakpoints match expected pixel values', () {
      expect(Breakpoints.mobile, 600);
      expect(Breakpoints.tablet, 900);
      expect(Breakpoints.desktop, 1200);
      expect(Breakpoints.wide, 1440);
    });
  });
}
