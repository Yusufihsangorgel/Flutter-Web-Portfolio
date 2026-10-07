import { readFile } from 'node:fs/promises';
import path from 'node:path';

export const boardFrame = Object.freeze({ width: 1600, height: 1000 });
export const compactFrame = Object.freeze({ width: 900, height: 1200 });

const imageTypes = new Map([
  ['.png', 'image/png'],
  ['.jpg', 'image/jpeg'],
  ['.jpeg', 'image/jpeg'],
]);

export function documentShell(body, styles, frame = boardFrame) {
  return `<!doctype html>
  <html lang="en">
    <head>
      <meta charset="utf-8" />
      <meta name="viewport" content="width=device-width, initial-scale=1" />
      <style>
        * {
          box-sizing: border-box;
        }

        html,
        body {
          width: ${frame.width}px;
          height: ${frame.height}px;
          margin: 0;
          overflow: hidden;
        }

        body {
          font-family: Arial, Helvetica, sans-serif;
          text-rendering: geometricPrecision;
        }

        ${styles}
      </style>
    </head>
    <body>${body}</body>
  </html>`;
}

export function compactDocumentShell(body, styles) {
  return documentShell(body, styles, compactFrame);
}

export async function imageDataUrlFrom(filePath) {
  const extension = path.extname(filePath).toLowerCase();
  const mime = imageTypes.get(extension);
  if (mime === undefined) {
    throw new Error(`Unsupported image extension: ${extension}`);
  }
  return dataUrl(mime, await readFile(filePath));
}

export function pngDataUrl(bytes) {
  return dataUrl('image/png', bytes);
}

// Returns lossless PNG bytes so encoding happens once, from unblemished pixels.
export async function capturePage(page, html, frame) {
  await page.setViewportSize(frame);
  await page.setContent(html, { waitUntil: 'load' });
  await page.evaluate(async () => {
    await document.fonts.ready;
    await Promise.all(
      Array.from(document.images, (image) =>
        image.complete ? Promise.resolve() : image.decode(),
      ),
    );
  });
  return page.screenshot({ type: 'png', animations: 'disabled' });
}

export function escapeHtml(value) {
  return value
    .replaceAll('&', '&amp;')
    .replaceAll('<', '&lt;')
    .replaceAll('>', '&gt;')
    .replaceAll('"', '&quot;')
    .replaceAll("'", '&#039;');
}

function dataUrl(mime, bytes) {
  return `data:${mime};base64,${bytes.toString('base64')}`;
}
