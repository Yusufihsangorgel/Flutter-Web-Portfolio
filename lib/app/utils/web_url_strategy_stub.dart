// Stub implementation for non-web platforms — all operations are no-ops.

/// Returns the current URL hash fragment (without leading `#`), or empty string.
String getUrlHash() => '';

/// Replaces the browser URL hash without triggering a page reload.
void setUrlHash(String hash) {}

/// Native targets do not persist a section across document reloads.
String takeReloadSection() => '';

/// No-op on non-web platforms.
void setHtmlLang(String languageCode) {}

/// No-op outside a browser.
void reloadPage() {}

/// Native targets can safely rebuild the locale without restarting.
bool reloadPageForLanguageChange({String? preserveSection}) => false;

/// Registers a listener that fires when the browser navigates back/forward.
/// Returns a dispose callback.
void Function() onPopState(void Function(String hash) callback) => () {};
