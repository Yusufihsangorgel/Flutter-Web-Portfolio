import 'package:flutter/material.dart';

abstract final class AppFonts {
  static const interFamily = 'Inter';
  static const spaceGroteskFamily = 'Space Grotesk';
  static const jetBrainsMonoFamily = 'JetBrains Mono';
  static const notoSansArabicFamily = 'Noto Sans Arabic';
  static const notoSansDevanagariFamily = 'Noto Sans Devanagari';
  // Eager subsets with the script glyphs every locale paints, such as language names.
  static const notoSansArabicSharedFamily = 'Noto Sans Arabic Shared';
  static const notoSansDevanagariSharedFamily = 'Noto Sans Devanagari Shared';
  static const scriptFallbackFamilies = [
    notoSansArabicFamily,
    notoSansDevanagariFamily,
    notoSansArabicSharedFamily,
    notoSansDevanagariSharedFamily,
  ];

  static const inter = _FontStyle(interFamily, [
    ...scriptFallbackFamilies,
    'Arial',
    'sans-serif',
  ]);
  static const spaceGrotesk = _FontStyle(spaceGroteskFamily, [
    interFamily,
    ...scriptFallbackFamilies,
    'Arial',
    'sans-serif',
  ]);
  static const jetBrainsMono = _FontStyle(jetBrainsMonoFamily, [
    ...scriptFallbackFamilies,
    'monospace',
  ]);

  static TextTheme interTextTheme(TextTheme textTheme) =>
      textTheme.apply(fontFamily: interFamily);
}

final class _FontStyle {
  const _FontStyle(this.family, this.fallback);

  final String family;
  final List<String> fallback;

  TextStyle call([TextStyle style = const TextStyle()]) =>
      style.copyWith(fontFamily: family, fontFamilyFallback: fallback);
}
