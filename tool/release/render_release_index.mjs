export function renderReleaseIndex(index, shell, staticDocument) {
  const shellMarker = /\s*<!-- bootstrap-content:start -->[\s\S]*?<!-- bootstrap-content:end -->/;
  const documentMarker = /<!-- static-document:start -->[\s\S]*?<!-- static-document:end -->/;
  if (!shellMarker.test(index) || !documentMarker.test(index)) {
    throw new Error('index.html is missing release content markers');
  }
  const shellBlock = `    <!-- bootstrap-content:start -->\n${shell}\n    <!-- bootstrap-content:end -->`;
  const documentBlock = `<!-- static-document:start -->\n${staticDocument}\n  <!-- static-document:end -->`;
  return index.replace(shellMarker, `\n${shellBlock}`)
    .replace(documentMarker, documentBlock);
}

export function renderLocaleData(locales) {
  const json = JSON.stringify(locales).replace(/[<>&\u2028\u2029]/g, (character) => ({
    '<': '\\u003c', '>': '\\u003e', '&': '\\u0026',
    '\u2028': '\\u2028', '\u2029': '\\u2029',
  })[character]);
  return `window.__portfolioBootstrapLocales = ${json};\n`;
}
