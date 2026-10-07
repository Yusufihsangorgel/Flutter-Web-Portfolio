import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_web_portfolio/app/data/dto/portfolio_document_mapper.dart';
import 'package:flutter_web_portfolio/app/domain/models/portfolio_document.dart';

void main() {
  _registerFeaturedTests();
  _registerMaturityTests();
  _registerCategoryTests();
}

void _registerFeaturedTests() {
  group('package featured flag', () {
    test('defaults to false when the field is absent', () {
      final packages = parsePortfolioDocument(_fixture()).packages;

      expect(packages[1].featured, isFalse);
    });

    test('reads an explicit value', () {
      final packages = parsePortfolioDocument(_fixture()).packages;

      expect(packages[0].featured, isTrue);
    });

    test('rejects a value that is not a boolean', () {
      _expectRejected(
        (package) => package['featured'] = 'yes',
        'Expected boolean at "featured".',
      );
    });
  });
}

void _registerMaturityTests() {
  group('package maturity level', () {
    test('is absent when the field is absent', () {
      final package = _parsePackage((entry) => entry.remove('maturity_level'));

      expect(package.maturityLevel, isNull);
    });

    test('accepts every level from 1 to 5', () {
      for (var level = 1; level <= 5; level++) {
        final package = _parsePackage(
          (entry) => entry['maturity_level'] = level,
        );

        expect(package.maturityLevel, level);
      }
    });

    test('rejects a level outside 1 to 5', () {
      for (final level in [0, 6, -1]) {
        _expectRejected(
          (package) => package['maturity_level'] = level,
          'Package "example_ui_kit" maturity level must be from 1 to 5, '
          'got $level.',
        );
      }
    });

    test('rejects a level that is not an integer', () {
      for (final level in ['3', 3.5, true]) {
        _expectRejected(
          (package) => package['maturity_level'] = level,
          'Expected integer at "maturity_level".',
        );
      }
    });

    test('rejects the retired letter field instead of ignoring it', () {
      _expectRejected(
        (package) => package['maturity'] = 'L3',
        'Package field "maturity" was replaced by "maturity_level" in schema '
        '11.',
      );
    });
  });
}

void _registerCategoryTests() {
  group('package category', () {
    test('declares the categories in reading order', () {
      expect(PortfolioPackageCategory.values.map((entry) => entry.wireValue), [
        'native-ffi',
        'ai-llm',
        'server',
        'flutter-ui',
        'dev-tool',
      ]);
    });

    test('accepts every declared category', () {
      for (final category in PortfolioPackageCategory.values) {
        final package = _parsePackage(
          (entry) => entry['category'] = category.wireValue,
        );

        expect(package.category, category);
      }
    });

    test('rejects a category that is not declared', () {
      for (final category in ['frontend', 'Server', ' server']) {
        _expectRejected(
          (package) => package['category'] = category,
          'Unsupported package category: $category',
        );
      }
    });

    test('requires a category', () {
      _expectRejected(
        (package) => package.remove('category'),
        'Expected non-empty string at "category".',
      );
    });
  });
}

Map<String, dynamic> _fixture() =>
    jsonDecode(File('test/fixtures/portfolio.json').readAsStringSync())
        as Map<String, dynamic>;

Map<String, dynamic> _secondPackage(Map<String, dynamic> json) =>
    (json['packages']! as List<dynamic>)[1] as Map<String, dynamic>;

PortfolioPackage _parsePackage(
  void Function(Map<String, dynamic> package) mutate,
) {
  final json = _fixture();
  mutate(_secondPackage(json));
  return parsePortfolioDocument(json).packages[1];
}

void _expectRejected(
  void Function(Map<String, dynamic> package) mutate,
  String message,
) {
  final json = _fixture();
  mutate(_secondPackage(json));

  expect(
    () => parsePortfolioDocument(json),
    throwsA(
      isA<FormatException>().having(
        (error) => error.message,
        'message',
        message,
      ),
    ),
  );
}
