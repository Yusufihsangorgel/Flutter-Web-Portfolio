import assert from 'node:assert/strict';
import { cp, mkdir, mkdtemp, readFile, rm, writeFile } from 'node:fs/promises';
import { tmpdir } from 'node:os';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import test from 'node:test';

import { inspectRaster } from '../assets/raster_inspector.mjs';
import { renderArchitectureBoard } from './architecture_boards.mjs';
import { selectSmallest } from './encoder.mjs';
import {
  manifestEntry,
  manifestSchema,
  renderInputDigest,
  verifyArtifacts,
  verifyFormatChoice,
  workArtifactPaths,
} from './manifest.mjs';
import { renderReleaseBoard } from './release_board.mjs';

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..', '..');

for (const render of [renderReleaseBoard, renderArchitectureBoard]) {
  test(`${render.name} replaces every title newline in its accessible label`, async () => {
    const config = {
      title: 'First line\nSecond line\nThird line',
      output: 'board.webp',
      eyebrow: 'EXAMPLE',
      descriptor: 'Example board',
      platform: 'Web',
      icon: 'icon.png',
      screens: [
        { file: 'first.png', label: 'FIRST' },
        { file: 'second.png', label: 'SECOND' },
      ],
      stages: ['INPUT', 'OUTPUT'],
      footer: 'Example footer',
      footerLeft: 'INPUT',
      footerRight: 'OUTPUT',
      palette: {
        paper: '#ffffff',
        ink: '#000000',
        accent: '#0000ff',
        stage: '#ffffff',
        stageInk: '#000000',
        rule: '#000000',
      },
    };
    const renderer = {
      imageDataUrl: async () => 'data:image/png;base64,',
      renderPage: async (html, output) => {
        assert.equal(output, config.output);
        const suffix = render === renderReleaseBoard ? ' release evidence' : '';
        assert.equal(
          html.match(/aria-label="([^"]*)"/)[1],
          `First line Second line Third line${suffix}`,
        );
        for (const line of config.title.split('\n')) {
          assert.ok(html.includes(`<span>${line}</span>`));
        }
      },
    };
    await render(renderer, config);
  });
}

async function copyFixture(t) {
  const copy = await mkdtemp(path.join(tmpdir(), 'work-artifacts-'));
  t.after(() => rm(copy, { recursive: true, force: true }));
  for (const relative of [
    'assets/work',
    'assets/content/portfolio.json',
    'tool/work_artifacts',
    'tool/work_sources',
  ]) {
    await cp(path.join(root, relative), path.join(copy, relative), { recursive: true });
  }
  const paths = workArtifactPaths(copy);
  const manifest = JSON.parse(await readFile(paths.manifest, 'utf8'));
  manifest.input_sha256 = await renderInputDigest(paths);
  await writeFile(paths.manifest, `${JSON.stringify(manifest, null, 2)}\n`);
  return paths;
}

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
  const entry = (format, candidates) => ({
    asset: 'assets/work/a.webp',
    format,
    candidates,
    bytes: candidates[format],
  });
  assert.deepEqual(verifyFormatChoice(entry('webp', { webp: 5, jpeg: 9 })), []);
  assert.deepEqual(verifyFormatChoice(entry('jpeg', { webp: 9, jpeg: 5 })), []);
  assert.equal(verifyFormatChoice(entry('jpeg', { webp: 5, jpeg: 5 })).length, 1);
  assert.equal(verifyFormatChoice(entry('webp', { webp: 9, jpeg: 5 })).length, 1);
  assert.equal(verifyFormatChoice(entry('png', { png: 5 })).length, 1);
});

function sizeEntry(format, candidates, bytes = candidates?.[format]) {
  return { asset: 'assets/work/candidate.webp', format, candidates, bytes };
}

function registerInvalidCandidateSizes() {
  const cases = [
    ['missing value', undefined],
    ['null', null],
    ['string', '5'],
    ['true', true],
    ['false', false],
    ['NaN', NaN],
    ['Infinity', Infinity],
    ['negative Infinity', -Infinity],
    ['zero', 0],
    ['negative', -1],
    ['fraction', 0.5],
    ['unsafe integer', Number.MAX_SAFE_INTEGER + 1],
  ];
  for (const [label, value] of cases) {
    test(`rejects ${label} selected candidate size`, () => {
      const entry = sizeEntry('webp', { webp: value, jpeg: 9 });
      assert.match(
        verifyFormatChoice(entry).join('\n'),
        /candidate sizes must be positive safe integers/,
      );
    });
    test(`rejects ${label} unselected candidate size`, () => {
      const entry = sizeEntry('webp', { webp: 5, jpeg: value });
      assert.match(
        verifyFormatChoice(entry).join('\n'),
        /candidate sizes must be positive safe integers/,
      );
    });
  }
}

function registerRecordedByteMismatches() {
  const cases = [
    ['missing', undefined],
    ['null', null],
    ['string', '5'],
    ['true', true],
    ['false', false],
    ['NaN', NaN],
    ['Infinity', Infinity],
    ['negative Infinity', -Infinity],
    ['zero', 0],
    ['negative', -1],
    ['fraction', 5.5],
    ['unsafe integer', Number.MAX_SAFE_INTEGER + 1],
    ['smaller', 4],
    ['larger', 6],
  ];
  for (const [label, bytes] of cases) {
    test(`rejects ${label} recorded bytes for the selected candidate`, () => {
      const entry = { ...sizeEntry('webp', { webp: 5, jpeg: 9 }), bytes };
      assert.match(
        verifyFormatChoice(entry).join('\n'),
        /selected candidate bytes differ from its recorded bytes/,
      );
    });
  }
}

function registerFormatChoiceControls() {
  const cases = [
    ['smaller WebP', 'webp', { webp: 5, jpeg: 9 }],
    ['smaller JPEG', 'jpeg', { webp: 9, jpeg: 5 }],
    ['smaller PNG', 'png', { webp: 9, png: 5 }],
    ['WebP JPEG tie', 'webp', { jpeg: 5, webp: 5 }],
    ['WebP PNG tie', 'webp', { png: 5, webp: 5 }],
    ['WebP only', 'webp', { webp: 5 }],
    ['maximum safe size', 'webp', { webp: Number.MAX_SAFE_INTEGER }],
  ];
  for (const [label, format, candidates] of cases) {
    test(`accepts ${label} with matching recorded bytes`, () => {
      assert.deepEqual(verifyFormatChoice(sizeEntry(format, candidates)), []);
    });
  }
  test('rejects a selected format absent from the candidate map', () => {
    const entry = sizeEntry('jpeg', { webp: 5 }, 5);
    assert.deepEqual(verifyFormatChoice(entry), [`${entry.asset} has no jpeg candidate`]);
  });
  test('keeps the missing WebP error for missing, null, empty, and PNG-only maps', () => {
    for (const candidates of [undefined, null, {}, { png: 5 }]) {
      const entry = sizeEntry('png', candidates, 5);
      assert.deepEqual(verifyFormatChoice(entry), [`${entry.asset} has no WebP candidate`]);
    }
  });
}

registerInvalidCandidateSizes();
registerRecordedByteMismatches();
registerFormatChoiceControls();

async function candidateFixture(t) {
  const copy = await mkdtemp(path.join(tmpdir(), 'candidate-sizes-'));
  t.after(() => rm(copy, { recursive: true, force: true }));
  const paths = workArtifactPaths(copy);
  for (const directory of [
    paths.output,
    paths.sources,
    paths.modules,
    path.dirname(paths.content),
  ]) {
    await mkdir(directory, { recursive: true });
  }
  const bytes = riff([lossyFrame(16, 16)]);
  const frame = { width: 16, height: 16 };
  const entry = manifestEntry(
    'assets/work/candidate.webp',
    { format: 'webp', bytes, candidates: { webp: bytes.length, jpeg: bytes.length + 1 } },
    frame,
  );
  await writeFile(path.join(paths.root, entry.asset), bytes);
  await writeFile(
    paths.content,
    JSON.stringify({ systems: [{ artifact: { asset: entry.asset, ...frame } }] }),
  );
  const document = {
    schema: manifestSchema,
    input_sha256: await renderInputDigest(paths),
    artifacts: [entry],
  };
  await writeFile(paths.manifest, JSON.stringify(document));
  return { paths, bytes, document };
}

test('check mode rejects metadata-only candidate edits without changing file bytes or digest', async (t) => {
  const { paths, bytes, document } = await candidateFixture(t);
  assert.deepEqual(await verifyArtifacts(paths), []);
  const original = document.artifacts[0];
  const edited = { ...original, candidates: { webp: 1, jpeg: 2 } };
  await writeFile(paths.manifest, JSON.stringify({ ...document, artifacts: [edited] }));
  const recorded = JSON.parse(await readFile(paths.manifest, 'utf8')).artifacts[0];
  assert.equal(recorded.bytes, original.bytes);
  assert.equal(recorded.sha256, original.sha256);
  assert.deepEqual(await readFile(path.join(paths.root, original.asset)), bytes);
  assert.deepEqual(await verifyArtifacts(paths), [
    `${original.asset} selected candidate bytes differ from its recorded bytes`,
  ]);
  await writeFile(paths.manifest, JSON.stringify(document));
  assert.deepEqual(await verifyArtifacts(paths), []);
});

test('check mode detects stale inputs, edited assets, and orphans', async (t) => {
  const paths = await copyFixture(t);
  assert.deepEqual(await verifyArtifacts(paths), []);

  const manifest = JSON.parse(await readFile(paths.manifest, 'utf8'));
  const first = path.join(paths.root, manifest.artifacts[0].asset);
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

test('check mode detects a changed split renderer helper', async (t) => {
  const paths = await copyFixture(t);
  assert.deepEqual(await verifyArtifacts(paths), []);

  const helper = path.join(paths.modules, 'template.mjs');
  await writeFile(helper, `${await readFile(helper, 'utf8')}\n// changed\n`);

  assert.match((await verifyArtifacts(paths)).join('\n'), /renderer inputs changed/);
});
