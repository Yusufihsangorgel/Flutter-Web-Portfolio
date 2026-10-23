// @ts-check
export const resumeArtifactFiles = ['resume.html', 'resume.pdf', 'resume.html.gz'];

/** @param {any} record */
export function isResumeEnabled(record) {
  const enabled = record.site?.resume_enabled;
  if (enabled !== undefined && typeof enabled !== 'boolean') {
    throw new Error('site.resume_enabled must be a boolean.');
  }
  return enabled === true;
}
