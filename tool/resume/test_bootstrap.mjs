// @ts-check
import assert from 'node:assert/strict';
import { readFile } from 'node:fs/promises';
import { test } from 'node:test';

import { verifyBootstrapSource } from '../release/verify_web_runtime_assets.mjs';

test('extracted bootstrap checks preserve valid release tokens and detect regressions', async () => {
  const source = await readFile(new URL('../../web/flutter_bootstrap.js', import.meta.url), 'utf8');
  const configuration = `"compileTarget":"dart2wasm" "useLocalCanvasKit":true main.dart.wasm?v=1 main.dart.mjs?v=1 main.dart.js?v=1`;
  const valid = source + configuration;
  assert.deepEqual(verifyBootstrapSource(valid), []);
  const missingTimeline = verifyBootstrapSource(
    valid.replaceAll('flutter-first-frame-to-reveal', 'removed-entry'),
  );
  assert.deepEqual(missingTimeline, [
    'the runtime timeline is missing flutter-first-frame-to-reveal',
  ]);
  assert.ok(
    verifyBootstrapSource(
      valid + '\n_flutter.loader.load({ serviceWorkerSettings: {} });',
    ).includes('the application bootstrap re-enabled the service worker'),
  );
  assert.ok(
    verifyBootstrapSource(valid.replace('"compileTarget":"dart2wasm"', '')).includes(
      'flutter_bootstrap.js does not advertise a dart2wasm build',
    ),
  );
});
