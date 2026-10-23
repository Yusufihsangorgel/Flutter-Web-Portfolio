// @ts-check
import { lstat, readFile } from 'node:fs/promises';
import path from 'node:path';

import { assertResumePdf } from './pdf_text.mjs';
import { normalizeResumePdf } from './normalize_resume_pdf.mjs';
import { assertResumeStructure } from './pdf_structure.mjs';
import { renderResumeHtml } from './render_resume_html.mjs';
import { loadResumeFont } from './resume_font.mjs';
import { isResumeEnabled, resumeArtifactFiles } from './resume_availability.mjs';

/**
 * @param {{ webRoot: string, record: any }} options
 * @returns {Promise<string[]>}
 */
export async function verifyResumeRelease({ webRoot, record }) {
  if (!isResumeEnabled(record)) return verifyDisabledResume(webRoot);
  const failures = [];
  let paper;
  try {
    const html = await readFile(path.join(webRoot, 'resume.html'), 'utf8');
    const fontBase64 = await loadResumeFont();
    paper = ['a4', 'letter'].find(
      (paper) => html === renderResumeHtml(record, { paper, fontBase64 }),
    );
    if (!paper) {
      failures.push('resume.html is stale or invalid');
    }
  } catch (error) {
    failures.push(`resume.html is missing or invalid: ${error.message}`);
  }
  try {
    const pdf = await readFile(path.join(webRoot, 'resume.pdf'));
    if (!normalizeResumePdf(pdf, record).equals(pdf)) {
      failures.push('resume.pdf metadata or document ID is not normalized');
    }
    assertResumePdf(pdf, record);
    if (paper) assertResumeStructure(pdf, paper);
  } catch (error) {
    failures.push(`resume.pdf is missing or invalid: ${error.message}`);
  }
  return failures;
}

async function verifyDisabledResume(webRoot) {
  const failures = [];
  for (const file of resumeArtifactFiles) {
    try {
      await lstat(path.join(webRoot, file));
      failures.push(`${file} must be absent when the resume is disabled`);
    } catch (error) {
      if (error.code !== 'ENOENT') failures.push(`${file} could not be checked: ${error.message}`);
    }
  }
  return failures;
}
