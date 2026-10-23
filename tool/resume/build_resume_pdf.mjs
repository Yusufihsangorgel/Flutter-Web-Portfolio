// @ts-check
import { mkdir, readFile, rm, writeFile } from 'node:fs/promises';
import path from 'node:path';
import process from 'node:process';
import { fileURLToPath } from 'node:url';

import { normalizeResumePdf, resumeMetadata } from './normalize_resume_pdf.mjs';
import { assertResumePdf } from './pdf_text.mjs';
import { assertResumeStructure } from './pdf_structure.mjs';
import { renderResumeHtml, validatePaper } from './render_resume_html.mjs';
import { loadResumeFont } from './resume_font.mjs';
import { isResumeEnabled, resumeArtifactFiles } from './resume_availability.mjs';

const root = fileURLToPath(new URL('../../', import.meta.url));

/**
 * @param {string[]} args
 * @returns {{ out: string, paper: string }}
 */
export function parseArguments(args) {
  const options = { out: 'build/web', paper: 'a4' };
  const seen = new Set();
  for (let index = 0; index < args.length; index += 2) {
    const option = args[index];
    const value = args[index + 1];
    if (
      !['--out', '--paper'].includes(option) ||
      seen.has(option) ||
      !value ||
      value.startsWith('--')
    ) {
      throw new Error(
        'Usage: node tool/resume/build_resume_pdf.mjs [--out build/web] [--paper a4|letter]',
      );
    }
    seen.add(option);
    options[option.slice(2)] = value;
  }
  validatePaper(options.paper);
  return options;
}

/**
 * @param {any} record
 * @param {{ paper?: string }} [options]
 * @returns {Promise<{ html: string, pdf: Buffer }>}
 */
export async function renderResumePdf(record, { paper = 'a4' } = {}) {
  resumeMetadata(record);
  const html = renderResumeHtml(record, { paper, fontBase64: await loadResumeFont() });
  const { chromium } = await import('@playwright/test');
  const browser = await chromium.launch();
  try {
    const page = await browser.newPage({ locale: 'en-US', timezoneId: 'UTC' });
    await page.route('**/*', (route) => route.abort());
    await page.setContent(html, { waitUntil: 'load' });
    await page.evaluate(() => document.fonts.ready);
    if (!(await page.evaluate(() => document.fonts.check('10pt Resume')))) {
      throw new Error('The bundled resume font did not load.');
    }
    const raw = await page.pdf({
      format: paper === 'a4' ? 'A4' : 'Letter',
      preferCSSPageSize: true,
      printBackground: false,
      displayHeaderFooter: false,
      tagged: true,
      outline: true,
    });
    const pdf = normalizeResumePdf(raw, record);
    assertResumePdf(pdf, record);
    assertResumeStructure(pdf, paper);
    return { html, pdf };
  } finally {
    await browser.close();
  }
}

/**
 * @param {{ out?: string, paper?: string }} [options]
 * @returns {Promise<{ html: string, pdf: Buffer } | null>}
 */
export async function buildResumePdf({ out = 'build/web', paper = 'a4' } = {}) {
  const record = JSON.parse(
    await readFile(path.join(root, 'assets/content/portfolio.json'), 'utf8'),
  );
  return writeResumeArtifacts(record, { out, paper });
}

/**
 * @param {any} record
 * @param {{ out?: string, paper?: string }} [options]
 * @returns {Promise<{ html: string, pdf: Buffer } | null>}
 */
export async function writeResumeArtifacts(record, { out = 'build/web', paper = 'a4' } = {}) {
  const output = path.resolve(out);
  if (!isResumeEnabled(record)) {
    for (const file of resumeArtifactFiles) await rm(path.join(output, file), { force: true });
    return null;
  }
  const { html, pdf } = await renderResumePdf(record, { paper });
  await mkdir(output, { recursive: true });
  await writeFile(path.join(output, 'resume.html'), html);
  await writeFile(path.join(output, 'resume.pdf'), pdf);
  return { html, pdf };
}

if (process.argv[1] && path.resolve(process.argv[1]) === fileURLToPath(import.meta.url)) {
  try {
    const options = parseArguments(process.argv.slice(2));
    const result = await buildResumePdf(options);
    console.log(
      result
        ? `Resume ready at ${path.join(options.out, 'resume.pdf')} and resume.html.`
        : 'Resume disabled; previous resume artifacts removed.',
    );
  } catch (error) {
    console.error(`Resume build failed: ${error.message}`);
    process.exitCode = 1;
  }
}
