Promise.all([
  import('./test_render_resume.mjs'),
  import('./test_pdf.mjs'),
  import('./test_bootstrap.mjs'),
]).catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
