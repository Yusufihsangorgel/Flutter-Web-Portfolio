import { readFile, writeFile } from 'node:fs/promises';
import path from 'node:path';
import process from 'node:process';
import { fileURLToPath } from 'node:url';

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const checkOnly = process.argv.includes('--check');
const sourcePath = path.join(root, 'assets', 'content', 'portfolio.json');
const document = JSON.parse(await readFile(sourcePath, 'utf8'));

const operations = [
  () => syncDelimitedFile(
    path.join(root, 'README.md'),
    '<!-- portfolio-demo:start -->',
    '<!-- portfolio-demo:end -->',
    renderDemoLinks(document),
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
      return `[${markdownLabel(label)}](${url})`;
    })
    .join(' · ');
}

function renderRobots(data) {
  const site = new URL(data.site.url);
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

function renderNginxCsp(data) {
  const analyticsOrigin = data.site.analytics
    ? new URL(data.site.analytics.script_url).origin
    : '';
  const scripts = ["'self'", "'unsafe-inline'", "'unsafe-eval'", analyticsOrigin]
    .filter(Boolean)
    .join(' ');
  const connections = ["'self'", analyticsOrigin].filter(Boolean).join(' ');
  return `  add_header Content-Security-Policy "default-src 'self'; script-src ${scripts}; worker-src 'self' blob:; style-src 'self' 'unsafe-inline'; font-src 'self'; img-src 'self' data: https: blob:; connect-src ${connections}; frame-ancestors 'self';" always;`;
}

function renderHeadMeta(data) {
  const site = data.site;
  const image = new URL(site.social_image, site.url).toString();
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
  ${JSON.stringify(
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
    null,
    2,
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
