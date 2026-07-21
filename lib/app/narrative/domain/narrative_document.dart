import 'package:flutter/foundation.dart';

/// Typed identity for a chapter in the single-page narrative.
extension type const SectionId(String value) {
  static const home = SectionId('home');
  static const about = SectionId('about');
  static const experience = SectionId('experience');
  static const proof = SectionId('proof');
  static const projects = SectionId('projects');
  static const packages = SectionId('packages');

  bool get isHome => this == home;
}

/// The one visual idea carried by a chapter of the engineering trace.
enum NarrativeMotif {
  origin,
  thread,
  timeline,
  branches,
  bracket;

  static NarrativeMotif parse(String value) => switch (value) {
    'origin' => origin,
    'thread' => thread,
    'timeline' => timeline,
    'branches' => branches,
    'bracket' => bracket,
    _ => throw FormatException('Unsupported narrative motif: $value'),
  };
}

@immutable
final class NarrativeChapter {
  const NarrativeChapter({required this.id, required this.motif});

  factory NarrativeChapter.fromJson(Map<String, dynamic> json) =>
      NarrativeChapter(
        id: SectionId(_requiredString(json, 'id')),
        motif: NarrativeMotif.parse(_requiredString(json, 'motif')),
      );

  final SectionId id;
  final NarrativeMotif motif;
}

/// Immutable presentation contract for the portfolio's continuous story.
///
/// It intentionally contains no biographical or project copy. Content stays
/// in the portfolio document, while this asset owns order and visual rhythm.
@immutable
final class NarrativeDocument {
  NarrativeDocument._({
    required this.schemaVersion,
    required this.id,
    required List<NarrativeChapter> chapters,
  }) : chapters = List.unmodifiable(chapters) {
    _validate();
  }

  factory NarrativeDocument.fromJson(Map<String, dynamic> json) {
    final schemaVersion = _requiredInt(json, 'schema_version');
    if (schemaVersion != 1) {
      throw FormatException(
        'Unsupported narrative schema version: $schemaVersion',
      );
    }
    final rawChapters = json['chapters'];
    if (rawChapters is! List<dynamic>) {
      throw const FormatException('Narrative chapters must be a JSON array.');
    }
    return NarrativeDocument._(
      schemaVersion: schemaVersion,
      id: _requiredString(json, 'id'),
      chapters: rawChapters
          .map((entry) {
            if (entry is! Map<String, dynamic>) {
              throw const FormatException(
                'Every narrative chapter must be a JSON object.',
              );
            }
            return NarrativeChapter.fromJson(entry);
          })
          .toList(growable: false),
    );
  }

  final int schemaVersion;
  final String id;
  final List<NarrativeChapter> chapters;

  List<SectionId> get sectionIds =>
      chapters.map((chapter) => chapter.id).toList(growable: false);

  NarrativeChapter chapterFor(SectionId sectionId) => chapters.firstWhere(
    (chapter) => chapter.id == sectionId,
    orElse: () => throw ArgumentError.value(
      sectionId.value,
      'sectionId',
      'is not declared by the narrative',
    ),
  );

  /// One-based editorial number in the configured presentation order.
  ///
  /// Home is the unnumbered origin; omitted optional chapters never leave a
  /// gap in the visible sequence.
  String sectionNumber(SectionId sectionId) {
    final visible = sectionIds
        .where((candidate) => !candidate.isHome)
        .toList(growable: false);
    final index = visible.indexOf(sectionId);
    if (index < 0) {
      throw ArgumentError.value(
        sectionId.value,
        'sectionId',
        'is not a numbered narrative chapter',
      );
    }
    return '${index + 1}'.padLeft(2, '0');
  }

  /// Selects the chapters that exist in the current content document.
  ///
  /// Every content section must be declared exactly once by the presentation
  /// asset. Presentation may declare optional chapters whose content is empty;
  /// those chapters are omitted without changing the remaining order.
  NarrativeDocument forActiveSections(Iterable<String> activeSections) {
    final requested = activeSections.map(SectionId.new).toSet();
    final declared = sectionIds.toSet();
    final missing = requested.difference(declared);
    if (missing.isNotEmpty) {
      throw FormatException(
        'Narrative does not declare active sections: '
        '${missing.map((section) => section.value).join(', ')}',
      );
    }
    final selected = chapters
        .where((chapter) => requested.contains(chapter.id))
        .toList(growable: false);
    if (selected.length != requested.length) {
      throw const FormatException(
        'Narrative and portfolio sections could not be reconciled.',
      );
    }
    return NarrativeDocument._(
      schemaVersion: schemaVersion,
      id: id,
      chapters: selected,
    );
  }

  void _validate() {
    if (id.trim().isEmpty || chapters.isEmpty) {
      throw const FormatException(
        'Narrative id and chapters must not be empty.',
      );
    }
    if (!chapters.first.id.isHome ||
        chapters.first.motif != NarrativeMotif.origin) {
      throw const FormatException(
        'The narrative must begin with the home origin chapter.',
      );
    }
    final uniqueIds = chapters.map((chapter) => chapter.id).toSet();
    if (uniqueIds.length != chapters.length) {
      throw const FormatException('Narrative section ids must be unique.');
    }
    for (final chapter in chapters) {
      if (chapter.id.value.trim().isEmpty) {
        throw const FormatException('Narrative section ids must not be empty.');
      }
    }
  }
}

String _requiredString(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is! String || value.trim().isEmpty) {
    throw FormatException('Narrative field "$key" must be a string.');
  }
  return value.trim();
}

int _requiredInt(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is! int) {
    throw FormatException('Narrative field "$key" must be an integer.');
  }
  return value;
}
