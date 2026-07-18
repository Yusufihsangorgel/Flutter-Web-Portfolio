import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_web_portfolio/app/domain/models/portfolio_document.dart';

void main() {
  final canonicalJson =
      jsonDecode(File('assets/content/portfolio.json').readAsStringSync())
          as Map<String, dynamic>;
  final canonical = PortfolioDocument.fromJson(canonicalJson);
  final expectedLocales = canonical.site.locales;

  group('portfolio localization catalog', () {
    test('advertises exactly the authored locale files', () {
      final localeDirectory = Directory('assets/content/locales');
      final localeFiles = <String>[
        if (localeDirectory.existsSync())
          ...localeDirectory
              .listSync()
              .whereType<File>()
              .where((file) => file.path.endsWith('.json'))
              .map(
                (file) => file.uri.pathSegments.last.replaceAll('.json', ''),
              ),
      ]..sort();
      final expectedFiles =
          expectedLocales.where((locale) => locale != 'en').toList()..sort();
      expect(localeFiles, expectedFiles);
    });

    test('every non-English locale is structurally complete and parseable', () {
      Object? referenceSchema;
      for (final locale in expectedLocales.where((entry) => entry != 'en')) {
        final file = File('assets/content/locales/$locale.json');
        expect(file.existsSync(), isTrue, reason: 'missing $locale catalog');
        final localization =
            jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
        final localized = canonical.localized(localization);

        referenceSchema ??= _schemaOf(localization);
        expect(
          _schemaOf(localization),
          referenceSchema,
          reason: '$locale must match the shared localization schema',
        );

        expect(localization['locale'], locale);
        expect(localization.keys.toSet(), {
          'schema_version',
          'locale',
          'site',
          'profile',
          'experience',
          'capabilities',
          'contributions',
          'systems',
        });
        final localizedSite = localization['site']! as Map<String, dynamic>;
        final localizedProfile =
            localization['profile']! as Map<String, dynamic>;
        expect(
          (localizedSite['engineering_links']! as Map<String, dynamic>).keys
              .toSet(),
          canonical.site.engineeringLinks.map((entry) => entry.id).toSet(),
        );
        expect(
          (localizedProfile['links']! as Map<String, dynamic>).keys.toSet(),
          canonical.profile.links.map((entry) => entry.id).toSet(),
        );
        expect(
          (localization['experience']! as Map<String, dynamic>).keys.toSet(),
          canonical.experience.map((entry) => entry.id).toSet(),
        );
        expect(
          (localization['capabilities']! as Map<String, dynamic>).keys.toSet(),
          canonical.capabilities.map((entry) => entry.id).toSet(),
        );
        expect(
          (localization['contributions']! as Map<String, dynamic>).keys.toSet(),
          canonical.contributions.map((entry) => entry.id).toSet(),
        );
        expect(
          (localization['systems']! as Map<String, dynamic>).keys.toSet(),
          canonical.systems.map((entry) => entry.id).toSet(),
        );
        expect(localized.activeSections, canonical.activeSections);
        expect(localized.profile.name, canonical.profile.name);
        expect(localized.profile.email, canonical.profile.email);
        expect(localized.site.title, isNot(canonical.site.title));
        expect(localized.site.description, isNot(canonical.site.description));
        expect(localized.profile.role, isNot(canonical.profile.role));
        expect(localized.profile.headline, isNot(canonical.profile.headline));
        expect(localized.experience.length, canonical.experience.length);
        expect(localized.contributions.length, canonical.contributions.length);
        expect(localized.systems.length, canonical.systems.length);
        for (var index = 0; index < canonical.experience.length; index++) {
          expect(
            localized.experience[index].summary,
            isNot(canonical.experience[index].summary),
            reason: '$locale experience ${canonical.experience[index].id}',
          );
        }
        for (var index = 0; index < canonical.contributions.length; index++) {
          expect(
            localized.contributions[index].title,
            isNot(canonical.contributions[index].title),
            reason: '$locale contribution ${canonical.contributions[index].id}',
          );
        }
        for (var index = 0; index < canonical.systems.length; index++) {
          expect(
            localized.systems[index].kind,
            isNot(canonical.systems[index].kind),
            reason: '$locale system kind ${canonical.systems[index].id}',
          );
          expect(
            localized.systems[index].artifact.alt,
            isNot(canonical.systems[index].artifact.alt),
            reason: '$locale artifact alt ${canonical.systems[index].id}',
          );
          expect(
            localized.systems[index].artifact.caption,
            isNot(canonical.systems[index].artifact.caption),
            reason: '$locale artifact caption ${canonical.systems[index].id}',
          );
        }
      }
    });

    test('partial locale documents fail instead of mixing languages', () {
      expect(
        () => canonical.localized({
          'schema_version': 1,
          'locale': 'tr',
          'site': <String, dynamic>{},
        }),
        throwsFormatException,
      );
    });
  });
}

Object _schemaOf(Object? value) => switch (value) {
  final Map<String, dynamic> map => {
    for (final entry in map.entries) entry.key: _schemaOf(entry.value),
  },
  final List<Object?> list => {
    'length': list.length,
    'list': (list.map(_schemaOf).map(jsonEncode).toSet().toList()..sort()),
  },
  String _ => 'string',
  num _ => 'number',
  bool _ => 'boolean',
  null => 'null',
  _ => value.runtimeType.toString(),
};
