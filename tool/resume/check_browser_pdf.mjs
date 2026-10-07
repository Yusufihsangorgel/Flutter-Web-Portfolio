import assert from 'node:assert/strict';
import { readFile } from 'node:fs/promises';

import { renderResumePdf } from './build_resume_pdf.mjs';
import { assertResumePdf } from './pdf_text.mjs';
import { assertResumeStructure } from './pdf_structure.mjs';

const record = JSON.parse(await readFile(new URL('../../assets/content/portfolio.json', import.meta.url), 'utf8'));
const compact = (value) => value.normalize('NFC').replace(/\s+/g, '');

for (const paper of ['a4', 'letter']) {
  const first = await renderResumePdf(record, { paper });
  await new Promise((resolve) => setTimeout(resolve, 1100));
  const second = await renderResumePdf(record, { paper });
  assert.deepEqual(first.pdf, second.pdf, `${paper} PDF bytes must be identical across independent runs`);
  assertResumeStructure(first.pdf, paper);
  if (paper === 'a4') {
    const artifact = await readFile(new URL('../../build/web/resume.pdf', import.meta.url));
    assert.deepEqual(first.pdf, artifact, 'the packaged A4 PDF must match the independently verified render');
  }
  const { pages, text } = assertResumePdf(first.pdf, record);
  assert.ok(pages >= 1 && pages <= 2, `${paper} canonical resume must have 1–2 pages; got ${pages}`);
  for (const experience of record.experience) {
    assert.ok(compact(text).includes(compact(experience.company)), `${paper}: ${experience.company} must be selectable text`);
    assert.ok(compact(text).includes(compact(experience.summary)), `${paper}: experience summary must remain complete`);
  }
  console.log(`${paper}: deterministic bytes, ${pages} pages, paper dimensions, accessibility tags, outline and complete experience text layer.`);
}
