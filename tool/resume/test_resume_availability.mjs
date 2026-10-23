import assert from 'node:assert/strict';
import { mkdtemp, readdir, rm, writeFile } from 'node:fs/promises';
import { tmpdir } from 'node:os';
import path from 'node:path';
import test from 'node:test';

import { isResumeEnabled, resumeArtifactFiles } from './resume_availability.mjs';
import { writeResumeArtifacts } from './build_resume_pdf.mjs';
import { checkBrowserResume } from './check_browser_pdf.mjs';
import { verifyResumeRelease } from './verify_resume_release.mjs';

test('resume availability requires an explicit boolean and defaults to disabled', () => {
  assert.equal(isResumeEnabled({}), false);
  assert.equal(isResumeEnabled({ site: {} }), false);
  assert.equal(isResumeEnabled({ site: { resume_enabled: false } }), false);
  assert.equal(isResumeEnabled({ site: { resume_enabled: true } }), true);
  for (const resume_enabled of [null, 'true', 1, {}]) {
    assert.throws(() => isResumeEnabled({ site: { resume_enabled } }), /boolean/);
  }
});

test('disabled releases remove old resume files without rendering or touching other assets', async () => {
  const out = await mkdtemp(path.join(tmpdir(), 'resume-disabled-'));
  try {
    for (const file of resumeArtifactFiles) await writeFile(path.join(out, file), 'old resume');
    await writeFile(path.join(out, 'index.html'), 'portfolio');
    const record = { site: { resume_enabled: false } };
    const failures = await verifyResumeRelease({ webRoot: out, record });
    assert.equal(failures.length, resumeArtifactFiles.length);
    assert.ok(failures.every((failure) => failure.includes('disabled')));
    assert.equal(await writeResumeArtifacts(record, { out }), null);
    assert.deepEqual(await readdir(out), ['index.html']);
    assert.deepEqual(await verifyResumeRelease({ webRoot: out, record }), []);
    // The record has no experience data, so any rendering attempt would throw.
    assert.equal(await checkBrowserResume(record), undefined);
    assert.equal(await writeResumeArtifacts({}, { out }), null);
  } finally {
    await rm(out, { recursive: true, force: true });
  }
});
