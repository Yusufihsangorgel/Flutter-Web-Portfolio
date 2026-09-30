import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_web_portfolio/app/data/dto/portfolio_document_mapper.dart';

Map<String, dynamic> fixture() =>
    jsonDecode(File('test/fixtures/portfolio.json').readAsStringSync())
        as Map<String, dynamic>;

void main() {
  _registerDocumentTests();
  _registerBasicMapperTests();
  _registerRemainingMapperTests();
}

void _registerDocumentTests() {
  test('maps the complete portfolio document', () {
    final document = parsePortfolioDocument(fixture());
    expect(document.schemaVersion, 10);
    expect(document.profile.focus, hasLength(greaterThanOrEqualTo(3)));
    expect(document.systems, isNotEmpty);
  });

  test('keeps the schema validation message', () {
    final json = fixture()..['schema_version'] = 0;
    expect(
      () => parsePortfolioDocument(json),
      throwsA(
        isA<FormatException>().having(
          (error) => error.message,
          'message',
          'Unsupported portfolio schema version: 0',
        ),
      ),
    );
  });
}

void _registerBasicMapperTests() {
  group('basic mapper validation', () {
    test('site', () {
      _expectFailure(
        'site',
        'The social image must be a root-relative asset path.',
        (entity) => entity['social_image'] = 'preview.png',
      );
    });

    test('profile', () {
      _expectFailure(
        'profile',
        'Expected an email address at "email".',
        (entity) => entity['email'] = 'invalid',
      );
    });

    test('experience', () {
      _expectFailure(
        'experience',
        'Expected boolean at "current".',
        (entity) => entity['current'] = 'yes',
      );
    });

    test('capability', () {
      _expectFailure(
        'capabilities',
        'Expected list at "items".',
        (entity) => entity['items'] = 'one',
      );
    });

    test('contribution', () {
      _expectFailure(
        'contributions',
        'Unsupported contribution status: unknown',
        (entity) => entity['status'] = 'unknown',
      );
    });
  });
}

void _registerRemainingMapperTests() {
  group('remaining mapper validation', () {
    test('system', () {
      _expectFailure(
        'systems',
        'Expected a six-digit hex colour at "background".',
        (entity) =>
            (entity['presentation']! as Map<String, dynamic>)['background'] =
                'blue',
      );
    });

    test('artifact', () {
      _expectFailure(
        'systems',
        'Unsupported artifact fit: parallax',
        (entity) =>
            (entity['artifact']! as Map<String, dynamic>)['fit'] = 'parallax',
      );
    });

    test('package', () {
      final json = fixture();
      final package =
          (json['packages']! as List<dynamic>).first as Map<String, dynamic>;
      package['roadmap'] = [
        <String, dynamic>{'title': 'Plan', 'status': 'unknown'},
      ];
      _expectMessage(json, 'Unknown roadmap status "unknown".');
    });

    test('writing source', () {
      final json = fixture();
      json['writing_sources'] = [
        <String, dynamic>{
          'id': 'feed',
          'label': 'Feed',
          'kind': 'unknown',
          'url': 'https://example.com/feed',
          'profile_url': 'https://example.com/profile',
        },
      ];
      _expectMessage(json, 'Unsupported writing source kind: unknown');
    });
  });
}

void _expectFailure(
  String section,
  String message,
  void Function(Map<String, dynamic>) mutate,
) {
  final json = fixture();
  final value = json[section];
  final entity = value is List<dynamic>
      ? value.first as Map<String, dynamic>
      : value as Map<String, dynamic>;
  mutate(entity);
  _expectMessage(json, message);
}

void _expectMessage(Map<String, dynamic> json, String message) {
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
