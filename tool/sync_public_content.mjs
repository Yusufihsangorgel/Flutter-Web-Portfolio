import { readFile, writeFile } from 'node:fs/promises';
import path from 'node:path';
import process from 'node:process';
import { fileURLToPath } from 'node:url';

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const checkOnly = process.argv.includes('--check');
const sourcePath = path.join(root, 'assets', 'content', 'portfolio.json');
const document = JSON.parse(await readFile(sourcePath, 'utf8'));

const operations = [
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
  const current = await readFile(file, 'utf8');
  const start = `<!-- ${marker}:start -->`;
  const end = `<!-- ${marker}:end -->`;
  const pattern = new RegExp(
    `${escapeRegExp(start)}[\\s\\S]*?${escapeRegExp(end)}`,
  );
  if (!pattern.test(current)) {
    throw new Error(`${path.relative(root, file)} is missing ${marker} markers`);
  }
  const next = current.replace(pattern, `${start}\n${body}\n${end}`);
  if (next === current) return { file, changed: false };
  if (!checkOnly) await writeFile(file, next);
  return { file, changed: true };
}

async function syncManifest(data) {
  const file = path.join(root, 'web', 'manifest.json');
  const current = await readFile(file, 'utf8');
  const manifest = JSON.parse(current);
  manifest.name = `${data.profile.role} Portfolio`;
  manifest.short_name = 'Portfolio';
  manifest.start_url = '.';
  manifest.description = data.site.description;
  const currentManifest = JSON.parse(current);
  if (
    currentManifest.name === manifest.name &&
    currentManifest.short_name === manifest.short_name &&
    currentManifest.start_url === manifest.start_url &&
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
  const lines = [
    '## Public engineering record',
    '',
    `**${data.profile.role}.** ${data.profile.headline}`,
    '',
    `${data.profile.summary}`,
    '',
    `Source status: \`${data.content_version}\`, verified ${data.verified_at} against the public GitHub and LinkedIn records declared in the manifest.`,
    '',
    '### Accepted upstream changes',
    '',
    '| Project | Change | Merged | Evidence |',
    '|---|---|---:|---|',
    ...merged.map(
      (item) =>
        `| ${table(item.project)} | ${table(item.title)} | ${item.date} | [Pull request](${item.url}) |`,
    ),
    '',
    '### Public systems',
    '',
    '| System | Engineering focus | Source |',
    '|---|---|---|',
    ...data.systems.map(
      (item) =>
        `| ${table(item.name)} | ${table(item.decision)} | [Repository](${item.url}) |`,
    ),
  ];

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

function renderHeadMeta(data) {
  const site = data.site;
  const image = new URL(site.social_image, site.url).toString();
  const title = html(site.title);
  const description = html(site.description);
  const social = html(site.social_description);
  const role = html(data.profile.role);
  return `  <link rel="canonical" href="${site.url}">
  <title>${title}</title>
  <meta name="description" content="${description}">
  <meta name="keywords" content="Software Engineer, Flutter, Dart, Go, PostgreSQL, Redis, Docker, Kubernetes, Open Source">
  <meta name="author" content="Portfolio owner">

  <meta property="og:type" content="website">
  <meta property="og:url" content="${site.url}">
  <meta property="og:title" content="${title}">
  <meta property="og:description" content="${social}">
  <meta property="og:site_name" content="${role} Portfolio">
  <meta property="og:image" content="${image}">
  <meta property="og:image:secure_url" content="${image}">
  <meta property="og:image:type" content="image/png">
  <meta property="og:image:width" content="1200">
  <meta property="og:image:height" content="630">
  <meta property="og:image:alt" content="${role} — Flutter, Dart, Go, and selected open-source work">
  <meta property="og:locale" content="en_US">

  <meta name="twitter:card" content="summary_large_image">
  <meta name="twitter:title" content="${title}">
  <meta name="twitter:description" content="${social}">
  <meta name="twitter:image" content="${image}">
  <meta name="twitter:image:alt" content="${role} — Flutter, Dart, Go, and selected open-source work">`;
}

function renderStructuredData(data) {
  return `  <script type="application/ld+json">
  ${JSON.stringify(
    {
      '@context': 'https://schema.org',
      '@type': 'WebSite',
      name: `${data.profile.role} Portfolio`,
      description: data.site.social_description,
      url: data.site.url,
    },
    null,
    2,
  ).replaceAll('\n', '\n  ')}
  </script>`;
}

function table(value) {
  return String(value).replaceAll('|', '\\|').replaceAll('\n', ' ');
}

function html(value) {
  return String(value)
    .replaceAll('&', '&amp;')
    .replaceAll('"', '&quot;')
    .replaceAll('<', '&lt;')
    .replaceAll('>', '&gt;');
}

function escapeRegExp(value) {
  return value.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
}
