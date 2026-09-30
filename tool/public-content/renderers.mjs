import { renderContentSecurityPolicy } from './security.mjs';

export function renderReadmeRecord(data) {
  const merged = data.contributions
    .filter((item) => item.status === 'merged')
    .sort((left, right) => right.date.localeCompare(left.date));
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

export function renderDemoLinks(data) {
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
      return `<a href="${html(url)}">${html(label)}</a>`;
    })
    .join(' · ');
}

export function renderCiBadge(repository) {
  if (!repository) {
    return '  <a href=".github/workflows/ci.yml"><img alt="CI workflow configuration" src="https://img.shields.io/badge/CI-configured-1E51FF?style=flat-square&amp;logo=githubactions&amp;logoColor=white"></a>';
  }
  const workflow = `https://github.com/${repository}/actions/workflows/ci.yml`;
  return `  <a href="${html(workflow)}"><img alt="CI status" src="${html(`${workflow}/badge.svg?branch=main`)}"></a>`;
}

export function renderTemplateCta(data, repository) {
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

export function renderOnboarding(data) {
  if (data.site.template_repository !== true) {
    return `This repository already contains an initialized portfolio. Clone it directly, then run the commands below to verify the current record. Run \`npm run portfolio:init\` only when you intend to replace that record and remove its optional work, experience, translations, and release artifact.`;
  }
  return `Choose **Use this template** above and create your own repository. Do not fork the demo for a personal site: GitHub forks retain the parent history, whereas a repository created from a template starts with one unrelated commit. Forks remain the right path for contributing changes back here. Clone your new repository, then run:`;
}

export function renderRecordIntro(data) {
  if (data.site.template_repository !== true) {
    return `This section is regenerated from the repository owner's canonical content document. It describes the current portfolio record rather than reusable starter data.`;
  }
  return `The live demo uses this template with the author's own record. This block is regenerated from the canonical content document; it is evidence for the demo, not starter data inherited by \`npm run portfolio:init\`.`;
}

export function renderRobots(data) {
  const site = siteDirectoryUrl(data.site.url);
  return `User-agent: *
Allow: /
Sitemap: ${new URL('sitemap.xml', site).toString()}`;
}

export function renderSitemap(data) {
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

export function renderNginxCsp(data) {
  return `  add_header Content-Security-Policy "${renderContentSecurityPolicy(data)}" always;`;
}

export function renderHeadMeta(data) {
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
  return `  <link rel="canonical" href="${site.url}">
  <title>${title}</title>
  <meta name="description" content="${description}">
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

export function renderStructuredData(data) {
  const sameAs = data.profile.links.map((link) => link.url);
  const personId = `${data.site.url.replace(/\/$/, '')}/#person`;
  const currentWork = data.experience.find((item) => item.current);
  const education = data.experience.find((item) => item.id === 'software-engineering-education');
  return `  <script type="application/ld+json">
  ${jsonForHtmlScript(
    {
      '@context': 'https://schema.org',
      '@graph': [
        {
          '@type': 'ProfilePage',
          url: data.site.url,
          mainEntity: { '@id': personId },
        },
        {
          '@type': 'Person',
          '@id': personId,
          name: data.profile.name,
          jobTitle: data.profile.role,
          email: data.profile.email,
          address: data.profile.location,
          url: data.site.url,
          sameAs,
          image: siteAssetUrl(data.site.url, data.site.social_image),
          ...(currentWork ? { worksFor: { '@type': 'Organization', name: currentWork.company } } : {}),
          ...(education ? { alumniOf: { '@type': 'EducationalOrganization', name: education.company } } : {}),
          knowsAbout: [...new Set(data.capabilities.flatMap((capability) => capability.items))],
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

export function renderAnalytics(data) {
  const analytics = data.site.analytics;
  if (!analytics) return '';
  const scriptUrl = new URL(analytics.script_url).toString();
  const domain = String(analytics.domain).trim();
  if (!domain) throw new Error('site.analytics.domain must not be empty');
  return `  <script defer src="${html(scriptUrl)}" data-domain="${html(domain)}"></script>`;
}

export function renderConductContact(data) {
  const name = markdownLabel(
    requiredString(data.profile.name, 'profile.name'),
  );
  const email = requiredEmail(data.profile.email, 'profile.email');
  return `Report conduct concerns privately to [${name}](mailto:${email}). Include the relevant context and links. Reports are reviewed discreetly; the maintainer may remove content, close participation, or restrict access when necessary to protect the project and its contributors.`;
}

export function renderSecurityContact(data) {
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

export function requiredString(value, path) {
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
