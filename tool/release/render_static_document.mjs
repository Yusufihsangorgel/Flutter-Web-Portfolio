/** @type {Array<[string, string, (portfolio: any) => string]>} */
const chapters = [
  ['about', 'About', renderAbout],
  ['experience', 'Experience', renderExperience],
  ['open-source', 'Open Source contributions', renderContributions],
  ['work', 'Work', renderWork],
  ['packages', 'Packages', renderPackages],
  ['writing', 'Writing', renderWriting],
];

export function renderStaticDocument(portfolio) {
  const profile = portfolio.profile ?? {};
  const rendered = chapters
    .map(([id, title, render]) => ({ id, title, body: render(portfolio) }))
    .filter(({ body }) => body);
  const nav = rendered
    .map(({ id, title }) => `<li><a href="#${id}">${escapeHtml(title)}</a></li>`)
    .join('');
  const sections = rendered
    .map(
      ({ id, title, body }) => `<section id="${id}"><h2>${escapeHtml(title)}</h2>${body}</section>`,
    )
    .join('\n');
  const contact = [
    profile.email ? `<a href="${escapeHtml(mailto(profile.email))}">Email</a>` : '',
    ...(profile.links ?? []).map(({ label, url }) => evidenceLink(label, url)),
  ]
    .filter(Boolean)
    .join(' ');
  const sources = renderList(portfolio.sources, (item) => evidenceLink(item.label, item.url));
  return `<div id="static-document">
  <header><h1>${escapeHtml(profile.name ?? '')}</h1><p>${escapeHtml(profile.role ?? '')}</p>
    <nav aria-label="Portfolio chapters"><ul>${nav}</ul></nav></header>
  <main>${sections}</main>
  <footer><p>Contact</p>${contact}${sources ? `<p>Sources</p>${sources}` : ''}</footer>
</div>`;
}

export function evidenceUrls(portfolio) {
  const urls = (portfolio.profile?.links ?? []).map((item) => item.url);
  appendUrls(urls, portfolio.sources);
  appendUrls(urls, portfolio.contributions, ['url', 'issue_url']);
  for (const item of portfolio.systems ?? []) {
    appendUrls(urls, [item]);
    appendUrls(urls, item.evidence);
  }
  appendUrls(urls, portfolio.packages, ['url', 'repository']);
  if (portfolio.writing?.length) {
    appendUrls(urls, portfolio.writing);
    appendUrls(urls, portfolio.writing_sources, ['url', 'profile_url']);
  }
  return urls;
}

function renderAbout({ profile }) {
  const paragraphs = [profile?.summary, profile?.background].filter(Boolean);
  return paragraphs.map((value) => `<p>${escapeHtml(value)}</p>`).join('');
}

function renderExperience({ experience }) {
  return renderList(
    experience,
    (item) => `<h3>${escapeHtml(item.role ?? '')} — ${escapeHtml(item.company ?? '')}</h3>
    <p>${escapeHtml(item.period ?? '')}</p><p>${escapeHtml(item.summary ?? '')}</p>`,
  );
}

function renderContributions({ contributions }) {
  return renderList(
    contributions,
    (item) => `<h3>${escapeHtml(item.title ?? '')}</h3>
    <p>${escapeHtml(item.project ?? '')}</p><p>${escapeHtml(item.change ?? '')}</p>
    ${item.url ? evidenceLink('Pull request', item.url) : ''}
    ${item.issue_url ? evidenceLink('Issue', item.issue_url) : ''}`,
  );
}

function renderWork({ systems }) {
  return renderList(
    systems,
    (item) => `<h3>${escapeHtml(item.name ?? '')}</h3>
    <p>${escapeHtml(item.summary ?? '')}</p>
    ${item.url ? evidenceLink(item.name ?? 'Project', item.url) : ''}
    ${renderList(item.evidence, (evidence) => evidenceLink(evidence.label ?? 'Evidence', evidence.url))}`,
  );
}

function renderPackages({ packages }) {
  return renderList(
    packages,
    (item) => `<h3>${escapeHtml(item.name ?? '')}</h3>
    <p>${escapeHtml(item.description ?? '')}</p>
    ${item.url ? evidenceLink('Package', item.url) : ''}
    ${item.repository ? evidenceLink('Repository', item.repository) : ''}`,
  );
}

function renderWriting({ writing, writing_sources: sources }) {
  if (!writing?.length) return '';
  const articles = renderList(
    writing,
    (item) => `<h3>${escapeHtml(item.title ?? '')}</h3>
    ${evidenceLink('Read article', item.url)}`,
  );
  const archives = renderList(
    sources,
    (item) => `${escapeHtml(item.label ?? '')}
    ${item.url ? evidenceLink('Source', item.url) : ''}
    ${item.profile_url ? evidenceLink('Profile', item.profile_url) : ''}`,
  );
  return `${articles}${archives}`;
}

function renderList(items, render) {
  if (!items?.length) return '';
  return `<ul>${items.map((item) => `<li>${render(item)}</li>`).join('')}</ul>`;
}

function evidenceLink(label, url) {
  return `<a data-evidence-link="" href="${escapeHtml(safeUrl(url))}">${escapeHtml(label)}</a>`;
}

function safeUrl(value) {
  if (typeof value !== 'string' || !/^https?:\/\//i.test(value)) {
    throw new Error(`Unsafe URL: ${String(value)}`);
  }
  return new URL(value).href;
}

function mailto(value) {
  if (typeof value !== 'string' || !/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(value)) {
    throw new Error('Invalid contact address');
  }
  return `mailto:${value}`;
}

function escapeHtml(value) {
  return String(value).replace(
    /[&<>"']/g,
    (character) =>
      ({
        '&': '&amp;',
        '<': '&lt;',
        '>': '&gt;',
        '"': '&quot;',
        "'": '&#39;',
      })[character],
  );
}

function appendUrls(urls, items, fields = ['url']) {
  for (const item of items ?? []) {
    for (const field of fields) {
      if (item[field]) urls.push(item[field]);
    }
  }
}
