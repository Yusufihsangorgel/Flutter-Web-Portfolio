import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  final catalog = _loadCatalog();

  group('translation catalog', () {
    test('all locale documents share the English schema', () {
      final reference = _schemaOf(catalog['en']!);

      for (final entry in catalog.entries) {
        expect(
          _schemaOf(entry.value),
          reference,
          reason: '${entry.key}.json must match the English key schema',
        );
      }
    });

    test('locale files contain interface copy, not portfolio records', () {
      const retiredTopLevelKeys = {
        'blog_section',
        'contact_section',
        'sidebar',
        'social_links',
        'cv_data',
      };
      const retiredNavigationKeys = {'blog', 'contact', 'skills'};
      const contentKeys = {'bio', 'bio2', 'subtitle', 'verification_body'};

      for (final entry in catalog.entries) {
        final document = entry.value;
        final navigation = document['nav']! as Map<String, dynamic>;

        expect(document.keys, isNot(contains(anyOf(retiredTopLevelKeys))));
        expect(navigation.keys, isNot(contains(anyOf(retiredNavigationKeys))));
        for (final section in [
          document['about_section'],
          document['home_section'],
          document['projects_section'],
          document['proof_section'],
          document['footer'],
        ].whereType<Map<String, dynamic>>()) {
          expect(section.keys, isNot(contains(anyOf(contentKeys))));
        }
      }
    });
  });
}

Map<String, Map<String, dynamic>> _loadCatalog() {
  final files =
      Directory('assets/i18n')
          .listSync()
          .whereType<File>()
          .where((file) => file.path.endsWith('.json'))
          .toList()
        ..sort((left, right) => left.path.compareTo(right.path));

  return {
    for (final file in files)
      file.uri.pathSegments.last.replaceAll('.json', ''):
          jsonDecode(file.readAsStringSync()) as Map<String, dynamic>,
  };
}

Object _schemaOf(Object? value) => switch (value) {
  final Map<String, dynamic> map => {
    for (final entry in map.entries) entry.key: _schemaOf(entry.value),
  },
  final List<Object?> list => {
    'list': (list.map(_schemaOf).map(jsonEncode).toSet().toList()..sort()),
  },
  String _ => 'string',
  num _ => 'number',
  bool _ => 'boolean',
  null => 'null',
  _ => value.runtimeType.toString(),
};
