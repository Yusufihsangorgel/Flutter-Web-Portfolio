# 0001 — Flutter Web for a document-first portfolio

## Status

Accepted.

## Context

The portfolio is a Flutter Web application assembled from [page sections](../../lib/app/modules/home/) and bundled [content JSON](../../assets/content/portfolio.json). The release is static [`build/web`](../../docs/DEPLOY.md); there is no application backend. The Flutter renderer brings a substantial download and canvas rendering cost. The current [HTML entrypoint](../../web/index.html) has metadata, a critical first-frame shell, and a JavaScript-required message, but does not provide the complete portfolio to a no-JavaScript reader. Flutter's semantics tree supports accessibility after startup; it is not a substitute for crawlable source HTML.

## Decision

Keep Flutter Web as the interactive presentation runtime. Generate the critical shell from canonical content during [release preparation](../../tool/prepare_web_release.mjs), keep static metadata and source documents, and ship both Wasm and JavaScript runtimes. A full static semantic document is the follow-up in [0002](0002-hash-routing-static-semantic-document.md), not a current capability.

## Consequences

Flutter widgets, interaction state, and tests stay in one application. Initial download and canvas rendering remain costs; the critical shell reduces blank time but its current `aria-hidden` content and `<noscript>` recovery do not make the whole document readable without JavaScript. Search and no-JavaScript coverage require the proposed semantic document and an explicit verification gate.

## Alternatives considered

- A separate HTML application would duplicate section composition and content behavior.
- Flutter alone, without a critical shell or static document, would leave the first frame and crawler-visible content to runtime loading.
