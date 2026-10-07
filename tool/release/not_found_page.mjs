import { normalizeBaseHref } from '../cli_safety.mjs';

const baseElement = /<base href="([^"]*)">/;
const sourceBase = '<base href="/">';

// The page is served for any missing path, so its relative links resolve
// against the base the Flutter build wrote into index.html.
export function releaseBaseHref(index) {
  const declared = baseElement.exec(index)?.[1];
  if (declared === undefined) throw new Error('index.html does not declare a base href');
  if (normalizeBaseHref(declared) !== declared) {
    throw new Error(`index.html declares an unsafe base href: ${declared}`);
  }
  return declared;
}

export function renderNotFoundPage(source, baseHref) {
  if (!source.includes(sourceBase)) {
    throw new Error(`web/404.html must declare ${sourceBase}`);
  }
  return source.replace(sourceBase, `<base href="${baseHref}">`);
}
