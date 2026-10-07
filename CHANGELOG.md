# Changelog

All notable changes to this project are documented in this file.
The format follows [Keep a Changelog 1.1.0](https://keepachangelog.com/en/1.1.0/),
and this project follows [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- Published package details, proof and roadmaps, a feed-backed Writing section, and generated `llms.txt` from the content record.
- Added weekly package/contribution/writing refreshes and reports for unlisted merged contributions.
- Added uncaught-error logging, generated typed interface strings and import-rule calibration (#22).
- Added eight ADRs, the template/contributor guides, a README leading with shipped work and third-party asset notices (#26).
- Added manual Linux visual-baseline generation and artifact upload (#28).
- Added a JavaScript-free semantic document, real 404s, version metadata, precompressed assets and Lighthouse checks (#35).
- Added content-derived résumé HTML and an ATS-readable, tagged PDF with text and determinism checks (#38).
- Added accessibility, Lighthouse and font-subsetting development dependencies (#15).

### Changed

- Updated the pinned toolchain to Flutter 3.47.5 and Dart 3.13.4; kept package topics authored instead of copying pub.dev labels.
- Replaced tracked builds and production CD with a tested, checksummed, attested CI artifact and independent pull delivery; refreshes use checked PRs (#16).
- Updated the pinned checkout and Pages deployment actions (#19).
- Updated `actions/setup-node` to 7.0.0 (#20).
- Split the smoke suite, replaced fixed sleeps, added accessibility checks and scheduled production browser checks (#23).
- Subset Latin/shared-script fonts, load full script fonts per locale, and documented the rendering-budget package's public API and web refresh-rate limit (#24).
- Kept Node type definitions on the pinned runtime major (#27).
- Split domain entities and data mappers; schema 11 adds featured entries, integer maturity levels and category validation (#30).
- Updated `url_launcher` to 6.3.3 (#32).
- Converted work images to WebP, load them near the viewport, and split the project atlas (#34).
- Grouped and split tooling by purpose; CI type-checks, lints and formats it (#39).
- Switched sections to real links, showed featured packages and writing first, and typed every locale's text (#41).
- Enabled shared strict analysis, shrink-only callable metrics and a blocking architecture gate with an empty import baseline (#42).
- Removed rail/scrollbar capture masks and set coverage floors to domain 99% and application 92% (#45).

### Fixed

- Corrected finished-work status and translated work descriptions in the authored record.
- Excluded regenerated social-card outputs from the source manifest and checked that manifest against the exact Git tree (#21).
- Initialized clones now have a neutral README and package links to their own repository, with rollback coverage (#25).
- Accepted history trailers only for the declared GitHub update bots (#29).
- Authenticated source audits with the workflow token and honored bounded API retry delays (#33).
- Disabled threaded Skwasm to avoid the pinned glyph-cache freeze, bounded scroll/frame waits and kept browser analytics requests local (#40).
- Served résumé files with explicit MIME types, revalidation and inherited security headers on the configured hosts (#43).
- Landed deep links on the first frame, exposed real navigation anchors, fixed keyboard focus and the skip link, and removed narrative domain imports (#44).

### Security

- Added import boundaries and prohibited-SDK checks (#14), now blocking through #42.
- Added supply-chain scanning, dependency review, SHA-pinned actions and main-only artifact provenance (#16).
- Tightened CSP and image sources, added HSTS and synchronized RFC 9116 security.txt with expiry checks (#35).

## [2.0.0] - 2026-07-18

### Added

- An interactive and scriptable portfolio initializer that produces a valid,
  identity-clean content document without editing Dart code.
- A clean-template smoke test that validates generated content through the same
  strict Dart model used before `runApp`.
- Reproducible release and deploy commands for GitHub Pages, Firebase Hosting,
  Netlify, Cloudflare Pages, Vercel, and Docker.
- Hosting-native SPA routes, security headers, and cache policies for Firebase,
  Netlify, Cloudflare Pages, Vercel, and Nginx, with the GitHub Pages header
  limitation documented explicitly.
- A clean-clone release gate that proves initialized repositories contain no
  inherited owner artifacts and still produce a verified web bundle.
- A full-history audit for prohibited attribution and control files, with
  development markers required to be resolved at the current head.
- Structured issue forms plus synchronized conduct and private security-report
  contacts for clean template-derived repositories.
- Complete professional-content overlays for Turkish, German, French, Spanish,
  Arabic, and Hindi, applied atomically with their interface catalogs.
- Exact Node and Flutter toolchain verification, hardened release inputs,
  raster-integrity checks, and content-bound social-card fingerprints.
- Keyboard-first skip navigation, focus-safe floating controls, and localized
  recovery states for saved-language and persistence failures.

### Changed

- Rebuilt the README as a visual product entrypoint with a guided first run,
  one-file customization contract, provider matrix, and collapsible live
  engineering record.
- Aligned contributor documentation and CI with template initialization,
  content validation, source reachability, and the canonical release command.
- Made initialization delete demo artifacts and regenerate the social card and
  source manifest before the first customized build.
- Made GitHub Pages distinguish project sites, user sites, custom domains, and
  explicit nested paths before running the canonical release build.
- Aligned initializer, Dart parsing, and generated community contacts on one
  conservative public-email contract.
- Reconciled the professional timeline with the current LinkedIn record and
  limited public work records to explicitly approved, traceable sources.
- Registered each variable font once and added the Arabic and Devanagari font
  coverage needed by the authored locale set.

### Fixed

- Prevented mixed-language pages by rejecting partial professional-content
  catalogs instead of silently falling back field by field.
- Preserved the newest language choice across overlapping persistence writes
  and kept a usable in-process locale when storage fails.
- Preserved the active deep-linked chapter across document-reloading language
  changes, including left-to-right and right-to-left transitions, without
  manufacturing an extra browser-history entry.
- Removed hidden controls from keyboard and accessibility traversal, while
  preserving focus visibility when those controls are available.
- Kept clean template clones free of inherited release artifacts, identity
  traces, and owner-specific social-card or changelog content.
- Made pointer-driven work previews swap atomically without moving index rows,
  cross-fading full panels, or decoding every hidden artifact.

## Earlier development

### Added

- A canonical portfolio record with typed validation, source provenance, and
  synchronized public metadata. Commits: `b1d1811`, `046fd65`, `4e5b439`.
- Data-driven system studies, professional cases, supporting-work evidence, and
  a responsive work index. Commits: `c3be628`, `cf2ca40`, `d6b6392`, `991e2f2`.
- Dual-runtime Flutter Web releases, same-origin renderer assets, and browser
  release checks. Commits: `c7ad6ca`, `4de51a9`, `a3d40cd`, `a15a19f`.
- First-paint and fallback flows, runtime diagnostics, performance budgets,
  and cross-renderer browser coverage. Commits: `a19d5c7`, `4ab901f`,
  `188d669`, `fb5fd36`, `15fd002`.
- Chapter navigation with direct links, browser history, RTL and reduced-motion
  behavior. Commits: `04ec6c2`, `5a80782`, `546f0cd`, `581f484`.
- Adaptive render-quality policies and responsive accessibility and visual
  regression coverage. Commits: `48efb82`, `49271a5`, `24721c9`, `95e9b96`.

### Changed

- Reworked the generic showcase into a narrative portfolio with case studies,
  system studies, and an evidence-led work index. Commits: `e4f2a9a`,
  `991e2f2`, `c3be628`, `d6b6392`.
- Kept authored portfolio content in the canonical record and limited locale
  catalogs to interface copy. Commits: `b1d1811`, `546f0cd`.
- Rebuilt narrative rendering around reusable typed buffers, scalar path
  reconstruction, and one coalesced frame notification. Commits: `39a1906`,
  `581f484`.

### Fixed

- Preserved deep links, browser history, and chapter progress through initial
  layout, responsive changes, and language transitions. Commits: `04ec6c2`,
  `5a80782`.
- Kept scene geometry, first-frame reveal, RTL mirroring, and reduced-motion
  behavior consistent. Commits: `39a1906`, `188d669`, `48efb82`.
- Corrected link semantics, focus handling, and narrow-screen evidence layouts.
  Commits: `95e9b96`, `24721c9`, `04ec6c2`.

## [1.1.0] - 2026-04-03

Historical experimental portfolio release; it predates the current template,
content validation, and release system.

[Unreleased]: https://github.com/Yusufihsangorgel/Flutter-Web-Portfolio/compare/v2.0.0...HEAD
[2.0.0]: https://github.com/Yusufihsangorgel/Flutter-Web-Portfolio/compare/v1.1.0...v2.0.0
[1.1.0]: https://github.com/Yusufihsangorgel/Flutter-Web-Portfolio/releases/tag/v1.1.0
