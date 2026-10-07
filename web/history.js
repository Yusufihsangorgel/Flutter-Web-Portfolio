'use strict';

document.documentElement.classList.add('js');
if (!history.state || history.state.flutter !== true) {
  history.replaceState({ flutter: true }, 'flutter', location.href);
}

// Modified in-page clicks open a new tab; hide them from engine tap handling.
const inPageAnchorSelector = 'flt-semantics-host a[href^="#/"]';
function modifiedInPageGesture(event) {
  if (!event.ctrlKey && !event.metaKey && !event.shiftKey && !event.altKey) {
    return false;
  }
  const target = event.target;
  if (!(target instanceof Element)) return false;
  return target.closest(inPageAnchorSelector) !== null;
}
for (const type of ['pointerdown', 'click']) {
  window.addEventListener(
    type,
    (event) => {
      if (modifiedInPageGesture(event)) {
        event.stopPropagation();
      }
    },
    true,
  );
}

let restoringHistoryAfterModal = false;
window.addEventListener('popstate', (event) => {
  if (restoringHistoryAfterModal) {
    restoringHistoryAfterModal = false;
    event.stopImmediatePropagation();
    return;
  }
  const transientOverlayOpen = document.documentElement.getAttribute(
    'data-portfolio-transient-overlay',
  ) === 'true';
  if (transientOverlayOpen) {
    event.stopImmediatePropagation();
    restoringHistoryAfterModal = true;
    window.dispatchEvent(new KeyboardEvent('keydown', {
      key: 'Escape', code: 'Escape', bubbles: true,
    }));
    window.dispatchEvent(new KeyboardEvent('keyup', {
      key: 'Escape', code: 'Escape', bubbles: true,
    }));
    window.setTimeout(() => window.history.forward(), 120);
    return;
  }
  event.stopImmediatePropagation();
  window.dispatchEvent(new Event('portfolio-popstate'));
}, true);
