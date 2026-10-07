import assert from 'node:assert/strict';
import { cp, mkdtemp, readFile, rm, writeFile } from 'node:fs/promises';
import { tmpdir } from 'node:os';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import test from 'node:test';

import { inspectRaster } from '../raster_inspector.mjs';
import { selectSmallest } from './encoder.mjs';
import {
  verifyArtifacts,
  verifyFormatChoice,
  workArtifactPaths,
} from './manifest.mjs';

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..', '..');

function riff(chunks) {
  const body = Buffer.concat([Buffer.from('WEBP', 'latin1'), ...chunks]);
  const header = Buffer.alloc(8);
  header.write('RIFF', 0, 'latin1');
  header.writeUInt32LE(body.length, 4);
  return Buffer.concat([header, body]);
}

function chunk(type, data) {
  const header = Buffer.alloc(8);
  header.write(type, 0, 'latin1');
  header.writeUInt32LE(data.length, 4);
  const padding = Buffer.alloc(data.length % 2);
  return Buffer.concat([header, data, padding]);
}

function lossyFrame(width, height) {
  const data = Buffer.alloc(10);
  data.set([0x9d, 0x01, 0x2a], 3);
  data.writeUInt16LE(width, 6);
  data.writeUInt16LE(height, 8);
  return chunk('VP8 ', data);
}

test('reads lossy, lossless, and extended WebP dimensions', () => {
  assert.deepEqual(inspectRaster(riff([lossyFrame(1600, 1000)])), {
    format: 'webp',
    width: 1600,
    height: 1000,
  });

  const lossless = Buffer.alloc(5);
  lossless[0] = 0x2f;
  lossless.writeUInt32LE((900 - 1) | ((1200 - 1) << 14), 1);
  assert.deepEqual(inspectRaster(riff([chunk('VP8L', lossless)])), {
    format: 'webp',
    width: 900,
    height: 1200,
  });

  const extended = Buffer.alloc(10);
  extended.writeUIntLE(640 - 1, 4, 3);
  extended.writeUIntLE(480 - 1, 7, 3);
  const withAlpha = riff([chunk('VP8X', extended), lossyFrame(640, 480)]);
  assert.equal(inspectRaster(withAlpha).width, 640);
  assert.equal(inspectRaster(withAlpha).height, 480);
});

test('rejects truncated, padded, and image-less WebP files', () => {
  const valid = riff([lossyFrame(16, 16)]);
  assert.throws(() => inspectRaster(valid.subarray(0, valid.length - 2)), /WebP/);
  assert.throws(() => inspectRaster(Buffer.concat([valid, Buffer.alloc(2)])), /WebP/);
  assert.throws(() => inspectRaster(riff([chunk('EXIF', Buffer.alloc(4))])), /WebP/);
  const badStartCode = riff([chunk('VP8 ', Buffer.alloc(10))]);
  assert.throws(() => inspectRaster(badStartCode), /lossy WebP/);
});

test('keeps the smallest encoding and lets WebP win ties', () => {
  const tie = new Map([
    ['jpeg', Buffer.alloc(10)],
    ['webp', Buffer.alloc(10)],
  ]);
  assert.equal(selectSmallest(tie).format, 'webp');
  const legacy = new Map([
    ['webp', Buffer.alloc(12)],
    ['png', Buffer.alloc(11)],
  ]);
  assert.deepEqual(selectSmallest(legacy).candidates, { webp: 12, png: 11 });
  assert.equal(selectSmallest(legacy).format, 'png');
});

test('flags a recorded format that is not the smallest candidate', () => {
  const entry = (format, candidates) => ({ asset: 'assets/work/a.webp', format, candidates });
  assert.deepEqual(verifyFormatChoice(entry('webp', { webp: 5, jpeg: 9 })), []);
  assert.deepEqual(verifyFormatChoice(entry('jpeg', { webp: 9, jpeg: 5 })), []);
  assert.equal(verifyFormatChoice(entry('jpeg', { webp: 5, jpeg: 5 })).length, 1);
  assert.equal(verifyFormatChoice(entry('webp', { webp: 9, jpeg: 5 })).length, 1);
  assert.equal(verifyFormatChoice(entry('png', { png: 5 })).length, 1);
});

test('check mode detects stale inputs, edited assets, and orphans', async (t) => {
  const copy = await mkdtemp(path.join(tmpdir(), 'work-artifacts-'));
  t.after(() => rm(copy, { recursive: true, force: true }));
  for (const relative of [
    'assets/work',
    'assets/content/portfolio.json',
    'tool/render_work_artifacts.mjs',
    'tool/work_artifacts',
    'tool/work_sources',
  ]) {
    await cp(path.join(root, relative), path.join(copy, relative), { recursive: true });
  }
  const paths = workArtifactPaths(copy);
  assert.deepEqual(await verifyArtifacts(paths), []);

  const manifest = JSON.parse(await readFile(paths.manifest, 'utf8'));
  const first = path.join(copy, manifest.artifacts[0].asset);
  const original = await readFile(first);
  await writeFile(first, Buffer.concat([original, Buffer.alloc(1)]));
  assert.match((await verifyArtifacts(paths)).join('\n'), /differs from its recorded digest/);
  await writeFile(first, original);

  await writeFile(path.join(paths.output, 'stray.png'), Buffer.alloc(1));
  assert.match((await verifyArtifacts(paths)).join('\n'), /stray\.png is not produced/);
  await rm(path.join(paths.output, 'stray.png'));

  await writeFile(path.join(paths.sources, 'README.md'), 'changed\n');
  assert.match((await verifyArtifacts(paths)).join('\n'), /renderer inputs changed/);
});
