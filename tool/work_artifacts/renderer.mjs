import path from 'node:path';

import { artifactFileName, manifestEntry } from './manifest.mjs';
import { encodeArtifact, encoderSettings } from './encoder.mjs';
import { boardFrame, capturePage, compactFrame, imageDataUrlFrom, pngDataUrl } from './page.mjs';

/** @typedef {import('@playwright/test').Page} Page */
/** @typedef {ReturnType<typeof import('./manifest.mjs').workArtifactPaths>} WorkArtifactPaths */

/**
 * @typedef {object} ArtifactRenderer
 * @property {WorkArtifactPaths} paths
 * @property {Map<string, Buffer>} renderedBoards
 * @property {Array<{entry: object, bytes: Buffer}>} outputs
 * @property {(html: string, outputFile: string) => Promise<void>} renderPage
 * @property {(html: string, outputFile: string) => Promise<void>} renderCompactPage
 * @property {(fileName: string) => Promise<string>} imageDataUrl
 * @property {(fileName: string) => string} renderedDataUrl
 */

/**
 * @param {Page} page
 * @param {WorkArtifactPaths} paths
 * @returns {ArtifactRenderer}
 */
export function createArtifactRenderer(page, paths) {
  const renderedBoards = new Map();
  const outputs = [];

  async function renderPage(html, outputFile) {
    const png = await capturePage(page, html, boardFrame);
    await publish(outputFile, png, boardFrame);
  }

  async function renderCompactPage(html, outputFile) {
    const png = await capturePage(page, html, compactFrame);
    await publish(outputFile, png, compactFrame);
  }

  // The configured extension names the legacy format, which stays only when
  // WebP is not smaller.
  async function publish(outputFile, png, frame) {
    renderedBoards.set(outputFile, png);
    const extension = path.extname(outputFile).toLowerCase();
    const stem = path.basename(outputFile, extension);
    const encoded = await encodeArtifact(page, png, {
      fallback: extension === '.png' ? 'png' : 'jpeg',
      settings: frame === compactFrame ? encoderSettings.compact : encoderSettings.board,
    });
    const asset = `assets/work/${artifactFileName(stem, encoded.format)}`;
    outputs.push({ entry: manifestEntry(asset, encoded, frame), bytes: encoded.bytes });
    process.stdout.write(
      `Rendered ${asset} at ${frame.width}x${frame.height} (${encoded.bytes.length} bytes).\n`,
    );
  }

  async function imageDataUrl(fileName) {
    return imageDataUrlFrom(path.join(paths.sources, fileName));
  }

  function renderedDataUrl(fileName) {
    const png = renderedBoards.get(fileName);
    if (png === undefined) throw new Error(`Rendered board is unavailable: ${fileName}`);
    return pngDataUrl(png);
  }

  return {
    paths,
    renderedBoards,
    outputs,
    renderPage,
    renderCompactPage,
    imageDataUrl,
    renderedDataUrl,
  };
}
