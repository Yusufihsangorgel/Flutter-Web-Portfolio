/// Renders `web/llms.txt` from the canonical portfolio content document,
/// following the llms.txt convention (https://llmstxt.org): an H1 with the
/// person's name, a one-line blockquote summary, then H2 sections of
/// Markdown link lists.
///
/// This module is intentionally free of file I/O so it can be imported by
/// both the sync tool and its test without triggering that tool's top-level
/// side effects.
export function renderLlmsTxt(data) {
  const profile = requiredObject(data.profile, 'profile');
  const site = requiredObject(data.site, 'site');

  const name = requiredString(profile.name, 'profile.name');
  const role = requiredString(profile.role, 'profile.role');
  const location = requiredString(profile.location, 'profile.location');
  const siteUrl = requiredHttpsUrl(site.url, 'site.url');
  const summary = requiredString(site.description, 'site.description');

  const lines = [`# ${name}`, '', `> ${summary}`];

  lines.push('', '## Profile');
  lines.push(`- [${markdownLabel(name)}](${siteUrl}): ${role} · ${location}`);
  if (typeof profile.email === 'string' && profile.email.includes('@')) {
    lines.push(`- [Email](mailto:${profile.email.trim()})`);
  }

  const links = renderLinks(data);
  if (links.length > 0) lines.push('', '## Links', ...links);

  const work = renderFeaturedSystems(data.systems);
  if (work.length > 0) lines.push('', '## Selected Work', ...work);

  const contributions = renderMergedContributions(data.contributions);
  if (contributions.length > 0) {
    lines.push('', '## Open Source Contributions', ...contributions);
  }

  const packages = renderPackages(data.packages);
  if (packages.length > 0) lines.push('', '## Packages', ...packages);

  return lines.join('\n');
}

function renderLinks(data) {
  const seen = new Set();
  const lines = [];
  for (const source of data.sources ?? []) {
    const url = requiredHttpsUrl(source.url, 'sources[].url');
    if (seen.has(url)) continue;
    seen.add(url);
    const label = requiredString(source.label, 'sources[].label');
    const scope = typeof source.scope === 'string' && source.scope.trim().length > 0
      ? `: ${source.scope.trim()}`
      : '';
    lines.push(`- [${markdownLabel(label)}](${url})${scope}`);
  }
  for (const link of data.profile?.links ?? []) {
    const url = requiredHttpsUrl(link.url, 'profile.links[].url');
    if (seen.has(url)) continue;
    seen.add(url);
    const label = requiredString(link.label, 'profile.links[].label');
    lines.push(`- [${markdownLabel(label)}](${url})`);
  }
  return lines;
}

function renderFeaturedSystems(systems) {
  return (systems ?? [])
    .filter((system) => system?.featured === true && isNonEmptyString(system?.url))
    .map((system, index) => {
      const name = requiredString(system.name, `systems[${index}].name`);
      const url = requiredHttpsUrl(system.url, `systems[${index}].url`);
      const summary = requiredString(system.summary, `systems[${index}].summary`);
      return `- [${markdownLabel(name)}](${url}): ${summary}`;
    });
}

function renderMergedContributions(contributions) {
  return (contributions ?? [])
    .filter((item) => item?.status === 'merged')
    .map((item, index) => {
      const project = requiredString(item.project, `contributions[${index}].project`);
      const title = requiredString(item.title, `contributions[${index}].title`);
      const url = requiredHttpsUrl(item.url, `contributions[${index}].url`);
      return `- [${markdownLabel(`${project}: ${title}`)}](${url})`;
    });
}

function renderPackages(packages) {
  return (packages ?? []).map((pkg, index) => {
    const name = requiredString(pkg.name, `packages[${index}].name`);
    const url = requiredHttpsUrl(pkg.url, `packages[${index}].url`);
    const description = requiredString(pkg.description, `packages[${index}].description`);
    const version = requiredString(pkg.version, `packages[${index}].version`);
    return `- [${markdownLabel(name)}](${url}): ${description} (v${version})`;
  });
}

function isNonEmptyString(value) {
  return typeof value === 'string' && value.trim().length > 0;
}

function requiredObject(value, path) {
  if (typeof value !== 'object' || value === null || Array.isArray(value)) {
    throw new Error(`${path} must be an object`);
  }
  return value;
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
  return raw;
}

function markdownLabel(value) {
  return value
    .replaceAll('\\', '\\\\')
    .replaceAll('[', '\\[')
    .replaceAll(']', '\\]');
}
