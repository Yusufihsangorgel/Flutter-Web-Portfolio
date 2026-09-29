import { spawnSync } from 'node:child_process';
import { readFileSync } from 'node:fs';
import { mkdir, readFile, writeFile } from 'node:fs/promises';
import path from 'node:path';
import process from 'node:process';
import { fileURLToPath } from 'node:url';

import { renderLlmsTxt } from './render_llms_txt.mjs';
import {
  renderContentSecurityPolicy,
  renderSecurityTxt,
  securityHeaders,
} from './public-content/security.mjs';
import {
  renderAnalytics,
  renderCiBadge,
  renderConductContact,
  renderDemoLinks,
  renderHeadMeta,
  renderNginxCsp,
  renderOnboarding,
  renderReadmeRecord,
  renderRecordIntro,
  renderRobots,
  renderSecurityContact,
  renderSitemap,
  renderStructuredData,
  renderTemplateCta,
  requiredString,
} from './public-content/renderers.mjs';

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const checkOnly = process.argv.includes('--check');
const sourcePath = path.join(root, 'assets', 'content', 'portfolio.json');
const document = JSON.parse(await readFile(sourcePath, 'utf8'));
const githubRepository = detectGithubRepository();

const operations = [
  () => syncDelimitedFile(
    path.join(root, 'README.md'),
    '<!-- portfolio-ci:start -->',
    '<!-- portfolio-ci:end -->',
    renderCiBadge(githubRepository),
  ),
  () => syncDelimitedFile(
    path.join(root, 'README.md'),
    '<!-- portfolio-template:start -->',
    '<!-- portfolio-template:end -->',
    renderTemplateCta(document, githubRepository),
  ),
  () => syncMarkedFile(
    path.join(root, 'README.md'),
    'portfolio-onboarding',
    renderOnboarding(document),
  ),
  () => syncDelimitedFile(
    path.join(root, 'README.md'),
    '<!-- portfolio-demo:start -->',
    '<!-- portfolio-demo:end -->',
    renderDemoLinks(document),
  ),
  () => syncMarkedFile(
    path.join(root, 'README.md'),
    'portfolio-record-intro',
    renderRecordIntro(document),
  ),
  () => syncMarkedFile(
    path.join(root, 'README.md'),
    'portfolio-record',
    renderReadmeRecord(document),
  ),
  () => syncMarkedFile(
    path.join(root, 'web', 'index.html'),
    'portfolio-meta',
    renderHeadMeta(document),
  ),
  () => syncMarkedFile(
    path.join(root, 'web', 'index.html'),
    'portfolio-structured-data',
    renderStructuredData(document),
  ),
  () => syncMarkedFile(
    path.join(root, 'web', 'index.html'),
    'portfolio-analytics',
    renderAnalytics(document),
  ),
  () => syncMarkedFile(
    path.join(root, 'CODE_OF_CONDUCT.md'),
    'portfolio-conduct-contact',
    renderConductContact(document),
  ),
  () => syncMarkedFile(
    path.join(root, 'SECURITY.md'),
    'portfolio-security-contact',
    renderSecurityContact(document),
  ),
  () => syncWholeFile(
    path.join(root, 'web', 'robots.txt'),
    renderRobots(document),
  ),
  () => syncWholeFile(
    path.join(root, 'web', 'sitemap.xml'),
    renderSitemap(document),
  ),
  () => syncWholeFile(
    path.join(root, 'web', 'llms.txt'),
    renderLlmsTxt(document),
  ),
  () => syncSecurityTxt(path.join(root, 'web', '.well-known', 'security.txt')),
  () => syncDelimitedFile(
    path.join(root, 'nginx', 'default.conf'),
    '  # portfolio-csp:start',
    '  # portfolio-csp:end',
    `${renderNginxCsp(document)}\n  add_header Strict-Transport-Security "${securityHeaders(document)['Strict-Transport-Security']}" always;`,
  ),
  () => syncDelimitedFile(
    path.join(root, 'web', '_headers'),
    '  # portfolio-csp:start',
    '  # portfolio-csp:end',
    `  Content-Security-Policy: ${renderContentSecurityPolicy(document)}\n  Strict-Transport-Security: ${securityHeaders(document)['Strict-Transport-Security']}`,
  ),
  () => syncDelimitedFile(
    path.join(root, 'netlify.toml'),
    '# portfolio-security:start',
    '# portfolio-security:end',
    `[[headers]]\n  for = "/*"\n  [headers.values]\n  Strict-Transport-Security = "${securityHeaders(document)['Strict-Transport-Security']}"\n  Content-Security-Policy = "${renderContentSecurityPolicy(document)}"`,
  ),
  () => syncProviderJson(
    path.join(root, 'firebase.json'),
    document,
    'Firebase',
  ),
  () => syncProviderJson(
    path.join(root, 'vercel.json'),
    document,
    'Vercel',
  ),
  () => syncPackage(document),
  () => syncManifest(document),
];

const results = [];
for (const operation of operations) results.push(await operation());
const drift = results.filter((result) => result.changed);

if (checkOnly && drift.length > 0) {
  for (const result of drift) {
    console.error(`Public content drift: ${path.relative(root, result.file)}`);
  }
  process.exitCode = 1;
} else if (drift.length === 0) {
  console.log('Public content is synchronized with assets/content/portfolio.json.');
} else {
  for (const result of drift) {
    console.log(`Synchronized ${path.relative(root, result.file)}.`);
  }
}

async function syncMarkedFile(file, marker, body) {
  const start = `<!-- ${marker}:start -->`;
  const end = `<!-- ${marker}:end -->`;
  return syncDelimitedFile(file, start, end, body);
}

async function syncDelimitedFile(file, start, end, body) {
  const current = await readFile(file, 'utf8');
  const pattern = new RegExp(
    `${escapeRegExp(start)}[\\s\\S]*?${escapeRegExp(end)}`,
  );
  if (!pattern.test(current)) {
    throw new Error(
      `${path.relative(root, file)} is missing the ${start} / ${end} delimiters`,
    );
  }
  const next = current.replace(pattern, `${start}\n${body}\n${end}`);
  if (next === current) return { file, changed: false };
  if (!checkOnly) await writeFile(file, next);
  return { file, changed: true };
}

async function syncWholeFile(file, body) {
  // New whole-file targets start empty.
  const current = await readFile(file, 'utf8').catch((error) => {
    if (error.code === 'ENOENT') return '';
    throw error;
  });
  const next = `${body.trimEnd()}\n`;
  if (next === current) return { file, changed: false };
  if (!checkOnly) {
    await mkdir(path.dirname(file), { recursive: true });
    await writeFile(file, next);
  }
  return { file, changed: true };
}

async function syncSecurityTxt(file) {
  const current = await readFile(file, 'utf8').catch((error) => {
    if (error.code === 'ENOENT') return '';
    throw error;
  });
  const expected = renderSecurityTxt(document);
  const expires = current.match(/^Expires: (.+)$/m)?.[1];
  const remaining = expires ? Date.parse(expires) - Date.now() : 0;
  const matches = current.replace(/^Expires: .+$/m, '') === expected.replace(/^Expires: .+$/m, '');
  if (matches && remaining > 30 * 24 * 60 * 60 * 1000) return { file, changed: false };
  if (!checkOnly) {
    await mkdir(path.dirname(file), { recursive: true });
    await writeFile(file, expected);
  }
  return { file, changed: true };
}

async function syncPackage(data) {
  const file = path.join(root, 'package.json');
  const current = await readFile(file, 'utf8');
  const packageDocument = JSON.parse(current);
  packageDocument.homepage = data.site.url;
  if (githubRepository) {
    packageDocument.repository = {
      type: 'git',
      url: `https://github.com/${githubRepository}.git`,
    };
  }
  const next = `${JSON.stringify(packageDocument, null, 2)}\n`;
  if (next === current) return { file, changed: false };
  if (!checkOnly) await writeFile(file, next);
  return { file, changed: true };
}

async function syncManifest(data) {
  const file = path.join(root, 'web', 'manifest.json');
  const current = await readFile(file, 'utf8');
  const manifest = JSON.parse(current);
  manifest.name = `${data.profile.name} — Portfolio`;
  manifest.short_name = requiredString(
    data.profile.display_name?.navigation,
    'profile.display_name.navigation',
  );
  manifest.start_url = '.';
  manifest.background_color = '#F2EEE5';
  manifest.theme_color = '#1E51FF';
  manifest.description = data.site.description;
  const currentManifest = JSON.parse(current);
  if (
    currentManifest.name === manifest.name &&
    currentManifest.short_name === manifest.short_name &&
    currentManifest.start_url === manifest.start_url &&
    currentManifest.background_color === manifest.background_color &&
    currentManifest.theme_color === manifest.theme_color &&
    currentManifest.description === manifest.description
  ) {
    return { file, changed: false };
  }
  const next = `${JSON.stringify(manifest, null, 2)}\n`;
  if (!checkOnly) await writeFile(file, next);
  return { file, changed: true };
}

async function syncProviderJson(file, data, provider) {
  const current = await readFile(file, 'utf8');
  const configuration = JSON.parse(current);
  const headerGroups = provider === 'Firebase'
    ? configuration.hosting?.headers
    : configuration.headers;
  if (!Array.isArray(headerGroups) || headerGroups.length === 0) {
    throw new Error(`${provider} configuration is missing its global header group`);
  }
  const global = headerGroups[0];
  if (!Array.isArray(global.headers)) {
    throw new Error(`${provider} global header group is malformed`);
  }
  for (const [key, value] of Object.entries(securityHeaders(data))) {
    const existing = global.headers.find((header) => header.key === key);
    if (existing) existing.value = value;
    else global.headers.push({ key, value });
  }
  const next = `${JSON.stringify(configuration, null, 2)}\n`;
  if (next === current) return { file, changed: false };
  if (!checkOnly) await writeFile(file, next);
  return { file, changed: true };
}

function detectGithubRepository() {
  const configured = process.env.PORTFOLIO_GITHUB_REPOSITORY?.trim();
  if (configured) return validateGithubRepository(configured);
  const result = spawnSync('git', ['config', '--get', 'remote.origin.url'], {
    cwd: root,
    encoding: 'utf8',
  });
  const remote = result.status === 0
    ? result.stdout.trim()
    : configuredRepositoryFromPackage();
  if (!remote) return null;
  const match = remote.match(
    /(?:github\.com[/:])([A-Za-z0-9_.-]+)\/([A-Za-z0-9_.-]+?)(?:\.git)?$/,
  );
  return match ? `${match[1]}/${match[2]}` : null;
}

function configuredRepositoryFromPackage() {
  const packageDocument = JSON.parse(
    readFileSync(path.join(root, 'package.json'), 'utf8'),
  );
  const repository = packageDocument.repository;
  if (typeof repository === 'string') return repository;
  return typeof repository?.url === 'string' ? repository.url : null;
}

function validateGithubRepository(value) {
  if (!/^[A-Za-z0-9_.-]+\/[A-Za-z0-9_.-]+$/.test(value)) {
    throw new Error(
      'PORTFOLIO_GITHUB_REPOSITORY must use the owner/repository form',
    );
  }
  return value;
}

function escapeRegExp(value) {
  return value.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
}
