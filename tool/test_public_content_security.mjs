import assert from 'node:assert/strict';
import { readFile } from 'node:fs/promises';

import { renderHeadMeta, renderReadmeRecord, renderStructuredData } from './public-content/renderers.mjs';
import { renderContentSecurityPolicy, renderSecurityTxt } from './public-content/security.mjs';

const content = JSON.parse(await readFile(new URL('../assets/content/portfolio.json', import.meta.url), 'utf8'));
const csp = renderContentSecurityPolicy(content);
const script = csp.match(/script-src ([^;]+);/)?.[1];
assert.ok(script?.includes("'wasm-unsafe-eval'"));
assert.ok(!script?.includes("'unsafe-inline'"));
assert.ok(!script?.includes("'unsafe-eval'"));
assert.ok(csp.includes("img-src 'self' data: blob:;"));
assert.ok(csp.includes('upgrade-insecure-requests;'));
const noAnalytics = { ...content, site: { ...content.site, analytics: null } };
assert.ok(!renderContentSecurityPolicy(noAnalytics).includes('https://analytics.developeryusuf.com'));
const remoteImage = { ...content, site: { ...content.site, social_image: 'https://images.example.invalid/card.png' } };
assert.ok(renderContentSecurityPolicy(remoteImage).includes('img-src \'self\' data: blob: https://images.example.invalid;'));
assert.ok(!renderHeadMeta(content).includes('name="keywords"'));

const graph = JSON.parse(renderStructuredData(content).match(/<script type="application\/ld\+json">\s*([\s\S]*?)\s*<\/script>/)?.[1]);
const person = graph['@graph'].find((item) => item['@type'] === 'Person');
const profilePage = graph['@graph'].find((item) => item['@type'] === 'ProfilePage');
assert.equal(profilePage.mainEntity['@id'], person['@id']);
assert.equal(person.worksFor.name, content.experience.find((item) => item.current).company);
assert.equal(person.alumniOf.name, content.experience.find((item) => item.id === 'software-engineering-education').company);
assert.ok(person.knowsAbout.includes(content.capabilities[0].items[0]));
assert.equal(person.image, new URL(content.site.social_image, `${content.site.url}/`).toString());
assert.ok(graph['@graph'].some((item) => item['@type'] === 'WebSite'));

const reversed = { ...content, contributions: [...content.contributions].reverse() };
const record = renderReadmeRecord(reversed);
const dates = [...record.matchAll(/^\|[^\n]*\| (\d{4}-\d{2}-\d{2}) \|/gm)].map((match) => match[1]);
assert.deepEqual(dates, [...dates].sort().reverse());

const generated = renderSecurityTxt(content, new Date('2026-09-29T00:00:00.000Z'));
assert.ok(generated.includes(`Contact: mailto:${content.profile.email}\n`));
assert.ok(generated.includes('Expires: 2027-09-29T00:00:00.000Z\n'));
assert.ok(generated.includes('Preferred-Languages: en, tr\n'));
assert.ok(generated.includes(`Canonical: ${content.site.url}/.well-known/security.txt\n`));
const projectSite = { ...content, site: { ...content.site, url: 'https://example.invalid/portfolio' } };
assert.ok(renderSecurityTxt(projectSite, new Date('2026-09-29T00:00:00.000Z')).includes('Canonical: https://example.invalid/portfolio/.well-known/security.txt\n'));

process.stdout.write('Public content security contracts passed.\n');
