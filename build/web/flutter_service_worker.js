'use strict';

self.addEventListener('install', (event) => {
  self.skipWaiting();
});

self.addEventListener('activate', (event) => {
  event.waitUntil((async () => {
    await self.registration.unregister();
    const names = await caches.keys();
    await Promise.all(names.map((name) => caches.delete(name)));
  })());
});
