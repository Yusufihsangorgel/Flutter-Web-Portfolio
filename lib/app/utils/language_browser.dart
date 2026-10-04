import 'package:flutter_web_portfolio/app/utils/web_url_strategy.dart'
    as url_strategy;

abstract interface class LanguageBrowser {
  bool reloadForLanguageChange({String? preserveSection});
  void setDocumentLanguage(String languageCode);
}

final class WebLanguageBrowser implements LanguageBrowser {
  const WebLanguageBrowser();

  @override
  bool reloadForLanguageChange({String? preserveSection}) => url_strategy
      .reloadPageForLanguageChange(preserveSection: preserveSection);

  @override
  void setDocumentLanguage(String languageCode) =>
      url_strategy.setHtmlLang(languageCode);
}
