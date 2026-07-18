import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_web_portfolio/app/narrative/domain/narrative_document.dart';

void main() {
  Map<String, dynamic> fixture() =>
      jsonDecode(File('assets/presentation/narrative.json').readAsStringSync())
          as Map<String, dynamic>;

  Set<String> templateIdentityMarkers() {
    final professional =
        jsonDecode(File('assets/content/portfolio.json').readAsStringSync())
            as Map<String, dynamic>;
    final markers = <String>{};
    const generic = {
      'flutter',
      'github',
      'linkedin',
      'medium',
      'portfolio',
      'software',
      'website',
    };

    void add(Object? value) {
      if (value is! String) return;
      final normalized = value.trim().toLowerCase();
      if (normalized.length >= 4 && !generic.contains(normalized)) {
        markers.add(normalized);
      }
    }

    void addWords(Object? value) {
      add(value);
      if (value is! String) return;
      for (final word in value.split(RegExp(r'[\s\-_/]+'))) {
        add(word);
      }
    }

    final profile = professional['profile']! as Map<String, dynamic>;
    addWords(profile['name']);
    add((profile['email'] as String?)?.split('@').first);
    for (final experience in professional['experience']! as List<dynamic>) {
      add((experience as Map<String, dynamic>)['company']);
    }
    for (final system in professional['systems']! as List<dynamic>) {
      final record = system as Map<String, dynamic>;
      if (record['id'] != 'portfolio') add(record['name']);
    }
    return markers;
  }

  group('NarrativeDocument', () {
    test('loads the generic presentation asset in editorial order', () {
      final document = NarrativeDocument.fromJson(fixture());

      expect(document.schemaVersion, 1);
      expect(document.sectionIds.map((section) => section.value), [
        'home',
        'experience',
        'proof',
        'projects',
        'about',
      ]);
      expect(document.chapters.map((chapter) => chapter.motif), const [
        NarrativeMotif.origin,
        NarrativeMotif.timeline,
        NarrativeMotif.branches,
        NarrativeMotif.bracket,
        NarrativeMotif.thread,
      ]);
    });

    test('presentation data contains no personal or project copy', () {
      final encoded = jsonEncode(fixture()).toLowerCase();

      for (final disallowed in templateIdentityMarkers()) {
        expect(encoded, isNot(contains(disallowed)));
      }
    });

    test('filters absent optional chapters without reordering the rest', () {
      final document = NarrativeDocument.fromJson(
        fixture(),
      ).forActiveSections(const ['home', 'about', 'proof', 'projects']);

      expect(document.sectionIds.map((section) => section.value), [
        'home',
        'proof',
        'projects',
        'about',
      ]);
      expect(
        document.chapterFor(SectionId.proof).motif,
        NarrativeMotif.branches,
      );
      expect(document.sectionNumber(SectionId.proof), '01');
      expect(document.sectionNumber(SectionId.projects), '02');
      expect(document.sectionNumber(SectionId.about), '03');
      expect(
        () => document.sectionNumber(SectionId.experience),
        throwsArgumentError,
      );
    });

    test('rejects an active content chapter missing from presentation', () {
      final document = NarrativeDocument.fromJson(fixture());

      expect(
        () => document.forActiveSections(const ['home', 'writing']),
        throwsFormatException,
      );
    });

    test('rejects duplicate chapter identities', () {
      final json = fixture();
      final chapters = json['chapters']! as List<dynamic>;
      chapters.add(Map<String, dynamic>.from(chapters.last as Map));

      expect(() => NarrativeDocument.fromJson(json), throwsFormatException);
    });

    test('requires the narrative to start at the origin', () {
      final json = fixture();
      final chapters = json['chapters']! as List<dynamic>;
      (chapters.first as Map<String, dynamic>)['motif'] = 'thread';

      expect(() => NarrativeDocument.fromJson(json), throwsFormatException);
    });
  });
}
