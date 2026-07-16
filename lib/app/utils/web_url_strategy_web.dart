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

/// Pushes an explicit chapter navigation into browser history.
void pushUrlHash(String hash) {
  web.window.history.pushState(null, '', _urlForHash(hash));
}

/// Synchronises passive reading progress without creating a history entry.
void replaceUrlHash(String hash) {
  web.window.history.replaceState(null, '', _urlForHash(hash));
}

String _urlForHash(String hash) {
  final normalised = (hash.isEmpty || hash == 'home') ? '' : hash;
  return normalised.isEmpty ? '#/' : '#/$normalised';
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

/// Exposes transient Navigator overlays to the document-level history bridge.
void setTransientOverlayOpen(bool open) {
  final root = web.document.documentElement;
  if (open) {
    root?.setAttribute('data-portfolio-transient-overlay', 'true');
  } else {
    root?.removeAttribute('data-portfolio-transient-overlay');
  }
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
  void handler(web.Event event) {
    callback(getUrlHash());
  }

  final jsHandler = handler.toJS;
  web.window.addEventListener('portfolio-popstate', jsHandler);
  return () => web.window.removeEventListener('portfolio-popstate', jsHandler);
}
