import 'dart:js_interop';
import 'package:web/web.dart' as web;

const _reloadSectionKey = 'render_atlas_reload_section';

/// Returns the URL hash fragment without leading `#` or `#/`.
///
/// Examples:
///   `#/about`  -> `about`
///   `#about`   -> `about`
///   `#/`       -> ``
///   (empty)    -> ``
String getUrlHash() {
  final raw = web.window.location.hash;
  if (raw.isEmpty) return '';
  // Strip leading '#', then optional leading '/'
  var hash = raw.startsWith('#') ? raw.substring(1) : raw;
  if (hash.startsWith('/')) hash = hash.substring(1);
  return hash;
}

/// Pushes a new browser history entry with the given hash.
///
/// If [hash] is empty or 'home', sets the URL to `#/` (root).
/// Otherwise sets it to `#/<hash>` (e.g. `#/about`).
void setUrlHash(String hash) {
  final normalised = (hash.isEmpty || hash == 'home') ? '' : hash;
  final url = normalised.isEmpty ? '#/' : '#/$normalised';
  web.window.history.pushState(null, '', url);
}

/// Returns and clears the section captured immediately before a web reload.
String takeReloadSection() {
  final section = web.window.sessionStorage.getItem(_reloadSectionKey) ?? '';
  web.window.sessionStorage.removeItem(_reloadSectionKey);
  return section;
}

/// Keeps the root document language and writing direction aligned with the
/// active application locale for assistive technology and browser tooling.
void setHtmlLang(String languageCode) {
  if (languageCode.isEmpty) return;
  web.document.documentElement
    ?..setAttribute('lang', languageCode)
    ..setAttribute('dir', languageCode == 'ar' ? 'rtl' : 'ltr');
}

/// Reloads the current document after an unrecoverable bootstrap failure.
void reloadPage() => web.window.location.reload();

/// Restarts the web renderer after a persisted user locale change.
///
/// Returns `true` so shared application code can stop the in-process locale
/// rebuild while the browser navigation takes over.
bool reloadPageForLanguageChange({String? preserveSection}) {
  if (preserveSection != null && preserveSection.isNotEmpty) {
    web.window.sessionStorage.setItem(_reloadSectionKey, preserveSection);
  }
  web.window.location.reload();
  return true;
}

/// Registers a listener for browser back/forward navigation.
///
/// Returns a dispose function that removes the listener.
void Function() onPopState(void Function(String hash) callback) {
  void handler(web.PopStateEvent event) {
    callback(getUrlHash());
  }

  final jsHandler = handler.toJS;
  web.window.addEventListener('popstate', jsHandler);
  return () => web.window.removeEventListener('popstate', jsHandler);
}
