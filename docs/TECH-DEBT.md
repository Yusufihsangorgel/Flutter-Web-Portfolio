# Flutter Web Portfolio — technical debt

Record date: 2026-09-29. Counts below are source line counts from the current checkout, excluding generated release output. [Architecture rules](ARCHITECTURE-RULES.md) set production files at 500 lines, tests at 800, members at 60, `build()` at 100, parameters at 4, nesting at 4, and cyclomatic complexity at 15. The [import checker](../quality/check_architecture.py) does not enforce these metrics yet. Targets mean the next focused refactor of the named area; they are not claims that work is scheduled.

## Domain boundary and parsing

| File or contract | Known debt | Planned fix |
|---|---|---|
| [Architecture baseline](../quality/architecture-baseline.json) | Four `F-DOMAIN-PURE` import violations across `narrative_anchor.dart`, `narrative_document.dart`, and `section_geometry.dart`. | Move Flutter annotations and `dart:ui` types to application or rendering adapters, keep domain value types in plain Dart, add focused tests, then shrink the baseline in the same change. |
| [`portfolio_document.dart`](../lib/app/domain/models/portfolio_document.dart) | JSON traversal and `dynamic` values live in a domain model; file is 1,586 lines. | Move decoding and validation into focused typed boundary components, preserve schema-version and all-or-nothing locale behavior, and test malformed input. |
| [`language_cubit.dart`](../lib/app/features/language/application/language_cubit.dart), [`bundle_asset_loader.dart`](../lib/app/data/providers/bundle_asset_loader.dart) | Translation lookup and merge still traverse `Map<String, dynamic>`. | Expose typed translation access after asset parsing; retain missing-key and failed-locale behavior in tests. |
| [`prepare_web_release.mjs`](../tool/release/prepare_web_release.mjs) | Optional stored-locale parsing has silent catch paths. | Make the fallback condition explicit and test malformed storage values. |

## Production source files over 500 lines

| File | Lines | Planned split |
|---|---:|---|
| [`portfolio_document.dart`](../lib/app/domain/models/portfolio_document.dart) | 1,586 | Split typed document sections and parsers at the data/domain boundary. |
| [`project_atlas.dart`](../lib/app/modules/home/sections/projects/widgets/project_atlas.dart) | 1,356 | Extract case header, artifact display, evidence rows, and focused stateful pieces. |
| [`proof_section.dart`](../lib/app/modules/home/sections/proof_section.dart) | 741 | Split featured contribution, ledger, and label assembly into focused widgets. |
| [`packages_section.dart`](../lib/app/modules/home/sections/packages/packages_section.dart) | 620 | Extract package grouping and category/card widgets. |
| [`contribution_event_order_lab.dart`](../lib/app/modules/home/sections/proof/widgets/contribution_event_order_lab.dart) | 583 | Extract controls, timeline, and result panels. |
| [`home_section.dart`](../lib/app/modules/home/sections/home_section.dart) | 572 | Split chapter widgets and responsive layout pieces. |
| [`scroll_controller.dart`](../lib/app/controllers/scroll_controller.dart) | 525 | Isolate geometry measurement from navigation and scroll state. |

## Tests over 800 lines

| File | Lines | Planned split |
|---|---:|---|
| [`smoke.spec.ts`](../tests/e2e/smoke.spec.ts) | 1,362 | Group navigation, accessibility, localization, and release smoke cases by behavior while sharing fixtures. |

Other tests formerly listed at the production 500-line threshold are below the 800-line test limit.

## Member and parameter limits

| Location | Known breach | Planned fix |
|---|---|---|
| [`ProofSection.build`](../lib/app/modules/home/sections/proof_section.dart) | Starts at line 21 and spans more than 100 lines. | Extract featured and ledger composition into widgets; preserve reading order and semantics tests. |
| [`PackagesSection.build`](../lib/app/modules/home/sections/packages/packages_section.dart) | Starts at line 59 and spans more than 100 lines. | Move grouping to a focused helper and split category rendering. |
| [`_NarrativeChapterHandoffPainter`](../lib/app/widgets/narrative_chapter_handoff.dart) | Constructor at line 129 has seven required parameters. | Pass a focused immutable painter configuration object; keep the repaint listenable explicit. |
| [`AppFonts`](../lib/app/core/theme/app_fonts.dart) | Public style helpers and `_style` accept far more than four named parameters. | Group style options into an immutable value object while preserving call-site defaults. |

These are verified examples, not a complete metric baseline. Add a calibrated metric gate in a later release, inventory the remaining member, nesting, and complexity breaches, and fix or register each one before making that gate blocking.

## Release and rule transition

| Area | Current state | Planned fix |
|---|---|---|
| [Artifact promotion](adr/0004-build-once-promote-artifact.md) | `build/web` is tracked; CI, Pages, and production do not promote one attested artifact; production CD uses a repository-registered self-hosted runner. | Verify one hosted build, publish digest/provenance, move production to an independent pull process, remove runner registration, then stop tracking generated output. |
| [Locale fonts](adr/0006-locales-and-font-loading.md) | Full Latin and script font files are bundled; shell preloads selected script fonts. | Subset Latin fonts and demand-load locale fonts with glyph and visual coverage. |
| [`architecture-rules.json`](../quality/architecture-rules.json) | The import gate still lists unused package bans, permits annotation package patterns in domain, and exempts provider-named UI imports. | Align rule JSON and calibration with [architecture rules](ARCHITECTURE-RULES.md) in the coordinator-owned configuration change; keep `NEW` and `STALE` detection and the current four-entry baseline. |

## Tooling consolidation

2026-10-07: the tooling source-size and renderer member breaches are closed. [Tooling inventory](TOOLING.md) records the folder map, callers, original/current line counts, and split modules. ESLint now checks source size, function size, parameters, nesting, and complexity in addition to its recommended rules. The four domain import violations remain outside this tooling change.
