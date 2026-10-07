# 0003 — Dual Wasm and JavaScript runtime

## Status

Accepted.

## Context

The [release command](../../tool/release/build_portfolio.mjs) builds with `--wasm --no-web-resources-cdn`. The [bundle verifier](../../tool/release/verify_web_build.mjs) checks Wasm, JavaScript, and renderer assets. [Host policy](../../web/_headers) sends Cross-Origin-Opener-Policy `same-origin` and Cross-Origin-Embedder-Policy `credentialless`; [deployment guidance](../DEPLOY.md) explains the same requirements for other hosts.

## Decision

Publish Flutter's Dart Wasm/SkWasm runtime alongside its JavaScript/CanvasKit fallback. Serve renderer resources from the same origin. Keep isolation headers on hosts that can set them and retain the fallback path on hosts that cannot.

## Consequences

The artifact contains multiple runtime variants, increasing release size even though a browser selects one. Threaded SkWasm needs cross-origin isolation; a host that cannot provide the headers can still serve the JavaScript fallback, subject to browser support. A release check must verify both variants and header policy, while browser checks verify actual startup.

## Alternatives considered

- Wasm-only output would exclude browsers or hosts that cannot satisfy its runtime requirements.
- JavaScript-only output would discard the Wasm path already built and verified by this repository.

## Single-threaded Skwasm

Status: Accepted (2026-10-07).

Context: Multi-threaded Skwasm in Flutter 3.47.5 shares the Skia glyph cache between page-side text layout and the raster worker (flutter/flutter#190039; fix flutter/flutter#190048 is on master only, the 3.47 backport was closed). When both reach it at once the page and the worker stop responding, so the loading surface is never removed. CI showed the freeze in 4 of 22 runs.

Decision: Set `forceSingleThreadedSkwasm: true` in `web/flutter_bootstrap.js` until a pinned stable release contains #190048. Keep the isolation headers in place; single-threaded Skwasm does not require them (verified in the pinned `skwasm_loader.js`: `skwasmSingleThreaded` is true when the page is not isolated or the flag is set), but the headers stay for the threaded path after the revert.

Measured cost (release build, `npm run verify:runtime` medians of 3 runs per invocation):

| Backend | Worst nav / bootstrap (ms) | Reveal after first frame | Intervals | Scroll p95 ratio | Long tasks |
|---|---|---|---|---|---|
| Mac Metal GPU, 3 invocations | 275.75 / 214.15 | 81.25 ms | 9.75 | 1.22 | 205 ms |
| Linux SwiftShader software GL, 5 invocations | 669.77 / 579.77 | 792.11 ms | 34.37 | 6.50 | 3363 ms |
| GitHub-hosted x86 runner, SwiftShader, 3 runs | 657.29 / 548.96 | — | 5.58 | 2.40 | 6049 ms |

Budgets for the three failing medians move to worst Linux plus 20-22 percent margin: intervals 3 to 42, ratio 2.25 to 7.8, long tasks 500 ms to 4040 ms. The CI runner then measured long tasks of 5558 to 6049 ms, so that budget is the worst CI run plus 20 percent: 7300 ms. Other budgets are unchanged. The reload regression spec in `tests/e2e/smoke-bootstrap-shell.spec.ts` asserts no raster worker spawns across localized reloads.

Revert condition: When the pinned stable includes flutter/flutter#190048, remove the flag, restore the earlier budgets, and rerun the reload spec 50 times.
