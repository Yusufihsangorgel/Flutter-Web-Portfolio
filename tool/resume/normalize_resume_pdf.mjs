import { createHash } from 'node:crypto';

import { assertSupportedPdfStream, encodePdfUnicode, readPdfDocument, writePdfDocument } from './pdf_document.mjs';
import { formatDate } from './render_resume_html.mjs';

export function resumeMetadata(record) {
  formatDate(record.verified_at);
  if (!record.profile?.name?.trim()) throw new Error('A profile name is required.');
  return {
    Title: `${record.profile.name} — Resume`,
    Author: record.profile.name,
    Subject: record.profile.role || 'Resume',
    Keywords: (record.profile.focus ?? []).join(', '),
    CreationDate: `D:${record.verified_at.replaceAll('-', '')}000000Z`,
    ModDate: `D:${record.verified_at.replaceAll('-', '')}000000Z`,
  };
}

export function normalizeResumePdf(bytes, record) {
  const document = readPdfDocument(bytes);
  if ([...document.objects.values()].some(hasUnsupportedDictionary)) {
    throw new Error('Unexpected PDF metadata or object streams require a normalization update.');
  }
  for (const body of document.objects.values()) {
    if (/stream\r?\n/.test(body)) assertSupportedPdfStream(body);
  }
  if (!document.objects.has(document.info)) {
    document.info = Math.max(...document.objects.keys()) + 1;
  }
  const metadata = Object.entries(resumeMetadata(record)).map(([key, value]) =>
    `/${key} ${key.endsWith('Date') ? `(${value})` : `<${encodePdfUnicode(value)}>`}`,
  );
  document.objects.set(document.info, `<<\n${metadata.join('\n')}\n>>`);
  const normalized = writePdfDocument(document, '0'.repeat(32));
  const id = createHash('sha256').update(normalized).digest('hex').slice(0, 32);
  return writePdfDocument(document, id);
}

function hasUnsupportedDictionary(body) {
  const streamStart = body.indexOf('stream');
  const dictionary = streamStart < 0 ? body : body.slice(0, streamStart);
  return /\/Type\s*\/(?:Metadata|ObjStm)\b/.test(dictionary);
}
