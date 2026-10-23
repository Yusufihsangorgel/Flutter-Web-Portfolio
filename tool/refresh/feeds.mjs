import { fetchJson, fetchText, describeFetchFailure } from './http.mjs';

export const WRITING_ENTRY_CAP = 12;

export function decodeFeedEntities(text) {
  const named = { lt: '<', gt: '>', quot: '"', apos: "'", amp: '&' };
  return text.replace(/&(lt|gt|quot|apos|amp|#x[0-9a-fA-F]+|#\d+);/g, (_, entity) => {
    if (entity[0] !== '#') return named[entity];
    const hex = entity[1] === 'x';
    return String.fromCodePoint(Number.parseInt(entity.slice(hex ? 2 : 1), hex ? 16 : 10));
  });
}

function delimitedEnd(xml, offset, ending) {
  const end = xml.indexOf(ending, offset);
  if (end < 0) throw new Error('Invalid or incomplete RSS/Atom document');
  return end + ending.length;
}

function doctypeEnd(xml, offset) {
  let quote = null;
  let brackets = 0;
  for (let index = offset; index < xml.length; index += 1) {
    const character = xml[index];
    if (quote) {
      if (character === quote) quote = null;
      continue;
    }
    if (xml.startsWith('<!--', index)) {
      index = delimitedEnd(xml, index + 4, '-->') - 1;
    } else if (xml.startsWith('<?', index)) {
      index = delimitedEnd(xml, index + 2, '?>') - 1;
    } else if (character === '"' || character === "'") {
      quote = character;
    } else if (character === '[') {
      brackets += 1;
    } else if (character === ']') {
      brackets = Math.max(0, brackets - 1);
    } else if (character === '>' && brackets === 0) {
      return index + 1;
    }
  }
  throw new Error('Invalid or incomplete RSS/Atom document');
}

function* feedTokens(xml) {
  const pattern =
    /<!--|<!\[CDATA\[|<\?|<!DOCTYPE|<\/?([A-Za-z_][\w:.-]*)(?=[\s/>])(?:"[^"]*"|'[^']*'|[^"'<>])*>/g;
  let match;
  while ((match = pattern.exec(xml))) {
    let end = pattern.lastIndex;
    if (match[0] === '<!--') end = delimitedEnd(xml, end, '-->');
    if (match[0] === '<![CDATA[') end = delimitedEnd(xml, end, ']]>');
    if (match[0] === '<?') end = delimitedEnd(xml, end, '?>');
    if (match[0] === '<!DOCTYPE') end = doctypeEnd(xml, end);
    pattern.lastIndex = end;
    yield { start: match.index, end, raw: xml.slice(match.index, end), name: match[1] };
  }
}

function* xmlElements(xml, tagName, parents = ['']) {
  const stack = [];
  const wanted = tagName.toLowerCase();
  const parentPaths = parents.map((parent) => (parent ? parent.split('/') : []));
  for (const token of feedTokens(xml)) {
    if (!token.name) continue;
    if (token.raw.startsWith('</')) {
      const opening = stack.pop();
      if (opening?.name !== token.name) {
        throw new Error('Invalid or incomplete RSS/Atom document');
      }
      if (opening.selected) {
        yield { tag: opening.raw, body: xml.slice(opening.end, token.start) };
      }
    } else {
      const lowerName = token.name.toLowerCase();
      const selected =
        lowerName === wanted &&
        parentPaths.some(
          (path) =>
            path.length === stack.length &&
            path.every((name, index) => name === stack[index].lowerName),
        );
      if (token.raw.endsWith('/>')) {
        if (selected) yield { tag: token.raw, body: '' };
      } else {
        stack.push({ ...token, lowerName, selected });
      }
    }
  }
}

function tagText(fragment, tagName, parents) {
  const element = xmlElements(fragment, tagName, parents).next().value;
  if (!element) return null;
  const raw = element.body;
  const cdata = /^\s*<!\[CDATA\[([\s\S]*?)\]\]>\s*$/.exec(raw);
  const text = cdata ? cdata[1] : decodeFeedEntities(raw);
  const trimmed = text.trim();
  return trimmed.length > 0 ? trimmed : null;
}

export function extractTagText(fragment, tagName) {
  return tagText(fragment, tagName, ['', 'item', 'entry']);
}

export function extractAtomLink(entryFragment) {
  return atomLink(entryFragment, ['', 'entry']);
}

function atomLink(entryFragment, parents) {
  let fallback = null;
  for (const { tag } of xmlElements(entryFragment, 'link', parents)) {
    const attributes = new Map(
      [...tag.matchAll(/([\w:.-]+)\s*=\s*(?:"([^"]*)"|'([^']*)')/g)].map(
        ([, name, doubleQuoted, singleQuoted]) => [name, doubleQuoted ?? singleQuoted],
      ),
    );
    if (!attributes.has('href')) continue;
    const href = decodeFeedEntities(attributes.get('href'));
    if (decodeFeedEntities(attributes.get('rel') ?? '') === 'alternate') return href;
    if (fallback === null) fallback = href;
  }
  return fallback;
}

function toIsoDate(value) {
  if (typeof value !== 'string' || value.trim().length === 0) return null;
  const date = new Date(value);
  return Number.isNaN(date.getTime()) ? null : date.toISOString();
}

export function parseRssItems(xml) {
  const items = [];
  for (const { body: fragment } of xmlElements(xml, 'item', ['', 'channel', 'rss/channel'])) {
    const title = tagText(fragment, 'title', ['']);
    const url = tagText(fragment, 'link', ['']);
    const publishedAt = toIsoDate(tagText(fragment, 'pubDate', ['']));
    if (!title || !url || !publishedAt) continue;
    items.push({ title, url, publishedAt });
  }
  return items;
}

export function parseAtomItems(xml) {
  const items = [];
  for (const { body: fragment } of xmlElements(xml, 'entry', ['', 'feed'])) {
    const title = tagText(fragment, 'title', ['']);
    const url = atomLink(fragment, ['']);
    const publishedAt = toIsoDate(
      tagText(fragment, 'published', ['']) ?? tagText(fragment, 'updated', ['']),
    );
    if (!title || !url || !publishedAt) continue;
    items.push({ title, url, publishedAt });
  }
  return items;
}

function invalidFeedText(text, insideElement) {
  return text.includes('<') || (!insideElement && text.trim().length > 0);
}

function feedRoot(xml) {
  // Check the envelope and balanced tags, not XML schema or entity declarations.
  const stack = [];
  let root = null;
  let offset = 0;
  for (const token of feedTokens(xml)) {
    if (invalidFeedText(xml.slice(offset, token.start), stack.length > 0)) {
      throw new Error('Invalid or incomplete RSS/Atom document');
    }
    offset = token.end;
    const name = token.name;
    if (!name) {
      if (token.raw.startsWith('<![CDATA[') && stack.length === 0) {
        throw new Error('Invalid or incomplete RSS/Atom document');
      }
      continue;
    }
    if (token.raw.startsWith('</')) {
      if (stack.pop() !== name) throw new Error('Invalid or incomplete RSS/Atom document');
    } else {
      if (stack.length === 0) {
        if (root !== null) throw new Error('Invalid or incomplete RSS/Atom document');
        root = name.toLowerCase();
      }
      if (!token.raw.endsWith('/>')) stack.push(name);
    }
  }
  if (stack.length > 0 || invalidFeedText(xml.slice(offset), false)) {
    throw new Error('Invalid or incomplete RSS/Atom document');
  }
  return root;
}

export function parseFeedItems(xml) {
  const root = feedRoot(xml);
  if (root === 'rss') return parseRssItems(xml);
  if (root === 'feed') return parseAtomItems(xml);
  throw new Error('Invalid or incomplete RSS/Atom document');
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
