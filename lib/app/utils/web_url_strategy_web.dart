import 'dart:js_interop';
import 'package:web/web.dart' as web;

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

/// Updates the `<html lang="...">` attribute so the document language tracks
/// the app locale. Keeps screen readers and SEO happy.
void setHtmlLang(String languageCode) {
  if (languageCode.isEmpty) return;
  web.document.documentElement?.setAttribute('lang', languageCode);
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
