import assert from 'node:assert/strict';
import { test } from 'node:test';
import {
  decodeFeedEntities,
  decideWrite,
  extractAtomLink,
  extractTagText,
  fetchWritingSourceEntries,
  mergeWritingEntries,
  parseAtomItems,
  parseDevToArticles,
  parseFeedItems,
  parseRssItems,
  refreshWriting,
} from './refresh_portfolio_data.mjs';
import { renderStaticDocument } from '../release/render_static_document.mjs';

const rssSource = { id: 'rss', kind: 'rss', url: 'https://example.com/feed.xml' };
const atomSource = { id: 'atom', kind: 'rss', url: 'https://example.org/feed.xml' };
const headers = { feedHeaders: {}, jsonHeaders: {} };
const isoDate = '2026-07-29T06:41:58.000Z';

function rssFeed(items = '') {
  return `<rss version="2.0"><channel>${items}</channel></rss>`;
}

function rssItem(title = 'Resource title', publication = `<pubDate>${isoDate}</pubDate>`) {
  return `<item><title>${title}</title><link>https://example.com/resource</link>${publication}</item>`;
}

function atomFeed(entries = '') {
  return `<feed xmlns="http://www.w3.org/2005/Atom">${entries}</feed>`;
}

function atomEntry(publication = `<published>${isoDate}</published>`, links = '') {
  return `<entry><title>Resource title</title>${links || '<link href="https://example.org/resource"/>'}${publication}</entry>`;
}

function mockFetch(t, responses) {
  const requests = [];
  t.mock.method(globalThis, 'fetch', async (input) => {
    const url = String(input);
    requests.push(url);
    assert.ok(Object.hasOwn(responses, url), `Unexpected request: ${url}`);
    const { body, status = 200 } = responses[url];
    return new Response(body, { status });
  });
  return requests;
}

function writingContext(sources, previous = []) {
  return {
    document: {
      writing_sources: structuredClone(sources),
      writing: structuredClone(previous),
      technical_settings: { retain: 'unchanged' },
    },
    headers: { feed: {}, pub: {} },
    limiter: async (fn) => fn(),
    writingFailures: [],
    visibleChanges: [],
    anyFailure: false,
    writingChanged: false,
    writingEntryCount: previous.length,
    previousWritingEntryCount: previous.length,
    writingSourceCount: sources.length,
  };
}

const malformedFeeds = [
  ['HTML', '<!doctype html><html><body>Temporarily unavailable</body></html>'],
  ['plain text', 'Feed temporarily unavailable'],
  ['empty response', ''],
  ['cut RSS root', '<rss version="2.0"><channel>'],
  ['cut Atom entry', '<feed><entry><title>Resource title</title>'],
  ['unclosed RSS item', '<rss><channel><item></channel></rss>'],
  ['unclosed Atom entry with closed root', '<feed><entry></feed>'],
  ['cut CDATA', '<rss><channel><description><![CDATA[cut</description></channel></rss>'],
  ['cut comment', '<feed><!-- cut</feed>'],
  ['HTML containing an item', `<html>${rssItem()}</html>`],
  ['trailing non-XML text', `${rssFeed()}cut`],
];

for (const [label, body] of malformedFeeds) {
  test(`HTTP 200 ${label} is a source failure, not an empty success`, async (t) => {
    const requests = mockFetch(t, { [rssSource.url]: { body } });
    const result = await fetchWritingSourceEntries(rssSource, headers);
    assert.equal(result.ok, false);
    assert.match(result.failure, /^rss: /);
    assert.throws(() => parseFeedItems(body), /RSS\/Atom/);
    assert.deepEqual(requests, [rssSource.url]);
  });
}

const emptyFeeds = [
  ['RSS', rssFeed()],
  ['self-closing RSS channel', '<rss version="2.0"><channel/></rss>'],
  ['Atom', atomFeed()],
  ['self-closing Atom', '<feed xmlns="http://www.w3.org/2005/Atom"/>'],
  ['prolog and comments', ` \n<?xml version="1.0"?>\n<!-- feed -->${rssFeed()}<!-- end -->\n`],
  ['declared RSS', `<!DOCTYPE rss SYSTEM "https://example.invalid/feed.dtd">${rssFeed()}`],
  ['commented Atom', `<!-- feed -->${atomFeed()}<!-- end -->`],
];

for (const [label, body] of emptyFeeds) {
  test(`valid empty ${label} remains a successful empty source`, async (t) => {
    mockFetch(t, { [rssSource.url]: { body } });
    assert.deepEqual(await fetchWritingSourceEntries(rssSource, headers), {
      ok: true,
      entries: [],
    });
  });
}

test('balanced content, comments, CDATA and quoted greater-than signs stay valid', () => {
  const body = `<?xml version="1.0"?>
    <!-- <item>not an item</item> -->
    <rss version="2.0"><channel><description><![CDATA[<unclosed>]]></description>
    <item resource=">"><title><![CDATA[Raw &amp; title]]></title>
    <link>https://example.com/resource?x=1&amp;y=2</link>
    <pubDate>Wed, 29 Jul 2026 06:41:58 GMT</pubDate></item></channel></rss>`;
  assert.deepEqual(parseFeedItems(body), [
    { title: 'Raw &amp; title', url: 'https://example.com/resource?x=1&y=2', publishedAt: isoDate },
  ]);
});

const previous = [
  {
    title: 'Neighbor resource',
    url: 'https://example.org/resource/neighbor',
    source: 'atom',
    date: '2026-01-02',
    summary: 'Keep the technical summary.',
  },
  {
    title: 'Stored resource',
    url: 'https://example.com/resource/stored',
    source: 'rss',
    date: '2026-01-01',
    metadata: { retain: true },
  },
];

for (const [label, body] of malformedFeeds.slice(0, 5)) {
  test(`${label} preserves prior entries while a valid neighbor updates`, async (t) => {
    const neighbor = atomFeed(`<entry><title>Neighbor resource</title>
      <link href="https://example.org/resource/neighbor"/><updated>${isoDate}</updated></entry>
      <entry><title>Stored resource!</title><link href="https://example.org/resource/duplicate"/>
      <published>${isoDate}</published></entry>`);
    const requests = mockFetch(t, {
      [rssSource.url]: { body },
      [atomSource.url]: { body: neighbor },
    });
    const ctx = writingContext([rssSource, atomSource], previous);
    await refreshWriting(ctx);
    assert.deepEqual(ctx.document.writing, [{ ...previous[0], date: '2026-07-29' }, previous[1]]);
    assert.deepEqual(ctx.document.technical_settings, { retain: 'unchanged' });
    assert.deepEqual(ctx.document.writing_sources, [rssSource, atomSource]);
    assert.equal(ctx.writingFailures.length, 1);
    assert.match(ctx.writingFailures[0], /^rss: /);
    assert.equal(ctx.anyFailure, false);
    assert.equal(ctx.writingChanged, true);
    assert.equal(ctx.writingEntryCount, 2);
    assert.equal(ctx.previousWritingEntryCount, 2);
    assert.equal(ctx.writingSourceCount, 2);
    assert.equal(ctx.visibleChanges.length, 1);
    assert.equal(
      decideWrite({
        anyFailure: ctx.anyFailure,
        check: false,
        hasVisible: true,
        hasCounters: false,
        includeCounters: false,
      }),
      true,
    );
    assert.deepEqual(requests, [rssSource.url, atomSource.url]);
  });
}

test('a failed source alone does not change the stored document or mark a visible change', async (t) => {
  mockFetch(t, { [rssSource.url]: { body: '<html>Unavailable</html>' } });
  const ctx = writingContext([rssSource], [previous[1]]);
  const before = structuredClone(ctx.document);
  await refreshWriting(ctx);
  assert.deepEqual(ctx.document, before);
  assert.equal(ctx.writingChanged, false);
  assert.deepEqual(ctx.visibleChanges, []);
  assert.equal(ctx.writingFailures.length, 1);
});

for (const [label, body] of [
  ['RSS', rssFeed()],
  ['Atom', atomFeed()],
]) {
  test(`valid empty ${label} may intentionally remove stored managed entries`, async (t) => {
    mockFetch(t, { [rssSource.url]: { body } });
    const ctx = writingContext([rssSource], [previous[1]]);
    await refreshWriting(ctx);
    assert.deepEqual(ctx.document.writing, []);
    assert.deepEqual(ctx.writingFailures, []);
    assert.equal(ctx.writingChanged, true);
    assert.deepEqual(ctx.document.technical_settings, { retain: 'unchanged' });
  });
}

for (const publication of [
  '',
  '<pubDate/>',
  '<pubDate> </pubDate>',
  '<pubDate>invalid</pubDate>',
]) {
  test(`RSS omits an absent or invalid publication: ${publication || 'missing'}`, () => {
    const items = parseRssItems(rssFeed(rssItem('Incomplete resource', publication) + rssItem()));
    assert.deepEqual(
      items.map((item) => item.title),
      ['Resource title'],
    );
    assert.equal(items[0].publishedAt, isoDate);
  });
}

for (const publication of ['', '<published/>', '<published> </published><updated> </updated>']) {
  test(`Atom omits an absent publication: ${publication || 'missing'}`, () => {
    assert.deepEqual(parseAtomItems(atomFeed(atomEntry(publication))), []);
    assert.equal(parseAtomItems(atomFeed(atomEntry(publication) + atomEntry())).length, 1);
  });
}

const invalidDates = [undefined, null, '', '  ', 0, 1, false, true, {}, [], 'invalid'];
for (const [index, published_at] of invalidDates.entries()) {
  test(`dev.to rejects missing, empty or non-string date case ${index}`, () => {
    const items = parseDevToArticles([
      { title: 'Incomplete resource', url: 'https://example.com/resource/invalid', published_at },
      { title: 'Resource title', url: 'https://example.org/resource', published_at: isoDate },
    ]);
    assert.deepEqual(items, [
      { title: 'Resource title', url: 'https://example.org/resource', publishedAt: isoDate },
    ]);
  });
}

test('dev.to JSON fetch preserves the valid neighbor while omitting null and numeric dates', async (t) => {
  const source = { id: 'json', kind: 'devto', url: 'https://example.org/articles.json' };
  const body = JSON.stringify(
    [null, 0, '1970-01-01T00:00:00Z'].map((published_at) => ({
      title: 'Resource title',
      url: 'https://example.org/resource',
      published_at,
    })),
  );
  mockFetch(t, { [source.url]: { body } });
  assert.deepEqual(await fetchWritingSourceEntries(source, headers), {
    ok: true,
    entries: [
      {
        title: 'Resource title',
        url: 'https://example.org/resource',
        publishedAt: '1970-01-01T00:00:00.000Z',
      },
    ],
  });
});

const validDates = [
  ['RFC', 'Thu, 01 Jan 1970 00:00:00 GMT', '1970-01-01T00:00:00.000Z'],
  ['ISO epoch', '1970-01-01T00:00:00Z', '1970-01-01T00:00:00.000Z'],
  ['ISO offset', '2026-07-29T08:41:58+02:00', isoDate],
];
for (const [label, value, expected] of validDates) {
  test(`${label} is accepted without inventing or shifting a date`, () => {
    const items = parseRssItems(rssFeed(rssItem('Resource title', `<pubDate>${value}</pubDate>`)));
    assert.equal(items[0].publishedAt, expected);
    assert.equal(mergeWritingEntries({ rss: items }, ['rss'])[0].date, expected.slice(0, 10));
    assert.equal(
      parseDevToArticles([
        { title: 'Resource title', url: 'https://example.org/resource', published_at: value },
      ])[0].publishedAt,
      expected,
    );
  });
}

for (const prefix of ['', '<published> </published>']) {
  test(`updated-only Atom fallback survives ${prefix ? 'blank' : 'missing'} published`, () => {
    const entries = parseAtomItems(atomFeed(atomEntry(`${prefix}<updated>${isoDate}</updated>`)));
    assert.equal(entries[0].publishedAt, isoDate);
  });
}

test('Atom retains published precedence over updated', () => {
  const entries = parseAtomItems(
    atomFeed(atomEntry(`<published>1970-01-01T00:00:00Z</published><updated>${isoDate}</updated>`)),
  );
  assert.equal(entries[0].publishedAt, '1970-01-01T00:00:00.000Z');
});

const entities = [
  ['&amp;', '&'],
  ['&#38;', '&'],
  ['&#x26;', '&'],
  ['&amp;amp;', '&amp;'],
  ['&#38;amp;', '&amp;'],
  ['&#x26;amp;', '&amp;'],
  ['&amp;lt;', '&lt;'],
  ['&#38;lt;', '&lt;'],
  ['&#x26;lt;', '&lt;'],
  ['&#8217;', '’'],
  ['&#x2019;', '’'],
  ['%26', '%26'],
  ['&quot;', '"'],
  ['&apos;', "'"],
];
for (const [encoded, decoded] of entities) {
  test(`XML entities decode exactly once: ${encoded}`, () => {
    assert.equal(decodeFeedEntities(encoded), decoded);
    const url = `https://example.org/resource?value=${encoded}`;
    const expected = `https://example.org/resource?value=${decoded}`;
    assert.equal(extractAtomLink(`<link href="${url}"/>`), expected);
    assert.equal(extractAtomLink(`<link href='${url.replaceAll("'", '&apos;')}'/>`), expected);
    assert.equal(extractTagText(`<title>${encoded}</title>`, 'title'), decoded);
    assert.equal(extractTagText(`<title><![CDATA[${encoded}]]></title>`, 'title'), encoded);
  });
}

test('Atom selects the alternate link and otherwise the first actual href attribute', () => {
  assert.equal(
    extractAtomLink(`<link href="https://example.org/self" rel="self"/>
    <link data-href="https://example.org/incorrect" href='https://example.com/resource?a=1&amp;b=2'
    rel='altern&#97;te'/>`),
    'https://example.com/resource?a=1&b=2',
  );
  assert.equal(
    extractAtomLink(`<link title=" rel='alternate'" href="https://example.org/first"/>
    <link rel="alternate" href="https://example.org/alternate"/>`),
    'https://example.org/alternate',
  );
  assert.equal(
    extractAtomLink(
      '<link rel="self"/><link href="https://example.org/first?a=1&amp;b=2"/><link href="https://example.org/second"/>',
    ),
    'https://example.org/first?a=1&b=2',
  );
  assert.equal(extractAtomLink('<title>No link</title>'), null);
});

test('decoded URLs survive merge and JSON while static markup stays escaped', () => {
  const entry = atomEntry(
    undefined,
    '<link href="https://example.org/resource?a=1&amp;b=2&amp;literal=%26"/>',
  ).replace('Resource title', '&lt;script&gt;throw new Error(&quot;resource&quot;)&lt;/script&gt;');
  const items = parseAtomItems(atomFeed(entry));
  const writing = JSON.parse(JSON.stringify(mergeWritingEntries({ atom: items }, ['atom'])));
  assert.equal(writing[0].url, 'https://example.org/resource?a=1&b=2&literal=%26');
  assert.equal(new URL(writing[0].url).searchParams.get('b'), '2');
  assert.equal(new URL(writing[0].url).searchParams.get('literal'), '&');
  const html = renderStaticDocument({ writing });
  assert.ok(html.includes('href="https://example.org/resource?a=1&amp;b=2&amp;literal=%26"'));
  assert.ok(html.includes('&lt;script&gt;throw new Error(&quot;resource&quot;)&lt;/script&gt;'));
  assert.ok(!html.includes('<script>'));
});

test('decoded URL quotes and markup cannot add executable static elements', () => {
  const entries = parseAtomItems(
    atomFeed(
      atomEntry(
        undefined,
        '<link href="https://example.org/resource?value=&quot;&gt;&lt;script&gt;resource&lt;/script&gt;&amp;quote=&apos;"/>',
      ),
    ),
  );
  assert.equal(
    entries[0].url,
    'https://example.org/resource?value="><script>resource</script>&quote=\'',
  );
  const html = renderStaticDocument({ writing: entries });
  assert.ok(
    html.includes(
      'href="https://example.org/resource?value=%22%3E%3Cscript%3Eresource%3C/script%3E&amp;quote=%27"',
    ),
  );
  assert.ok(!html.includes('<script>'));
});

test('a non-array dev.to response follows the existing parse-failure boundary', async (t) => {
  const source = { id: 'json', kind: 'devto', url: 'https://example.org/articles.json' };
  mockFetch(t, { [source.url]: { body: '{"articles":[]}' } });
  assert.deepEqual(await fetchWritingSourceEntries(source, headers), {
    ok: false,
    failure: 'json: dev.to articles response is not an array',
  });
});

test('HTTP failure and unsupported sources retain the existing error boundary', async (t) => {
  mockFetch(t, { [rssSource.url]: { body: '', status: 403 } });
  assert.deepEqual(await fetchWritingSourceEntries(rssSource, headers), {
    ok: false,
    failure: 'rss: feed fetch: HTTP 403',
  });
  assert.equal(
    (await fetchWritingSourceEntries({ ...rssSource, kind: 'unsupported' }, headers)).ok,
    false,
  );
});
