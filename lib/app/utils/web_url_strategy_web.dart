import 'dart:js_interop';
import 'package:web/web.dart' as web;

const _reloadSectionKey = 'render_atlas_reload_section';

/// Returns the language already selected by the critical HTML shell.
String getHtmlLanguage() =>
    web.document.documentElement?.getAttribute('lang') ?? 'en';

/// Reads the chapter identifier from the URL fragment.
String getUrlHash() {
  final raw = web.window.location.hash;
  if (raw.isEmpty) return '';
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

/// Aligns document language and direction with the active locale.
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

/// Reloads the document after a locale change.
bool reloadPageForLanguageChange({String? preserveSection}) {
  if (preserveSection != null && preserveSection.isNotEmpty) {
    web.window.sessionStorage.setItem(_reloadSectionKey, preserveSection);
  }
  web.window.location.reload();
  return true;
}

var _inPageLinkClicksIntercepted = false;

/// Preserves browser gestures on in-page links.
void interceptInPageLinkClicks() {
  if (_inPageLinkClicksIntercepted) return;
  _inPageLinkClicksIntercepted = true;
  web.window.addEventListener(
    'click',
    ((web.MouseEvent event) {
      final target = event.target;
      if (target == null || !target.isA<web.Element>()) return;
      final anchor = (target as web.Element).closest(
        'flt-semantics-host a[href^="#/"]',
      );
      if (anchor == null) return;
      if (event.ctrlKey || event.metaKey || event.shiftKey || event.altKey) {
        event.stopPropagation();
      } else {
        event.preventDefault();
      }
    }).toJS,
    true.toJS,
  );
}

/// Subscribes to chapter history navigation.
void Function() onPopState(void Function(String hash) callback) {
  void handler(web.Event event) {
    callback(getUrlHash());
  }

  final jsHandler = handler.toJS;
  web.window.addEventListener('portfolio-popstate', jsHandler);
  return () => web.window.removeEventListener('portfolio-popstate', jsHandler);
}
