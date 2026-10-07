'use strict';

const staticDocument = document.getElementById('static-document');
const bootstrapSurface = document.getElementById('bootstrap-surface');
if (staticDocument && bootstrapSurface) {
  const observer = new MutationObserver(() => {
    if (bootstrapSurface.isConnected) return;
    staticDocument.hidden = true;
    staticDocument.inert = true;
    observer.disconnect();
  });
  observer.observe(document.body, { childList: true });
}
