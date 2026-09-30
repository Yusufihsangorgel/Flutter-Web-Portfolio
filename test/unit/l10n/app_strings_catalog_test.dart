import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  final english = _flatten(_readJson('assets/i18n/en.json'));

  test('every interface catalog has the English keys and placeholders', () {
    final locales = _catalogLocales();
    expect(locales, ['ar', 'de', 'en', 'es', 'fr', 'hi', 'tr']);
    expect(
      locales,
      containsAll(_siteLocales()),
      reason: 'a locale advertised in portfolio.json has no interface catalog',
    );

    for (final locale in locales) {
      final translated = _flatten(_readJson('assets/i18n/$locale.json'));
      final keys = translated.keys.toSet();
      expect(
        english.keys.toSet().difference(keys),
        isEmpty,
        reason: '$locale is missing keys',
      );
      expect(
        keys.difference(english.keys.toSet()),
        isEmpty,
        reason: '$locale has keys English does not',
      );
      for (final key in english.keys) {
        expect(
          _placeholders(translated[key]!),
          _placeholders(english[key]!),
          reason: '$locale: $key',
        );
      }
    }
  });

  test('every literal getText key in lib exists in English', () {
    final calls = RegExp(r'''\bgetText\(\s*['"]([^'"]+)['"]''');
    final dartFiles = Directory('lib')
        .listSync(recursive: true)
        .whereType<File>()
        .where((file) => file.path.endsWith('.dart'));
    var scannedCalls = 0;
    for (final file in dartFiles) {
      for (final match in calls.allMatches(file.readAsStringSync())) {
        if (match.group(1)!.contains(r'$')) continue;
        scannedCalls++;
        expect(english, contains(match.group(1)), reason: file.path);
      }
    }
    expect(scannedCalls, greaterThan(0));
  });
}

Map<String, dynamic> _readJson(String path) =>
    jsonDecode(File(path).readAsStringSync()) as Map<String, dynamic>;

List<String> _catalogLocales() => [
  for (final file in Directory('assets/i18n').listSync().whereType<File>())
    if (file.path.endsWith('.json'))
      file.uri.pathSegments.last.replaceAll('.json', ''),
]..sort();

Set<String> _siteLocales() {
  if (_readJson('assets/content/portfolio.json') case {
    'site': {'locales': final List<Object?> locales},
  }) {
    return locales.whereType<String>().toSet();
  }
  throw const FormatException('portfolio.json has no site.locales list');
}

Map<String, String> _flatten(
  Map<String, dynamic> document, [
  String prefix = '',
]) {
  final values = <String, String>{};
  for (final entry in document.entries) {
    final key = prefix.isEmpty ? entry.key : '$prefix.${entry.key}';
    if (entry.value case final Map<String, dynamic> nested) {
      values.addAll(_flatten(nested, key));
    } else if (entry.value case final String value) {
      values[key] = value;
    } else {
      throw FormatException('Interface string is not text: $key');
    }
  }
  return values;
}

Set<String> _placeholders(String value) => RegExp(
  r'\{([a-zA-Z_][a-zA-Z_0-9]*)\}',
).allMatches(value).map((match) => match.group(1)!).toSet();
