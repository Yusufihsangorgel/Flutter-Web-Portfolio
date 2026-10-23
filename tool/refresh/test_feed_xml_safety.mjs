import assert from 'node:assert/strict';
import { execFile } from 'node:child_process';
import { realpathSync } from 'node:fs';
import { test } from 'node:test';
import {
  extractAtomLink,
  extractTagText,
  fetchWritingSourceEntries,
  parseAtomItems,
  parseFeedItems,
  parseRssItems,
  refreshWriting,
} from './refresh_portfolio_data.mjs';

const source = { id: 'rss', kind: 'rss', url: 'https://example.com/feed.xml' };
const headers = { feedHeaders: {}, jsonHeaders: {} };
const date = '2026-07-29T00:00:00.000Z';
const ghostItem = `<item><title>Sample resource</title><link>https://example.org/sample</link>
  <pubDate>${date}</pubDate></item>`;
const ghostEntry = `<entry><title>Sample resource</title>
  <link rel="alternate" href="https://example.org/sample"/><updated>${date}</updated></entry>`;
const sampleLink = '<link rel="alternate" href="https://example.org/embedded-sample"/>';
const realItem = `<item><title><![CDATA[Actual &amp; <item>title resource</item>]]></title>
  <link><![CDATA[https://example.com/resource?literal=&amp;&encoded=%26]]></link>
  <pubDate><![CDATA[Wed, 29 Jul 2026 00:00:00 GMT]]></pubDate></item>`;
const realEntry = `<entry><title><![CDATA[Actual &amp; <entry>title resource</entry>]]></title>
  <link rel="alternate" href="https://example.com/resource?x=1&amp;y=2"/>
  <updated><![CDATA[${date}]]></updated></entry>`;

function mockFeed(t, body) {
  const requests = [];
  t.mock.method(globalThis, 'fetch', async (input) => {
    requests.push(String(input));
    assert.equal(String(input), source.url, 'Only the mocked feed may be requested');
    return new Response(body, { status: 200 });
  });
  return requests;
}

const wrappers = [
  ['comment', '<!--', '-->'],
  ['CDATA', '<description><![CDATA[', ']]></description>'],
  ['nested description', '<description>', '</description>'],
];
for (const [label, before, after] of wrappers) {
  test(`RSS ${label} item examples do not become articles`, async (t) => {
    const body = `<rss><channel>${before}${ghostItem}${after}</channel></rss>`;
    const requests = mockFeed(t, body);
    assert.deepEqual(await fetchWritingSourceEntries(source, headers), { ok: true, entries: [] });
    assert.deepEqual(parseRssItems(body), []);
    assert.deepEqual(requests, [source.url]);
  });

  test(`RSS ${label} examples leave real field CDATA intact`, async (t) => {
    const body = `<rss><channel>${before}${ghostItem}${after}${realItem}</channel></rss>`;
    mockFeed(t, body);
    const expected = [
      {
        title: 'Actual &amp; <item>title resource</item>',
        url: 'https://example.com/resource?literal=&amp;&encoded=%26',
        publishedAt: date,
      },
    ];
    assert.deepEqual(parseFeedItems(body), expected);
    assert.deepEqual(await fetchWritingSourceEntries(source, headers), {
      ok: true,
      entries: expected,
    });
  });
}

const atomWrappers = [
  ['comment', '<!--', '-->'],
  ['CDATA', '<content><![CDATA[', ']]></content>'],
  ['nested content', '<content>', '</content>'],
];
for (const [label, before, after] of atomWrappers) {
  test(`Atom ${label} entry examples are not selected`, async (t) => {
    const body = `<feed>${before}${ghostEntry}${after}${realEntry}</feed>`;
    mockFeed(t, body);
    assert.deepEqual(await fetchWritingSourceEntries(source, headers), {
      ok: true,
      entries: [
        {
          title: 'Actual &amp; <entry>title resource</entry>',
          url: 'https://example.com/resource?x=1&y=2',
          publishedAt: date,
        },
      ],
    });
  });

  test(`Atom ${label} alternate examples cannot replace the real link`, () => {
    const fragment = `<title>Actual resource</title>${before}${sampleLink}${after}
      <link href="https://example.com/self" rel="self"/>
      <link href="https://example.com/actual-article?a=1&amp;b=2" rel="alternate"/>
      <updated>${date}</updated>`;
    assert.equal(extractAtomLink(fragment), 'https://example.com/actual-article?a=1&b=2');
    assert.equal(
      parseAtomItems(`<entry>${fragment}</entry>`)[0].url,
      'https://example.com/actual-article?a=1&b=2',
    );
  });

  test(`Atom ${label} examples do not become fallback hrefs or fields`, () => {
    const fragment = `${before}${sampleLink}<title>Sample resource</title>
      <published>1970-01-01T00:00:00Z</published>${after}
      <title><![CDATA[Actual &amp; <title>resource</title>]]></title>
      <link href='https://example.com/actual-article?x=&#38;amp;' />
      <updated>${date}</updated>`;
    assert.equal(extractAtomLink(fragment), 'https://example.com/actual-article?x=&amp;');
    assert.equal(extractTagText(fragment, 'title'), 'Actual &amp; <title>resource</title>');
    assert.deepEqual(parseAtomItems(`<entry>${fragment}</entry>`), [
      {
        title: 'Actual &amp; <title>resource</title>',
        url: 'https://example.com/actual-article?x=&amp;',
        publishedAt: date,
      },
    ]);
  });
}

test('opaque RSS examples still permit intentional deletion of previous managed entries', async (t) => {
  mockFeed(t, `<rss><channel><!--${ghostItem}--></channel></rss>`);
  const ctx = {
    document: {
      writing_sources: [source],
      writing: [
        {
          title: 'Stored resource',
          url: 'https://example.com/stored',
          source: 'rss',
          date: '2026-01-01',
          metadata: { keep: true },
        },
      ],
      technical_settings: { keep: true },
    },
    headers: { feed: {}, pub: {} },
    limiter: async (fn) => fn(),
    writingFailures: [],
    visibleChanges: [],
    writingChanged: false,
  };
  await refreshWriting(ctx);
  assert.deepEqual(ctx.document.writing, []);
  assert.deepEqual(ctx.document.technical_settings, { keep: true });
  assert.deepEqual(ctx.writingFailures, []);
  assert.equal(ctx.writingChanged, true);
});

const declarations = [
  '<!DOCTYPE rss SYSTEM "https://example.invalid/feed.dtd">',
  '<!DOCTYPE rss PUBLIC "resource > [ ]" "https://example.invalid/feed.dtd">',
  `<!DOCTYPE rss [<!ENTITY resource "Resource > [ ]"><!-- ] [ " --><?resource ] [ ?>]>`,
];
for (const declaration of declarations) {
  test(`bounded declaration preserves valid feed neighbors: ${declaration}`, async (t) => {
    const body = `<?xml version="1.0"?><!-- before -->${declaration}
      <rss><channel><item><title>&resource;</title><link>https://example.com/resource</link>
      <pubDate>${date}</pubDate></item></channel></rss><!-- after -->`;
    const requests = mockFeed(t, body);
    assert.deepEqual(await fetchWritingSourceEntries(source, headers), {
      ok: true,
      entries: [{ title: '&resource;', url: 'https://example.com/resource', publishedAt: date }],
    });
    assert.deepEqual(requests, [source.url]);
  });
}

const deadlineProgram = `
import { createHash } from 'node:crypto';
import { readFileSync, realpathSync } from 'node:fs';
const moduleUrl = process.argv[1];
const sourceUrl = new URL('./feeds.mjs', moduleUrl);
const hash = (value) => createHash('sha256').update(value).digest('hex');
const body = '<!DOCTYPE ' + '[]'.repeat(32);
console.log(JSON.stringify({ runtime: {
  execRealpath: realpathSync(process.execPath), version: process.version,
  execSHA256: hash(readFileSync(process.execPath)), argv: process.argv,
  execArgv: process.execArgv, cwd: process.cwd(),
}, sourceUrl: sourceUrl.href, sourceSHA256: hash(readFileSync(sourceUrl)), inputBytes: Buffer.byteLength(body) }));
const first = { id: 'rss', kind: 'rss', url: 'https://example.com/feed.xml' };
const neighbor = { id: 'neighbor', kind: 'rss', url: 'https://example.org/feed.xml' };
const requests = [];
globalThis.fetch = async (url) => {
  requests.push(String(url));
  if (url === first.url) return new Response(body);
  if (url !== neighbor.url) throw new Error('Unexpected request');
  return new Response('<rss><channel><item><title>Neighbor resource</title><link>https://example.org/resource</link><pubDate>2026-07-29T00:00:00Z</pubDate></item></channel></rss>');
};
const { refreshWriting } = await import(moduleUrl);
const previous = { title: 'Stored resource', url: 'https://example.com/stored', source: 'rss', date: '2026-01-01', metadata: { keep: true } };
const ctx = { document: { writing_sources: [first, neighbor], writing: [previous] },
  headers: { feed: {}, pub: {} }, limiter: async (fn) => fn(), writingFailures: [], visibleChanges: [] };
const start = performance.now();
await refreshWriting(ctx);
console.log(JSON.stringify({ result: { writing: ctx.document.writing, writingFailures: ctx.writingFailures, requests }, elapsedMs: performance.now() - start, sourceSHA256: hash(readFileSync(sourceUrl)) }));
`;

/** @returns {Promise<{exit: string | number, signal: string | null, timedOut: boolean, stdout: string, stderr: string}>} */
function runDoctypeProbe() {
  return new Promise((resolve) => {
    execFile(
      process.execPath,
      [
        '--max-old-space-size=64',
        '--input-type=module',
        '--eval',
        deadlineProgram,
        '--',
        new URL('./refresh_portfolio_data.mjs', import.meta.url).href,
      ],
      {
        cwd: process.cwd(),
        env: {},
        encoding: 'utf8',
        timeout: 1500,
        killSignal: 'SIGKILL',
        maxBuffer: 65536,
      },
      (error, stdout, stderr) =>
        resolve({
          exit: error?.code ?? 0,
          signal: error?.signal ?? null,
          timedOut: error?.killed === true,
          stdout,
          stderr,
        }),
    );
  });
}

test('unfinished DOCTYPE reaches source preservation within an owned child deadline', async () => {
  const probe = await runDoctypeProbe();
  console.log(JSON.stringify({ boundedDoctypeProbe: probe }));
  assert.equal(probe.timedOut, false, 'The 74-byte declaration exceeded the owned child deadline');
  assert.equal(probe.exit, 0, probe.stderr);
  const [identity, outcome] = probe.stdout
    .trim()
    .split('\n')
    .map((line) => JSON.parse(line));
  assert.equal(identity.runtime.execRealpath, realpathSync(process.execPath));
  assert.equal(identity.runtime.version, process.version);
  assert.equal(identity.runtime.cwd, process.cwd());
  assert.equal(identity.inputBytes, 74);
  assert.equal(identity.sourceSHA256, outcome.sourceSHA256);
  assert.deepEqual(outcome.result, {
    writing: [
      {
        title: 'Neighbor resource',
        url: 'https://example.org/resource',
        source: 'neighbor',
        date: '2026-07-29',
      },
      {
        title: 'Stored resource',
        url: 'https://example.com/stored',
        source: 'rss',
        date: '2026-01-01',
        metadata: { keep: true },
      },
    ],
    writingFailures: ['rss: Invalid or incomplete RSS/Atom document'],
    requests: ['https://example.com/feed.xml', 'https://example.org/feed.xml'],
  });
});

function recordFields(kind, missing = '') {
  const fields = [
    ['title', '<title><![CDATA[Actual &amp; resource]]></title>'],
    [
      'link',
      kind === 'rss'
        ? '<link>https://example.com/actual?a=1&amp;b=2</link>'
        : '<link rel="alternate" href="https://example.com/actual?a=1&amp;b=2"/>',
    ],
    [
      'date',
      kind === 'rss'
        ? '<pubDate><![CDATA[Wed, 29 Jul 2026 00:00:00 GMT]]></pubDate>'
        : `<updated><![CDATA[${date}]]></updated>`,
    ],
  ];
  return fields
    .filter(([field]) => field !== missing)
    .map(([, markup]) => markup)
    .join('');
}

function recordDocument(kind, records) {
  return kind === 'rss' ? `<rss><channel>${records}</channel></rss>` : `<feed>${records}</feed>`;
}

for (const kind of ['rss', 'atom']) {
  const recordTag = kind === 'rss' ? 'item' : 'entry';
  const extensionFields =
    kind === 'rss'
      ? '<title>Embedded resource</title><link>https://example.org/embedded</link><pubDate>1970-01-01T00:00:00Z</pubDate>'
      : '<title>Embedded resource</title><link rel="alternate" href="https://example.org/embedded"/><published>1970-01-01T00:00:00Z</published>';
  const neighbor = `<${recordTag}><title>Neighbor resource</title>${
    kind === 'rss'
      ? '<link>https://example.org/neighbor</link><pubDate>2026-07-29T00:00:00Z</pubDate>'
      : '<link href="https://example.org/neighbor"/><updated>2026-07-29T00:00:00Z</updated>'
  }</${recordTag}>`;
  for (const nestedTag of ['item', 'entry']) {
    for (const missing of ['', 'title', 'link', 'date']) {
      test(`${kind} nested ${nestedTag} cannot own ${missing || 'the actual'} fields`, async (t) => {
        const extension = `<${nestedTag} xmlns="urn:technical:extension">${extensionFields}</${nestedTag}>`;
        const record = `<${recordTag}>${extension}${recordFields(kind, missing)}</${recordTag}>`;
        const body = recordDocument(kind, record + neighbor);
        const requests = mockFeed(t, body);
        const actual = {
          title: 'Actual &amp; resource',
          url: 'https://example.com/actual?a=1&b=2',
          publishedAt: date,
        };
        const validNeighbor = {
          title: 'Neighbor resource',
          url: 'https://example.org/neighbor',
          publishedAt: date,
        };
        const expected = missing ? [validNeighbor] : [actual, validNeighbor];
        assert.deepEqual(await fetchWritingSourceEntries(source, headers), {
          ok: true,
          entries: expected,
        });
        assert.deepEqual(parseFeedItems(body), expected);
        assert.deepEqual(requests, [source.url]);
      });
    }
  }
}

test('generic field helpers retain bare-fragment and whole-wrapper convenience', () => {
  const title = '<title><![CDATA[Actual &amp; resource]]></title>';
  for (const wrapper of ['item', 'entry']) {
    assert.equal(
      extractTagText(`<${wrapper}>${title}</${wrapper}>`, 'title'),
      'Actual &amp; resource',
    );
  }
  assert.equal(extractTagText(title, 'title'), 'Actual &amp; resource');
  const links =
    '<link rel="self" href="https://example.org/self"/><link rel="alternate" href="https://example.com/actual?a=1&amp;b=2"/>';
  assert.equal(extractAtomLink(`<entry>${links}</entry>`), 'https://example.com/actual?a=1&b=2');
  assert.equal(extractAtomLink(links), 'https://example.com/actual?a=1&b=2');
});

test('unsupported candidate depths are ignored without rejecting real field neighbors', async (t) => {
  const nested =
    '<item>'.repeat(8) +
    '<title>Nested resource</title><link>https://example.org/nested</link><pubDate>1970-01-01T00:00:00Z</pubDate>' +
    '</item>'.repeat(8);
  const record = `<item>${nested}${recordFields('rss')}</item>`;
  const neighbor =
    '<item><title>Neighbor resource</title><link>https://example.org/neighbor</link><pubDate>2026-07-30T00:00:00Z</pubDate></item>';
  mockFeed(t, recordDocument('rss', record + neighbor));
  const ctx = {
    document: {
      writing_sources: [source],
      writing: [
        {
          title: 'Actual &amp; resource',
          url: 'https://example.com/actual?a=1&b=2',
          source: 'rss',
          date: '2026-01-01',
          metadata: { keep: true },
        },
      ],
      technical_settings: { keep: true },
    },
    headers: { feed: {}, pub: {} },
    limiter: async (fn) => fn(),
    writingFailures: [],
    visibleChanges: [],
    writingChanged: false,
  };
  await refreshWriting(ctx);
  assert.deepEqual(
    ctx.document.writing.map((entry) => entry.title),
    ['Neighbor resource', 'Actual &amp; resource'],
  );
  assert.deepEqual(ctx.document.writing[1].metadata, { keep: true });
  assert.deepEqual(ctx.document.technical_settings, { keep: true });
  assert.deepEqual(ctx.writingFailures, []);
  assert.equal(ctx.writingChanged, true);
});
