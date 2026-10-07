# 0001 — Flutter Web for a document-first portfolio

## Status

Accepted.

## Context

The portfolio is a Flutter Web application assembled from [page sections](../../lib/app/modules/home/) and bundled [content JSON](../../assets/content/portfolio.json). The release is static [`build/web`](../DEPLOY.md); there is no application backend. The Flutter renderer brings a substantial download and canvas rendering cost. The [HTML entrypoint](../../web/index.html) supplies metadata and a critical first-frame shell. Release preparation adds a semantic portfolio document that remains readable without JavaScript. Flutter's semantics tree supports accessibility after startup; source HTML provides the pre-startup document.

## Decision

Keep Flutter Web as the interactive presentation runtime. Generate the critical shell and static semantic document from canonical content during [release preparation](../../tool/release/prepare_web_release.mjs), keep static metadata and source documents, and ship both Wasm and JavaScript runtimes. [0002](0002-hash-routing-static-semantic-document.md) records the implemented static-document and routing contract.

## Consequences

Flutter widgets, interaction state, and tests stay in one application. Initial download and canvas rendering remain costs. The critical shell reduces blank time; the static document exposes section headings, text and links before startup and without JavaScript. It becomes hidden and inert after Flutter reveals. Release-document tests, bundle verification and browser tests check that contract.

## Alternatives considered

- A separate HTML application would duplicate section composition and content behavior.
- Flutter alone, without a critical shell or static document, would leave the first frame and crawler-visible content to runtime loading.
