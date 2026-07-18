import { spawnSync } from 'node:child_process';
import { readFileSync } from 'node:fs';
import { readFile, writeFile } from 'node:fs/promises';
import path from 'node:path';
import process from 'node:process';
import { fileURLToPath } from 'node:url';

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
  () => syncDelimitedFile(
    path.join(root, 'nginx', 'default.conf'),
    '  # portfolio-csp:start',
    '  # portfolio-csp:end',
    renderNginxCsp(document),
  ),
  () => syncDelimitedFile(
    path.join(root, 'web', '_headers'),
    '  # portfolio-csp:start',
    '  # portfolio-csp:end',
    `  Content-Security-Policy: ${renderContentSecurityPolicy(document)}`,
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
  const current = await readFile(file, 'utf8');
  const next = `${body.trimEnd()}\n`;
  if (next === current) return { file, changed: false };
  if (!checkOnly) await writeFile(file, next);
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
  const value = renderContentSecurityPolicy(data);
  const existing = global.headers.find(
    (header) => header.key === 'Content-Security-Policy',
  );
  if (existing) existing.value = value;
  else global.headers.push({ key: 'Content-Security-Policy', value });
  const next = `${JSON.stringify(configuration, null, 2)}\n`;
  if (next === current) return { file, changed: false };
  if (!checkOnly) await writeFile(file, next);
  return { file, changed: true };
}

function renderReadmeRecord(data) {
  const merged = data.contributions.filter((item) => item.status === 'merged');
  const review = data.contributions.filter(
    (item) => item.status === 'under_review',
  );
  const sourceLabels = naturalList(data.sources.map((source) => source.label));
  const lines = [
    '## Public engineering record',
    '',
    `**${data.profile.name} — ${data.profile.role}.** ${data.profile.headline}`,
    '',
    `${data.profile.summary}`,
    '',
    `Source status: \`${data.content_version}\`, verified ${data.verified_at} against ${sourceLabels}.`,
  ];

  if (merged.length > 0) {
    lines.push(
      '',
      '### Accepted upstream changes',
      '',
      '| Project | Change | Merged | Evidence |',
      '|---|---|---:|---|',
      ...merged.map(
        (item) =>
          `| ${table(item.project)} | ${table(item.title)} | ${item.date} | [Pull request](${item.url}) |`,
      ),
    );
  }

  if (data.systems.length > 0) {
    lines.push(
      '',
      '### Selected work',
      '',
      '| Project | Responsibility | Evidence |',
      '|---|---|---|',
      ...data.systems.map(
        (item) =>
          `| ${table(item.name)} | ${table(item.ownership)} | [Project](${item.url}) |`,
      ),
    );
  }

  if (review.length > 0) {
    lines.push(
      '',
      '### Work under review',
      '',
      ...review.map(
        (item) =>
          `- **${item.project}:** [${item.title}](${item.url}) — ${item.change}`,
      ),
    );
  }
  return lines.join('\n');
}

function renderDemoLinks(data) {
  const links = data.site.engineering_links;
  if (!Array.isArray(links) || links.length === 0) {
    throw new Error('site.engineering_links must contain at least one link');
  }
  return links
    .map((link, index) => {
      const label = requiredString(
        link?.label,
        `site.engineering_links[${index}].label`,
      );
      const url = requiredHttpsUrl(
        link?.url,
        `site.engineering_links[${index}].url`,
      );
      // This fragment lives inside a raw HTML <p> block in README.md.
      // GitHub does not parse Markdown links inside that block, so emit real
      // anchors instead of leaving visible `[label](url)` syntax behind.
      return `<a href="${html(url)}">${html(label)}</a>`;
    })
    .join(' · ');
}

function renderCiBadge(repository) {
  if (!repository) {
    return '  <a href=".github/workflows/ci.yml"><img alt="CI workflow configuration" src="https://img.shields.io/badge/CI-configured-1E51FF?style=flat-square&amp;logo=githubactions&amp;logoColor=white"></a>';
  }
  const workflow = `https://github.com/${repository}/actions/workflows/ci.yml`;
  return `  <a href="${html(workflow)}"><img alt="CI status" src="${html(`${workflow}/badge.svg?branch=main`)}"></a>`;
}

function renderTemplateCta(data, repository) {
  if (data.site.template_repository !== true) {
    if (!repository) {
      return '  This repository has been initialized. Enable GitHub’s <strong>Template repository</strong> setting before offering one-click copies.';
    }
    const source = `https://github.com/${repository}`;
    return `  <a href="${html(source)}"><img alt="View repository" src="https://img.shields.io/badge/VIEW%20REPOSITORY-F2EEE5?style=for-the-badge&amp;logo=github&amp;logoColor=12110F"></a>`;
  }
  if (!repository) {
    return '  Use GitHub’s <strong>Use this template</strong> action, then run the initializer below.';
  }
  const generate = `https://github.com/${repository}/generate`;
  return `  <a href="${html(generate)}"><img alt="Create a repository from this template" src="https://img.shields.io/badge/USE%20THIS%20TEMPLATE-DFFF3F?style=for-the-badge&amp;logo=github&amp;logoColor=12110F"></a>`;
}

function renderOnboarding(data) {
  if (data.site.template_repository !== true) {
    return `This repository already contains an initialized portfolio. Clone it directly, then run the commands below to verify the current record. Run \`npm run portfolio:init\` only when you intend to replace that record and remove its optional work, experience, translations, and release artifact.`;
  }
  return `Choose **Use this template** above and create your own repository. Do not fork the demo for a personal site: GitHub forks retain the parent history, whereas a repository created from a template starts with one unrelated commit. Forks remain the right path for contributing changes back here. Clone your new repository, then run:`;
}

function renderRecordIntro(data) {
  if (data.site.template_repository !== true) {
    return `This section is regenerated from the repository owner's canonical content document. It describes the current portfolio record rather than reusable starter data.`;
  }
  return `The live demo uses the same template with a real professional record. This block is regenerated from the canonical content document; it is evidence for the demo, not starter data inherited by \`npm run portfolio:init\`.`;
}

function renderRobots(data) {
  const site = siteDirectoryUrl(data.site.url);
  return `User-agent: *
Allow: /
Sitemap: ${new URL('sitemap.xml', site).toString()}`;
}

function renderSitemap(data) {
  const site = new URL(data.site.url);
  return `<?xml version="1.0" encoding="UTF-8"?>
<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">
  <url>
    <loc>${xml(site.toString())}</loc>
    <changefreq>weekly</changefreq>
    <priority>1.0</priority>
  </url>
</urlset>`;
}

function renderContentSecurityPolicy(data) {
  const analyticsOrigin = data.site.analytics
    ? new URL(data.site.analytics.script_url).origin
    : '';
  const scripts = ["'self'", "'unsafe-inline'", "'unsafe-eval'", analyticsOrigin]
    .filter(Boolean)
    .join(' ');
  const connections = ["'self'", analyticsOrigin].filter(Boolean).join(' ');
  return `default-src 'self'; base-uri 'self'; object-src 'none'; form-action 'self'; script-src ${scripts}; worker-src 'self' blob:; style-src 'self' 'unsafe-inline'; font-src 'self'; img-src 'self' data: https: blob:; connect-src ${connections}; frame-ancestors 'self';`;
}

function renderNginxCsp(data) {
  return `  add_header Content-Security-Policy "${renderContentSecurityPolicy(data)}" always;`;
}

function renderHeadMeta(data) {
  const site = data.site;
  const image = siteAssetUrl(site.url, site.social_image);
  const title = html(site.title);
  const description = html(site.description);
  const social = html(site.social_description);
  const role = html(data.profile.role);
  const name = html(data.profile.name);
  const accessibleName = html(
    requiredString(
      data.profile.display_name?.accessible,
      'profile.display_name.accessible',
    ),
  );
  const keywords = html(
    [
      data.profile.role,
      ...data.capabilities.flatMap((capability) => capability.items),
      'Open Source',
    ]
      .filter((value, index, values) => values.indexOf(value) === index)
      .slice(0, 14)
      .join(', '),
  );
  return `  <link rel="canonical" href="${site.url}">
  <title>${title}</title>
  <meta name="description" content="${description}">
  <meta name="keywords" content="${keywords}">
  <meta name="author" content="${name}">

  <meta property="og:type" content="website">
  <meta property="og:url" content="${site.url}">
  <meta property="og:title" content="${title}">
  <meta property="og:description" content="${social}">
  <meta property="og:site_name" content="${name} — ${role}">
  <meta property="og:image" content="${image}">
  <meta property="og:image:secure_url" content="${image}">
  <meta property="og:image:type" content="image/png">
  <meta property="og:image:width" content="1200">
  <meta property="og:image:height" content="630">
  <meta property="og:image:alt" content="${accessibleName} — ${role}">
  <meta property="og:locale" content="en_US">

  <meta name="twitter:card" content="summary_large_image">
  <meta name="twitter:title" content="${title}">
  <meta name="twitter:description" content="${social}">
  <meta name="twitter:image" content="${image}">
  <meta name="twitter:image:alt" content="${accessibleName} — ${role}">`;
}

function renderStructuredData(data) {
  const sameAs = data.profile.links.map((link) => link.url);
  return `  <script type="application/ld+json">
  ${jsonForHtmlScript(
    {
      '@context': 'https://schema.org',
      '@graph': [
        {
          '@type': 'Person',
          name: data.profile.name,
          jobTitle: data.profile.role,
          email: data.profile.email,
          address: data.profile.location,
          url: data.site.url,
          sameAs,
        },
        {
          '@type': 'WebSite',
          name: `${data.profile.name} — Portfolio`,
          description: data.site.social_description,
          url: data.site.url,
        },
      ],
    },
  ).replaceAll('\n', '\n  ')}
  </script>`;
}

function renderAnalytics(data) {
  const analytics = data.site.analytics;
  if (!analytics) return '';
  const scriptUrl = new URL(analytics.script_url).toString();
  const domain = String(analytics.domain).trim();
  if (!domain) throw new Error('site.analytics.domain must not be empty');
  return `  <script defer src="${html(scriptUrl)}" data-domain="${html(domain)}"></script>`;
}

function renderConductContact(data) {
  const name = markdownLabel(
    requiredString(data.profile.name, 'profile.name'),
  );
  const email = requiredEmail(data.profile.email, 'profile.email');
  return `Report conduct concerns privately to [${name}](mailto:${email}). Include the relevant context and links. Reports are reviewed discreetly; the maintainer may remove content, close participation, or restrict access when necessary to protect the project and its contributors.`;
}

function renderSecurityContact(data) {
  const email = requiredEmail(data.profile.email, 'profile.email');
  return `Please report vulnerabilities privately to [${email}](mailto:${email}) rather than opening a public issue. Include the affected revision, reproduction steps, impact, and any suggested mitigation. Do not include secrets or personal data in the report.`;
}

function table(value) {
  return String(value).replaceAll('|', '\\|').replaceAll('\n', ' ');
}

function naturalList(values) {
  if (values.length < 2) return values.join('');
  if (values.length === 2) return values.join(' and ');
  return `${values.slice(0, -1).join(', ')}, and ${values.at(-1)}`;
}

function requiredString(value, path) {
  if (typeof value !== 'string' || value.trim().length === 0) {
    throw new Error(`${path} must be a non-empty string`);
  }
  return value.trim();
}

function requiredEmail(value, path) {
  const email = requiredString(value, path);
  if (
    email.length > 254 ||
    !/^[A-Za-z0-9._%+\-]+@[A-Za-z0-9](?:[A-Za-z0-9\-]{0,61}[A-Za-z0-9])?(?:\.[A-Za-z0-9](?:[A-Za-z0-9\-]{0,61}[A-Za-z0-9])?)+$/.test(
      email,
    )
  ) {
    throw new Error(`${path} must be a safe public email address`);
  }
  return email;
}

function requiredHttpsUrl(value, path) {
  const raw = requiredString(value, path);
  const url = new URL(raw);
  if (url.protocol !== 'https:') {
    throw new Error(`${path} must be an absolute HTTPS URL`);
  }
  return url.toString();
}

function markdownLabel(value) {
  return value
    .replaceAll('\\', '\\\\')
    .replaceAll('[', '\\[')
    .replaceAll(']', '\\]');
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

function siteDirectoryUrl(value) {
  const site = new URL(value);
  if (!site.pathname.endsWith('/')) site.pathname = `${site.pathname}/`;
  site.search = '';
  site.hash = '';
  return site;
}

function siteAssetUrl(siteUrl, assetPath) {
  const relative = requiredString(assetPath, 'site.social_image').replace(/^\/+/, '');
  return new URL(relative, siteDirectoryUrl(siteUrl)).toString();
}

function jsonForHtmlScript(value) {
  return JSON.stringify(value, null, 2).replace(
    /[<>&\u2028\u2029]/g,
    (character) => ({
      '<': '\\u003c',
      '>': '\\u003e',
      '&': '\\u0026',
      '\u2028': '\\u2028',
      '\u2029': '\\u2029',
    })[character],
  );
}

function html(value) {
  return String(value)
    .replaceAll('&', '&amp;')
    .replaceAll('"', '&quot;')
    .replaceAll('<', '&lt;')
    .replaceAll('>', '&gt;');
}

function xml(value) {
  return String(value)
    .replaceAll('&', '&amp;')
    .replaceAll('<', '&lt;')
    .replaceAll('>', '&gt;')
    .replaceAll('"', '&quot;')
    .replaceAll("'", '&apos;');
}

function escapeRegExp(value) {
  return value.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
}
