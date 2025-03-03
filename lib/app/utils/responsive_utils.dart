import 'package:flutter/material.dart';

/// Responsive tasarım için yardımcı sınıf
class ResponsiveUtils {
  /// Ekran boyutu bilgileri
  static const double mobileWidth = 576; // < 576px - Mobil
  static const double tabletWidth = 992; // 576px - 992px - Tablet
  static const double desktopWidth = 1200; // 992px - 1200px - Küçük Masaüstü
  static const double largeDesktopWidth = 1400; // > 1200px - Büyük Masaüstü

  /// Cihaz tipini kontrol eden metotlar
  static bool isMobile(BuildContext context) {
    return MediaQuery.of(context).size.width < mobileWidth;
  }

  static bool isTablet(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= mobileWidth && width < tabletWidth;
  }

  static bool isDesktop(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= tabletWidth && width < desktopWidth;
  }

  static bool isLargeDesktop(BuildContext context) {
    return MediaQuery.of(context).size.width >= desktopWidth;
  }

  /// Cihaz tipine göre değer döndüren yardımcı metot
  static T getValueForScreenType<T>({
    required BuildContext context,
    required T mobile,
    T? tablet,
    T? desktop,
    T? largeDesktop,
  }) {
    // Default değerler
    final T tabletValue = tablet ?? mobile;
    final T desktopValue = desktop ?? tabletValue;
    final T largeDesktopValue = largeDesktop ?? desktopValue;

    if (isMobile(context)) {
      return mobile;
    } else if (isTablet(context)) {
      return tabletValue;
    } else if (isDesktop(context)) {
      return desktopValue;
    } else {
      return largeDesktopValue;
    }
  }

  static Widget responsive({
    required Widget mobile,
    Widget? tablet,
    Widget? desktop,
    Widget? largeDesktop,
  }) {
    // Default değerler
    tablet = tablet ?? mobile;
    desktop = desktop ?? tablet;
    largeDesktop = largeDesktop ?? desktop;

    return ResponsiveBuilder(
      mobile: mobile,
      tablet: tablet,
      desktop: desktop,
      largeDesktop: largeDesktop,
    );
  }
}

/// Responsive ekran boyutuna göre widget döndüren builder
class ResponsiveBuilder extends StatelessWidget {
  final Widget mobile;
  final Widget tablet;
  final Widget desktop;
  final Widget largeDesktop;

  const ResponsiveBuilder({
    Key? key,
    required this.mobile,
    required this.tablet,
    required this.desktop,
    required this.largeDesktop,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // GetX reaktif ekran boyutu
    final screenWidth = MediaQuery.of(context).size.width;

    if (screenWidth < ResponsiveUtils.mobileWidth) {
      return mobile;
    } else if (screenWidth < ResponsiveUtils.tabletWidth) {
      return tablet;
    } else if (screenWidth < ResponsiveUtils.desktopWidth) {
      return desktop;
    } else {
      return largeDesktop;
    }
  }
}
