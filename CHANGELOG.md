# Changelog

All notable changes to this project are documented in this file.
The format follows [Keep a Changelog 1.1.0](https://keepachangelog.com/en/1.1.0/),
and this project follows [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- A published Packages section with localized package details, documented
  claims, live roadmaps, and contribution evidence. The record also reflects
  later package and contribution updates. Commits: `ec64edb`, `30a9ca0`,
  `42eca5c`, `27f00a8`, `a4102b6`, `2a5310c`, `f7cab7f`, `3e13390`,
  `618bb2e`, `645a938`, `661902c`, `028e548`, `1f3d12a`.
- A Writing section populated from the declared feeds. Commit: `e486135`.
- A generated `llms.txt` based on the canonical portfolio record, including in
  initialized projects. Commits: `1a5762b`, `d47315e`.
- A scheduled workflow that refreshes package metrics and contribution status
  from pub.dev and GitHub, commits visitor-facing changes, and reports merged
  contributions missing from the record. Commit: `9d5c417`.
- Automatic Pages deployment of refreshed content and a main-branch deployment
  workflow that runs after successful CI. Commits: `72beb21`, `000d9f2`.
- Eight architecture decision records for the document-first application,
  routing, rendering runtimes, artifact promotion, content contracts, locales,
  render budgets, and repository tooling. Commit: `5e2ca05`.
- A template guide with the setup, content, and hosting steps that were in the
  README, and a `NOTICE` that excludes third-party screenshots and product names
  from the MIT license. Commits: `56475b2`, `6b3c259`.

### Changed

- Upgraded the application, CI, and deployment toolchain to Flutter 3.47.5 and
  Dart 3.13.4. Commit: `90b1a1c`.
- Kept package records to declared information instead of copying pub.dev
  topics. Commit: `328ed4a`.
- Aligned architecture rules and technical-debt records with the repository.
  Commit: `5e2ca05`.
- Rewrote the README to lead with the author, a screenshot, engineering
  highlights, an architecture diagram, and the CI quality gates. The
  contributor guide and pull request template list the pinned toolchain, the CI
  checks, and the Conventional Commits title rule. Commits: `56475b2`,
  `adea33f`.
- The history audit finds attribution trailers and instruction files without
  naming any tool. Commit: `e0ecd79`.

### Fixed

- Corrected portfolio entries that marked finished work as pending and
  regenerated the synchronized README and release content. Commits:
  `dfd834a`, `c9df785`, `d7a6bc7`.
- Filled gaps in authored work descriptions across the translated locale
  catalogs. Commit: `05f20c1`.
- Stabilized browser visual checks with progress-based scroll waits, refreshed
  baselines, and tolerances for live-canvas variation; removed the
  snapshot-update workflow. Commits: `c24406b`, `90c0ee2`, `c8acf37`,
  `b41fda7`, `f03257e`.
- The history audit missed an attribution trailer on a later line of an
  annotated tag message. Commit: `e0ecd79`.

### Security

- Added a CI architecture gate for layer boundaries and prohibited SDK imports.
  Commit: `f920149`.

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
