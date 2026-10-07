import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_web_portfolio/app/data/dto/portfolio_document_mapper.dart';

void main() {
  _registerSchemaTests();
  _registerFeaturedPackageTests();
  _registerFeaturedWritingTests();
}

void _registerSchemaTests() {
  group('schema version', () {
    test('accepts version 11', () {
      expect(parsePortfolioDocument(_fixture()).schemaVersion, 11);
    });

    test('rejects the previous version and names it', () {
      final json = _fixture()..['schema_version'] = 10;

      _expectRejected(json, 'Unsupported portfolio schema version: 10');
    });
  });
}

void _registerFeaturedPackageTests() {
  group('featured packages', () {
    test('allows exactly five', () {
      final document = parsePortfolioDocument(
        _withPackages(total: 8, featured: 5),
      );

      expect(document.packages.where((entry) => entry.featured), hasLength(5));
    });

    test('rejects a sixth', () {
      _expectRejected(
        _withPackages(total: 8, featured: 6),
        'At most 5 packages may be featured.',
      );
    });

    test('counts only the featured entries', () {
      final document = parsePortfolioDocument(
        _withPackages(total: 23, featured: 5),
      );

      expect(document.packages, hasLength(23));
    });
  });
}

void _registerFeaturedWritingTests() {
  group('featured writing', () {
    test('allows exactly three', () {
      final document = parsePortfolioDocument(
        _withWriting(total: 12, featured: 3),
      );

      expect(document.writing.where((entry) => entry.featured), hasLength(3));
    });

    test('rejects a fourth', () {
      _expectRejected(
        _withWriting(total: 12, featured: 4),
        'At most 3 writing entries may be featured.',
      );
    });

    test('counts only the featured entries', () {
      final document = parsePortfolioDocument(
        _withWriting(total: 12, featured: 0),
      );

      expect(document.writing, hasLength(12));
    });
  });
}

Map<String, dynamic> _fixture() =>
    jsonDecode(File('test/fixtures/portfolio.json').readAsStringSync())
        as Map<String, dynamic>;

Map<String, dynamic> _withPackages({
  required int total,
  required int featured,
}) {
  final json = _fixture();
  final template =
      (json['packages']! as List<dynamic>).first as Map<String, dynamic>;
  json['packages'] = [
    for (var index = 0; index < total; index++)
      {
        ...template,
        'id': 'package_$index',
        'name': 'package_$index',
        'url': 'https://pub.dev/packages/package_$index',
        'featured': index < featured,
      },
  ];
  return json;
}

Map<String, dynamic> _withWriting({required int total, required int featured}) {
  final json = _fixture();
  json['writing_sources'] = [
    {
      'id': 'blog',
      'label': 'Blog',
      'kind': 'rss',
      'url': 'https://example.com/writing/feed.xml',
      'profile_url': 'https://example.com/writing',
    },
  ];
  json['writing'] = [
    for (var index = 0; index < total; index++)
      {
        'title': 'Article number $index',
        'url': 'https://example.com/writing/article-$index',
        'source': 'blog',
        'date': '2026-08-${(index + 1).toString().padLeft(2, '0')}',
        'featured': index < featured,
      },
  ];
  return json;
}

void _expectRejected(Map<String, dynamic> json, String message) {
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
