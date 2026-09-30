import 'package:flutter_web_portfolio/app/utils/web_url_strategy.dart' as url;

/// The URL hash and history entries of the page, abstracted for tests.
abstract interface class BrowserHistory {
  String get hash;
  String takeReloadSection();
  void pushHash(String section);
  void replaceHash(String section);
  void Function() onPopState(void Function(String hash) callback);
}

/// [BrowserHistory] backed by the page's location and history.
final class WebBrowserHistory implements BrowserHistory {
  const WebBrowserHistory();

  @override
  String get hash => url.getUrlHash();

  @override
  String takeReloadSection() => url.takeReloadSection();

  @override
  void pushHash(String section) => url.pushUrlHash(section);

  @override
  void replaceHash(String section) => url.replaceUrlHash(section);

  @override
  void Function() onPopState(void Function(String hash) callback) =>
      url.onPopState(callback);
}

/// [BrowserHistory] for platforms without a browser.
final class StubBrowserHistory implements BrowserHistory {
  const StubBrowserHistory();

  @override
  String get hash => '';

  @override
  String takeReloadSection() => '';

  @override
  void pushHash(String section) {}

  @override
  void replaceHash(String section) {}

  @override
  void Function() onPopState(void Function(String hash) callback) => () {};
}
