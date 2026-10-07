/// Native bootstrap failures use the English fallback copy.
String getHtmlLanguage() => 'en';

/// Returns the current URL hash fragment (without leading `#`), or empty string.
String getUrlHash() => '';

/// No-op outside a browser.
void pushUrlHash(String hash) {}

/// No-op outside a browser.
void replaceUrlHash(String hash) {}

/// Native targets do not persist a section across document reloads.
String takeReloadSection() => '';

/// No-op on non-web platforms.
void setHtmlLang(String languageCode) {}

/// No-op outside a browser.
void setTransientOverlayOpen(bool open) {}

/// No-op outside a browser.
void reloadPage() {}

/// Native targets can safely rebuild the locale without restarting.
bool reloadPageForLanguageChange({String? preserveSection}) => false;

/// No-op outside a browser.
void interceptInPageLinkClicks() {}

/// Returns an inactive browser history listener.
void Function() onPopState(void Function(String hash) callback) => () {};
