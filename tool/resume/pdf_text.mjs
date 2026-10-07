import { decodePdfUnicode, pdfStream, readPdfDocument } from './pdf_document.mjs';
import { formatPeriod } from './render_resume_html.mjs';

function unicodeMap(source) {
  const map = new Map();
  for (const block of source.matchAll(/beginbfchar([\s\S]*?)endbfchar/g)) {
    for (const entry of block[1].matchAll(/<([\da-f]+)>\s*<([\da-f]+)>/gi)) {
      map.set(entry[1].toUpperCase(), decodePdfUnicode(entry[2]));
    }
  }
  for (const block of source.matchAll(/beginbfrange([\s\S]*?)endbfrange/g)) {
    for (const entry of block[1].matchAll(/<([\da-f]+)>\s*<([\da-f]+)>\s*(<([\da-f]+)>|\[([^\]]*)\])/gi)) {
      addRange(map, entry);
    }
  }
  return map;
}

function addRange(map, entry) {
  const start = parseInt(entry[1], 16);
  const end = parseInt(entry[2], 16);
  if (end < start || end - start > 65535) throw new Error('Invalid Unicode CMap range.');
  const values = entry[5] && [...entry[5].matchAll(/<([\da-f]+)>/gi)].map((match) => match[1]);
  for (let code = start; code <= end; code += 1) {
    const hex = values ? values[code - start] : (parseInt(entry[4], 16) + code - start).toString(16).padStart(entry[4].length, '0');
    if (!hex) throw new Error('Incomplete Unicode CMap range.');
    map.set(code.toString(16).padStart(entry[1].length, '0').toUpperCase(), decodePdfUnicode(hex));
  }
}

function pageFonts(page, objects) {
  const resource = /\/Resources (\d+) 0 R/.exec(page);
  const resources = resource ? objects.get(Number(resource[1])) : page;
  const fontReference = /\/Font (\d+) 0 R/.exec(resources);
  const fonts = fontReference ? objects.get(Number(fontReference[1])) : resources;
  const maps = new Map();
  for (const entry of fonts.matchAll(/\/(F\d+) (\d+) 0 R/g)) {
    const font = objects.get(Number(entry[2]));
    const unicode = /\/ToUnicode (\d+) 0 R/.exec(font);
    if (unicode) maps.set(entry[1], unicodeMap(pdfStream(objects.get(Number(unicode[1])))));
  }
  return maps;
}

function decodeGlyphs(hex, map) {
  if (!map) throw new Error('PDF text is missing a font Unicode map.');
  const width = map.keys().next().value?.length;
  if (!width || hex.length % width) throw new Error('PDF glyph encoding is unsupported.');
  let text = '';
  for (let index = 0; index < hex.length; index += width) {
    text += map.get(hex.slice(index, index + width).toUpperCase()) ?? '\uFFFD';
  }
  return text;
}

function streamText(stream, fonts) {
  let font;
  let text = '';
  const tokens = /\/(F\d+)\s+[\d.]+\s+Tf|<([\da-f]+)>\s*Tj|\[([^\]]*)\]\s*TJ|\bET\b/gi;
  for (const token of stream.matchAll(tokens)) {
    if (token[1]) font = fonts.get(token[1]);
    else if (token[2]) text += decodeGlyphs(token[2], font);
    else if (token[3]) {
      for (const glyph of token[3].matchAll(/<([\da-f]+)>/gi)) text += decodeGlyphs(glyph[1], font);
    } else text += '\n';
  }
  return text;
}

export function inspectResumePdf(bytes) {
  const { objects } = readPdfDocument(bytes);
  const pages = [...objects.values()].filter((body) => /\/Type\s*\/Page\b/.test(body));
  const text = pages.map((page) => {
    const contents = /\/Contents\s*(\[[^\]]*\]|\d+ 0 R)/.exec(page)?.[1];
    if (!contents) throw new Error('PDF page has no text content stream.');
    const fonts = pageFonts(page, objects);
    return [...contents.matchAll(/(\d+) 0 R/g)].map((reference) =>
      streamText(pdfStream(objects.get(Number(reference[1]))), fonts),
    ).join('\n');
  }).join('\n');
  return { pages: pages.length, text };
}

export function assertResumePdf(bytes, record) {
  const result = inspectResumePdf(bytes);
  const compact = (value) => value.normalize('NFC').replace(/\s+/g, '');
  if (!record.profile?.name || !compact(result.text).includes(compact(record.profile.name))) {
    throw new Error('resume.pdf does not contain the profile name in its text layer.');
  }
  for (const entry of record.experience ?? []) {
    const facts = [entry.company, entry.role, entry.period && formatPeriod(entry.period), entry.summary].filter(Boolean);
    if (facts.some((fact) => !compact(result.text).includes(compact(fact)))) {
      throw new Error('resume.pdf is missing canonical experience text.');
    }
  }
  return result;
}
