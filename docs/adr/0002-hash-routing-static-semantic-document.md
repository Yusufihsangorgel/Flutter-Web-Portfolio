# 0002 — Hash routing with a static semantic document

## Status

Proposed.

## Context

The [URL bridge](../../lib/app/utils/web_url_strategy_web.dart) already uses `#/section` fragments, so section changes do not require a server request. The current [HTML entrypoint](../../web/index.html) offers metadata and a critical shell, but its `<noscript>` element asks readers to enable JavaScript. The [host redirects](../../web/_redirects) and [bundle verifier](../../tool/verify_web_build.mjs) currently require a catch-all rewrite to `index.html`.

## Decision

Generate a semantic HTML document from the canonical [portfolio content](../../assets/content/portfolio.json) at release time, with headings, text, and links available before Flutter starts. Keep hash fragments for interactive section navigation. Remove the catch-all SPA rewrite once every configured host serves the root document and assets correctly without it. An unknown path should return HTTP 404; a known root URL with any hash still serves the same document, because fragments are not sent to the server.

## Consequences

Crawlers and no-JavaScript readers can read core content from the release artifact after implementation. Hash fragments cannot produce distinct server responses or per-section metadata. The static document and Flutter view must derive from the same content and be checked for drift. Host configs, the verifier, and browser tests must change together; until then, unknown paths are rewritten to a 200 response by current hosting rules.

## Alternatives considered

- Path-based Flutter routes would require server fallback and separate 404 handling on every static host.
- Keeping only the current splash and `<noscript>` message would not expose the portfolio document to no-JavaScript readers.
