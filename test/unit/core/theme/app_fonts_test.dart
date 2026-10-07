import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_web_portfolio/app/core/theme/app_fonts.dart';
import 'package:flutter_web_portfolio/app/core/theme/app_theme.dart';

void main() {
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
