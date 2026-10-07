import { createHash } from 'node:crypto';
import { readFile, readdir, rm, writeFile } from 'node:fs/promises';
import path from 'node:path';

import { assertRasterDimensions, inspectRaster } from '../raster_inspector.mjs';

export const manifestSchema = 'portfolio-work-artifacts/v1';

const extensions = Object.freeze({ webp: '.webp', jpeg: '.jpg', png: '.png' });
const rasterPattern = /\.(png|jpe?g|webp)$/i;

export function workArtifactPaths(root) {
  const sources = path.join(root, 'tool', 'work_sources');
  return Object.freeze({
    root,
    output: path.join(root, 'assets', 'work'),
    sources,
    manifest: path.join(sources, 'artifact-manifest.json'),
    renderer: path.join(root, 'tool', 'render_work_artifacts.mjs'),
    modules: path.join(root, 'tool', 'work_artifacts'),
    content: path.join(root, 'assets', 'content', 'portfolio.json'),
  });
}

export function artifactFileName(stem, format) {
  const extension = extensions[format];
  if (!extension) throw new Error(`Unsupported artifact format: ${format}`);
  return `${stem}${extension}`;
}

/** Digest of everything that determines the rendered pixels. */
export async function renderInputDigest(paths) {
  const modules = (await listFiles(paths.modules)).filter(
    (file) => !path.basename(file).startsWith('test_'),
  );
  const sources = (await listFiles(paths.sources)).filter(
    (file) => file !== paths.manifest,
  );
  const hash = createHash('sha256');
  for (const file of [paths.renderer, ...modules, ...sources]) {
    hash.update(path.relative(paths.root, file).split(path.sep).join('/'));
    hash.update('\0');
    hash.update(await readFile(file));
    hash.update('\0');
  }
  return hash.digest('hex');
}

export function manifestEntry(asset, encoded, frame) {
  return {
    asset,
    format: encoded.format,
    width: frame.width,
    height: frame.height,
    bytes: encoded.bytes.length,
    sha256: sha256(encoded.bytes),
    candidates: encoded.candidates,
  };
}

/** Writes outputs and the manifest; removes only files a previous run recorded. */
export async function writeArtifacts(paths, { outputs, inputDigest, renderer }) {
  const previous = await readManifest(paths.manifest).catch(() => null);
  const next = new Set(outputs.map((output) => output.entry.asset));
  for (const entry of previous?.artifacts ?? []) {
    if (!next.has(entry.asset) && isWorkAsset(entry.asset)) {
      await rm(path.join(paths.root, entry.asset), { force: true });
    }
  }
  for (const output of outputs) {
    await writeFile(path.join(paths.root, output.entry.asset), output.bytes);
  }
  const document = {
    schema: manifestSchema,
    input_sha256: inputDigest,
    renderer,
    artifacts: outputs
      .map((output) => output.entry)
      .sort((left, right) => left.asset.localeCompare(right.asset)),
  };
  await writeFile(paths.manifest, `${JSON.stringify(document, null, 2)}\n`);
}

/** Returns human-readable failures; an empty list means the assets are current. */
export async function verifyArtifacts(paths) {
  let manifest;
  try {
    manifest = await readManifest(paths.manifest);
  } catch (error) {
    return [`artifact manifest is missing or invalid: ${error.message}`];
  }
  const failures = [];
  if (manifest.input_sha256 !== (await renderInputDigest(paths))) {
    failures.push('renderer inputs changed since the artifacts were rendered');
  }
  for (const entry of manifest.artifacts) {
    failures.push(...(await verifyEntry(paths, entry)));
  }
  failures.push(...(await verifyContentReferences(paths, manifest)));
  failures.push(...(await findOrphans(paths, manifest)));
  return failures;
}

async function verifyEntry(paths, entry) {
  if (!isWorkAsset(entry.asset)) return [`unsafe artifact path: ${entry.asset}`];
  const label = entry.asset;
  let bytes;
  try {
    bytes = await readFile(path.join(paths.root, entry.asset));
  } catch {
    return [`${label} is missing`];
  }
  const failures = [];
  if (sha256(bytes) !== entry.sha256 || bytes.length !== entry.bytes) {
    failures.push(`${label} differs from its recorded digest`);
  }
  try {
    const raster = inspectRaster(bytes, label);
    if (raster.format !== entry.format) {
      failures.push(`${label} is ${raster.format}; recorded ${entry.format}`);
    }
    assertRasterDimensions(raster, entry.width, entry.height, label);
  } catch (error) {
    failures.push(error.message);
  }
  if (path.extname(entry.asset) !== extensions[entry.format]) {
    failures.push(`${label} extension does not match ${entry.format}`);
  }
  failures.push(...verifyFormatChoice(entry));
  return failures;
}

export function verifyFormatChoice(entry) {
  const sizes = Object.entries(entry.candidates ?? {});
  if (!sizes.some(([format]) => format === 'webp')) {
    return [`${entry.asset} has no WebP candidate`];
  }
  const smallest = Math.min(...sizes.map(([, size]) => size));
  const webpSize = entry.candidates.webp;
  const expected = webpSize === smallest ? 'webp' : entry.format;
  if (entry.candidates[entry.format] !== smallest || entry.format !== expected) {
    return [`${entry.asset} is not the smallest candidate (WebP wins ties)`];
  }
  return [];
}

async function verifyContentReferences(paths, manifest) {
  const recorded = new Map(manifest.artifacts.map((entry) => [entry.asset, entry]));
  const portfolio = JSON.parse(await readFile(paths.content, 'utf8'));
  const failures = [];
  for (const system of portfolio.systems ?? []) {
    for (const artifact of [system.artifact, system.artifact?.compact]) {
      if (!artifact?.asset?.startsWith('assets/work/')) continue;
      const entry = recorded.get(artifact.asset);
      if (!entry) {
        failures.push(`${artifact.asset} is referenced but not rendered`);
      } else if (entry.width !== artifact.width || entry.height !== artifact.height) {
        failures.push(`${artifact.asset} content dimensions differ from the render`);
      }
    }
  }
  return failures;
}

async function findOrphans(paths, manifest) {
  const recorded = new Set(manifest.artifacts.map((entry) => entry.asset));
  return (await readdir(paths.output))
    .filter((name) => rasterPattern.test(name))
    .map((name) => `assets/work/${name}`)
    .filter((asset) => !recorded.has(asset))
    .map((asset) => `${asset} is not produced by the renderer`);
}

async function readManifest(file) {
  const document = JSON.parse(await readFile(file, 'utf8'));
  if (document?.schema !== manifestSchema || !Array.isArray(document.artifacts)) {
    throw new Error(`expected schema ${manifestSchema}`);
  }
  return document;
}

async function listFiles(directory) {
  const entries = await readdir(directory, { withFileTypes: true });
  return entries
    .filter((entry) => entry.isFile())
    .map((entry) => path.join(directory, entry.name))
    .sort();
}

function isWorkAsset(asset) {
  return (
    typeof asset === 'string' &&
    /^assets\/work\/[a-z0-9][a-z0-9-]*\.(png|jpg|webp)$/.test(asset)
  );
}

function sha256(bytes) {
  return createHash('sha256').update(bytes).digest('hex');
}
