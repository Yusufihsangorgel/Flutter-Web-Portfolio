import assert from 'node:assert/strict';

import { renderHeadMeta, renderReadmeRecord, renderStructuredData } from './public-content/renderers.mjs';
import { renderContentSecurityPolicy, renderSecurityTxt } from './public-content/security.mjs';

const analyticsOrigin = 'https://stats.example.com';
const content = {
  content_version: '2026.01.01.1',
  verified_at: '2026-01-01',
  site: {
    url: 'https://portfolio.example.com',
    title: 'Example Engineer — Software Engineer',
    description: 'A software engineer building reliable products.',
    social_description: 'Selected work and verified contributions.',
    social_image: 'assets/og/card.png',
    analytics: { script_url: `${analyticsOrigin}/js/script.js`, domain: 'portfolio.example.com' },
  },
  sources: [{ label: 'GitHub' }, { label: 'LinkedIn' }],
  profile: {
    name: 'Example Engineer',
    role: 'Software Engineer',
    headline: 'I build reliable software.',
    summary: 'Builds and maintains production software.',
    email: 'engineer@example.com',
    location: 'London, UK',
    display_name: { accessible: 'Example Engineer' },
    links: [{ url: 'https://github.com/example' }],
  },
  experience: [
    { id: 'current-role', company: 'Current Company', current: true },
    { id: 'software-engineering-education', company: 'Example University', current: false },
  ],
  capabilities: [{ items: ['Dart', 'Go'] }, { items: ['Go', 'PostgreSQL'] }],
  contributions: [
    { status: 'merged', project: 'Alpha', title: 'First', date: '2026-01-02', url: 'https://github.com/example/alpha/pull/1' },
    { status: 'merged', project: 'Beta', title: 'Second', date: '2026-03-04', url: 'https://github.com/example/beta/pull/2' },
    { status: 'merged', project: 'Gamma', title: 'Third', date: '2026-02-03', url: 'https://github.com/example/gamma/pull/3' },
  ],
  systems: [],
};

const csp = renderContentSecurityPolicy(content);
const script = csp.match(/script-src ([^;]+);/)?.[1];
assert.equal(script, `'self' 'wasm-unsafe-eval' ${analyticsOrigin}`);
assert.ok(!script?.includes("'unsafe-inline'"));
assert.ok(!script?.includes("'unsafe-eval'"));
assert.ok(csp.includes("img-src 'self' data: blob:;"));
assert.ok(csp.includes(`connect-src 'self' ${analyticsOrigin};`));
assert.ok(csp.includes('upgrade-insecure-requests;'));
const noAnalytics = { ...content, site: { ...content.site, analytics: null } };
assert.ok(!renderContentSecurityPolicy(noAnalytics).includes(analyticsOrigin));
const remoteImage = { ...content, site: { ...content.site, social_image: 'https://images.example.invalid/card.png' } };
assert.ok(renderContentSecurityPolicy(remoteImage).includes("img-src 'self' data: blob: https://images.example.invalid;"));
assert.ok(!renderHeadMeta(content).includes('name="keywords"'));

const graph = JSON.parse(renderStructuredData(content).match(/<script type="application\/ld\+json">\s*([\s\S]*?)\s*<\/script>/)?.[1]);
const person = graph['@graph'].find((item) => item['@type'] === 'Person');
const profilePage = graph['@graph'].find((item) => item['@type'] === 'ProfilePage');
assert.equal(profilePage.mainEntity['@id'], person['@id']);
assert.equal(person.worksFor.name, 'Current Company');
assert.equal(person.alumniOf.name, 'Example University');
assert.deepEqual(person.knowsAbout, ['Dart', 'Go', 'PostgreSQL']);
assert.equal(person.image, 'https://portfolio.example.com/assets/og/card.png');
assert.ok(graph['@graph'].some((item) => item['@type'] === 'WebSite'));

const starter = { ...content, experience: [] };
const starterPerson = JSON.parse(renderStructuredData(starter).match(/<script type="application\/ld\+json">\s*([\s\S]*?)\s*<\/script>/)?.[1])['@graph']
  .find((item) => item['@type'] === 'Person');
assert.ok(!('worksFor' in starterPerson));
assert.ok(!('alumniOf' in starterPerson));

const record = renderReadmeRecord(content);
const dates = [...record.matchAll(/^\|[^\n]*\| (\d{4}-\d{2}-\d{2}) \|/gm)].map((match) => match[1]);
assert.deepEqual(dates, ['2026-03-04', '2026-02-03', '2026-01-02']);

const generated = renderSecurityTxt(content, new Date('2026-09-29T00:00:00.000Z'));
assert.ok(generated.includes('Contact: mailto:engineer@example.com\n'));
assert.ok(generated.includes('Expires: 2027-09-29T00:00:00.000Z\n'));
assert.ok(generated.includes('Preferred-Languages: en, tr\n'));
assert.ok(generated.includes('Canonical: https://portfolio.example.com/.well-known/security.txt\n'));
const projectSite = { ...content, site: { ...content.site, url: 'https://example.invalid/portfolio' } };
assert.ok(renderSecurityTxt(projectSite, new Date('2026-09-29T00:00:00.000Z')).includes('Canonical: https://example.invalid/portfolio/.well-known/security.txt\n'));

process.stdout.write('Public content security contracts passed.\n');
