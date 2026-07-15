import 'dart:convert';
import 'dart:io';

import 'package:flutter_web_portfolio/app/narrative/domain/narrative_document.dart';

NarrativeDocument loadNarrativeFixture({
  Iterable<String>? activeSections,
  void Function(Map<String, dynamic> json)? mutate,
}) {
  final json =
      jsonDecode(File('assets/presentation/narrative.json').readAsStringSync())
          as Map<String, dynamic>;
  mutate?.call(json);
  final narrative = NarrativeDocument.fromJson(json);
  return activeSections == null
      ? narrative
      : narrative.forActiveSections(activeSections);
}
