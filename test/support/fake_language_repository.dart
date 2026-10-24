import 'dart:async';

import 'package:flutter_web_portfolio/app/domain/repositories/language_repository.dart';

/// Exposes the start and completion of one repository operation to a test.
final class FakeLanguageRepositoryGate {
  final Completer<void> _started = Completer<void>();
  final Completer<void> _released = Completer<void>();

  Future<void> get started => _started.future;
  bool get hasStarted => _started.isCompleted;

  Future<void> wait() {
    if (!_started.isCompleted) _started.complete();
    return _released.future;
  }

  void release() {
    if (!_released.isCompleted) _released.complete();
  }
}

final class FakeLanguageRepositoryBehavior {
  const FakeLanguageRepositoryBehavior({
    this.loadGates = const {},
    this.saveGates = const {},
    this.loadErrors = const {},
    this.saveError,
  });

  final Map<String, FakeLanguageRepositoryGate> loadGates;
  final Map<String, FakeLanguageRepositoryGate> saveGates;
  final Map<String, Object> loadErrors;
  final Object? saveError;
}

final class FakeLanguageRepository implements LanguageRepository {
  FakeLanguageRepository({
    this.selectedLanguage = 'en',
    this.supportedLanguages = const {'en'},
    this.documents = const {},
    this.behavior = const FakeLanguageRepositoryBehavior(),
  });

  String selectedLanguage;

  @override
  final Set<String> supportedLanguages;

  final Map<String, Map<String, dynamic>> documents;
  final FakeLanguageRepositoryBehavior behavior;
  final List<String> savedLanguages = [];
  final List<String> saveEvents = [];

  @override
  Future<String> getSelectedLanguage() async => selectedLanguage;

  @override
  Future<Map<String, dynamic>> getTranslations(String languageCode) async {
    final gate = behavior.loadGates[languageCode];
    if (gate != null) await gate.wait();
    final error = behavior.loadErrors[languageCode];
    if (error != null) throw error;
    return documents[languageCode] ?? const <String, dynamic>{};
  }

  @override
  Future<void> saveSelectedLanguage(String languageCode) async {
    saveEvents.add('start:$languageCode');
    final gate = behavior.saveGates[languageCode];
    if (gate != null) await gate.wait();
    final error = behavior.saveError;
    if (error != null) throw error;
    selectedLanguage = languageCode;
    savedLanguages.add(languageCode);
    saveEvents.add('finish:$languageCode');
  }
}
