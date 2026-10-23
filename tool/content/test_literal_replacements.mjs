import assert from 'node:assert/strict';
import { spawnSync } from 'node:child_process';
import { mkdtemp, readFile, rm, stat, writeFile } from 'node:fs/promises';
import os from 'node:os';
import path from 'node:path';
import test from 'node:test';
import { fileURLToPath } from 'node:url';

import { syncDelimitedFile } from './sync_public_content.mjs';
import { renderDemoLinks } from '../public-content/renderers.mjs';
import { renderLocaleData, renderReleaseIndex } from '../release/render_release_index.mjs';

const root = fileURLToPath(new URL('../..', import.meta.url));
const start = '<!-- artifact:start -->';
const end = '<!-- artifact:end -->';
const prefix = 'prefix $$ $&\r\n';
const suffix = "\r\nsuffix $` $'\0";
const current = `${prefix}${start}\r\nstale\r\n${end}${suffix}`;
const payloads = ['$$', '$&', '$`', "$'", "$$ $& $` $'", 'ordinary λ — 42\r\nnext'];
const index =
  'prefix\r\n<!-- static-document:start -->stale<!-- static-document:end -->\r\noutside\ttext<!-- bootstrap-content:start -->stale<!-- bootstrap-content:end -->\r\nsuffix';

async function withFile(run) {
  const directory = await mkdtemp(path.join(os.tmpdir(), 'literal-replacements-'));
  const file = path.join(directory, 'artifact.txt');
  try {
    await writeFile(file, current);
    return await run(file);
  } finally {
    await rm(directory, { recursive: true, force: true });
  }
}

for (const payload of payloads) {
  test(`content synchronization preserves literal ${JSON.stringify(payload)}`, async () => {
    await withFile(async (file) => {
      assert.deepEqual(await syncDelimitedFile(file, start, end, payload), {
        file,
        changed: true,
      });
      const expected = Buffer.from(`${prefix}${start}\n${payload}\n${end}${suffix}`);
      assert.deepEqual(await readFile(file), expected);
      const before = await stat(file);
      assert.deepEqual(await syncDelimitedFile(file, start, end, payload), {
        file,
        changed: false,
      });
      assert.deepEqual(await readFile(file), expected);
      assert.equal((await stat(file)).mtimeMs, before.mtimeMs);
    });
  });

  for (const boundary of ['shell', 'document']) {
    test(`release ${boundary} preserves literal ${JSON.stringify(payload)}`, () => {
      const shell = boundary === 'shell' ? payload : '<div class="bootstrap-shell"></div>';
      const document = boundary === 'document' ? payload : '<main id="static-document"></main>';
      const expected = `prefix\r\n<!-- static-document:start -->\n${document}\n  <!-- static-document:end -->\r\noutside\ttext\n    <!-- bootstrap-content:start -->\n${shell}\n    <!-- bootstrap-content:end -->\r\nsuffix`;
      const output = renderReleaseIndex(index, shell, document);
      assert.deepEqual(Buffer.from(output), Buffer.from(expected));
      assert.equal(renderReleaseIndex(output, shell, document), output);
    });
  }
}

test('content synchronization treats regexp punctuation and marker dollars literally', async () => {
  await withFile(async (file) => {
    const opening = '<!-- artifact.[($$)]:start -->';
    const closing = '<!-- artifact.[($&)]:end -->';
    await writeFile(file, `${prefix}${opening}stale${closing}${suffix}`);
    await syncDelimitedFile(file, opening, closing, 'next');
    assert.equal(await readFile(file, 'utf8'), `${prefix}${opening}\nnext\n${closing}${suffix}`);
    assert.deepEqual(await syncDelimitedFile(file, opening, closing, 'next'), {
      file,
      changed: false,
    });
  });
});

test('content synchronization accepts an empty body without changing its neighbors', async () => {
  await withFile(async (file) => {
    await syncDelimitedFile(file, start, end, '');
    assert.equal(await readFile(file, 'utf8'), `${prefix}${start}\n\n${end}${suffix}`);
  });
});

for (const source of ['no markers', start, end]) {
  test(`content synchronization keeps the missing-delimiter error for ${source}`, async () => {
    await withFile(async (file) => {
      await writeFile(file, source);
      await assert.rejects(syncDelimitedFile(file, start, end, '$&'), {
        message: `${path.relative(root, file)} is missing the ${start} / ${end} delimiters`,
      });
      assert.equal(await readFile(file, 'utf8'), source);
    });
  });
}

function checkFile(file, body) {
  const moduleUrl = new URL('./sync_public_content.mjs', import.meta.url).href;
  const script = `import { syncDelimitedFile } from ${JSON.stringify(moduleUrl)};
const [file, start, end, body] = process.argv.slice(1);
console.log(JSON.stringify(await syncDelimitedFile(file, start, end, body)));`;
  const result = spawnSync(
    process.execPath,
    ['--input-type=module', '--eval', script, file, start, end, body, '--check'],
    { encoding: 'utf8', timeout: 10_000 },
  );
  assert.ifError(result.error);
  assert.equal(result.status, 0, result.stderr);
  assert.equal(result.stderr, '');
  return JSON.parse(result.stdout);
}

test('check-only detects drift without writing literal replacement data', async () => {
  await withFile(async (file) => {
    const before = await stat(file);
    assert.deepEqual(checkFile(file, payloads[4]), { file, changed: true });
    assert.equal(await readFile(file, 'utf8'), current);
    assert.equal((await stat(file)).mtimeMs, before.mtimeMs);
  });
});

test('check-only accepts synchronized literal data without writing', async () => {
  await withFile(async (file) => {
    const expected = `${prefix}${start}\n${payloads[4]}\n${end}${suffix}`;
    await writeFile(file, expected);
    const before = await stat(file);
    assert.deepEqual(checkFile(file, payloads[4]), { file, changed: false });
    assert.equal(await readFile(file, 'utf8'), expected);
    assert.equal((await stat(file)).mtimeMs, before.mtimeMs);
  });
});

for (const source of [
  '<!-- static-document:start --><!-- static-document:end -->',
  '<!-- bootstrap-content:start --><!-- bootstrap-content:end -->',
  'no markers',
]) {
  test(`release rendering keeps the missing-marker error for ${source}`, () => {
    assert.throws(() => renderReleaseIndex(source, '$$', '$&'), {
      message: 'index.html is missing release content markers',
    });
  });
}

test('release rendering also preserves literals when the shell precedes the document', () => {
  const source =
    'before<!-- bootstrap-content:start -->old<!-- bootstrap-content:end -->between<!-- static-document:start -->old<!-- static-document:end -->after';
  const output = renderReleaseIndex(source, '$&', '$`');
  assert.equal(
    output,
    'before\n    <!-- bootstrap-content:start -->\n$&\n    <!-- bootstrap-content:end -->between<!-- static-document:start -->\n$`\n  <!-- static-document:end -->after',
  );
});

test('escaped HTML with dollar tokens stays escaped through both generators', async () => {
  const markup = renderDemoLinks({
    site: {
      engineering_links: [
        { label: '$$ $& $` $\' </a><script>"&</script>', url: 'https://example.invalid/artifact' },
      ],
    },
  });
  const expected =
    '<a href="https://example.invalid/artifact">$$ $&amp; $` $\' &lt;/a&gt;&lt;script&gt;&quot;&amp;&lt;/script&gt;</a>';
  assert.equal(markup, expected);
  await withFile(async (file) => {
    await syncDelimitedFile(file, start, end, markup);
    assert.equal(await readFile(file, 'utf8'), `${prefix}${start}\n${expected}\n${end}${suffix}`);
  });
  const output = renderReleaseIndex(index, markup, markup);
  assert.equal(output.split(expected).length, 3);
  assert.equal(output.includes('<script>'), false);
});

test('script-safe JSON keeps dollar tokens and hostile markup after release insertion', async () => {
  const payload = '$$ $& $` $\' </script><SCRIPT>"&  ';
  const script = renderLocaleData({ en: { title: payload } });
  for (const character of ['<', '>', '&', ' ', ' ']) {
    assert.equal(script.includes(character), false);
  }
  const json = script.match(/^window\.__portfolioBootstrapLocales = ([\s\S]*);\n$/)?.[1];
  assert.equal(JSON.parse(json).en.title, payload);
  const markup = `<script type="application/ld+json">${json}</script>`;
  const output = renderReleaseIndex(index, '<div></div>', markup);
  assert.equal(output.split(markup).length, 2);
  await withFile(async (file) => {
    await syncDelimitedFile(file, start, end, markup);
    assert.equal(await readFile(file, 'utf8'), `${prefix}${start}\n${markup}\n${end}${suffix}`);
  });
});
