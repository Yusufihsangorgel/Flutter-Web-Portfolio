const months = [
  'January', 'February', 'March', 'April', 'May', 'June',
  'July', 'August', 'September', 'October', 'November', 'December',
];

export function escapeHtml(value) {
  return String(value).replace(/[&<>"']/g, (character) => ({
    '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;',
  })[character]);
}

export function validatePaper(paper) {
  if (!['a4', 'letter'].includes(paper)) throw new Error('Paper must be a4 or letter.');
  return paper;
}

export function formatDate(value) {
  const match = /^(\d{4})-(\d{2})-(\d{2})$/.exec(value);
  const date = new Date(`${value}T00:00:00Z`);
  if (!match || !Number.isFinite(date.getTime()) || date.toISOString().slice(0, 10) !== value) {
    throw new Error('Dates must be valid YYYY-MM-DD values.');
  }
  return `${months[Number(match[2]) - 1]} ${Number(match[3])}, ${match[1]}`;
}

export function formatPeriod(value) {
  return String(value).trim().replace(/\s+(?:—|–|-)\s+/g, ' — ');
}

function paragraph(value, className = '') {
  return value ? `<p${className ? ` class="${className}"` : ''}>${escapeHtml(value)}</p>` : '';
}

function link(value, label = '') {
  const url = new URL(value);
  if (url.protocol !== 'https:' || url.username || url.password) {
    throw new Error('Resume links must be absolute HTTPS URLs without credentials.');
  }
  return `${label ? `${escapeHtml(label)}: ` : ''}<a href="${escapeHtml(value)}">${escapeHtml(value)}</a>`;
}

function section(title, entries) {
  return entries.length ? `<section><h2>${title}</h2><ul>${entries.join('')}</ul></section>` : '';
}

function experienceEntry(entry) {
  const heading = [entry.role, entry.company].filter(Boolean).map(escapeHtml).join(' — ');
  return `<li><h3>${heading}</h3>${paragraph(entry.period && formatPeriod(entry.period), 'date')}${paragraph(entry.summary)}</li>`;
}

function selected(entries, limit) {
  const available = entries ?? [];
  const featured = available.filter((entry) => entry.featured === true);
  return (featured.length ? featured : available).slice(0, limit);
}

function contributionEntry(entry) {
  const heading = [entry.project, entry.title].filter(Boolean).map(escapeHtml).join(' — ');
  const details = [entry.date && formatDate(entry.date), entry.status].filter(Boolean).join(' · ');
  return `<li><h3>${heading}</h3>${paragraph(details, 'date')}${paragraph(entry.change)}<p class="url">${link(entry.url)}</p></li>`;
}

function packageEntry(entry) {
  return `<li><h3>${escapeHtml(entry.name)}</h3>${paragraph(entry.description)}<p class="url">${link(entry.url)}</p></li>`;
}

function writingEntry(entry) {
  return `<li><h3>${escapeHtml(entry.title)}</h3>${paragraph(entry.date && formatDate(entry.date), 'date')}<p class="url">${link(entry.url)}</p></li>`;
}

function printStyles(paper, fontBase64) {
  if (fontBase64 && !/^[A-Za-z\d+/]+={0,2}$/.test(fontBase64)) throw new Error('Font must be base64 encoded.');
  const fontFace = fontBase64 ? `@font-face { font-family: Resume; src: url(data:font/ttf;base64,${fontBase64}) format("truetype"); font-weight: 100 900; }\n` : '';
  return `${fontFace}@page { size: ${paper === 'a4' ? 'A4' : 'Letter'}; margin: 14mm; }
* { box-sizing: border-box; }
body { color: #111; font: 10pt/1.3 Resume, Arial, "Liberation Sans", sans-serif; margin: 0 auto; max-width: 182mm; padding: 5mm; }
h1 { font-size: 22pt; line-height: 1.15; margin: 0 0 4pt; }
h2 { font-size: 12pt; border-bottom: 1px solid #777; margin: 12pt 0 5pt; break-after: avoid; }
h3 { font-size: 10pt; margin: 0; break-after: avoid; }
p { margin: 3pt 0; }
ul { list-style: none; padding: 0; margin: 0; }
li { margin-bottom: 7pt; break-inside: avoid; }
.role { font-size: 12pt; }
.date { color: #333; }
.url { font-size: 9pt; }
a { color: inherit; overflow-wrap: anywhere; text-decoration: underline; }
@media print { body { max-width: none; padding: 0; } }`;
}

export function renderResumeHtml(record, { paper = 'a4', fontBase64 } = {}) {
  validatePaper(paper);
  const profile = record.profile;
  if (!profile?.name?.trim()) throw new Error('A profile name is required.');
  const contacts = [profile.location, profile.email].filter(Boolean).map(escapeHtml);
  const links = [...(profile.links ?? [])];
  if (record.site?.url && !links.some((entry) => entry.url === record.site.url)) {
    links.unshift({ url: record.site.url });
  }
  const header = `<header><h1>${escapeHtml(profile.name)}</h1>${paragraph(profile.role, 'role')}${contacts.length ? `<p>${contacts.join(' · ')}</p>` : ''}${links.map((entry) => `<p class="url">${link(entry.url, entry.label)}</p>`).join('')}</header>`;
  const sections = [
    paragraph(profile.summary),
    section('Experience', (record.experience ?? []).map(experienceEntry)),
    section('Selected contributions', selected(record.contributions, 3).map(contributionEntry)),
    section('Selected packages', selected(record.packages, 3).map(packageEntry)),
    section('Selected writing', selected(record.writing, 2).map(writingEntry)),
  ].join('\n');
  return `<!doctype html>
<html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width, initial-scale=1"><meta http-equiv="Content-Security-Policy" content="default-src 'none'; style-src 'unsafe-inline'; font-src data:; base-uri 'none'"><title>${escapeHtml(profile.name)} — Resume</title><style>${printStyles(paper, fontBase64)}</style></head>
<body><main>${header}\n${sections}</main></body></html>\n`;
}
