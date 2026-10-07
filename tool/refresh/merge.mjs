import { WRITING_ENTRY_CAP } from './feeds.mjs';

export function bumpContentVersion(current, todayIso) {
  const todayKey = todayIso.replaceAll('-', '.');
  const match = /^(\d{4}\.\d{2}\.\d{2})\.(\d+)$/.exec(typeof current === 'string' ? current : '');
  if (match && match[1] === todayKey) {
    return `${todayKey}.${Number(match[2]) + 1}`;
  }
  return `${todayKey}.1`;
}

export function applyContentVersionBump(document, { shouldWrite, hasVisible }, todayIso) {
  if (shouldWrite && hasVisible) {
    document.content_version = bumpContentVersion(document.content_version, todayIso);
  }
}

export function normalizeWritingTitle(title) {
  return title
    .toLowerCase()
    .normalize('NFKC')
    .replace(/[.,!?;:'"“”‘’()[\]{}]/g, '')
    .replace(/\s+/g, ' ')
    .trim();
}

export function mergeWritingEntries(
  entriesBySource,
  sourceOrder,
  { cap = WRITING_ENTRY_CAP, previous = [] } = {},
) {
  const bestByTitle = new Map();
  for (const sourceId of sourceOrder) {
    for (const entry of entriesBySource[sourceId] ?? []) {
      const key = normalizeWritingTitle(entry.title);
      if (key.length === 0 || bestByTitle.has(key)) continue;
      bestByTitle.set(key, { ...entry, source: sourceId });
    }
  }
  return [...bestByTitle.values()]
    .sort((a, b) => new Date(b.publishedAt).getTime() - new Date(a.publishedAt).getTime())
    .slice(0, cap)
    .map((entry) => ({
      ...(previous.find((item) => item.source === entry.source && item.url === entry.url) ??
        previous.find(
          (item) =>
            item.source === entry.source &&
            normalizeWritingTitle(item.title) === normalizeWritingTitle(entry.title),
        ) ??
        previous.find(
          (item) => normalizeWritingTitle(item.title) === normalizeWritingTitle(entry.title),
        ) ??
        {}),
      title: entry.title,
      url: entry.url,
      source: entry.source,
      date: entry.publishedAt.slice(0, 10),
    }));
}

export function isWritingListChanged(previous, next) {
  const before = Array.isArray(previous) ? previous : [];
  if (before.length !== next.length) return true;
  for (let index = 0; index < next.length; index += 1) {
    const a = before[index];
    const b = next[index];
    if (a?.title !== b.title || a?.url !== b.url || a?.source !== b.source || a?.date !== b.date) {
      return true;
    }
  }
  return false;
}

export function decideWrite({ anyFailure, check, hasVisible, hasCounters, includeCounters }) {
  return !anyFailure && !check && (hasVisible || (hasCounters && includeCounters));
}
