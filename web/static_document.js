'use strict';

const staticDocument = document.getElementById('static-document');
const bootstrapSurface = document.getElementById('bootstrap-surface');
if (staticDocument && bootstrapSurface) {
  staticDocument.lang = 'en';
  staticDocument.dir = 'ltr';
  let failed = false;
  const observer = new MutationObserver(() => {
    if (bootstrapSurface.isConnected) return;
    staticDocument.hidden = true;
    staticDocument.inert = true;
    observer.disconnect();
  });
  observer.observe(document.body, { childList: true });

  const showBootstrapFailure = () => {
    if (failed) return;
    failed = true;
    observer.disconnect();
    window.performance?.mark('flutter-bootstrap-failed');
    const copy = window.__portfolioBootstrapLocale ?? {
      loadFailure: 'The portfolio could not load. Please try again.',
      retry: 'Retry',
    };
    staticDocument.hidden = false;
    staticDocument.inert = false;
    document.documentElement.classList.add('bootstrap-failed');
    bootstrapSurface.classList.remove('bootstrap-surface--done');
    bootstrapSurface.setAttribute('aria-busy', 'false');
    bootstrapSurface.removeAttribute('role');
    bootstrapSurface.removeAttribute('aria-label');
    const status = document.createElement('div');
    status.className = 'bootstrap-error';
    status.setAttribute('role', 'alert');
    status.textContent = copy.loadFailure;
    const retry = document.createElement('button');
    retry.type = 'button';
    retry.className = 'bootstrap-retry';
    retry.textContent = copy.retry;
    retry.addEventListener('click', () => window.location.reload());
    status.appendChild(retry);
    bootstrapSurface.replaceChildren(status);
    staticDocument.before(bootstrapSurface);
  };
  document.addEventListener('portfolio-bootstrap-failed', showBootstrapFailure);

  // A missing or invalid bootstrap script never reaches its own catch handler.
  const bootstrapUrl = new URL('flutter_bootstrap.js', document.baseURI).href;
  const stopWatching = () => {
    window.removeEventListener('error', onScriptError, true);
    document.removeEventListener('load', onScriptLoad, true);
  };
  const onScriptError = (event) => {
    if (
      (event.target instanceof HTMLScriptElement && event.target.src === bootstrapUrl) ||
      (event instanceof ErrorEvent && event.filename === bootstrapUrl)
    ) {
      showBootstrapFailure();
      stopWatching();
    }
  };
  const onScriptLoad = (event) => {
    if (event.target instanceof HTMLScriptElement && event.target.src === bootstrapUrl) {
      stopWatching();
    }
  };
  window.addEventListener('error', onScriptError, true);
  document.addEventListener('load', onScriptLoad, true);
}
