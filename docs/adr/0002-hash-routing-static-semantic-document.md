# 0002 — Hash routing with a static semantic document

## Status

Accepted.

## Context

The [URL bridge](../../lib/app/utils/web_url_strategy_web.dart) uses `#/section` fragments, so section changes do not require a server request. A Flutter Web entrypoint on its own offers metadata and a loading shell but no readable content before the engine starts, and the usual catch-all rewrite to `index.html` answers every unknown path with status 200.

## Decision

Generate a semantic HTML document from the canonical [portfolio content](../../assets/content/portfolio.json) at release time, with headings, text, and links available before Flutter starts. Keep hash fragments for interactive section navigation. Configure no catch-all rewrite: an unknown path returns HTTP 404 with the static [`404.html`](../../web/404.html) page, and the root URL with any hash serves the same document, because fragments are not sent to the server.

## Consequences

Crawlers and no-JavaScript readers can read core content from the release artifact; [`render_static_document.mjs`](../../tool/render_static_document.mjs) builds it and the [bundle verifier](../../tool/verify_web_build.mjs) checks its headings and links. Once Flutter has revealed the interactive view, the static document is hidden and inert so assistive technology reads one document. Hash fragments cannot produce distinct server responses or per-section metadata. The static document and Flutter view must derive from the same content and be checked for drift. The 404 page links home through the base the release build declares, so it works at a domain root and on a project Pages site. Host configs, the verifier, and browser tests change together.

## Alternatives considered

- Path-based Flutter routes would require server fallback and separate 404 handling on every static host.
- Keeping only a loading shell and a `<noscript>` message would not expose the portfolio document to no-JavaScript readers.
