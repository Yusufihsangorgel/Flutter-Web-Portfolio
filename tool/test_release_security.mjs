import assert from "node:assert/strict";
import { spawnSync } from "node:child_process";
import { mkdir, mkdtemp, readFile, rm, symlink, writeFile } from "node:fs/promises";
import os from "node:os";
import path from "node:path";

import {
  normalizeBaseHref,
  resolveExecutable,
  validateDeploymentValue,
} from "./cli_safety.mjs";
import { assertRasterDimensions, inspectRaster } from "./raster_inspector.mjs";
import { renderSourceManifest } from "./source_manifest.mjs";
import {
  serializeSocialCardFingerprint,
  sha256,
  verifySocialCardFingerprint,
} from "./social_card_fingerprint.mjs";
import { parseGlobalStaticHeaders } from "./static_header_policy.mjs";
import {
  canonicalStaticRoot,
  resolveStaticFile,
  StaticPathViolation,
} from "./safe_static_path.mjs";

assert.equal(normalizeBaseHref("portfolio"), "/portfolio/");
assert.equal(normalizeBaseHref("/preview/site/"), "/preview/site/");
for (const malicious of [
  "../private",
  "/%2e%2e/private",
  "/%252e%252e/private",
  "/safe%2f..%2fprivate",
  "/safe\\..\\private",
  "/safe?x=$(touch pwned)",
  "/safe#fragment",
  "https://attacker.invalid/",
  "/safe;$(touch pwned)",
  "/safe\n--output=/tmp/pwned",
]) {
  assert.throws(() => normalizeBaseHref(malicious), malicious);
}

for (const [kind, valid] of [
  ["firebase-project", "portfolio-prod1"],
  ["cloudflare-project", "portfolio_pages"],
  ["netlify-site", "9b552cf4-51f9-4b71-b3e1-0ea62bff3333"],
  ["docker-image", "registry.example.com:5000/team/portfolio:v1.2.3"],
]) {
  assert.equal(validateDeploymentValue(kind, valid), valid);
  for (const malicious of [
    "--help",
    "safe;touch-pwned",
    "safe && touch pwned",
    "safe$(touch-pwned)",
    "safe`touch-pwned`",
    "../private",
    "safe\n--token=stolen",
  ]) {
    assert.throws(
      () => validateDeploymentValue(kind, malicious),
      `${kind}: ${malicious}`,
    );
  }
}
assert.equal(resolveExecutable("npm", "win32"), "npm.cmd");
assert.equal(resolveExecutable("flutter", "win32"), "flutter.bat");
assert.equal(resolveExecutable("dart", "win32"), "dart.bat");
assert.equal(resolveExecutable("docker", "win32"), "docker");
assert.equal(resolveExecutable("npm", "linux"), "npm");

const staticFixture = await mkdtemp(path.join(os.tmpdir(), "portfolio-static-root-"));
const staticRoot = path.join(staticFixture, "web");
const outsideFile = path.join(staticFixture, "private.txt");
try {
  await mkdir(staticRoot);
  await writeFile(path.join(staticRoot, "index.html"), "safe");
  await writeFile(outsideFile, "private");
  await symlink(outsideFile, path.join(staticRoot, "leak.txt"));
  const canonicalRoot = canonicalStaticRoot(staticRoot);
  assert.equal(
    resolveStaticFile(canonicalRoot, "/missing-route"),
    path.join(canonicalRoot, "index.html"),
  );
  assert.throws(
    () => resolveStaticFile(canonicalRoot, "/leak.txt"),
    StaticPathViolation,
  );
} finally {
  await rm(staticFixture, { recursive: true, force: true });
}

const inputDigest = "a".repeat(64);
const card = await readFile("web/assets/og/engineering-showcase.png");
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
  "a bit-flipped committed PNG must invalidate its fingerprint",
);
assert.equal(
  verifySocialCardFingerprint({
    fingerprintText: fingerprint,
    expectedInputDigest: "b".repeat(64),
    pngBytes: card,
  }),
  false,
  "changed renderer inputs must invalidate the fingerprint",
);

const png = inspectRaster(card, "social card fixture");
assert.deepEqual(png, { format: "png", width: 1200, height: 630 });
assertRasterDimensions(png, 1200, 630, "social card fixture");
assert.throws(
  () => assertRasterDimensions(png, 1201, 630, "wrong-size fixture"),
  /expected 1201x630/,
);
assert.throws(
  () => inspectRaster(bitFlippedCard, "corrupt PNG fixture"),
  /corrupt|invalid/,
);

// Self-contained neutral fixture: a 16x16 baseline JPEG generated from a solid
// color. Template initialization may intentionally remove every demo artifact,
// so release tooling tests must not depend on the original portfolio content.
const jpegBytes = Buffer.from(
  "/9j/4AAQSkZJRgABAgAAAQABAAD//gAQTGF2YzYyLjI4LjEwMQD/2wBDAAgEBAQEBAUFBQUFBQYGBgYGBgYGBgYGBgYGBwcICAgHBwcGBgcHCAgICAkJCQgICAgJCQoKCgwMCwsODg4RERT/xABMAAEBAAAAAAAAAAAAAAAAAAAABwEBAQAAAAAAAAAAAAAAAAAABQcQAQAAAAAAAAAAAAAAAAAAAAARAQAAAAAAAAAAAAAAAAAAAAD/wAARCAAQABADASIAAhEAAxEA/9oADAMBAAIRAxEAPwCOAL+Kf//Z",
  "base64",
);
const jpeg = inspectRaster(jpegBytes, "JPEG fixture");
assert.deepEqual(jpeg, { format: "jpeg", width: 16, height: 16 });
assert.throws(
  () =>
    inspectRaster(
      jpegBytes.subarray(0, jpegBytes.length - 32),
      "truncated JPEG",
    ),
  /truncated|missing/,
);

const sourceManifest = await renderSourceManifest();
assert.match(
  sourceManifest,
  /  packages\/adaptive_render_budget\/lib\/adaptive_render_budget\.dart$/m,
);
assert.doesNotMatch(
  sourceManifest,
  /  packages\/adaptive_render_budget\/pubspec\.lock$/m,
  "ignored package lockfiles must not make release provenance machine-specific",
);
for (const output of [
  "web/assets/og/engineering-showcase.png",
  "web/assets/og/engineering-showcase.png.sha256",
]) {
  // The file is in the tree; the manifest must still not list it.
  await readFile(output);
  assert.doesNotMatch(
    sourceManifest,
    manifestLine(output),
    `${output} is regenerated by prepare:source and must not be attested by its bytes`,
  );
}
for (const input of [
  "assets/content/portfolio.json",
  "package-lock.json",
  "tool/render_social_card.mjs",
  "tool/social_card.html",
]) {
  assert.match(
    sourceManifest,
    manifestLine(input),
    `${input} determines the social card and must stay attested`,
  );
}

const manifestFixtureSources = {
  "analysis_options.yaml": "analysis_options.yaml\n",
  "package.json": "package.json\n",
  "package-lock.json": "package-lock.json\n",
  "pubspec.yaml": "pubspec.yaml\n",
  "pubspec.lock": "pubspec.lock\n",
  "assets/content/portfolio.json": portfolioFixture("/assets/og/card.png?v=1"),
  "lib/main.dart": "void main() {}\n",
  "tool/render_social_card.mjs": "// renderer input\n",
  "web/index.html": "<!doctype html>\n",
  "web/assets/og/other.png": "hand-authored image beside the card\n",
  "packages/fixture/lib/fixture.dart": "library fixture;\n",
};
const manifestFixtureGenerated = {
  "packages/fixture/pubspec.lock": "generated lock\n",
  "packages/fixture/.dart_tool/state": "generated\n",
  "packages/fixture/build/output": "generated\n",
  "packages/fixture/node_modules/package": "generated\n",
};
const manifestFixtureRegenerated = {
  "web/assets/og/card.png": "card rendered on the committing machine",
  "web/assets/og/card.png.sha256": "fingerprint of an older input digest",
  "assets/build/source_manifest.sha256": "manifest of the previous run\n",
};
const manifestFixture = await mkdtemp(
  path.join(os.tmpdir(), "portfolio-source-manifest-"),
);
try {
  await assertSourceManifestContract(manifestFixture);
} finally {
  await rm(manifestFixture, { recursive: true, force: true });
}
const dockerfile = await readFile("Dockerfile", "utf8");
assert.match(dockerfile, /^COPY packages packages$/m);
assert.match(dockerfile, /^RUN sha256sum -c \/tmp\/source_manifest\.sha256/m);
const buildHelper = await readFile("tool/build_portfolio.mjs", "utf8");
assert.match(
  buildHelper,
  /run\(process\.execPath, \['tool\/verify_toolchain\.mjs', '--current'\]\)/,
);
assert.match(buildHelper, /shell: false/);
const deployHelper = await readFile("tool/deploy_portfolio.mjs", "utf8");
assert.match(deployHelper, /shell: false/);
const initializer = await readFile("tool/init_portfolio.mjs", "utf8");
assert.match(initializer, /resolveExecutable\(command\)/);
assert.match(initializer, /shell: false/);
assert.doesNotMatch(buildHelper, /shell: process\.platform/);
assert.doesNotMatch(deployHelper, /shell: process\.platform/);
assert.doesNotMatch(initializer, /shell: process\.platform/);
const hostedBuild = await readFile("tool/hosted_build.sh", "utf8");
assert.match(hostedBuild, /TOOLCHAIN_JSON="tool\/toolchain\.json"/);
assert.match(hostedBuild, /"\$\{VERCEL:-\}" == "1"/);
assert.match(hostedBuild, /--allow-node-patch/);
assert.doesNotMatch(hostedBuild, /FLUTTER_(?:VERSION|REVISION)="\$\{FLUTTER_/);

const staticHeaderSource = await readFile("web/_headers", "utf8");
const staticHeaders = Object.fromEntries(
  parseGlobalStaticHeaders(staticHeaderSource).map(({ name, value }) => [
    name.toLowerCase(),
    value,
  ]),
);
for (const name of [
  "content-security-policy",
  "cross-origin-embedder-policy",
  "cross-origin-opener-policy",
  "cross-origin-resource-policy",
  "permissions-policy",
  "referrer-policy",
  "x-content-type-options",
  "x-frame-options",
]) {
  assert.ok(staticHeaders[name], `preview policy must include ${name}`);
}
assert.doesNotMatch(staticHeaders["content-security-policy"], /api\.github\.com/);
assert.throws(
  () => parseGlobalStaticHeaders("/*\n  Set-Cookie: unsafe=true\n"),
  /may not set Set-Cookie/,
);
assert.throws(
  () =>
    parseGlobalStaticHeaders(
      "/*\n  X-Frame-Options: SAMEORIGIN\n  x-frame-options: DENY\n",
    ),
  /repeats x-frame-options/,
);
assert.throws(
  () => parseGlobalStaticHeaders("/*\n  X-Frame-Options SAMEORIGIN\n"),
  /malformed/,
);
const previewServer = await readFile("tool/serve_web.mjs", "utf8");
assert.match(previewServer, /parseGlobalStaticHeaders/);
assert.match(previewServer, /resolveStaticFile/);
assert.match(previewServer, /Cache-Control', 'no-store'/);
assert.doesNotMatch(previewServer, /api\.(?:github|rss2json)\.com/);

const [gitignore, dockerignore] = await Promise.all([
  readFile(".gitignore", "utf8"),
  readFile(".dockerignore", "utf8"),
]);
for (const pattern of [".env.*", "*.key", "*.pem", ".vercel/"]) {
  assert.ok(gitignore.includes(pattern), `.gitignore must cover ${pattern}`);
}
for (const pattern of [".env.*", "*.key", "*.pem", ".vercel"]) {
  assert.ok(dockerignore.includes(pattern), `.dockerignore must cover ${pattern}`);
}
assert.match(gitignore, /^\/build\/\*$/m);
assert.doesNotMatch(gitignore, /^!\/build\/web\//m);
assert.match(
  dockerignore,
  /^build\/\*\n!build\/web\n!build\/web\/\*\*$/m,
  "the Docker context must exclude build output except build/web",
);

const pubspec = await readFile("pubspec.yaml", "utf8");
const fontSection = pubspec.split("\n  fonts:\n")[1];
assert.ok(fontSection, "pubspec must declare its fonts section");
const fontAssets = [...fontSection.matchAll(/^        - asset: (.+)$/gm)].map(
  (match) => match[1].trim(),
);
assert.ok(
  fontAssets.length > 0,
  "pubspec must declare at least one font asset",
);
assert.equal(
  new Set(fontAssets).size,
  fontAssets.length,
  "each variable font file must be registered exactly once",
);

for (const [script, arguments_, message] of [
  [
    "tool/build_portfolio.mjs",
    ["--base-href", "/safe;$(touch-pwned)"],
    "unsafe path segment",
  ],
  [
    "tool/init_portfolio.mjs",
    ["--unknown", "value"],
    "Unexpected argument",
  ],
  [
    "tool/build_portfolio.mjs",
    ["--unknown"],
    "Unexpected argument",
  ],
  [
    "tool/build_portfolio.mjs",
    ["--base-href", "/one/", "--base-href", "/two/"],
    "may only be provided once",
  ],
  [
    "tool/deploy_portfolio.mjs",
    ["firebase", "--skip-build", "--project", "safe;touch-pwned"],
    "Invalid firebase-project",
  ],
  [
    "tool/deploy_portfolio.mjs",
    ["docker", "--skip-build", "--image", "safe;touch-pwned"],
    "Invalid docker-image",
  ],
]) {
  const result = spawnSync(process.execPath, [script, ...arguments_], {
    encoding: "utf8",
    shell: false,
  });
  assert.notEqual(result.status, 0, `${script} must reject adversarial input`);
  assert.match(`${result.stdout}${result.stderr}`, new RegExp(message));
}

process.stdout.write("Release security contracts passed.\n");

async function assertSourceManifestContract(root) {
  await writeTree(root, {
    ...manifestFixtureSources,
    ...manifestFixtureGenerated,
    ...manifestFixtureRegenerated,
  });
  const manifest = await renderSourceManifest(root);
  for (const source of Object.keys(manifestFixtureSources)) {
    assert.match(manifest, manifestLine(source), `${source} must be attested`);
  }
  for (const output of [
    ...Object.keys(manifestFixtureGenerated),
    ...Object.keys(manifestFixtureRegenerated),
  ]) {
    assert.doesNotMatch(
      manifest,
      manifestLine(output),
      `${output} must not enter release provenance`,
    );
  }
  await assertRegeneratedOutputsAreIgnored(root, manifest);
  await assertChangedSourceFailsVerification(root, manifest);
  await assertSocialCardOutputsFollowTheConfiguredPath(root);
  await assertMalformedSocialImageIsRejected(root);
}

// prepare:source re-renders the card before it writes the manifest, so the
// committed tree is verified against a manifest made beside different outputs.
async function assertRegeneratedOutputsAreIgnored(root, manifest) {
  await writeTree(root, {
    "web/assets/og/card.png": "card rendered by the release machine",
    "web/assets/og/card.png.sha256": "fingerprint of a newer input digest",
  });
  assert.equal(
    await renderSourceManifest(root),
    manifest,
    "re-rendering the social card must not change the manifest",
  );
  assert.deepEqual(
    await failedManifestEntries(manifest, root),
    [],
    "the manifest must verify against a tree whose regenerated outputs differ",
  );
}

async function assertChangedSourceFailsVerification(root, manifest) {
  for (const source of Object.keys(manifestFixtureSources)) {
    const target = path.join(root, ...source.split("/"));
    const original = await readFile(target);
    await writeFile(target, Buffer.concat([original, Buffer.from("\n")]));
    try {
      assert.deepEqual(
        await failedManifestEntries(manifest, root),
        [source],
        `a changed ${source} must fail verification`,
      );
      assert.notEqual(
        await renderSourceManifest(root),
        manifest,
        `a changed ${source} must change the rendered manifest`,
      );
    } finally {
      await writeFile(target, original);
    }
  }
}

async function assertSocialCardOutputsFollowTheConfiguredPath(root) {
  await writeTree(root, {
    "assets/content/portfolio.json": portfolioFixture("/social/preview.png"),
    "web/social/preview.png": "card at the configured path",
    "web/social/preview.png.sha256": "fingerprint at the configured path",
  });
  const manifest = await renderSourceManifest(root);
  for (const output of ["web/social/preview.png", "web/social/preview.png.sha256"]) {
    assert.doesNotMatch(
      manifest,
      manifestLine(output),
      `${output} is the configured social card and must not be attested`,
    );
  }
}

async function assertMalformedSocialImageIsRejected(root) {
  for (const socialImage of [undefined, "/assets/og/card.jpg", "/assets/../card.png"]) {
    await writeTree(root, {
      "assets/content/portfolio.json": portfolioFixture(socialImage),
    });
    await assert.rejects(
      renderSourceManifest(root),
      /site\.social_image/,
      `social_image ${socialImage} must fail instead of changing what is attested`,
    );
  }
}

// Mirrors `sha256sum -c`: every listed file must exist with the listed digest.
async function failedManifestEntries(manifest, root) {
  const failed = [];
  for (const line of manifest.trimEnd().split("\n")) {
    const entry = /^([0-9a-f]{64}) {2}(.+)$/.exec(line);
    assert.ok(entry, `not a sha256sum manifest line: ${line}`);
    const [, digest, relative] = entry;
    const bytes = await readFile(path.join(root, ...relative.split("/"))).catch(
      () => null,
    );
    if (bytes === null || sha256(bytes) !== digest) failed.push(relative);
  }
  return failed;
}

async function writeTree(root, files) {
  await Promise.all(
    Object.entries(files).map(async ([relative, content]) => {
      const target = path.join(root, ...relative.split("/"));
      await mkdir(path.dirname(target), { recursive: true });
      await writeFile(target, content);
    }),
  );
}

function portfolioFixture(socialImage) {
  return JSON.stringify({ site: { social_image: socialImage } });
}

function manifestLine(relative) {
  return new RegExp(`  ${relative.replace(/[.*+?^${}()|[\]\\]/g, "\\$&")}$`, "m");
}
