import { access, readFile, stat } from "node:fs/promises";
import path from "node:path";
import process from "node:process";
import { fileURLToPath } from "node:url";

import { resolvePagesBaseHref } from "./resolve_pages_base_href.mjs";

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");
const read = (relativePath) => readFile(path.join(root, relativePath), "utf8");
const failures = [];

const firebase = JSON.parse(await read("firebase.json"));
const vercel = JSON.parse(await read("vercel.json"));
const netlify = await read("netlify.toml");
const headers = await read("web/_headers");
const redirects = await read("web/_redirects");
const nginx = await read("nginx/default.conf");
const pagesWorkflow = await read(".github/workflows/deploy.yml");
const ciWorkflow = await read(".github/workflows/ci.yml");
const hostedBuild = await read("tool/hosted_build.sh");
const releasePreparation = await read("tool/prepare_web_release.mjs");
const releaseVerification = await read("tool/verify_web_build.mjs");
const deployHelper = await read("tool/deploy_portfolio.mjs");
const dockerfile = await read("Dockerfile");
const dockerignore = await read(".dockerignore");
const nodeVersion = (await read(".nvmrc")).trim();
const packageDocument = JSON.parse(await read("package.json"));
const toolchain = JSON.parse(await read("tool/toolchain.json"));

expect(
  firebase.hosting?.public === "build/web",
  "Firebase publishes build/web",
);
expect(
  firebase.hosting?.rewrites?.some(
    (rewrite) =>
      rewrite.source === "**" && rewrite.destination === "/index.html",
  ),
  "Firebase preserves document routes",
);
expect(
  vercel.buildCommand === "bash tool/hosted_build.sh" &&
    vercel.outputDirectory === "build/web",
  "Vercel uses the pinned hosted build",
);
expect(
  netlify.includes('command = "bash tool/hosted_build.sh"') &&
    netlify.includes('publish = "build/web"'),
  "Netlify uses the pinned hosted build",
);
expect(
  redirects.includes("/*  /index.html  200"),
  "static providers preserve document routes",
);
expect(
  pagesWorkflow.includes("tool/resolve_pages_base_href.mjs") &&
    pagesWorkflow.includes("npm run build:release -- --base-href"),
  "GitHub Pages resolves its hosting path through the canonical release command",
);
expect(
  resolvePagesBaseHref({ repository: "portfolio", owner: "ada" }) ===
    "/portfolio/",
  "project Pages uses its repository path",
);
expect(
  resolvePagesBaseHref({ repository: "ada.github.io", owner: "ada" }) === "/",
  "user Pages uses the origin root",
);
expect(
  resolvePagesBaseHref({
    repository: "portfolio",
    owner: "ada",
    cname: "portfolio.example.com",
  }) === "/",
  "custom-domain Pages uses the origin root",
);
expect(
  resolvePagesBaseHref({
    repository: "portfolio",
    owner: "ada",
    override: "/preview/site",
  }) === "/preview/site/",
  "an explicit Pages base path is normalized",
);
expectThrows(
  () =>
    resolvePagesBaseHref({
      repository: "portfolio",
      owner: "ada",
      override: "/preview/%2e%2e/private",
    }),
  "Pages base paths reject encoded traversal",
);

for (const [name, value] of [
  ["Cross-Origin-Opener-Policy", "same-origin"],
  ["Cross-Origin-Embedder-Policy", "credentialless"],
  ["Cross-Origin-Resource-Policy", "same-origin"],
  ["X-Content-Type-Options", "nosniff"],
  ["X-Frame-Options", "SAMEORIGIN"],
  ["Referrer-Policy", "strict-origin-when-cross-origin"],
  ["Permissions-Policy", "camera=(), microphone=(), geolocation=()"],
  ["Content-Security-Policy", "default-src 'self'"],
]) {
  expect(
    headers.includes(`${name}: ${value}`),
    `static headers include ${name}`,
  );
  expect(
    JSON.stringify(firebase.hosting?.headers).includes(name) &&
      JSON.stringify(firebase.hosting?.headers).includes(value),
    `Firebase headers include ${name}`,
  );
  expect(
    JSON.stringify(vercel.headers).includes(name) &&
      JSON.stringify(vercel.headers).includes(value),
    `Vercel headers include ${name}`,
  );
  expect(
    nginx.includes(`add_header ${name} "`) && nginx.includes(value),
    `Nginx headers include ${name}`,
  );
}

expect(
  packageDocument.engines?.node === "24.x" && nodeVersion === toolchain.node,
  "provider selection stays Node 24-compatible while local tooling pins the exact canonical release",
);
expect(
  ciWorkflow.includes(`node-version: ${toolchain.node}`) &&
    pagesWorkflow.includes(`node-version: ${toolchain.node}`) &&
    ciWorkflow.includes(`flutter-version: ${toolchain.flutter}`) &&
    pagesWorkflow.includes(`flutter-version: ${toolchain.flutter}`) &&
    ciWorkflow.includes("node tool/verify_toolchain.mjs --current") &&
    pagesWorkflow.includes("node tool/verify_toolchain.mjs --current"),
  "GitHub build workflows pin and verify the canonical Node and Flutter toolchain",
);
expect(
  !hostedBuild.includes("npm run setup:browsers") &&
    hostedBuild.includes("PORTFOLIO_VERIFY_SOCIAL_CARD=true") &&
    hostedBuild.includes("tool/toolchain.json") &&
    hostedBuild.includes("NODE_VERIFY_ARGS=(--current)") &&
    hostedBuild.includes("NODE_VERIFY_ARGS+=(--allow-node-patch)") &&
    hostedBuild.includes('"${VERCEL:-}" == "1"') &&
    hostedBuild.includes(
      'node tool/verify_toolchain.mjs "${NODE_VERIFY_ARGS[@]}"',
    ) &&
    hostedBuild.includes("refs/tags/${FLUTTER_VERSION}") &&
    hostedBuild.includes("rev-list -n 1") &&
    !hostedBuild.includes("${FLUTTER_REVISION:-") &&
    !hostedBuild.includes("${FLUTTER_VERSION:-"),
  "hosted builds consume the immutable toolchain contract and verify the committed card without a browser",
);
expect(
  releasePreparation.includes(
    "for (const file of ['_headers', '_redirects'])",
  ) &&
    releasePreparation.includes(
      "path.join(webRoot, 'release-toolchain.json')",
    ) &&
    releaseVerification.includes(
      "for (const sidecar of ['_headers', '_redirects'])",
    ) &&
    releaseVerification.includes("expectedToolchain.flutterEngineRevision"),
  "static-host sidecars are copied into and verified in the release artifact",
);
expect(
  deployHelper.includes("run('vercel', ['deploy', '--prod'])") &&
    deployHelper.includes(
      "run(process.execPath, [path.join(root, 'tool', 'verify_web_build.mjs')])",
    ),
  "deploy helper preserves the Vercel project root and verifies skipped builds",
);
expect(
  dockerfile.includes("nginx:1.29.5-alpine@sha256:") &&
    dockerfile.includes("COPY packages packages") &&
    dockerignore.includes("node_modules") &&
    dockerignore.includes(".hosted-cache") &&
    !dockerignore.split(/\r?\n/).some((line) => line.trim() === "*.md"),
  "Docker uses a pinned runtime, excludes dependency caches, and keeps manifest-hashed Markdown sources",
);

expect(
  headers.includes(
    "/assets/*\n  Cache-Control: public, max-age=0, must-revalidate",
  ),
  "stable static assets revalidate",
);
expect(
  JSON.stringify(vercel.headers).includes("/assets/(.*)") &&
    JSON.stringify(vercel.headers).includes("must-revalidate"),
  "Vercel revalidates stable assets",
);
expect(
  JSON.stringify(vercel.headers).includes("main\\\\.dart\\\\.wasm") &&
    JSON.stringify(vercel.headers).includes("must-revalidate"),
  "Vercel revalidates stable release entrypoints",
);
expect(
  JSON.stringify(vercel.headers).includes(
    "/canvaskit/:revision([0-9a-f]{40})/:asset*",
  ) && JSON.stringify(vercel.headers).includes("immutable"),
  "Vercel caches revisioned renderer assets immutably",
);
expect(
  nginx.includes("add_header_inherit merge;") &&
    nginx.includes(
      'add_header Cache-Control "public, max-age=0, must-revalidate" always;',
    ) &&
    nginx.includes(
      'add_header Cache-Control "public, max-age=31536000, immutable" always;',
    ),
  "Nginx merges security headers with stable-asset revalidation and immutable revisioned renderer caching",
);

const cspValues = [
  headers.match(/^  Content-Security-Policy: (.+)$/m)?.[1],
  nginx.match(/^  add_header Content-Security-Policy "(.+)" always;$/m)?.[1],
  firebase.hosting?.headers?.[0]?.headers?.find(
    (header) => header.key === "Content-Security-Policy",
  )?.value,
  vercel.headers?.[0]?.headers?.find(
    (header) => header.key === "Content-Security-Policy",
  )?.value,
];
expect(
  cspValues.every((value) => value && value === cspValues[0]),
  "CSP is byte-for-byte synchronized across static, Nginx, Firebase, and Vercel providers",
);
for (const directive of [
  "default-src 'self'",
  "base-uri 'self'",
  "object-src 'none'",
  "form-action 'self'",
  "frame-ancestors 'self'",
]) {
  expect(cspValues[0]?.includes(`${directive};`), `CSP includes ${directive}`);
}
expect(
  headers.includes(
    "/canvaskit/*\n  Cache-Control: public, max-age=31536000, immutable",
  ),
  "revisioned renderer assets are immutable",
);
expect(
  JSON.stringify(firebase.hosting?.headers).includes("assets/**") &&
    JSON.stringify(firebase.hosting?.headers).includes("must-revalidate"),
  "Firebase revalidates stable assets",
);
expect(
  JSON.stringify(firebase.hosting?.headers).includes("canvaskit/**") &&
    JSON.stringify(firebase.hosting?.headers).includes("immutable"),
  "Firebase caches revisioned renderer assets immutably",
);

const hostedBuildPath = path.join(root, "tool", "hosted_build.sh");
await access(hostedBuildPath);
expect(
  ((await stat(hostedBuildPath)).mode & 0o111) !== 0,
  "hosted build is executable",
);

if (failures.length > 0) {
  for (const failure of failures) console.error(`- ${failure}`);
  process.exit(1);
}

console.log(
  "Hosting contracts verified for Firebase, Netlify, Cloudflare, Vercel, and Nginx.",
);

function expect(condition, message) {
  if (!condition) failures.push(message);
}

function expectThrows(operation, message) {
  try {
    operation();
    failures.push(message);
  } catch {
    // Expected validation failure.
  }
}
