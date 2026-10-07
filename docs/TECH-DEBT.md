# Flutter Web Portfolio — technical debt

Record date: 2026-10-07. [Architecture rules](ARCHITECTURE-RULES.md) set production files at 500 lines, tests at 800, members at 60, `build()` at 100, parameters at 4, nesting at 4, and cyclomatic complexity at 15. The [import checker](../quality/check_architecture.py) blocks architecture violations with an empty baseline. The [Dart metrics gate](../tool/quality/dart_metrics.dart) measures callables and rejects new, increased, or stale debt against [its baseline](../quality/metrics-baseline.json). Targets mean the next focused refactor of the named area; they are not claims that work is scheduled.

## Domain boundary and parsing

| File or contract | Known debt | Planned fix |
|---|---|---|
| [`AssetLoader`](../lib/app/domain/providers/asset_loader.dart), [`LanguageRepository`](../lib/app/domain/repositories/language_repository.dart) | Boundary contracts still expose `Map<String, dynamic>` even though UI strings are typed and decoding belongs to data adapters. | Narrow boundary payloads to `Object?` or typed catalogs in a focused contract migration; preserve malformed-document and locale fallback tests. |

## Closed source-size and boundary entries

The merged section and navigation changes removed the domain import violations and split the previously listed
oversized files. Current lengths: `portfolio_document.dart` 295, `project_atlas.dart` 51, `proof_section.dart` 128,
`packages_section.dart` 174, `contribution_event_order_lab.dart` 232, `home_section.dart` 111, `scroll_controller.dart` 301,
and `smoke.spec.ts` 149. No Dart production file in `lib/` or `packages/` exceeds 500 lines; no Dart test exceeds 800.
These lengths were checked with `wc -l` against the merged source on 2026-10-07. The deleted
`portfolio_action_button.dart` and its widget test are absent. File-size checks remain a manual review criterion.

## Member and parameter limits

| Location | Known breach | Planned fix |
|---|---|---|
| [`_FontStyle.call`](../lib/app/core/theme/app_fonts.dart) | The shared style adapter accepts nineteen named style options. | Migrate callers to an immutable style configuration in a separate API refactor; retain font fallback and style defaults. |

The proof/package build methods and handoff painter constructor listed previously are below their respective limits.
Every remaining callable breach is registered individually, with its measured value and deferral reason, in the metrics
baseline. Deferral preserves behavior under the ratchet; each owning area must split its legacy
callables and shrink the matching entries in its next focused refactor.

## Open release workaround

| Area | Current state | Planned fix |
|---|---|---|
| [Single-threaded Skwasm](adr/0003-dual-wasm-javascript-runtime.md) | `forceSingleThreadedSkwasm: true` in `web/flutter_bootstrap.js` avoids the Flutter 3.47.5 glyph-cache freeze (flutter/flutter#190039, 4 of 22 CI runs); measured cost is 81 ms reveal on Metal GPU and 3363 ms long tasks with 34.37 reveal intervals on software GL, with budgets at 42, 7.8 and 7300 ms (CI runner). | Remove the flag, restore intervals 3, ratio 2.25 and long 500 ms, and rerun the reload spec 50 times once the pinned stable includes flutter/flutter#190048. |

## Closed release and font entries

- [Artifact promotion](adr/0004-build-once-promote-artifact.md): CI verifies one release, uploads its deterministic
  tarball and checksum, and attests successful `main` builds. `git ls-files build/web` returns no files. There is no
  production CD workflow or self-hosted job. The independent production pull contract promotes by image digest;
  Pages retains a separate base-path build. External delivery state requires its own verification.
- [Locale fonts](adr/0006-locales-and-font-loading.md): three Latin subsets and two shared-script subsets are eagerly
  registered. Full Arabic and Devanagari assets load for their own locales. `verify:fonts` checks subset bytes and
  glyph coverage per locale; browser tests check the English font-transfer budget.

## Refresh and hosted-build follow-up

| File | Rule / existing gap | Deferral reason and target | Recorded |
|---|---|---|---|
| [refresh.yml](../.github/workflows/refresh.yml) | security.txt renewal runs only after canonical content changes, so an unchanged weekly record skips it. | Workflow code is outside this documentation change. Next refresh change: run renewal independently of the content diff and test the unchanged-record expiry case. | 2026-10-07 |
| [hosted_build.sh](../tool/release/hosted_build.sh) | The release invokes Chromium for résumé generation but the hosted-build script does not provision the browser or its system dependencies. | Build code/provider setup is outside this documentation change. Next hosted-build change: define and verify the browser prerequisite on every supported provider. | 2026-10-07 |

## Tooling consolidation

2026-10-07: the tooling source-size and renderer member breaches are closed. [Tooling inventory](TOOLING.md) records the folder map, entry points, callers and contribution checks. ESLint checks source size, function size, parameters, nesting, and complexity in addition to its recommended rules.

Strict analysis shares all three analyzer switches and the requested lints between the application and
package. The `getText` bridge is removed, interface strings are typed, and test fakes are centralized. Domain
annotations are now rejected by import calibration; there are no provider exceptions and no architecture baseline
entries. The repository contains no lint suppression: the metrics tool counts parameters through
`FormalParameterList.parameterFragments` and recognises an `else if` branch from `IfElement.elseKeyword`, and its
intentionally imperfect fixtures under `tool/quality/fixtures/` are excluded from analysis in `analysis_options.yaml`.

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

| Metric | Limit | Before strictness | Retained baseline |
|---|---:|---:|---:|
| Callable lines | 60 | 60 | 54 |
| `build()` lines | 100 | 0 | 0 |
| Parameters | 4 | 24 | 23 |
| Control-flow nesting | 4 | 0 | 0 |
| Cyclomatic complexity | 15 | 2 | 2 |
| Total violations | | 86 | 79 |

At introduction, the same metric implementation measured the initial revision and changed sources: 2,421 and 2,486
callables respectively. The merged revision now has 2,576 callables, 79 retained violations and 0 ratchet issues
(`dart run tool/quality/dart_metrics.dart --base-ref HEAD --json`, exit 0, 2026-10-07). No retained violation key was new
or greater than its introduction measurement. Every retained entry is listed
with file, callable, metric, value, and reason in [metrics-baseline.json](../quality/metrics-baseline.json). Each owning
area must split the registered callable in its next focused refactor, preserving existing behavior and then lowering or
removing that entry. The new tooling has zero metric violations.

The local check fails on new or increased violations and on removed/lower measurements left stale in the baseline.
CI also supplies the PR base or previous push revision through `--base-ref`, rejecting baseline additions or increases
in the same change. Creating the first baseline refuses to overwrite an existing file.
