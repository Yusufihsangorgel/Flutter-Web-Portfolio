import { fetchJson, fetchText, describeFetchFailure } from './http.mjs';

export const WRITING_ENTRY_CAP = 12;

export function decodeFeedEntities(text) {
  return text
    .replaceAll('&lt;', '<')
    .replaceAll('&gt;', '>')
    .replaceAll('&quot;', '"')
    .replaceAll('&apos;', "'")
    .replace(/&#x([0-9a-fA-F]+);/g, (_, hex) => String.fromCodePoint(Number.parseInt(hex, 16)))
    .replace(/&#(\d+);/g, (_, dec) => String.fromCodePoint(Number(dec)))
    .replaceAll('&amp;', '&');
}

export function extractTagText(fragment, tagName) {
  const pattern = new RegExp(`<${tagName}(?:\\s[^>]*)?>([\\s\\S]*?)<\\/${tagName}>`, 'i');
  const match = pattern.exec(fragment);
  if (!match) return null;
  const raw = match[1];
  const cdata = /^\s*<!\[CDATA\[([\s\S]*?)\]\]>\s*$/.exec(raw);
  const text = cdata ? cdata[1] : decodeFeedEntities(raw);
  const trimmed = text.trim();
  return trimmed.length > 0 ? trimmed : null;
}

export function extractAtomLink(entryFragment) {
  const linkPattern = /<link\b([^>]*)\/?>/gi;
  let match;
  let fallback = null;
  while ((match = linkPattern.exec(entryFragment))) {
    const attributes = match[1];
    const hrefMatch = /href\s*=\s*"([^"]*)"|href\s*=\s*'([^']*)'/.exec(attributes);
    if (!hrefMatch) continue;
    const href = hrefMatch[1] ?? hrefMatch[2];
    const relMatch = /rel\s*=\s*"([^"]*)"|rel\s*=\s*'([^']*)'/.exec(attributes);
    const rel = relMatch ? relMatch[1] ?? relMatch[2] : null;
    if (rel === 'alternate') return href;
    if (fallback === null) fallback = href;
  }
  return fallback;
}

function toIsoDate(value) {
  const date = new Date(value);
  return Number.isNaN(date.getTime()) ? null : date.toISOString();
}

export function parseRssItems(xml) {
  const items = [];
  const itemPattern = /<item\b[^>]*>([\s\S]*?)<\/item>/gi;
  let match;
  while ((match = itemPattern.exec(xml))) {
    const fragment = match[1];
    const title = extractTagText(fragment, 'title');
    const url = extractTagText(fragment, 'link');
    const publishedAt = toIsoDate(extractTagText(fragment, 'pubDate'));
    if (!title || !url || !publishedAt) continue;
    items.push({ title, url, publishedAt });
  }
  return items;
}

export function parseAtomItems(xml) {
  const items = [];
  const entryPattern = /<entry\b[^>]*>([\s\S]*?)<\/entry>/gi;
  let match;
  while ((match = entryPattern.exec(xml))) {
    const fragment = match[1];
    const title = extractTagText(fragment, 'title');
    const url = extractAtomLink(fragment);
    const publishedAt = toIsoDate(
      extractTagText(fragment, 'published') ?? extractTagText(fragment, 'updated'),
    );
    if (!title || !url || !publishedAt) continue;
    items.push({ title, url, publishedAt });
  }
  return items;
}

export function parseFeedItems(xml) {
  const withoutProlog = xml.trimStart().replace(/^<\?xml[^>]*\?>\s*/i, '');
  if (/^<rss\b/i.test(withoutProlog)) return parseRssItems(xml);
  if (/^<feed\b/i.test(withoutProlog)) return parseAtomItems(xml);
  const rssItems = parseRssItems(xml);
  return rssItems.length > 0 ? rssItems : parseAtomItems(xml);
}

export function parseDevToArticles(payload) {
  if (!Array.isArray(payload)) {
    throw new Error('dev.to articles response is not an array');
  }
  const items = [];
  for (const entry of payload) {
    const title = typeof entry?.title === 'string' ? entry.title.trim() : '';
    const url = typeof entry?.url === 'string' ? entry.url : '';
    const publishedAt = toIsoDate(entry?.published_at);
    if (!title || !url || !publishedAt) continue;
    items.push({ title, url, publishedAt });
  }
  return items;
}

export async function fetchWritingSourceEntries(source, { feedHeaders, jsonHeaders }) {
  if (source.kind === 'rss') {
    const result = await fetchText(source.url, { headers: feedHeaders });
    if (!result.ok) {
      return { ok: false, failure: describeFetchFailure(result, `${source.id}: feed fetch`) };
    }
    try {
      return { ok: true, entries: parseFeedItems(result.body) };
    } catch (error) {
      return { ok: false, failure: `${source.id}: ${error.message}` };
    }
  }
  if (source.kind === 'devto') {
    const result = await fetchJson(source.url, { headers: jsonHeaders });
    if (!result.ok) {
      return { ok: false, failure: describeFetchFailure(result, `${source.id}: dev.to fetch`) };
    }
    try {
      return { ok: true, entries: parseDevToArticles(result.body) };
    } catch (error) {
      return { ok: false, failure: `${source.id}: ${error.message}` };
    }
  }
  return { ok: false, failure: `${source.id}: unsupported writing source kind "${source.kind}"` };
}
