'use strict';

window.addEventListener('load', function retireLegacyCacheOwnership() {
  if (!('serviceWorker' in navigator)) return;
  const scopeRoot = new URL('.', document.baseURI).href;
  navigator.serviceWorker.getRegistrations()
    .then((registrations) => Promise.allSettled(
      registrations
        .filter((registration) => registration.scope.startsWith(scopeRoot))
        .map((registration) => registration.unregister()),
    ))
    .then(() => {
      if (!('caches' in window)) return [];
      return window.caches.keys().then((names) => Promise.allSettled(
        names.map((name) => window.caches.open(name)
          .then((cache) => cache.keys())
          .then((requests) => {
            const belongsToPortfolio = requests.length > 0 &&
              requests.every((request) => request.url.startsWith(scopeRoot));
            return belongsToPortfolio ? window.caches.delete(name) : false;
          })),
      ));
    })
    .catch((error) => console.warn('Legacy cache cleanup was unavailable', error));
}, { once: true });
