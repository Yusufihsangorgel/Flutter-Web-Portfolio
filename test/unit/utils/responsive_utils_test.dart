import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_web_portfolio/app/utils/responsive_utils.dart';
import 'package:flutter_web_portfolio/app/core/constants/breakpoints.dart';

Widget _wrapWithMediaQuery({required double width, required Widget child}) {
  return MediaQuery(
    data: MediaQueryData(size: Size(width, 800)),
    child: MaterialApp(home: Builder(builder: (context) => child)),
  );
}

void main() {
  group('ResponsiveUtils', () {
    testWidgets('isMobile returns true for narrow screens', (tester) async {
      late bool result;
      await tester.pumpWidget(
        _wrapWithMediaQuery(
          width: Breakpoints.mobile - 1,
          child: Builder(builder: (context) {
            result = ResponsiveUtils.isMobile(context);
            return const SizedBox();
          }),
        ),
      );
      expect(result, isTrue);
    });

    testWidgets('isMobile returns false for wide screens', (tester) async {
      late bool result;
      await tester.pumpWidget(
        _wrapWithMediaQuery(
          width: Breakpoints.mobile + 1,
          child: Builder(builder: (context) {
            result = ResponsiveUtils.isMobile(context);
            return const SizedBox();
          }),
        ),
      );
      expect(result, isFalse);
    });

    testWidgets('isTablet returns true for tablet-width screens', (tester) async {
      late bool result;
      await tester.pumpWidget(
        _wrapWithMediaQuery(
          width: (Breakpoints.mobile + Breakpoints.tablet) / 2,
          child: Builder(builder: (context) {
            result = ResponsiveUtils.isTablet(context);
            return const SizedBox();
          }),
        ),
      );
      expect(result, isTrue);
    });

    testWidgets('isLargeDesktop returns true for wide screens', (tester) async {
      late bool result;
      await tester.pumpWidget(
        _wrapWithMediaQuery(
          width: Breakpoints.desktop + 100,
          child: Builder(builder: (context) {
            result = ResponsiveUtils.isLargeDesktop(context);
            return const SizedBox();
          }),
        ),
      );
      expect(result, isTrue);
    });

    testWidgets('getValueForScreenType returns correct value per breakpoint', (tester) async {
      late String result;
      await tester.pumpWidget(
        _wrapWithMediaQuery(
          width: Breakpoints.mobile - 1,
          child: Builder(builder: (context) {
            result = ResponsiveUtils.getValueForScreenType(
              context: context,
              mobile: 'mobile',
              tablet: 'tablet',
              desktop: 'desktop',
            );
            return const SizedBox();
          }),
        ),
      );
      expect(result, 'mobile');
    });

    testWidgets('getValueForScreenType falls back when value is null', (tester) async {
      late String result;
      await tester.pumpWidget(
        _wrapWithMediaQuery(
          width: (Breakpoints.mobile + Breakpoints.tablet) / 2,
          child: Builder(builder: (context) {
            result = ResponsiveUtils.getValueForScreenType(
              context: context,
              mobile: 'mobile',
            );
            return const SizedBox();
          }),
        ),
      );
      expect(result, 'mobile');
    });
  });

  group('ResponsiveBuilder', () {
    testWidgets('renders mobile widget for small screens', (tester) async {
      await tester.pumpWidget(
        _wrapWithMediaQuery(
          width: Breakpoints.mobile - 1,
          child: const ResponsiveBuilder(
            mobile: Text('mobile'),
            tablet: Text('tablet'),
            desktop: Text('desktop'),
            largeDesktop: Text('large'),
          ),
        ),
      );
      expect(find.text('mobile'), findsOneWidget);
    });

    testWidgets('renders desktop widget for large screens', (tester) async {
      await tester.pumpWidget(
        _wrapWithMediaQuery(
          width: Breakpoints.tablet + 50,
          child: const ResponsiveBuilder(
            mobile: Text('mobile'),
            tablet: Text('tablet'),
            desktop: Text('desktop'),
            largeDesktop: Text('large'),
          ),
        ),
      );
      expect(find.text('desktop'), findsOneWidget);
    });
  });
}
