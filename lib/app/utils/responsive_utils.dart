import 'package:flutter/material.dart';
import 'package:flutter_web_portfolio/app/core/constants/breakpoints.dart';

/// Breakpoint-aware utilities — isMobile, isTablet, getValueForScreenType.
class ResponsiveUtils {
  static const double mobileWidth = Breakpoints.mobile;
  static const double tabletWidth = Breakpoints.tablet;
  static const double desktopWidth = Breakpoints.desktop;
  static const double largeDesktopWidth = Breakpoints.wide;

  static bool isMobile(BuildContext context) =>
      MediaQuery.sizeOf(context).width < mobileWidth;

  static bool isTablet(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    return width >= mobileWidth && width < tabletWidth;
  }

  static bool isDesktop(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    return width >= tabletWidth && width < desktopWidth;
  }

  static bool isLargeDesktop(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= desktopWidth;

  static T getValueForScreenType<T>({
    required BuildContext context,
    required T mobile,
    T? tablet,
    T? desktop,
    T? largeDesktop,
  }) {
    final tabletValue = tablet ?? mobile;
    final desktopValue = desktop ?? tabletValue;
    final largeDesktopValue = largeDesktop ?? desktopValue;
    final width = MediaQuery.sizeOf(context).width;

    return switch (width) {
      < Breakpoints.mobile => mobile,
      < Breakpoints.tablet => tabletValue,
      < Breakpoints.desktop => desktopValue,
      _ => largeDesktopValue,
    };
  }

  static Widget responsive({
    required Widget mobile,
    Widget? tablet,
    Widget? desktop,
    Widget? largeDesktop,
  }) {
    tablet ??= mobile;
    desktop ??= tablet;
    largeDesktop ??= desktop;

    return ResponsiveBuilder(
      mobile: mobile,
      tablet: tablet,
      desktop: desktop,
      largeDesktop: largeDesktop,
    );
  }
}

class ResponsiveBuilder extends StatelessWidget {

  const ResponsiveBuilder({
    super.key,
    required this.mobile,
    required this.tablet,
    required this.desktop,
    required this.largeDesktop,
  });
  final Widget mobile;
  final Widget tablet;
  final Widget desktop;
  final Widget largeDesktop;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;

    return switch (screenWidth) {
      < Breakpoints.mobile => mobile,
      < Breakpoints.tablet => tablet,
      < Breakpoints.desktop => desktop,
      _ => largeDesktop,
    };
  }
}
