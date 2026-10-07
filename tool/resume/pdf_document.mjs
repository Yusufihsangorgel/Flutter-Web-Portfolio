// @ts-check
import { inflateSync } from 'node:zlib';

/**
 * @param {Buffer} bytes
 * @returns {{ header: string, objects: Map<number, string>, root: number, info: number }}
 */
export function readPdfDocument(bytes) {
  const source = bytes.toString('latin1');
  if (!source.startsWith('%PDF-')) throw new Error('resume.pdf must start with %PDF.');
  const ending = /startxref\s+(\d+)\s+%%EOF\s*$/.exec(source);
  if (!ending) throw new Error('PDF cross-reference offset is missing.');
  const xrefOffset = Number(ending[1]);
  const xref = /^xref\s+0 (\d+)\s*\n([\s\S]*?)trailer\s*(<<[\s\S]*?>>)\s*startxref/.exec(
    source.slice(xrefOffset),
  );
  if (!xref || /\/(?:Prev|Encrypt|XRefStm)\b/.test(xref[3])) {
    throw new Error('Only a single, unencrypted Chromium cross-reference table is supported.');
  }
  const rows = [...xref[2].matchAll(/(\d{10}) (\d{5}) ([nf])\s/g)];
  if (rows.length !== Number(xref[1])) throw new Error('PDF cross-reference size is invalid.');
  if (Number(/\/Size (\d+)\b/.exec(xref[3])?.[1]) !== rows.length)
    throw new Error('PDF trailer size is invalid.');
  const offsets = rows.flatMap((row, id) =>
    row[3] === 'n' ? [{ id, offset: Number(row[1]), generation: row[2] }] : [],
  );
  offsets.sort((left, right) => left.offset - right.offset);
  if (
    !offsets.length ||
    offsets.some(
      (entry, index) =>
        entry.offset >= xrefOffset || entry.offset <= (offsets[index - 1]?.offset ?? 0),
    )
  ) {
    throw new Error('PDF object offsets must be unique and before the cross-reference table.');
  }
  const objects = new Map();
  offsets.forEach((entry, index) => {
    if (entry.generation !== '00000') throw new Error('PDF object generations are unsupported.');
    const object = source.slice(entry.offset, offsets[index + 1]?.offset ?? xrefOffset);
    const match = new RegExp(`^${entry.id} 0 obj\\s*([\\s\\S]*?)\\s*endobj\\s*$`).exec(object);
    if (!match) throw new Error('PDF object offset is invalid.');
    objects.set(entry.id, match[1]);
  });
  const root = Number(/\/Root (\d+) 0 R/.exec(xref[3])?.[1]);
  const info = Number(/\/Info (\d+) 0 R/.exec(xref[3])?.[1]);
  if (!objects.has(root)) throw new Error('PDF catalog is missing.');
  return { header: source.slice(0, offsets[0].offset), objects, root, info };
}

/**
 * @param {string} body
 * @returns {{ offset: number, length: number, flate: boolean }}
 */
export function assertSupportedPdfStream(body) {
  const start = /stream\r?\n/.exec(body);
  if (!start) throw new Error('PDF stream is missing.');
  const dictionary = body.slice(0, start.index);
  const lengthMatch = /\/Length (\d+)\b(?:\s+(\d+)\s+R)?/.exec(dictionary);
  const length = Number(lengthMatch?.[1]);
  if (lengthMatch?.[2]) throw new Error('PDF stream length must be direct.');
  if (!Number.isSafeInteger(length)) throw new Error('PDF stream length must be direct.');
  const flate = /\/Filter\s*\/FlateDecode\b/.test(dictionary);
  if (/\/Filter\b/.test(dictionary) && !flate) throw new Error('Unsupported PDF stream filter.');
  const offset = start.index + start[0].length;
  if (!/^\r?\nendstream\s*$/.test(body.slice(offset + length)))
    throw new Error('PDF stream length is invalid.');
  return { offset, length, flate };
}

/**
 * @param {string} body
 * @returns {string}
 */
export function pdfStream(body) {
  const { offset, length, flate } = assertSupportedPdfStream(body);
  const bytes = Buffer.from(body.slice(offset, offset + length), 'latin1');
  if (flate) return inflateSync(bytes).toString('latin1');
  return bytes.toString('latin1');
}

/**
 * @param {{ header: string, objects: Map<number, string>, root: number, info: number }} document
 * @param {string} id
 * @returns {Buffer}
 */
export function writePdfDocument(document, id) {
  const chunks = [Buffer.from(document.header, 'latin1')];
  const count = Math.max(...document.objects.keys()) + 1;
  const rows = ['0000000000 65535 f \n'];
  let offset = chunks[0].length;
  for (let index = 1; index < count; index += 1) {
    const body = document.objects.get(index);
    if (body === undefined) {
      rows.push('0000000000 00000 f \n');
      continue;
    }
    rows.push(`${String(offset).padStart(10, '0')} 00000 n \n`);
    const chunk = Buffer.from(`${index} 0 obj\n${body}\nendobj\n`, 'latin1');
    chunks.push(chunk);
    offset += chunk.length;
  }
  chunks.push(
    Buffer.from(
      `xref\n0 ${count}\n${rows.join('')}trailer\n<< /Size ${count} /Root ${document.root} 0 R /Info ${document.info} 0 R /ID [<${id}><${id}>] >>\nstartxref\n${offset}\n%%EOF\n`,
    ),
  );
  return Buffer.concat(chunks);
}

/**
 * @param {string} hex
 * @returns {string}
 */
export function decodePdfUnicode(hex) {
  return Buffer.from(hex, 'hex').swap16().toString('utf16le');
}

/**
 * @param {unknown} value
 * @returns {string}
 */
export function encodePdfUnicode(value) {
  return `FEFF${Buffer.from(String(value), 'utf16le').swap16().toString('hex').toUpperCase()}`;
}
