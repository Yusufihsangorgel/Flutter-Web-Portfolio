import './test_release_security_static.mjs';

await import('./test_preview_security.mjs');
process.stdout.write('Release security contracts passed.\n');
