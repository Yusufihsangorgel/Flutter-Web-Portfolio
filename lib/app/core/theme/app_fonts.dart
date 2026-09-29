import 'dart:ui' as ui;

import 'package:flutter/material.dart';

abstract final class AppFonts {
  static const interFamily = 'Inter';
  static const spaceGroteskFamily = 'Space Grotesk';
  static const jetBrainsMonoFamily = 'JetBrains Mono';
  static const notoSansArabicFamily = 'Noto Sans Arabic';
  static const notoSansDevanagariFamily = 'Noto Sans Devanagari';
  static const scriptFallbackFamilies = [
    notoSansArabicFamily,
    notoSansDevanagariFamily,
  ];

  static const inter = _FontStyle(interFamily, [
    notoSansArabicFamily,
    notoSansDevanagariFamily,
    'Arial',
    'sans-serif',
  ]);
  static const spaceGrotesk = _FontStyle(spaceGroteskFamily, [
    interFamily,
    notoSansArabicFamily,
    notoSansDevanagariFamily,
    'Arial',
    'sans-serif',
  ]);
  static const jetBrainsMono = _FontStyle(jetBrainsMonoFamily, [
    notoSansArabicFamily,
    notoSansDevanagariFamily,
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
