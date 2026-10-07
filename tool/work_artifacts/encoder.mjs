// Encodes in the renderer's own Chromium, so no image codec dependency is
// needed and the same browser build always yields the same bytes.
const canvasTypes = Object.freeze({ webp: 'image/webp', jpeg: 'image/jpeg' });

export const encoderSettings = Object.freeze({
  board: Object.freeze({ webpQuality: 0.86, jpegQuality: 0.86 }),
  compact: Object.freeze({ webpQuality: 0.88, jpegQuality: 0.88 }),
});

/**
 * Encodes lossless [png] bytes as WebP and as the board's [fallback] format
 * ("jpeg" or "png") and keeps the smallest; WebP wins ties.
 */
export async function encodeArtifact(page, png, { fallback, settings }) {
  if (fallback !== 'jpeg' && fallback !== 'png') {
    throw new Error(`Unsupported fallback format: ${fallback}`);
  }
  const requests = [{ format: 'webp', quality: settings.webpQuality }];
  if (fallback === 'jpeg') {
    requests.push({ format: 'jpeg', quality: settings.jpegQuality });
  }
  const encoded = await encodeInBrowser(page, png, requests);
  const candidates = new Map(encoded);
  if (fallback === 'png') candidates.set('png', png);
  return selectSmallest(candidates);
}

export function selectSmallest(candidates) {
  let chosen = null;
  for (const [format, bytes] of candidates) {
    const smaller = chosen === null || bytes.length < chosen.bytes.length;
    const webpTie = chosen !== null && bytes.length === chosen.bytes.length && format === 'webp';
    if (smaller || webpTie) {
      chosen = { format, bytes };
    }
  }
  if (chosen === null) throw new Error('No encoded candidate was produced');
  return {
    ...chosen,
    candidates: Object.fromEntries(
      [...candidates].map(([format, bytes]) => [format, bytes.length]),
    ),
  };
}

async function encodeInBrowser(page, png, requests) {
  const results = await page.evaluate(
    async ({ source, jobs, types }) => {
      const binary = Uint8Array.from(atob(source), (char) => char.charCodeAt(0));
      const bitmap = await createImageBitmap(
        new Blob([binary], { type: 'image/png' }),
      );
      const canvas = document.createElement('canvas');
      canvas.width = bitmap.width;
      canvas.height = bitmap.height;
      // An opaque software canvas keeps readback reliable and yields the
      // simple (alpha-free) WebP layout.
      canvas
        .getContext('2d', { alpha: false, willReadFrequently: true })
        .drawImage(bitmap, 0, 0);
      const output = [];
      for (const job of jobs) {
        const blob = await new Promise((resolve) =>
          canvas.toBlob(resolve, types[job.format], job.quality),
        );
        if (!blob || blob.type !== types[job.format]) {
          throw new Error(`Chromium cannot encode ${job.format}`);
        }
        const bytes = new Uint8Array(await blob.arrayBuffer());
        let text = '';
        for (let offset = 0; offset < bytes.length; offset += 0x8000) {
          text += String.fromCharCode(...bytes.subarray(offset, offset + 0x8000));
        }
        output.push([job.format, btoa(text)]);
      }
      return output;
    },
    { source: png.toString('base64'), jobs: requests, types: canvasTypes },
  );
  return results.map(([format, base64]) => [
    format,
    Buffer.from(base64, 'base64'),
  ]);
}
