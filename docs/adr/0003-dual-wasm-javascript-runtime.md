# 0003 — Dual Wasm and JavaScript runtime

## Status

Accepted.

## Context

The [release command](../../tool/build_portfolio.mjs) builds with `--wasm --no-web-resources-cdn`. The [bundle verifier](../../tool/verify_web_build.mjs) checks Wasm, JavaScript, and renderer assets. [Host policy](../../web/_headers) sends Cross-Origin-Opener-Policy `same-origin` and Cross-Origin-Embedder-Policy `credentialless`; [deployment guidance](../DEPLOY.md) explains the same requirements for other hosts.

## Decision

Publish Flutter's Dart Wasm/SkWasm runtime alongside its JavaScript/CanvasKit fallback. Serve renderer resources from the same origin. Keep isolation headers on hosts that can set them and retain the fallback path on hosts that cannot.

## Consequences

The artifact contains multiple runtime variants, increasing release size even though a browser selects one. Threaded SkWasm needs cross-origin isolation; a host that cannot provide the headers can still serve the JavaScript fallback, subject to browser support. A release check must verify both variants and header policy, while browser checks verify actual startup.

## Alternatives considered

- Wasm-only output would exclude browsers or hosts that cannot satisfy its runtime requirements.
- JavaScript-only output would discard the Wasm path already built and verified by this repository.
