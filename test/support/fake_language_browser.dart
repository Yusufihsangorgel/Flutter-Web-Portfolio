import 'package:flutter_web_portfolio/app/utils/language_browser.dart';

final class FakeLanguageBrowser implements LanguageBrowser {
  FakeLanguageBrowser({this.reloads = false});

  final bool reloads;
  final List<String?> reloadedSections = [];
  final List<String> documentLanguages = [];

  @override
  bool reloadForLanguageChange({String? preserveSection}) {
    reloadedSections.add(preserveSection);
    return reloads;
  }

  @override
  void setDocumentLanguage(String languageCode) {
    documentLanguages.add(languageCode);
  }
}
