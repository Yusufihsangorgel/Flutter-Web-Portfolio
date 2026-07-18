import { access, readFile, stat } from 'node:fs/promises';
import path from 'node:path';
import process from 'node:process';
import { fileURLToPath } from 'node:url';

import { resolvePagesBaseHref } from './resolve_pages_base_href.mjs';

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const read = (relativePath) => readFile(path.join(root, relativePath), 'utf8');
const failures = [];

const firebase = JSON.parse(await read('firebase.json'));
const vercel = JSON.parse(await read('vercel.json'));
const netlify = await read('netlify.toml');
const headers = await read('web/_headers');
const redirects = await read('web/_redirects');
const nginx = await read('nginx/default.conf');
const pagesWorkflow = await read('.github/workflows/deploy.yml');

expect(firebase.hosting?.public === 'build/web', 'Firebase publishes build/web');
expect(
  firebase.hosting?.rewrites?.some(
    (rewrite) => rewrite.source === '**' && rewrite.destination === '/index.html',
  ),
  'Firebase preserves document routes',
);
expect(
  vercel.buildCommand === 'bash tool/hosted_build.sh' &&
    vercel.outputDirectory === 'build/web',
  'Vercel uses the pinned hosted build',
);
expect(
  netlify.includes('command = "bash tool/hosted_build.sh"') &&
    netlify.includes('publish = "build/web"'),
  'Netlify uses the pinned hosted build',
);
expect(
  redirects.includes('/*  /index.html  200'),
  'static providers preserve document routes',
);
expect(
  pagesWorkflow.includes('tool/resolve_pages_base_href.mjs') &&
    pagesWorkflow.includes('npm run build:release -- --base-href'),
  'GitHub Pages resolves its hosting path through the canonical release command',
);
expect(
  resolvePagesBaseHref({ repository: 'portfolio', owner: 'ada' }) ===
    '/portfolio/',
  'project Pages uses its repository path',
);
expect(
  resolvePagesBaseHref({ repository: 'ada.github.io', owner: 'ada' }) === '/',
  'user Pages uses the origin root',
);
expect(
  resolvePagesBaseHref({
    repository: 'portfolio',
    owner: 'ada',
    cname: 'portfolio.example.com',
  }) === '/',
  'custom-domain Pages uses the origin root',
);
expect(
  resolvePagesBaseHref({
    repository: 'portfolio',
    owner: 'ada',
    override: '/preview/site',
  }) === '/preview/site/',
  'an explicit Pages base path is normalized',
);
expectThrows(
  () =>
    resolvePagesBaseHref({
      repository: 'portfolio',
      owner: 'ada',
      override: '/preview/%2e%2e/private',
    }),
  'Pages base paths reject encoded traversal',
);

for (const [name, value] of [
  ['Cross-Origin-Opener-Policy', 'same-origin'],
  ['Cross-Origin-Embedder-Policy', 'credentialless'],
  ['X-Content-Type-Options', 'nosniff'],
]) {
  expect(headers.includes(`${name}: ${value}`), `static headers include ${name}`);
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
    nginx.includes(`add_header ${name} "${value}"`),
    `Nginx headers include ${name}`,
  );
}

expect(
  headers.includes('/assets/*\n  Cache-Control: public, max-age=0, must-revalidate'),
  'stable static assets revalidate',
);
expect(
  headers.includes('/canvaskit/*\n  Cache-Control: public, max-age=31536000, immutable'),
  'revisioned renderer assets are immutable',
);
expect(
  JSON.stringify(firebase.hosting?.headers).includes('assets/**') &&
    JSON.stringify(firebase.hosting?.headers).includes('must-revalidate'),
  'Firebase revalidates stable assets',
);
expect(
  JSON.stringify(firebase.hosting?.headers).includes('canvaskit/**') &&
    JSON.stringify(firebase.hosting?.headers).includes('immutable'),
  'Firebase caches revisioned renderer assets immutably',
);

const hostedBuild = path.join(root, 'tool', 'hosted_build.sh');
await access(hostedBuild);
expect(((await stat(hostedBuild)).mode & 0o111) !== 0, 'hosted build is executable');

if (failures.length > 0) {
  for (const failure of failures) console.error(`- ${failure}`);
  process.exit(1);
}

console.log('Hosting contracts verified for Firebase, Netlify, Cloudflare, Vercel, and Nginx.');

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
