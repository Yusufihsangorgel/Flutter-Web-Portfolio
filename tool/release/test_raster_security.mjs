import assert from 'node:assert/strict';
import { readFile } from 'node:fs/promises';
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
