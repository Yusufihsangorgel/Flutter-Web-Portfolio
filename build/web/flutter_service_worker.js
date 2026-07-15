'use strict';

self.addEventListener('install', (event) => {
  self.skipWaiting();
});

self.addEventListener('activate', (event) => {
  event.waitUntil((async () => {
    const scope = self.registration.scope;
    const names = await caches.keys();
    await Promise.all(names.map(async (name) => {
      const cache = await caches.open(name);
      const requests = await cache.keys();
      if (
        requests.length > 0 &&
        requests.every((request) => request.url.startsWith(scope))
      ) {
        await caches.delete(name);
      }
    }));
    await self.registration.unregister();
  })());
});
