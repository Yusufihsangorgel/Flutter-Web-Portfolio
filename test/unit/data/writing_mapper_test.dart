import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_web_portfolio/app/data/dto/portfolio_document_mapper.dart';

void main() {
  group('writing featured flag', () {
    test('defaults to false when the field is absent', () {
      final document = parsePortfolioDocument(_withWriting(featured: null));

      expect(document.writing.map((entry) => entry.featured), [false, false]);
    });

    test('reads an explicit value', () {
      final document = parsePortfolioDocument(_withWriting(featured: true));

      expect(document.writing.map((entry) => entry.featured), [true, false]);
    });

    test('rejects a value that is not a boolean', () {
      expect(
        () => parsePortfolioDocument(_withWriting(featured: 'yes')),
        throwsA(
          isA<FormatException>().having(
            (error) => error.message,
            'message',
            'Expected boolean at "featured".',
          ),
        ),
      );
    });
  });
}

/// A document with two writing entries; only the first carries [featured],
/// and only when it is not null.
Map<String, dynamic> _withWriting({required Object? featured}) {
  final json =
      jsonDecode(File('test/fixtures/portfolio.json').readAsStringSync())
          as Map<String, dynamic>;
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
    {
      'title': 'A published article',
      'url': 'https://example.com/writing/a-published-article',
      'source': 'blog',
      'date': '2026-08-01',
      'featured': ?featured,
    },
    {
      'title': 'A second article',
      'url': 'https://example.com/writing/a-second-article',
      'source': 'blog',
      'date': '2026-07-20',
    },
  ];
  return json;
}
