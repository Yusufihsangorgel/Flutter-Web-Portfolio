# Flutter Web Portfolio — technical debt

Record date: 2026-10-07. [Architecture rules](ARCHITECTURE-RULES.md) set production files at 500 lines, tests at 800, members at 60, `build()` at 100, parameters at 4, nesting at 4, and cyclomatic complexity at 15. The [import checker](../quality/check_architecture.py) blocks architecture violations with an empty baseline. The [Dart metrics gate](../tool/quality/dart_metrics.dart) measures callables and rejects new, increased, or stale debt against [its baseline](../quality/metrics-baseline.json). Targets mean the next focused refactor of the named area; they are not claims that work is scheduled.

## Domain boundary and parsing

| File or contract | Known debt | Planned fix |
|---|---|---|
| [`AssetLoader`](../lib/app/domain/providers/asset_loader.dart), [`LanguageRepository`](../lib/app/domain/repositories/language_repository.dart) | Boundary contracts still expose `Map<String, dynamic>` even though UI strings are typed and decoding belongs to data adapters. | Narrow boundary payloads to `Object?` or typed catalogs in a focused contract migration; preserve malformed-document and locale fallback tests. |

## Closed source-size and boundary entries

The prerequisite section and navigation changes removed the domain import violations and split the previously listed
oversized files. Current lengths: `portfolio_document.dart` 295, `project_atlas.dart` 51, `proof_section.dart` 128,
`packages_section.dart` 174, `contribution_event_order_lab.dart` 232, `home_section.dart` 111, `scroll_controller.dart` 301,
and `smoke.spec.ts` 149. No Dart production file in `lib/` or `packages/` exceeds 500 lines; no Dart test exceeds 800.
File-size checks remain a manual review criterion.

## Member and parameter limits

| Location | Known breach | Planned fix |
|---|---|---|
| [`_FontStyle.call`](../lib/app/core/theme/app_fonts.dart) | The shared style adapter accepts nineteen named style options. | Migrate callers to an immutable style configuration in a separate API refactor; retain font fallback and style defaults. |

The proof/package build methods and handoff painter constructor listed previously are below their respective limits.
Every remaining callable breach is registered individually, with its measured value and deferral reason, in the metrics
baseline. Deferral preserves behavior while this lane installs the ratchet; each owning area must split its legacy
callables and shrink the matching entries in its next focused refactor.

## Release and rule transition

| Area | Current state | Planned fix |
|---|---|---|
| [Artifact promotion](adr/0004-build-once-promote-artifact.md) | `build/web` is tracked; CI, Pages, and production do not promote one attested artifact; production CD uses a repository-registered self-hosted runner. | Verify one hosted build, publish digest/provenance, move production to an independent pull process, remove runner registration, then stop tracking generated output. |
| [Locale fonts](adr/0006-locales-and-font-loading.md) | Full Latin and script font files are bundled; shell preloads selected script fonts. | Subset Latin fonts and demand-load locale fonts with glyph and visual coverage. |

## Tooling consolidation

2026-10-07: the tooling source-size and renderer member breaches are closed. [Tooling inventory](TOOLING.md) records the folder map, callers, original/current line counts, and split modules. ESLint checks source size, function size, parameters, nesting, and complexity in addition to its recommended rules.

The strictness lane shares all three strict analyzer switches and the requested lints between the application and
package. It removes the `getText` bridge, uses typed interface strings, and centralizes duplicated test fakes. Domain
annotations are now rejected by import calibration; there are no provider exceptions and no architecture baseline
entries. Application and package code add no lint suppression. The metrics tool uses two `deprecated_member_use`
suppressions: `FormalParameterList.parameters` in the engine and `IfElement.elseElement` in the flow visitor.
Their replacements are still experimental in the pinned analyzer release; each adjacent source comment records the
reason for using the stable accessor.

## Dart metrics baseline

The calibrated AST tool measures constructors, primary constructors, getters, setters, methods, named functions, and
closures under `lib/`, `test/`, `tool/`, and `packages/`. Generated build/cache directories and its deliberate metric
fixtures are excluded; a source directory named `cache` is included. Callable identities use file, type, callable kind,
and name. Closure ordinals are local to their owning callable and remain stable when lines move.

Lines run from the declaration's first token through its last token, including multiline parameters and comments
inside the declaration. A method named `build` has a 100-line limit; other callables have 60. Parameter counts include
all formal parameters. Nesting counts statement and collection `if`/`for`, loops, switches, and catch clauses; `else if`
stays at its parent's depth. Complexity starts at one and adds control-flow decisions, non-default switch cases,
switch-expression arms, ternaries, `&&`, and `||`. Constructor initializers are measured. Nested callables contribute
their own flow metrics, without increasing the parent's complexity or nesting.

| Metric | Limit | Initial HEAD | Final baseline |
|---|---:|---:|---:|
| Callable lines | 60 | 60 | 54 |
| `build()` lines | 100 | 0 | 0 |
| Parameters | 4 | 24 | 23 |
| Control-flow nesting | 4 | 0 | 0 |
| Cyclomatic complexity | 15 | 2 | 2 |
| Total violations | | 86 | 79 |

The same final metric implementation measured the initial HEAD and the changed sources: 2,421 and 2,486 callables
respectively. No final violation key is new or greater than its initial HEAD measurement. Every retained entry is listed
with file, callable, metric, value, and reason in [metrics-baseline.json](../quality/metrics-baseline.json). Each owning
area must split the registered callable in its next focused refactor, preserving existing behavior and then lowering or
removing that entry. The new tooling has zero metric violations.

The local check fails on new or increased violations and on removed/lower measurements left stale in the baseline.
CI also supplies the PR base or previous push revision through `--base-ref`, rejecting baseline additions or increases
in the same change. Creating the first baseline refuses to overwrite an existing file.

## L12 verification and changed-file inventory

All successful commands below returned exit 0 on 2026-10-07 with the pinned toolchain.

| Command | Result |
|---|---|
| `dart format --output=none --set-exit-if-changed lib test tool` | 201 files, 0 changes |
| Package: `dart format --output=none --set-exit-if-changed lib test example/lib` | 15 files, 0 changes |
| Root and package: `flutter analyze --no-pub --fatal-infos` | 0 findings in each |
| `dart tool/quality/dart_metrics_test.dart` | 75 checks passed |
| `dart tool/quality/dart_metrics.dart --base-ref HEAD --json` | 2,486 callables, 79 retained violations, 0 ratchet issues |
| `python3 quality/check_architecture.py` | 594 imports; 0 violations, new, baseline, or stale entries |
| `python3 -m unittest discover -s quality/tests -p test_architecture.py` | 6 tests passed |
| `npm run typecheck` | Both TypeScript projects passed |
| `npm run verify:content` | Canonical content synchronized |
| `npm run verify:strings` | Generated typed strings synchronized |
| `npm run test:strings` | 8 tests passed |
| `npm run verify:source` | 128/128 Dart application sources reachable |
| `node tool/quality/verify_toolchain.mjs --current` | Node 24.18.0, Flutter 3.47.5 |
| `git diff --check` | No whitespace errors |

The initial strict analysis reported 57 infos and no errors or warnings. The application and package now share all
requested strict settings and have no findings. Default `flutter analyze` attempted an unavailable pub.dev advisory
request; `--no-pub` uses the already resolved dependencies. Analyzer was added only after confirming it was absent
from the SDK's exposed package configuration; `flutter pub get --offline` resolved the new dev dependency.

A targeted Flutter command covering 16 test files stopped during loading because the sandbox denied opening a server
socket. No test assertions ran in that attempt. Full root/package Flutter suites and browser suites must run in the
coordinator's socket-capable environment; they are not recorded as passed here. The new warning fallback and section
string regression tests are included in that pending validation. No release build or deployment was performed.

The deleted action-button component had no application caller and was referenced only by its own two tests. Both were
removed; the source graph check changed from one unreachable source to 128/128 reachable sources.

This table lists every changed, created, and deleted file. Strict infos are measured after enabling the requested rules
and before code fixes. Architecture counts apply only to `lib/`, matching the import gate's scope. Metric fixture rows
are deliberate calibration inputs excluded from the repository ratchet. New test fixtures and tooling explain their
new source lines; final production and test files remain below their respective file-size limits.

| Status | File | Lines before → after | Strict infos before → after | Architecture before → after | Metric violations before → after |
|---|---|---:|---:|---:|---:|
| Modified | `.github/workflows/architecture.yml` | 40 → 40 | — | — | — |
| Modified | `.github/workflows/ci.yml` | 185 → 201 | — | — | — |
| Modified | `analysis_options.yaml` | 31 → 36 | — | — | — |
| Modified | `docs/ARCHITECTURE-RULES.md` | 177 → 180 | — | — | — |
| Modified | `docs/TECH-DEBT.md` | 55 → 197 | — | — | — |
| Modified | `lib/app/controllers/scroll/reading_anchor_restorer.dart` | 103 → 103 | 1 → 0 | 0 → 0 | 0 → 0 |
| Modified | `lib/app/controllers/scroll/section_scroller.dart` | 42 → 42 | 1 → 0 | 0 → 0 | 0 → 0 |
| Modified | `lib/app/controllers/scroll_controller.dart` | 259 → 258 | 1 → 0 | 0 → 0 | 0 → 0 |
| Created | `lib/app/core/l10n/section_strings.dart` | 0 → 18 | 0 → 0 | 0 → 0 | 0 → 0 |
| Modified | `lib/app/core/logging/app_logger_web.dart` | 23 → 23 | 1 → 0 | 0 → 0 | 0 → 0 |
| Modified | `lib/app/core/theme/app_theme.dart` | 52 → 52 | 1 → 0 | 0 → 0 | 0 → 0 |
| Modified | `lib/app/features/language/application/language_cubit.dart` | 298 → 299 | 0 → 0 | 0 → 0 | 3 → 3 |
| Modified | `lib/app/modules/home/home_view.dart` | 352 → 353 | 6 → 0 | 0 → 0 | 0 → 0 |
| Modified | `lib/app/modules/home/home_view_sections.dart` | 25 → 17 | 0 → 0 | 0 → 0 | 0 → 0 |
| Modified | `lib/app/modules/home/sections/about_section.dart` | 364 → 364 | 2 → 0 | 0 → 0 | 0 → 0 |
| Modified | `lib/app/modules/home/sections/experience_section.dart` | 218 → 218 | 1 → 0 | 0 → 0 | 0 → 0 |
| Modified | `lib/app/modules/home/sections/home_section.dart` | 111 → 111 | 1 → 0 | 0 → 0 | 0 → 0 |
| Modified | `lib/app/modules/home/sections/projects/projects_section.dart` | 158 → 109 | 0 → 0 | 0 → 0 | 1 → 0 |
| Modified | `lib/app/modules/home/sections/proof/widgets/contribution_event_order_lab.dart` | 233 → 232 | 1 → 0 | 0 → 0 | 0 → 0 |
| Modified | `lib/app/modules/home/sections/proof_section.dart` | 128 → 128 | 2 → 0 | 0 → 0 | 0 → 0 |
| Modified | `lib/app/widgets/back_to_top_button.dart` | 237 → 234 | 1 → 0 | 0 → 0 | 1 → 0 |
| Modified | `lib/app/widgets/background/narrative_background.dart` | 296 → 296 | 4 → 0 | 0 → 0 | 0 → 0 |
| Modified | `lib/app/widgets/command_palette.dart` | 489 → 469 | 3 → 0 | 0 → 0 | 1 → 1 |
| Modified | `lib/app/widgets/custom_sliver_app_bar.dart` | 372 → 371 | 5 → 0 | 0 → 0 | 1 → 1 |
| Modified | `lib/app/widgets/language_switcher.dart` | 128 → 138 | 4 → 0 | 0 → 0 | 2 → 0 |
| Modified | `lib/app/widgets/narrative_stage.dart` | 372 → 372 | 3 → 0 | 0 → 0 | 0 → 0 |
| Modified | `lib/app/widgets/navigation_overlay.dart` | 381 → 383 | 5 → 0 | 0 → 0 | 2 → 2 |
| Modified | `lib/app/widgets/numbered_section_heading.dart` | 91 → 91 | 1 → 0 | 0 → 0 | 1 → 1 |
| Deleted | `lib/app/widgets/portfolio_action_button.dart` | 90 → 0 | 2 → 0 | 0 → 0 | 0 → 0 |
| Modified | `lib/app/widgets/portfolio_footer.dart` | 341 → 340 | 0 → 0 | 0 → 0 | 0 → 0 |
| Modified | `lib/app/widgets/scroll_indicator.dart` | 202 → 202 | 1 → 0 | 0 → 0 | 0 → 0 |
| Modified | `lib/main.dart` | 182 → 185 | 5 → 0 | 0 → 0 | 0 → 0 |
| Modified | `packages/adaptive_render_budget/analysis_options.yaml` | 34 → 7 | — | — | — |
| Modified | `packages/adaptive_render_budget/test/adaptive_render_budget_controller_test.dart` | 335 → 271 | 0 → 0 | — | 2 → 2 |
| Created | `packages/adaptive_render_budget/test/support/render_budget_fakes.dart` | 0 → 60 | 0 → 0 | — | 0 → 0 |
| Modified | `pubspec.lock` | 454 → 534 | — | — | — |
| Modified | `pubspec.yaml` | 62 → 63 | — | — | — |
| Modified | `quality/architecture-rules.json` | 348 → 356 | — | — | — |
| Created | `quality/metrics-baseline.json` | 0 → 565 | — | — | — |
| Created | `test/support/fake_app_logger.dart` | 0 → 22 | 0 → 0 | — | 0 → 0 |
| Created | `test/support/fake_key_value_store.dart` | 0 → 22 | 0 → 0 | — | 0 → 0 |
| Created | `test/support/fake_language_browser.dart` | 0 → 20 | 0 → 0 | — | 0 → 0 |
| Created | `test/support/fake_language_repository.dart` | 0 → 55 | 0 → 0 | — | 0 → 0 |
| Modified | `test/unit/bootstrap/app_dependencies_test.dart` | 153 → 143 | 0 → 0 | — | 3 → 3 |
| Modified | `test/unit/bootstrap/asset_logging_test.dart` | 54 → 36 | 0 → 0 | — | 0 → 0 |
| Modified | `test/unit/controllers/language_cubit_test.dart` | 371 → 360 | 0 → 0 | — | 3 → 2 |
| Modified | `test/unit/core/logging/error_handlers_test.dart` | 67 → 49 | 0 → 0 | — | 0 → 0 |
| Modified | `test/unit/core/theme/locale_font_loader_test.dart` | 117 → 104 | 0 → 0 | — | 1 → 1 |
| Modified | `test/unit/data/persistent_language_repository_test.dart` | 93 → 73 | 0 → 0 | — | 0 → 0 |
| Modified | `test/unit/features/language/app_strings_test.dart` | 54 → 40 | 0 → 0 | — | 0 → 0 |
| Modified | `test/unit/features/language/language_browser_seam_test.dart` | 117 → 89 | 0 → 0 | — | 1 → 0 |
| Modified | `test/unit/features/language/language_context_test.dart` | 56 → 53 | 0 → 0 | — | 0 → 0 |
| Modified | `test/unit/features/language/language_font_switch_test.dart` | 110 → 95 | 0 → 0 | — | 0 → 0 |
| Created | `test/unit/features/language/language_warning_fallback_test.dart` | 0 → 63 | 0 → 0 | — | 0 → 0 |
| Created | `test/unit/features/language/section_strings_test.dart` | 0 → 53 | 0 → 0 | — | 0 → 0 |
| Modified | `test/unit/features/render_quality/render_quality_controller_test.dart` | 208 → 150 | 0 → 0 | — | 2 → 2 |
| Modified | `test/unit/l10n/app_strings_catalog_test.dart` | 97 → 116 | 0 → 0 | — | 0 → 0 |
| Modified | `test/widget/accessible_action_test.dart` | 180 → 180 | 1 → 0 | — | 2 → 2 |
| Modified | `test/widget/command_palette_test.dart` | 86 → 79 | 1 → 0 | — | 0 → 0 |
| Modified | `test/widget/home_section_test.dart` | 209 → 202 | 2 → 0 | — | 0 → 0 |
| Modified | `test/widget/home_view_accessibility_test.dart` | 247 → 239 | 0 → 0 | — | 0 → 0 |
| Modified | `test/widget/language_switcher_test.dart` | 90 → 82 | 0 → 0 | — | 0 → 0 |
| Modified | `test/widget/navigation_overlay_test.dart` | 88 → 75 | 0 → 0 | — | 1 → 0 |
| Modified | `test/widget/packages_section_test.dart` | 306 → 293 | 0 → 0 | — | 0 → 0 |
| Deleted | `test/widget/portfolio_action_button_test.dart` | 32 → 0 | 0 → 0 | — | 0 → 0 |
| Modified | `test/widget/projects_section_test.dart` | 454 → 446 | 0 → 0 | — | 1 → 1 |
| Modified | `test/widget/proof_section_test.dart` | 393 → 386 | 1 → 0 | — | 0 → 0 |
| Modified | `test/widget/writing_section_test.dart` | 288 → 282 | 0 → 0 | — | 0 → 0 |
| Created | `tool/quality/dart_metrics.dart` | 0 → 216 | 0 → 0 | — | 0 → 0 |
| Created | `tool/quality/dart_metrics_baseline.dart` | 0 → 278 | 0 → 0 | — | 0 → 0 |
| Created | `tool/quality/dart_metrics_engine.dart` | 0 → 379 | 0 → 0 | — | 0 → 0 |
| Created | `tool/quality/dart_metrics_flow.dart` | 0 → 133 | 0 → 0 | — | 0 → 0 |
| Created | `tool/quality/dart_metrics_test.dart` | 0 → 384 | 0 → 0 | — | 0 → 0 |
| Created | `tool/quality/fixtures/dart_metrics/callables.dart` | 0 → 423 | 0 → 0 | — | fixture |
| Created | `tool/quality/fixtures/dart_metrics/collection_control.dart` | 0 → 87 | 0 → 0 | — | fixture |
