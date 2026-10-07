import assert from 'node:assert/strict';

import {
  buildReport,
  decodeFeedEntities,
  extractAtomLink,
  extractTagText,
  isWritingListChanged,
  mergeWritingEntries,
  normalizeWritingTitle,
  parseAtomItems,
  parseDevToArticles,
  parseFeedItems,
  parseRssItems,
} from './refresh_portfolio_data.mjs';

import { test } from './test_support.mjs';

const sampleRssFeed = `<?xml version="1.0" encoding="UTF-8"?>
<rss version="2.0">
  <channel>
    <title>Example Blog</title>
    <item>
      <title><![CDATA[A cross’posted piece]]></title>
      <link>https://example.com/posts/cross-posted</link>
      <pubDate>Wed, 29 Jul 2026 06:41:58 GMT</pubDate>
    </item>
    <item>
      <title>Plain &amp; simple title</title>
      <link>https://example.com/posts/plain</link>
      <pubDate>Mon, 20 Jul 2026 18:34:05 GMT</pubDate>
    </item>
    <item>
      <title>Missing link is skipped</title>
      <pubDate>Mon, 01 Jun 2026 00:00:00 GMT</pubDate>
    </item>
  </channel>
</rss>`;

const sampleAtomFeed = `<?xml version="1.0" encoding="utf-8"?><feed xmlns="http://www.w3.org/2005/Atom">
  <entry>
    <title type="html">A cross-posted piece</title>
    <link href="https://example.com/self" rel="self" type="text/html"/>
    <link href="https://example.com/blog/cross-posted" rel="alternate" type="text/html"/>
    <published>2026-07-16T16:01:56+00:00</published>
  </entry>
  <entry>
    <title>Only self link falls back</title>
    <link href="https://example.com/blog/only-self"/>
    <updated>2026-07-01T00:00:00+00:00</updated>
  </entry>
</feed>`;

const sampleDevToPayload = [
  {
    title: 'A dev.to exclusive',
    url: 'https://dev.to/example/a-dev-to-exclusive',
    published_at: '2026-08-03T08:48:55Z',
  },
  {
    title: 'A cross-posted piece!',
    url: 'https://dev.to/example/cross-posted',
    published_at: '2026-07-29T06:41:58Z',
  },
  { title: '', url: 'https://dev.to/example/blank-title', published_at: '2026-01-01T00:00:00Z' },
];

test('extractTagText unwraps CDATA verbatim and decodes plain-text entities', () => {
  assert.equal(
    extractTagText('<title><![CDATA[Raw & unescaped]]></title>', 'title'),
    'Raw & unescaped',
  );
  assert.equal(
    extractTagText('<title>Plain &amp; simple &#8217;quoted&#8217;</title>', 'title'),
    'Plain & simple ’quoted’',
  );
  assert.equal(extractTagText('<title></title>', 'title'), null);
  assert.equal(extractTagText('<link>no title here</link>', 'title'), null);
});

test('decodeFeedEntities decodes named and numeric entities without double-decoding amp', () => {
  assert.equal(decodeFeedEntities('&amp;lt;'), '&lt;');
  assert.equal(decodeFeedEntities('&#8217;'), '’');
  assert.equal(decodeFeedEntities('&#x2019;'), '’');
});

test('extractAtomLink prefers rel="alternate" and falls back to the first href', () => {
  assert.equal(
    extractAtomLink(
      '<link href="https://example.com/self" rel="self"/><link href="https://example.com/alt" rel="alternate"/>',
    ),
    'https://example.com/alt',
  );
  assert.equal(
    extractAtomLink('<link href="https://example.com/only"/>'),
    'https://example.com/only',
  );
  assert.equal(extractAtomLink('<title>no link</title>'), null);
});

test('parseRssItems reads title, link, and date and skips an incomplete item', () => {
  const items = parseRssItems(sampleRssFeed);
  assert.equal(items.length, 2);
  assert.equal(items[0].title, 'A cross’posted piece');
  assert.equal(items[0].url, 'https://example.com/posts/cross-posted');
  assert.equal(items[0].publishedAt, new Date('2026-07-29T06:41:58Z').toISOString());
  assert.equal(items[1].title, 'Plain & simple title');
});

test('parseAtomItems reads the alternate link and falls back to the bare href', () => {
  const items = parseAtomItems(sampleAtomFeed);
  assert.equal(items.length, 2);
  assert.equal(items[0].url, 'https://example.com/blog/cross-posted');
  assert.equal(items[1].url, 'https://example.com/blog/only-self');
});

test('parseFeedItems detects RSS vs. Atom from the root element', () => {
  assert.equal(parseFeedItems(sampleRssFeed).length, 2);
  assert.equal(parseFeedItems(sampleAtomFeed).length, 2);
});

test('parseDevToArticles reads title/url/published_at and drops a blank title', () => {
  const items = parseDevToArticles(sampleDevToPayload);
  assert.equal(items.length, 2);
  assert.equal(items[0].title, 'A dev.to exclusive');
  assert.throws(() => parseDevToArticles({ not: 'an array' }));
});

test('normalizeWritingTitle case-folds, strips punctuation, and collapses whitespace', () => {
  assert.equal(
    normalizeWritingTitle('A Cross’Posted   Piece!'),
    normalizeWritingTitle('a cross’posted piece'),
  );
  assert.equal(normalizeWritingTitle('"Quoted" title.'), normalizeWritingTitle('Quoted title'));
  assert.notEqual(normalizeWritingTitle('One thing'), normalizeWritingTitle('Another thing'));
});

test('mergeWritingEntries dedupes by normalized title, preferring the earliest source', () => {
  const bySource = {
    blog: parseAtomItems(sampleAtomFeed),
    devto: parseDevToArticles(sampleDevToPayload),
  };
  const merged = mergeWritingEntries(bySource, ['blog', 'devto']);
  const crossPosted = merged.find((entry) => entry.title === 'A cross-posted piece');
  assert.ok(crossPosted, 'the cross-posted title must survive the merge');
  assert.equal(crossPosted.source, 'blog', 'the earlier-listed source wins the duplicate');
  assert.equal(crossPosted.url, 'https://example.com/blog/cross-posted');
  const devToExclusive = merged.find((entry) => entry.title === 'A dev.to exclusive');
  assert.ok(devToExclusive);
  assert.equal(devToExclusive.source, 'devto');
});

test('mergeWritingEntries sorts newest first and caps at 12', () => {
  const bySource = {
    feed: Array.from({ length: 20 }, (_, index) => ({
      title: `Post number ${index}`,
      url: `https://example.com/${index}`,
      publishedAt: new Date(Date.UTC(2026, 0, index + 1)).toISOString(),
    })),
  };
  const merged = mergeWritingEntries(bySource, ['feed']);
  assert.equal(merged.length, 12);
  assert.equal(merged[0].title, 'Post number 19');
  assert.equal(merged[0].date, '2026-01-20');
  assert.equal(merged.at(-1).title, 'Post number 8');
});

test('mergeWritingEntries formats the stored date as YYYY-MM-DD', () => {
  const merged = mergeWritingEntries(
    {
      feed: [
        {
          title: 'Dated',
          url: 'https://example.com/dated',
          publishedAt: '2026-07-29T06:41:58.000Z',
        },
      ],
    },
    ['feed'],
  );
  assert.equal(merged[0].date, '2026-07-29');
});

test('isWritingListChanged compares entries field-by-field, including order', () => {
  const a = [{ title: 'A', url: 'https://x/a', source: 's', date: '2026-01-01' }];
  const b = [{ title: 'A', url: 'https://x/a', source: 's', date: '2026-01-01' }];
  assert.equal(isWritingListChanged(a, b), false);
  assert.equal(isWritingListChanged(a, []), true);
  assert.equal(isWritingListChanged([], []), false);
  assert.equal(isWritingListChanged(a, [{ ...b[0], date: '2026-01-02' }]), true);
  const reordered = [
    { title: 'A', url: 'https://x/a', source: 's', date: '2026-01-01' },
    { title: 'B', url: 'https://x/b', source: 's', date: '2026-01-02' },
  ];
  const swapped = [reordered[1], reordered[0]];
  assert.equal(isWritingListChanged(reordered, swapped), true);
});

test('buildReport renders the writing section, changed and unchanged', () => {
  const unchanged = buildReport({
    generatedAt: '2026-09-22T00:00:00.000Z',
    visibleChanges: [],
    counterChanges: [],
    pendingScorePackages: [],
    closedUnmergedContributions: [],
    failures: [],
    writingChanged: false,
    writingEntryCount: 5,
    previousWritingEntryCount: 5,
    writingFailures: [],
    candidateGroups: [],
    candidatesError: null,
  });
  assert.ok(unchanged.includes('## Writing'));
  assert.ok(unchanged.includes('No change.'));
  assert.ok(unchanged.includes('No source failures.'));

  const changedWithFailure = buildReport({
    generatedAt: '2026-09-22T00:00:00.000Z',
    visibleChanges: ['writing: 6 entries (was 5)'],
    counterChanges: [],
    pendingScorePackages: [],
    closedUnmergedContributions: [],
    failures: [],
    writingChanged: true,
    writingEntryCount: 6,
    previousWritingEntryCount: 5,
    writingFailures: ['medium: feed fetch: HTTP 403'],
    candidateGroups: [],
    candidatesError: null,
  });
  assert.ok(changedWithFailure.includes('Updated: 6 entries (was 5).'));
  assert.ok(changedWithFailure.includes('medium: feed fetch: HTTP 403'));
});
