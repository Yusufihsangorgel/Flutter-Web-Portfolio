import assert from 'node:assert/strict';

import { renderContentSecurityPolicy, securityHeaders } from './public-content/security.mjs';
import { validateHostingSecurity } from './public-content/hosting_security.mjs';

const content = {
  site: { analytics: { script_url: 'https://analytics.example.invalid/script.js' } },
};
const csp = renderContentSecurityPolicy(content);
const hsts = securityHeaders(content)['Strict-Transport-Security'];
const valid = {
  nginx: `server {\nadd_header Strict-Transport-Security "${hsts}" always;\nadd_header Content-Security-Policy "${csp}" always;\nlocation / { try_files $uri $uri/ =404; }\n}`,
  staticHeaders: `/*\n  Strict-Transport-Security: ${hsts}\n  Content-Security-Policy: ${csp}\n`,
  firebase: { hosting: { headers: [{ source: '**', headers: [
    { key: 'Strict-Transport-Security', value: hsts },
    { key: 'Content-Security-Policy', value: csp },
  ] }], rewrites: [] } },
  vercel: { headers: [{ source: '/(.*)', headers: [
    { key: 'Strict-Transport-Security', value: hsts },
    { key: 'Content-Security-Policy', value: csp },
  ] }], rewrites: [] },
  netlify: `[[headers]]\n  for = "/*"\n  [headers.values]\n  Strict-Transport-Security = "${hsts}"\n  Content-Security-Policy = "${csp}"`,
  redirects: '',
};

assert.deepEqual(validateHostingSecurity(valid, content), []);

for (const host of ['nginx', 'staticHeaders', 'firebase', 'vercel', 'netlify']) {
  const fixture = structuredClone(valid);
  if (typeof fixture[host] === 'string') {
    fixture[host] = fixture[host].replace(/Strict-Transport-Security[^\n]*/, '');
  } else {
    const group = host === 'firebase' ? fixture.firebase.hosting.headers[0] : fixture.vercel.headers[0];
    group.headers = group.headers.filter((header) => header.key !== 'Strict-Transport-Security');
  }
  assert.ok(validateHostingSecurity(fixture, content).some((error) => error.includes(`${host} HSTS`)), host);
}

for (const host of ['nginx', 'staticHeaders', 'firebase', 'vercel', 'netlify']) {
  const fixture = structuredClone(valid);
  if (host === 'nginx') fixture.nginx = fixture.nginx.replace('add_header Strict-Transport-Security', 'location /assets/ { add_header Strict-Transport-Security');
  if (host === 'staticHeaders') fixture.staticHeaders = fixture.staticHeaders.replace('/*', '/assets/*');
  if (host === 'firebase') fixture.firebase.hosting.headers[0].source = 'assets/**';
  if (host === 'vercel') fixture.vercel.headers[0].source = '/assets/(.*)';
  if (host === 'netlify') fixture.netlify = fixture.netlify.replace('for = "/*"', 'for = "/assets/*"');
  assert.ok(validateHostingSecurity(fixture, content).some((error) => error.includes(`${host} HSTS`)), `${host} global scope`);
}

for (const host of ['nginx', 'staticHeaders', 'firebase', 'vercel', 'netlify']) {
  const fixture = structuredClone(valid);
  if (typeof fixture[host] === 'string') {
    fixture[host] = fixture[host].replace("script-src 'self'", "script-src 'self' 'unsafe-inline'");
  } else {
    const group = host === 'firebase' ? fixture.firebase.hosting.headers[0] : fixture.vercel.headers[0];
    group.headers.find((header) => header.key === 'Content-Security-Policy').value = csp.replace(
      "script-src 'self'", "script-src 'self' 'unsafe-eval'",
    );
  }
  assert.ok(validateHostingSecurity(fixture, content).some((error) => error.includes(`${host} CSP`)), host);
}

for (const [host, mutate] of [
  ['nginx', (fixture) => { fixture.nginx = fixture.nginx.replace('=404', '/index.html'); }],
  ['firebase', (fixture) => { fixture.firebase.hosting.rewrites.push({ source: '**', destination: '/index.html' }); }],
  ['vercel', (fixture) => { fixture.vercel.rewrites.push({ source: '/(.*)', destination: '/index.html' }); }],
  ['redirects', (fixture) => { fixture.redirects = '/*  /index.html  200'; }],
  ['netlify', (fixture) => { fixture.netlify += '\n[[redirects]]\n  from = "/*"\n  to = "/index.html"'; }],
  ['nginx', (fixture) => { fixture.nginx = fixture.nginx.replace('=404;', '/index.html =404;'); }],
  ['nginx', (fixture) => { fixture.nginx = fixture.nginx.replace('location / {', 'rewrite ^ /index.html;\nlocation / {'); }],
  ['nginx', (fixture) => { fixture.nginx = fixture.nginx.replace('location / {', 'rewrite ^/(.*)$ /index.html last;\nlocation / {'); }],
  ['nginx', (fixture) => { fixture.nginx = fixture.nginx.replace('location / {', 'rewrite ^(.*)$ /index.html last;\nlocation / {'); }],
  ['redirects', (fixture) => { fixture.redirects = '/*  /  200!'; }],
  ['netlify', (fixture) => { fixture.netlify += '\n[[redirects]]\n  from = "/*"\n  to = "/"\n  status = 200'; }],
]) {
  const fixture = structuredClone(valid);
  mutate(fixture);
  assert.ok(validateHostingSecurity(fixture, content).some((error) => error.includes(`${host} catch-all`)), host);
}

const narrowRewrite = structuredClone(valid);
narrowRewrite.nginx = narrowRewrite.nginx.replace('location / {', 'location /old { rewrite ^ /index.html; }\nlocation / {');
assert.deepEqual(validateHostingSecurity(narrowRewrite, content), []);

process.stdout.write('Hosting security fixtures passed.\n');
