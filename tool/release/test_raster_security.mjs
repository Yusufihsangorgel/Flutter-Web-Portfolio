import assert from 'node:assert/strict';
import { readFile } from 'node:fs/promises';
import test from 'node:test';
import { assertRasterDimensions, inspectRaster } from '../assets/raster_inspector.mjs';
import {
  serializeSocialCardFingerprint,
  verifySocialCardFingerprint,
} from '../assets/social_card_fingerprint.mjs';

const inputDigest = 'a'.repeat(64);
const card = await readFile('web/assets/og/engineering-showcase.png');
const fingerprint = serializeSocialCardFingerprint({
  inputDigest,
  pngBytes: card,
});
assert.equal(
  verifySocialCardFingerprint({
    fingerprintText: fingerprint,
    expectedInputDigest: inputDigest,
    pngBytes: card,
  }),
  true,
);
const bitFlippedCard = Buffer.from(card);
bitFlippedCard[Math.floor(bitFlippedCard.length / 2)] ^= 0x01;
assert.equal(
  verifySocialCardFingerprint({
    fingerprintText: fingerprint,
    expectedInputDigest: inputDigest,
    pngBytes: bitFlippedCard,
  }),
  false,
  'a bit-flipped committed PNG must invalidate its fingerprint',
);
assert.equal(
  verifySocialCardFingerprint({
    fingerprintText: fingerprint,
    expectedInputDigest: 'b'.repeat(64),
    pngBytes: card,
  }),
  false,
  'changed renderer inputs must invalidate the fingerprint',
);

const png = inspectRaster(card, 'social card fixture');
assert.deepEqual(png, { format: 'png', width: 1200, height: 630 });
assertRasterDimensions(png, 1200, 630, 'social card fixture');
assert.throws(
  () => assertRasterDimensions(png, 1201, 630, 'wrong-size fixture'),
  /expected 1201x630/,
);
assert.throws(() => inspectRaster(bitFlippedCard, 'corrupt PNG fixture'), /corrupt|invalid/);

// Self-contained neutral fixture: a 16x16 baseline JPEG generated from a solid
// color. Template initialization may intentionally remove every demo artifact,
// so release tooling tests must not depend on the original portfolio content.
const jpegBytes = Buffer.from(
  '/9j/4AAQSkZJRgABAgAAAQABAAD//gAQTGF2YzYyLjI4LjEwMQD/2wBDAAgEBAQEBAUFBQUFBQYGBgYGBgYGBgYGBgYGBwcICAgHBwcGBgcHCAgICAkJCQgICAgJCQoKCgwMCwsODg4RERT/xABMAAEBAAAAAAAAAAAAAAAAAAAABwEBAQAAAAAAAAAAAAAAAAAABQcQAQAAAAAAAAAAAAAAAAAAAAARAQAAAAAAAAAAAAAAAAAAAAD/wAARCAAQABADASIAAhEAAxEA/9oADAMBAAIRAxEAPwCOAL+Kf//Z',
  'base64',
);
const jpeg = inspectRaster(jpegBytes, 'JPEG fixture');
assert.deepEqual(jpeg, { format: 'jpeg', width: 16, height: 16 });
assert.throws(
  () => inspectRaster(jpegBytes.subarray(0, jpegBytes.length - 32), 'truncated JPEG'),
  /truncated|missing/,
);

// Buffer-only structural header controls, not decoder-valid WebP images.
const webpLabel = 'WebP header fixture';
const canvas = extendedHeader(32, 24);
const imageHeaders = [
  { type: 'VP8 ', bytes: lossyHeader(16, 12), reason: 'has an invalid lossy WebP frame header' },
  { type: 'VP8L', bytes: losslessHeader(16, 12), reason: 'has an invalid lossless WebP header' },
];

function webpChunk(type, data) {
  const header = Buffer.alloc(8);
  header.write(type, 0, 'latin1');
  header.writeUInt32LE(data.length, 4);
  return Buffer.concat([header, data, Buffer.alloc(data.length % 2)]);
}

function webpFile(chunks) {
  const body = Buffer.concat([Buffer.from('WEBP', 'latin1'), ...chunks]);
  const header = Buffer.alloc(8);
  header.write('RIFF', 0, 'latin1');
  header.writeUInt32LE(body.length, 4);
  return Buffer.concat([header, body]);
}

function extendedHeader(width, height) {
  const header = Buffer.alloc(10);
  header.writeUIntLE(width - 1, 4, 3);
  header.writeUIntLE(height - 1, 7, 3);
  return header;
}

function lossyHeader(width, height) {
  const header = Buffer.alloc(10);
  header[0] = 0x10;
  header.set([0x9d, 0x01, 0x2a], 3);
  header.writeUInt16LE(width, 6);
  header.writeUInt16LE(height, 8);
  return header;
}

function losslessHeader(width, height) {
  const header = Buffer.alloc(5);
  header[0] = 0x2f;
  header.writeUInt32LE((width - 1) | ((height - 1) << 14), 1);
  return header;
}

function rejectsWebp(bytes, reason) {
  assert.throws(() => inspectRaster(bytes, webpLabel), { message: `${webpLabel} ${reason}` });
}

for (const { type, bytes, reason } of imageHeaders) {
  test(`reads a simple ${type.trim()} structural header`, () => {
    assert.deepEqual(inspectRaster(webpFile([webpChunk(type, bytes)])), {
      format: 'webp',
      width: 16,
      height: 12,
    });
  });
  test(`keeps the extended canvas dimensions with a smaller ${type.trim()} image`, () => {
    assert.deepEqual(inspectRaster(webpFile([webpChunk('VP8X', canvas), webpChunk(type, bytes)])), {
      format: 'webp',
      width: 32,
      height: 24,
    });
  });

  const badSignature = Buffer.from(bytes);
  badSignature[type === 'VP8 ' ? 3 : 0] = 0;
  for (const [variant, header] of [
    ['empty', Buffer.alloc(0)],
    ['short', bytes.subarray(0, bytes.length - 1)],
    ['bad signature', badSignature],
  ]) {
    for (const extended of [false, true]) {
      test(`rejects ${variant} ${type.trim()} after ${extended ? 'VP8X' : 'RIFF'}`, () => {
        const prefix = extended ? [webpChunk('VP8X', canvas)] : [];
        rejectsWebp(webpFile([...prefix, webpChunk(type, header)]), reason);
      });
    }
  }

  test(`validates another ${type.trim()} header after valid image dimensions`, () => {
    rejectsWebp(webpFile([webpChunk(type, bytes), webpChunk(type, Buffer.alloc(0))]), reason);
  });
  test(`ignores unrelated padded chunks around ${type.trim()} headers`, () => {
    const metadata = webpChunk('EXIF', Buffer.from([1, 2, 3]));
    assert.deepEqual(
      inspectRaster(
        webpFile([metadata, webpChunk('VP8X', canvas), metadata, webpChunk(type, bytes), metadata]),
      ),
      { format: 'webp', width: 32, height: 24 },
    );
  });
}

for (const [variant, header] of [
  ['empty', Buffer.alloc(0)],
  ['short', canvas.subarray(0, 9)],
]) {
  for (const late of [false, true]) {
    test(`rejects ${variant} VP8X ${late ? 'after' : 'before'} an image`, () => {
      const image = webpChunk('VP8 ', lossyHeader(16, 12));
      const extended = webpChunk('VP8X', header);
      rejectsWebp(
        webpFile(late ? [image, extended] : [extended, image]),
        'has an invalid WebP extended header',
      );
    });
  }
}

for (const [variant, type, header] of [
  ['zero width', 'VP8 ', lossyHeader(0, 12)],
  ['zero height', 'VP8 ', lossyHeader(16, 0)],
  ['excessive lossy pixels', 'VP8 ', lossyHeader(10001, 10000)],
  ['excessive lossless pixels', 'VP8L', losslessHeader(10001, 10000)],
]) {
  for (const extended of [false, true]) {
    test(`rejects ${variant} ${extended ? 'behind a safe canvas' : 'without a canvas'}`, () => {
      const prefix = extended ? [webpChunk('VP8X', canvas)] : [];
      rejectsWebp(webpFile([...prefix, webpChunk(type, header)]), 'has unsafe raster dimensions');
    });
  }
}

test('preserves the canvas pixel-budget boundary', () => {
  assert.deepEqual(
    inspectRaster(
      webpFile([
        webpChunk('VP8X', extendedHeader(10000, 10000)),
        webpChunk('VP8 ', lossyHeader(16, 12)),
      ]),
    ),
    { format: 'webp', width: 10000, height: 10000 },
  );
  rejectsWebp(
    webpFile([
      webpChunk('VP8X', extendedHeader(10001, 10000)),
      webpChunk('VP8 ', lossyHeader(16, 12)),
    ]),
    'has unsafe raster dimensions',
  );
});

for (const [variant, chunks] of [
  ['empty container', []],
  ['extended header only', [webpChunk('VP8X', canvas)]],
  ['unrelated chunk only', [webpChunk('EXIF', Buffer.from([1]))]],
  [
    'extended header and unrelated chunk',
    [webpChunk('VP8X', canvas), webpChunk('EXIF', Buffer.from([1]))],
  ],
]) {
  test(`rejects a missing image in an ${variant}`, () => {
    rejectsWebp(webpFile(chunks), 'is missing a WebP image chunk');
  });
}

const simpleWebp = webpFile([webpChunk('VP8 ', lossyHeader(16, 12))]);
for (const [variant, bytes] of [
  ['truncated file', simpleWebp.subarray(0, simpleWebp.length - 1)],
  ['trailing byte', Buffer.concat([simpleWebp, Buffer.alloc(1)])],
]) {
  test(`rejects a RIFF size mismatch from a ${variant}`, () => {
    rejectsWebp(bytes, 'is a truncated or trailing-data WebP');
  });
}

for (const length of [1, 7]) {
  test(`rejects a ${length}-byte in-container tail as a truncated chunk`, () => {
    rejectsWebp(
      webpFile([webpChunk('VP8 ', lossyHeader(16, 12)), Buffer.alloc(length)]),
      'has a truncated WebP chunk',
    );
  });
}

test('rejects a declared chunk length extending beyond RIFF', () => {
  const chunk = webpChunk('VP8 ', lossyHeader(16, 12));
  chunk.writeUInt32LE(12, 4);
  rejectsWebp(webpFile([chunk]), 'has an invalid WebP chunk length');
});

for (const type of ['VP8L', 'EXIF']) {
  test(`rejects missing required odd-chunk padding on ${type}`, () => {
    const data = type === 'VP8L' ? losslessHeader(16, 12) : Buffer.from([1]);
    const padded = webpChunk(type, data);
    rejectsWebp(
      webpFile([
        webpChunk('VP8X', canvas),
        webpChunk('VP8 ', lossyHeader(16, 12)),
        padded.subarray(0, padded.length - 1),
      ]),
      'has an invalid WebP chunk length',
    );
  });
}
