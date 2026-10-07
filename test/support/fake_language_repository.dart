import 'package:flutter_web_portfolio/app/domain/repositories/language_repository.dart';

final class FakeLanguageRepositoryBehavior {
  const FakeLanguageRepositoryBehavior({
    this.loadDelays = const {},
    this.saveDelays = const {},
    this.loadErrors = const {},
    this.saveError,
  });

  final Map<String, Duration> loadDelays;
  final Map<String, Duration> saveDelays;
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

  @override
  Future<String> getSelectedLanguage() async => selectedLanguage;

  @override
  Future<Map<String, dynamic>> getTranslations(String languageCode) async {
    final delay = behavior.loadDelays[languageCode];
    if (delay != null) await Future<void>.delayed(delay);
    final error = behavior.loadErrors[languageCode];
    if (error != null) throw error;
    return documents[languageCode] ?? const <String, dynamic>{};
  }

  @override
  Future<void> saveSelectedLanguage(String languageCode) async {
    final delay = behavior.saveDelays[languageCode];
    if (delay != null) await Future<void>.delayed(delay);
    final error = behavior.saveError;
    if (error != null) throw error;
    selectedLanguage = languageCode;
    savedLanguages.add(languageCode);
  }
}
