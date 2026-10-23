import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_web_portfolio/app/core/theme/app_fonts.dart';
import 'package:flutter_web_portfolio/app/core/theme/app_theme.dart';

void main() {
  _registerCompositionTests();

  test('every text style falls back to the script families', () {
    final styles = [
      AppFonts.inter(),
      AppFonts.spaceGrotesk(),
      AppFonts.jetBrainsMono(),
      AppTheme.light.textTheme.bodyMedium!,
    ];
    for (final style in styles) {
      expect(
        style.fontFamilyFallback,
        containsAllInOrder(AppFonts.scriptFallbackFamilies),
      );
    }
  });

  test('the shared script subsets load with the app', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();
    for (final family in [
      AppFonts.notoSansArabicSharedFamily,
      AppFonts.notoSansDevanagariSharedFamily,
    ]) {
      expect(pubspec, contains('- family: $family\n'));
    }
  });
}

void _registerCompositionTests() {
  test('default styles match the original font composition', () {
    final cases = [
      (AppFonts.inter(), AppFonts.interFamily, const ['Arial', 'sans-serif']),
      (
        AppFonts.spaceGrotesk(),
        AppFonts.spaceGroteskFamily,
        const ['Arial', 'sans-serif'],
      ),
      (
        AppFonts.jetBrainsMono(),
        AppFonts.jetBrainsMonoFamily,
        const ['monospace'],
      ),
    ];
    for (final (actual, family, suffix) in cases) {
      final expected = const TextStyle().copyWith(
        fontFamily: family,
        fontFamilyFallback: [
          if (family == AppFonts.spaceGroteskFamily) AppFonts.interFamily,
          ...AppFonts.scriptFallbackFamilies,
          ...suffix,
        ],
      );
      expect(actual, expected);
    }
  });
  _registerExplicitStyleTest();
  _registerInheritedStyleTests();
  _registerPaintStyleTest();
}

void _registerExplicitStyleTest() {
  test('explicit style fields match the original copyWith composition', () {
    final expected = const TextStyle().copyWith(
      fontFamily: AppFonts.spaceGroteskFamily,
      fontFamilyFallback: AppFonts.spaceGrotesk.fallback,
      color: Colors.blue,
      backgroundColor: Colors.white,
      fontSize: 24,
      fontWeight: FontWeight.w700,
      fontStyle: FontStyle.italic,
      letterSpacing: 1.2,
      wordSpacing: 2,
      textBaseline: TextBaseline.alphabetic,
      height: 1.5,
      locale: const Locale('tr'),
      shadows: const [ui.Shadow(blurRadius: 2)],
      fontFeatures: const [ui.FontFeature.tabularFigures()],
      decoration: TextDecoration.underline,
      decorationColor: Colors.red,
      decorationStyle: TextDecorationStyle.dashed,
      decorationThickness: 2,
    );
    final actual = AppFonts.spaceGrotesk(
      const TextStyle(
        color: Colors.blue,
        backgroundColor: Colors.white,
        fontSize: 24,
        fontWeight: FontWeight.w700,
        fontStyle: FontStyle.italic,
        letterSpacing: 1.2,
        wordSpacing: 2,
        textBaseline: TextBaseline.alphabetic,
        height: 1.5,
        locale: Locale('tr'),
        shadows: [ui.Shadow(blurRadius: 2)],
        fontFeatures: [ui.FontFeature.tabularFigures()],
        decoration: TextDecoration.underline,
        decorationColor: Colors.red,
        decorationStyle: TextDecorationStyle.dashed,
        decorationThickness: 2,
      ),
    );
    expect(actual, expected);
  });
}

void _registerInheritedStyleTests() {
  const base = TextStyle(
    inherit: false,
    fontFamily: 'Original family',
    fontFamilyFallback: ['Original fallback'],
    color: Colors.green,
    fontSize: 18,
    height: 1.4,
    letterSpacing: 0.75,
    decoration: TextDecoration.lineThrough,
    leadingDistribution: TextLeadingDistribution.even,
    fontVariations: [ui.FontVariation.weight(650)],
    overflow: TextOverflow.ellipsis,
  );
  test('the selected family overrides the supplied style family', () {
    final labelled = base.copyWith(debugLabel: 'Original style');
    final expected = labelled.copyWith(
      fontFamily: AppFonts.interFamily,
      fontFamilyFallback: AppFonts.inter.fallback,
    );
    final actual = AppFonts.inter(labelled);
    expect(actual, expected);
    expect(actual.debugLabel, expected.debugLabel);
  });
  test('base style overrides match the original single copyWith', () {
    final expected = base.copyWith(
      fontFamily: AppFonts.jetBrainsMonoFamily,
      fontFamilyFallback: AppFonts.jetBrainsMono.fallback,
      color: Colors.orange,
      height: 1.8,
      letterSpacing: 2,
      decoration: TextDecoration.overline,
    );
    final actual = AppFonts.jetBrainsMono(
      base.copyWith(
        color: Colors.orange,
        height: 1.8,
        letterSpacing: 2,
        decoration: TextDecoration.overline,
      ),
    );
    expect(actual, expected);
  });
}

void _registerPaintStyleTest() {
  test('paint styles match the original copyWith composition', () {
    final foreground = ui.Paint()..color = Colors.blue;
    final background = ui.Paint()..color = Colors.white;
    final expected = const TextStyle().copyWith(
      fontFamily: AppFonts.interFamily,
      fontFamilyFallback: AppFonts.inter.fallback,
      foreground: foreground,
      background: background,
    );
    final actual = AppFonts.inter(
      TextStyle(foreground: foreground, background: background),
    );
    expect(actual, expected);
  });
}
