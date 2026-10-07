import assert from 'node:assert/strict';
import { mkdir, mkdtemp, readFile, rm, writeFile } from 'node:fs/promises';
import path from 'node:path';
import { test } from 'node:test';

import { parseArguments, renderResumePdf } from './build_resume_pdf.mjs';
import { normalizeResumePdf, resumeMetadata } from './normalize_resume_pdf.mjs';
import { decodePdfUnicode, encodePdfUnicode, pdfStream, readPdfDocument, writePdfDocument } from './pdf_document.mjs';
import { pdfFixture } from './pdf_fixture.mjs';
import { assertResumePdf, inspectResumePdf } from './pdf_text.mjs';
import { renderResumeHtml } from './render_resume_html.mjs';
import { verifyResumeRelease } from './verify_resume_release.mjs';
import { loadResumeFont } from './resume_font.mjs';
import { assertResumeStructure } from './pdf_structure.mjs';

const record = { verified_at: '2026-08-29', profile: { name: 'Example', role: 'Engineer', focus: ['Software'] } };

test('date and document ID changes normalize to identical bytes with stable Unicode metadata', () => {
  const first = normalizeResumePdf(pdfFixture(), record);
  const second = normalizeResumePdf(pdfFixture({ date: 'D:20261108142311Z', id: 'B'.repeat(32) }), record);
  assert.deepEqual(first, second);
  assert.deepEqual(normalizeResumePdf(first, record), first);
  const document = readPdfDocument(first);
  const info = document.objects.get(document.info);
  for (const [key, value] of Object.entries(resumeMetadata(record))) {
    assert.ok(info.includes(`/${key} ${key.endsWith('Date') ? `(${value})` : `<${encodePdfUnicode(value)}>`}`));
  }
  assert.ok(!first.includes(Buffer.from('20261007')));
  assert.equal(inspectResumePdf(first).text.trim(), record.profile.name);
  assert.deepEqual(document.objects.get(4), readPdfDocument(pdfFixture()).objects.get(4));
});

test('rebuilt cross-reference offsets point to the original object numbers', () => {
  const bytes = normalizeResumePdf(pdfFixture(), record);
  const source = bytes.toString('latin1');
  const offset = Number(/startxref\s+(\d+)/.exec(source)[1]);
  assert.ok(source.slice(offset).startsWith('xref\n'));
  const rows = [...source.slice(offset).matchAll(/(\d{10}) 00000 n/g)];
  rows.forEach((row, index) => assert.ok(source.slice(Number(row[1])).startsWith(`${index + 1} 0 obj\n`)));
});

test('paper dimensions, accessibility tags and heading outline are required', () => {
  const document = readPdfDocument(pdfFixture());
  document.objects.set(1, '<< /Type /Catalog /Pages 2 0 R /MarkInfo << /Marked true >> /StructTreeRoot 8 0 R /Outlines 9 0 R >>');
  document.objects.set(8, '<< /Type /StructTreeRoot /K [] >>');
  document.objects.set(9, '<< /Type /Outlines /First 10 0 R /Last 10 0 R /Count 1 >>');
  document.objects.set(10, '<< /Title (Example) /Parent 9 0 R /Dest [3 0 R /XYZ 0 0 0] >>');
  const serialize = () => writePdfDocument(document, '0'.repeat(32));
  assert.doesNotThrow(() => assertResumeStructure(serialize(), 'a4'));
  assert.throws(() => assertResumeStructure(serialize(), 'letter'), /dimensions/);
  document.objects.set(3, document.objects.get(3).replace('595 842', '612 792'));
  assert.doesNotThrow(() => assertResumeStructure(serialize(), 'letter'));
  document.objects.delete(10);
  assert.throws(() => assertResumeStructure(serialize(), 'letter'), /outline/);
  document.objects.delete(8);
  assert.throws(() => assertResumeStructure(serialize(), 'letter'), /tags/);
});

test('only text-layer names pass, including non-ASCII glyphs and range CMaps', () => {
  assert.equal(assertResumePdf(pdfFixture(), record).pages, 1);
  assert.throws(() => assertResumePdf(pdfFixture({ metadataOnly: true }), record), /text layer/);
  const name = 'Example İĞü';
  assert.equal(inspectResumePdf(pdfFixture({ text: name, arrayRange: true })).text.trim(), name);
  assert.equal(decodePdfUnicode(encodePdfUnicode(name).slice(4)), name);
  assert.throws(() => assertResumePdf(Buffer.from('not a PDF'), record), /%PDF/);
});

test('a name-only PDF cannot stand in for authored experience text', () => {
  const withExperience = { ...record, experience: [{ company: 'Example', role: 'Engineer', period: '2021 — Present', summary: 'Complete authored experience.' }] };
  assert.throws(() => assertResumePdf(pdfFixture(), withExperience), /experience/);
});

test('normalization rejects unsupported preserved non-text streams', () => {
  const document = readPdfDocument(pdfFixture());
  for (const body of ['<< /Length 2 0 R >>\nstream\nab\nendstream', '<< /Length 2 /Filter /Unsupported >>\nstream\nab\nendstream']) {
    document.objects.set(8, body);
    assert.throws(() => normalizeResumePdf(writePdfDocument(document, '0'.repeat(32)), record), /stream/);
  }
});

test('unsupported PDF formats and invalid verification dates fail explicitly', () => {
  assert.throws(() => normalizeResumePdf(pdfFixture(), { ...record, verified_at: '2025-02-29' }));
  assert.throws(() => readPdfDocument(Buffer.from('%PDF-1.4\nstartxref\n0\n%%EOF')), /cross-reference table/);
  assert.throws(() => pdfStream('<< /Length 2 /Filter /Unsupported >>\nstream\nab\nendstream'), /filter/);
  assert.throws(() => pdfStream('<< /Length 2 0 R >>\nstream\nab\nendstream'), /direct/);
  const invalidSize = pdfFixture().toString('latin1').replace('/Size 8', '/Size 9');
  assert.throws(() => readPdfDocument(Buffer.from(invalidSize, 'latin1')), /size/);
});

test('the canonical Unicode author survives metadata and text-layer normalization', async () => {
  const canonical = JSON.parse(await readFile(new URL('../../assets/content/portfolio.json', import.meta.url), 'utf8'));
  const text = [canonical.profile.name, ...canonical.experience.flatMap((entry) => [entry.company, entry.role, entry.period, entry.summary])].join(' ');
  const pdf = normalizeResumePdf(pdfFixture({ text }), canonical);
  const document = readPdfDocument(pdf);
  assert.ok(document.objects.get(document.info).includes(`/Author <${encodePdfUnicode(canonical.profile.name)}>`));
  assert.ok(assertResumePdf(pdf, canonical).text.includes(canonical.profile.name));
});

test('CLI defaults, paper sizes and argument errors require no browser', () => {
  assert.deepEqual(parseArguments([]), { out: 'build/web', paper: 'a4' });
  assert.deepEqual(parseArguments(['--paper', 'letter', '--out', 'build/example']), { out: 'build/example', paper: 'letter' });
  for (const args of [['--paper'], ['--paper', 'legal'], ['--unknown', 'value'], ['--out', 'a', '--out', 'b']]) {
    assert.throws(() => parseArguments(args));
  }
});

test('invalid metadata is rejected before any browser work', async () => {
  await assert.rejects(renderResumePdf({ profile: { name: 'Example' } }), /YYYY-MM-DD/);
});

test('release verification rejects missing, stale, malformed and metadata-only artifacts', async () => {
  await mkdir('build', { recursive: true });
  const webRoot = await mkdtemp(path.resolve('build/resume-verify-'));
  try {
    assert.equal((await verifyResumeRelease({ webRoot, record })).length, 2);
    await writeFile(path.join(webRoot, 'resume.html'), renderResumeHtml(record, { fontBase64: await loadResumeFont() }));
    await writeFile(path.join(webRoot, 'resume.pdf'), normalizeResumePdf(pdfFixture({ structured: true }), record));
    assert.deepEqual(await verifyResumeRelease({ webRoot, record }), []);
    await writeFile(path.join(webRoot, 'resume.pdf'), pdfFixture({ structured: true }));
    assert.ok((await verifyResumeRelease({ webRoot, record })).some((failure) => failure.includes('normalized')));
    await writeFile(path.join(webRoot, 'resume.pdf'), normalizeResumePdf(pdfFixture(), record));
    assert.ok((await verifyResumeRelease({ webRoot, record })).some((failure) => failure.includes('tags')));
    const wrongPaper = readPdfDocument(pdfFixture({ structured: true }));
    wrongPaper.objects.set(3, wrongPaper.objects.get(3).replace('595 842', '612 792'));
    await writeFile(path.join(webRoot, 'resume.pdf'), normalizeResumePdf(writePdfDocument(wrongPaper, '0'.repeat(32)), record));
    assert.ok((await verifyResumeRelease({ webRoot, record })).some((failure) => failure.includes('dimensions')));
    wrongPaper.objects.set(3, wrongPaper.objects.get(3).replace('612 792', '595 842'));
    wrongPaper.objects.delete(10);
    await writeFile(path.join(webRoot, 'resume.pdf'), normalizeResumePdf(writePdfDocument(wrongPaper, '0'.repeat(32)), record));
    assert.ok((await verifyResumeRelease({ webRoot, record })).some((failure) => failure.includes('outline')));
    await writeFile(path.join(webRoot, 'resume.html'), '<h1>Example</h1>');
    await writeFile(path.join(webRoot, 'resume.pdf'), normalizeResumePdf(pdfFixture({ metadataOnly: true, structured: true }), record));
    assert.equal((await verifyResumeRelease({ webRoot, record })).length, 2);
  } finally {
    await rm(webRoot, { recursive: true, force: true });
  }
});
