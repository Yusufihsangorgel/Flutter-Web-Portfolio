const genericMarkers = new Set([
  'flutter',
  'github',
  'linkedin',
  'medium',
  'portfolio',
  'software',
  'website',
]);

export function collectTemplateIdentityMarkers(document) {
  const markers = new Set();
  const add = (value) => {
    if (typeof value !== 'string') return;
    const normalized = value.trim().toLocaleLowerCase('en-US');
    for (const candidate of [
      normalized,
      normalized.normalize('NFKD').replace(/\p{M}/gu, '').replaceAll('ı', 'i'),
    ]) {
      if (candidate.length < 4 || genericMarkers.has(candidate)) continue;
      markers.add(candidate);
    }
  };
  const addWords = (value) => {
    add(value);
    for (const word of value?.match(/[\p{L}\p{N}]+/gu) ?? []) add(word);
  };
  const addUrlIdentity = (value) => {
    if (typeof value !== 'string') return;
    let url;
    try {
      url = new URL(value);
    } catch {
      return;
    }
    const hostLabels = url.hostname.replace(/^www\./, '').split('.');
    if (hostLabels.length > 2 || !genericMarkers.has(hostLabels[0])) {
      add(hostLabels[0]);
    }
    for (const rawSegment of url.pathname.split('/').filter(Boolean)) {
      let segment = rawSegment;
      try {
        segment = decodeURIComponent(rawSegment);
      } catch {
        // The full encoded path is still covered by the canonical URL checks.
      }
      addWords(segment.replace(/^@/, ''));
    }
  };

  addWords(document.profile?.name);
  for (const value of Object.values(document.profile?.display_name ?? {})) {
    addWords(value);
  }
  add(document.profile?.email?.split('@')[0]);
  addUrlIdentity(document.site?.url);

  for (const link of document.profile?.links ?? []) addUrlIdentity(link.url);
  for (const source of document.sources ?? []) addUrlIdentity(source.url);
  for (const experience of document.experience ?? []) add(experience.company);
  for (const system of document.systems ?? []) {
    if (system.id !== 'portfolio') add(system.name);
  }

  const professionalIds = new Set([
    ...(document.experience ?? []).map((item) => item.id),
    ...(document.systems ?? []).map((item) => item.id),
  ]);
  for (const source of document.sources ?? []) {
    if (professionalIds.has(source.id)) add(source.label);
  }

  return [...markers].sort((left, right) => right.length - left.length);
}

export function findTemplateIdentityResidue(text, markers, limit = 3) {
  const normalizedLines = text.split('\n');
  const matches = [];
  for (const marker of markers) {
    const pattern = new RegExp(
      `(^|[^\\p{L}\\p{N}])${escapeRegExp(marker)}(?=$|[^\\p{L}\\p{N}])`,
      'iu',
    );
    for (const line of normalizedLines) {
      if (!pattern.test(line)) continue;
      matches.push({ marker, line });
      if (matches.length >= limit) return matches;
    }
  }
  return matches;
}

function escapeRegExp(value) {
  return value.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
}
