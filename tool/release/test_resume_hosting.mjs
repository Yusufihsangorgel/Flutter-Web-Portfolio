import assert from 'node:assert/strict';
import test from 'node:test';

import { validateResumeHosting } from './resume_hosting.mjs';

const cache = 'public, max-age=0, must-revalidate';
const files = ['resume.pdf', 'resume.html'];
const groups = files.map((file) => ({
  source: `/${file}`,
  headers: [
    { key: 'Content-Type', value: file.endsWith('.pdf') ? 'application/pdf' : 'text/html' },
    { key: 'Cache-Control', value: cache },
  ],
}));
const valid = {
  nginx: `gzip_static on;
server {
  add_header_inherit merge;
  location = /resume.pdf {
    types { application/pdf pdf; }
    try_files $uri =404;
    add_header Cache-Control "${cache}" always;
    gzip off;
    gzip_static off;
  }
  location = /resume.html {
    types { text/html html; }
    try_files $uri =404;
    add_header Cache-Control "${cache}" always;
  }
}`,
  firebase: {
    hosting: { headers: groups.map((group) => ({ ...group, source: group.source.slice(1) })) },
  },
  vercel: { headers: groups },
  netlify: groups
    .map(
      (group) => `[[headers]]
  for = "${group.source}"
  [headers.values]
  Content-Type = "${group.headers[0].value}"
  Cache-Control = "${cache}"`,
    )
    .join('\n'),
};

test('explicit resume policies pass for all hosts', () => {
  assert.deepEqual(validateResumeHosting(valid), []);
});

for (const host of ['nginx', 'firebase', 'vercel', 'netlify']) {
  for (const file of files) {
    for (const policy of ['scope', 'Content-Type', 'Cache-Control']) {
      test(`${host} rejects missing or incorrect ${file} ${policy}`, () => {
        const fixture = structuredClone(valid);
        mutatePolicy(fixture, { host, file, policy });
        assert.ok(
          validateResumeHosting(fixture).some((error) => error.includes(`${host} ${file}`)),
        );
      });
    }
  }
}

function mutatePolicy(fixture, { host, file, policy }) {
  if (host === 'firebase' || host === 'vercel') {
    const headers = host === 'firebase' ? fixture.firebase.hosting.headers : fixture.vercel.headers;
    const group = headers.find((entry) => entry.source.endsWith(file));
    if (policy === 'scope') group.source += '.missing';
    else group.headers.find((header) => header.key === policy).value = 'incorrect';
    return;
  }
  const type = file.endsWith('.pdf') ? 'application/pdf' : 'text/html';
  const old = policy === 'scope' ? `/${file}` : policy === 'Content-Type' ? type : cache;
  const start = fixture[host].indexOf(`/${file}`);
  fixture[host] =
    fixture[host].slice(0, start) + fixture[host].slice(start).replace(old, 'incorrect');
}

for (const [label, before, after] of [
  ['security header inheritance', 'add_header_inherit merge;', 'add_header_inherit off;'],
  ['direct PDF requests', 'try_files $uri =404;', 'return 404;'],
  ['HTML static compression', 'gzip_static on;', 'gzip_static off;'],
  ['PDF compression policy', 'gzip_static off;', 'gzip_static on;'],
  ['PDF dynamic compression', 'gzip off;', 'gzip on;'],
  ['commented PDF MIME', 'types { application/pdf pdf; }', '# types { application/pdf pdf; }'],
  ['conflicting PDF cache', 'gzip off;', 'expires 1y;\n    gzip off;'],
  ['PDF rewrite', 'gzip off;', 'rewrite ^ /404.html;\n    gzip off;'],
  ['local inheritance override', 'gzip off;', 'add_header_inherit off;\n    gzip off;'],
  ['conflicting static compression', 'gzip_static off;', 'gzip_static off;\n    gzip_static on;'],
  ['conflicting dynamic compression', 'gzip off;', 'gzip off;\n    gzip on;'],
  ['local security override', 'gzip off;', 'add_header X-Frame-Options "DENY";\n    gzip off;'],
]) {
  test(`nginx rejects broken ${label}`, () => {
    const fixture = structuredClone(valid);
    fixture.nginx = fixture.nginx.replace(before, after);
    assert.ok(validateResumeHosting(fixture).some((error) => error.startsWith('nginx')));
  });
}

for (const [label, before, after] of [
  ['direct HTML requests', 'try_files $uri =404;', 'return 404;'],
  ['HTML rewrite', 'try_files $uri =404;', 'try_files $uri =404; rewrite ^ /404.html;'],
  ['HTML immutable cache', 'try_files $uri =404;', 'try_files $uri =404; expires 1y;'],
  [
    'HTML inheritance override',
    'try_files $uri =404;',
    'try_files $uri =404; add_header_inherit off;',
  ],
  ['HTML compression override', 'try_files $uri =404;', 'try_files $uri =404; gzip_static off;'],
]) {
  test(`nginx rejects broken ${label}`, () => {
    const fixture = structuredClone(valid);
    const start = fixture.nginx.indexOf('location = /resume.html');
    fixture.nginx =
      fixture.nginx.slice(0, start) + fixture.nginx.slice(start).replace(before, after);
    assert.ok(validateResumeHosting(fixture).some((error) => error.includes('nginx resume.html')));
  });
}

test('multiline MIME blocks retain the entire document location', () => {
  const fixture = structuredClone(valid);
  fixture.nginx = fixture.nginx.replace(
    'types { application/pdf pdf; }',
    'types {\n      application/pdf pdf;\n    }',
  );
  assert.deepEqual(validateResumeHosting(fixture), []);
});

for (const host of ['firebase', 'vercel']) {
  for (const duplicate of ['group', 'header']) {
    test(`${host} rejects duplicate resume ${duplicate}s`, () => {
      const fixture = structuredClone(valid);
      const groups =
        host === 'firebase' ? fixture.firebase.hosting.headers : fixture.vercel.headers;
      if (duplicate === 'group') groups.push(structuredClone(groups[0]));
      else
        groups[0].headers.push({
          key: 'Cache-Control',
          value: 'public, max-age=31536000, immutable',
        });
      assert.ok(
        validateResumeHosting(fixture).some((error) => error.includes(`${host} resume.pdf`)),
      );
    });
  }
}

test('Netlify rejects duplicate document blocks', () => {
  const fixture = structuredClone(valid);
  fixture.netlify += `\n${valid.netlify}`;
  assert.equal(validateResumeHosting(fixture).length, 2);
});

test('rules hidden in Netlify comments do not satisfy the contract', () => {
  const fixture = structuredClone(valid);
  fixture.netlify = fixture.netlify.replaceAll('  Cache-Control', '# Cache-Control');
  assert.equal(validateResumeHosting(fixture).length, 2);
});

for (const replacement of ['', '[wrong.values]']) {
  test(`Netlify rejects missing header value tables (${replacement || 'removed'})`, () => {
    const fixture = structuredClone(valid);
    fixture.netlify = fixture.netlify.replaceAll('[headers.values]', replacement);
    assert.equal(validateResumeHosting(fixture).length, 2);
  });
}
