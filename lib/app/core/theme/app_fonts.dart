import 'dart:ui' as ui;

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

  TextStyle call({
    TextStyle? textStyle,
    Color? color,
    Color? backgroundColor,
    double? fontSize,
    FontWeight? fontWeight,
    FontStyle? fontStyle,
    double? letterSpacing,
    double? wordSpacing,
    TextBaseline? textBaseline,
    double? height,
    Locale? locale,
    Paint? foreground,
    Paint? background,
    List<ui.Shadow>? shadows,
    List<ui.FontFeature>? fontFeatures,
    TextDecoration? decoration,
    Color? decorationColor,
    TextDecorationStyle? decorationStyle,
    double? decorationThickness,
  }) => (textStyle ?? const TextStyle()).copyWith(
    fontFamily: family,
    fontFamilyFallback: fallback,
    color: color,
    backgroundColor: backgroundColor,
    fontSize: fontSize,
    fontWeight: fontWeight,
    fontStyle: fontStyle,
    letterSpacing: letterSpacing,
    wordSpacing: wordSpacing,
    textBaseline: textBaseline,
    height: height,
    locale: locale,
    foreground: foreground,
    background: background,
    shadows: shadows,
    fontFeatures: fontFeatures,
    decoration: decoration,
    decorationColor: decorationColor,
    decorationStyle: decorationStyle,
    decorationThickness: decorationThickness,
  );
}
