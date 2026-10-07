// @ts-check
import { readPdfDocument } from './pdf_document.mjs';
import { validatePaper } from './render_resume_html.mjs';

/**
 * @param {string | undefined} body
 * @param {string} key
 * @param {Map<number, string>} objects
 * @returns {string | undefined}
 */
function referencedObject(body, key, objects) {
  if (!body) return undefined;
  const reference = new RegExp(`/${key}\\s+(\\d+) 0 R`).exec(body);
  return reference ? objects.get(Number(reference[1])) : undefined;
}

/**
 * @param {Buffer} bytes
 * @param {string} [paper]
 * @returns {void}
 */
export function assertResumeStructure(bytes, paper = 'a4') {
  validatePaper(paper);
  const { objects, root } = readPdfDocument(bytes);
  const catalog = objects.get(root);
  checkStructureTags(catalog, objects);
  checkOutline(catalog, objects);
  const expected = paper === 'a4' ? [595.28, 841.89] : [612, 792];
  checkPageDimensions(objects, expected, paper);
}

/**
 * @param {string | undefined} catalog
 * @param {Map<number, string>} objects
 * @returns {void}
 */
function checkStructureTags(catalog, objects) {
  const structure = referencedObject(catalog, 'StructTreeRoot', objects);
  const markInfo = referencedObject(catalog, 'MarkInfo', objects) ?? catalog;
  if (
    !structure ||
    !/\/Type\s*\/StructTreeRoot\b/.test(structure) ||
    !/\/Marked\s+true\b/.test(markInfo)
  ) {
    throw new Error('Resume PDF must retain its accessibility tags.');
  }
}

/**
 * @param {string | undefined} catalog
 * @param {Map<number, string>} objects
 * @returns {void}
 */
function checkOutline(catalog, objects) {
  const outline = referencedObject(catalog, 'Outlines', objects);
  const first = outline && referencedObject(outline, 'First', objects);
  if (!first || !/\/Title\b/.test(first)) {
    throw new Error('Resume PDF must retain its heading outline.');
  }
}

/**
 * @param {Map<number, string>} objects
 * @param {number[]} expected
 * @param {string} paper
 * @returns {void}
 */
function checkPageDimensions(objects, expected, paper) {
  const pages = [...objects.values()].filter((body) => /\/Type\s*\/Page\b/.test(body));
  if (!pages.length) throw new Error('Resume PDF must have pages.');
  for (const page of pages) checkPageBox(page, expected, paper);
}

/**
 * @param {string} page
 * @param {number[]} expected
 * @param {string} paper
 * @returns {void}
 */
function checkPageBox(page, expected, paper) {
  const box = /\/MediaBox\s*\[([^\]]*)\]/.exec(page)?.[1].trim().split(/\s+/).map(Number);
  if (!box || box.length !== 4 || box.some((value) => !Number.isFinite(value))) {
    throw new Error('Resume PDF page dimensions are missing or invalid.');
  }
  const actual = [box[2] - box[0], box[3] - box[1]];
  if (actual.some((value, index) => Math.abs(value - expected[index]) > 1.5)) {
    throw new Error(`Resume PDF page dimensions do not match ${paper}.`);
  }
}
