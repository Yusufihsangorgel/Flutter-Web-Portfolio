'use strict';

(function selectBootstrapLocale() {
  const locales = window.__portfolioBootstrapLocales ?? {};
  let selected = 'en';
  try {
    const stored = window.localStorage.getItem('flutter.selected_language');
    if (stored !== null) {
      let decoded = stored;
      try { decoded = JSON.parse(stored); } catch (_) {}
      if (typeof decoded === 'string') selected = decoded;
    }
  } catch (_) {}
  if (!Object.prototype.hasOwnProperty.call(locales, selected)) selected = 'en';
  const locale = locales[selected];
  if (!locale) return;
  document.documentElement.lang = selected;
  document.documentElement.dir = locale.direction;
  document.title = locale.title;
  window.__portfolioBootstrapLocale = locale.copy;
  if (locale.fontHref) {
    const fontPreload = document.createElement('link');
    fontPreload.rel = 'preload';
    fontPreload.as = 'font';
    fontPreload.type = 'font/ttf';
    fontPreload.crossOrigin = 'anonymous';
    fontPreload.href = locale.fontHref;
    document.head.appendChild(fontPreload);
  }
  window.__applyPortfolioBootstrapLocale = () => {
    const shell = document.querySelector('#bootstrap-surface .bootstrap-shell');
    const surface = document.getElementById('bootstrap-surface');
    if (surface) surface.setAttribute('aria-label', locale.copy.loadingPortfolio);
    if (shell) shell.outerHTML = locale.markup;
  };
})();
