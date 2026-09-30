import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_web_portfolio/app/data/dto/portfolio_document_mapper.dart';

void main() {
  _registerSelfOverlayTest();
  _registerLocaleCatalogTest();
  _registerOverlayFailureTests();
  _registerFieldCoverageTest();
}

Map<String, dynamic> _canonicalJson() =>
    jsonDecode(File('assets/content/portfolio.json').readAsStringSync())
        as Map<String, dynamic>;

void _registerSelfOverlayTest() {
  test('a complete self overlay preserves every model field', () {
    final raw = _canonicalJson();
    final document = parsePortfolioDocument(raw);

    expect(
      document.localized(_normalize(_selfOverlay(raw))).toJson(),
      document.toJson(),
    );
  });
}

void _registerLocaleCatalogTest() {
  test('every authored locale remains parseable', () {
    final document = parsePortfolioDocument(_canonicalJson());
    for (final locale in document.site.locales.where(
      (value) => value != 'en',
    )) {
      final overlay =
          jsonDecode(
                File('assets/content/locales/$locale.json').readAsStringSync(),
              )
              as Map<String, dynamic>;
      expect(
        document.localized(overlay).systems,
        hasLength(document.systems.length),
      );
    }
  });
}

void _registerOverlayFailureTests() {
  group('overlay validation', () {
    test('an absent overlay returns the same document', () {
      final document = parsePortfolioDocument(_canonicalJson());

      expect(identical(document.localized(null), document), isTrue);
      expect(identical(document.localized(const {}), document), isTrue);
    });

    test('rejects an unsupported overlay schema version', () {
      _expectOverlayFailure(
        (overlay) => overlay['schema_version'] = 2,
        'Unsupported portfolio localization schema version.',
      );
    });

    test('rejects the source locale and malformed locale codes', () {
      _expectOverlayFailure(
        (overlay) => overlay['locale'] = 'en',
        'Invalid translated portfolio locale: en',
      );
      _expectOverlayFailure(
        (overlay) => overlay['locale'] = 'tr-TR',
        'Invalid translated portfolio locale: tr-TR',
      );
    });

    test('rejects an evidence list of a different length', () {
      final systemId = (_canonicalJson()['systems']! as List<dynamic>)
          .cast<Map<String, dynamic>>()
          .first['id']!;
      _expectOverlayFailure(
        (overlay) =>
            (((overlay['systems']! as Map<String, dynamic>)[systemId]!
                        as Map<String, dynamic>)['evidence']!
                    as List<dynamic>)
                .removeLast(),
        'Localized evidence count does not match system "$systemId".',
      );
    });

    test('rejects an overlay that omits a declared entry', () {
      final experienceId = (_canonicalJson()['experience']! as List<dynamic>)
          .cast<Map<String, dynamic>>()
          .first['id']!;
      _expectOverlayFailure(
        (overlay) => (overlay['experience']! as Map<String, dynamic>).remove(
          experienceId,
        ),
        'Expected object at "$experienceId".',
      );
    });
  });
}

void _expectOverlayFailure(
  void Function(Map<String, dynamic> overlay) mutate,
  String message,
) {
  final raw = _canonicalJson();
  final document = parsePortfolioDocument(raw);
  final overlay = _normalize(_selfOverlay(raw));
  mutate(overlay);

  expect(
    () => document.localized(overlay),
    throwsA(
      isA<FormatException>().having(
        (error) => error.message,
        'message',
        message,
      ),
    ),
  );
}

void _registerFieldCoverageTest() {
  test('every field is carried by copyWith and toJson', () {
    const files = {
      'portfolio_document.dart',
      'site.dart',
      'profile.dart',
      'shared_value_types.dart',
      'experience.dart',
      'capability.dart',
      'contribution.dart',
      'system.dart',
      'artifact.dart',
    };
    for (final file in files) {
      final source = File('lib/app/domain/models/$file').readAsStringSync();
      final classes = RegExp(
        r'(?:(?:final|sealed) class|enum) (\w+)[^{]*\{',
      ).allMatches(source).toList();
      for (var index = 0; index < classes.length; index++) {
        final start = classes[index].end;
        final end = index + 1 < classes.length
            ? classes[index + 1].start
            : source.length;
        final body = source.substring(start, end);
        if (!body.contains(' copyWith(')) continue;
        final copyBody = body.substring(
          body.indexOf(' copyWith('),
          body.indexOf('Map<String, Object?> toJson()'),
        );
        final jsonBody = body.substring(body.indexOf('toJson()'));
        final className = classes[index].group(1)!;
        final fields = RegExp(
          r'^  final [^;]+ (\w+);$',
          multiLine: true,
        ).allMatches(body).map((match) => match.group(1)!);
        final inherited =
            className == 'PortfolioFeaturedSystem' ||
                className == 'PortfolioSupportingSystem'
            ? RegExp(r'^  final [^;]+ (\w+);$', multiLine: true)
                  .allMatches(
                    source.substring(classes.first.end, classes[1].start),
                  )
                  .map((match) => match.group(1)!)
            : <String>[];
        for (final field in {
          ...fields,
          ...inherited,
        }.where((name) => !name.startsWith('_'))) {
          final key = field.replaceAllMapped(
            RegExp(r'[A-Z]'),
            (match) => '_${match.group(0)!.toLowerCase()}',
          );
          expect(copyBody, contains('$field:'), reason: '$className.$field');
          expect(jsonBody, contains("'$key':"), reason: '$className.$field');
        }
      }
    }
  });
}

Map<String, dynamic> _normalize(Map<dynamic, dynamic> source) => {
  for (final entry in source.entries)
    entry.key as String: switch (entry.value) {
      final Map<dynamic, dynamic> map => _normalize(map),
      final List<dynamic> list => [
        for (final value in list)
          switch (value) {
            final Map<dynamic, dynamic> map => _normalize(map),
            _ => value,
          },
      ],
      final value => value,
    },
};

Map<String, dynamic> _selfOverlay(Map<String, dynamic> raw) {
  final site = raw['site']! as Map<String, dynamic>;
  final profile = raw['profile']! as Map<String, dynamic>;
  final contributions = _entries(raw, 'contributions');
  final systems = _entries(raw, 'systems');
  return {
    'schema_version': 1,
    'locale': 'tr',
    'site': {
      'title': site['title'],
      'description': site['description'],
      'social_description': site['social_description'],
      'engineering_links': {
        for (final link in (site['engineering_links']! as List<dynamic>))
          (link as Map<String, dynamic>)['id']: link['label'],
      },
    },
    'profile': {
      for (final key in [
        'role',
        'location',
        'headline',
        'summary',
        'background',
        'focus',
      ])
        key: profile[key],
      'links': {
        for (final link in (profile['links']! as List<dynamic>))
          (link as Map<String, dynamic>)['id']: link['label'],
      },
    },
    'experience': {
      for (final entry in (raw['experience']! as List<dynamic>))
        (entry as Map<String, dynamic>)['id']: {
          for (final key in ['role', 'domain', 'period', 'summary', 'evidence'])
            key: entry[key],
        },
    },
    'capabilities': {
      for (final entry in (raw['capabilities']! as List<dynamic>))
        (entry as Map<String, dynamic>)['id']: {
          'label': entry['label'],
          'items': entry['items'],
        },
    },
    'contributions': {
      for (final entry in contributions)
        entry['id']: {
          for (final key in ['title', 'problem', 'change']) key: entry[key],
          if (entry['event_order_lab'] case final Map<String, dynamic> lab)
            'event_order_lab': _labOverlay(lab),
        },
    },
    'systems': {
      for (final entry in systems) entry['id']: _systemOverlay(entry),
    },
  };
}

List<Map<String, dynamic>> _entries(Map<String, dynamic> raw, String key) =>
    (raw[key]! as List<dynamic>).cast<Map<String, dynamic>>();

Map<String, dynamic> _labOverlay(Map<String, dynamic> lab) {
  final baseline = lab['baseline']! as Map<String, dynamic>;
  final withPatch = lab['with_patch']! as Map<String, dynamic>;
  final gap = baseline['gap']! as Map<String, dynamic>;
  return {
    'title': lab['title'],
    'events': {
      for (final event in (lab['events']! as List<dynamic>))
        (event as Map<String, dynamic>)['id']: event['label'],
    },
    'baseline_summary': baseline['summary'],
    'with_patch_summary': withPatch['summary'],
    'gap_label': gap['label'],
  };
}

Map<String, dynamic> _systemOverlay(Map<String, dynamic> entry) {
  final artifact = entry['artifact']! as Map<String, dynamic>;
  return {
    for (final key in [
      'kind',
      'year',
      'technologies',
      'summary',
      'ownership',
      'decision',
    ])
      key: entry[key],
    if (entry['featured'] == true)
      for (final key in ['challenge', 'approach', 'outcome']) key: entry[key],
    if (entry['featured'] == false) 'spotlight': entry['spotlight'],
    'evidence': [
      for (final item in (entry['evidence']! as List<dynamic>))
        (item as Map<String, dynamic>)['label'],
    ],
    'artifact': {
      for (final key in ['label', 'alt', 'caption']) key: artifact[key],
      if (artifact['compact'] case final Map<String, dynamic> compact) ...{
        'compact_alt': compact['alt'],
        'compact_caption': compact['caption'],
      },
    },
  };
}
