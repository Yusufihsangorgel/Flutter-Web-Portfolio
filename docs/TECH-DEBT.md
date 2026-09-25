# Flutter Web Portfolio — Technical Debt Record

Rule (`docs/ARCHITECTURE-RULES.md` §5): unrecorded debt is not accepted. Debt found in a touched file is fixed in that
work unit or recorded here; remove a closed item in the same change. The architecture checker’s complete violation
list is `quality/architecture-baseline.json` (5 entries); this document summarizes it.

Target codes: **Scout** = in the first work unit that touches the file · **R1** = next portfolio sprint ·
**R2** = separate refactor package within two sprints · **R3** = planned transition requiring an architecture decision.
Record date: 2026-09-24 · measured base commit: `618bb2e`.

## 1. Architecture (`check_architecture.py` baseline: 5 entries)

| Rule | Count | Example | Why not now | Target |
|---|---:|---|---|---|
| `F-DOMAIN-PURE` | 5 | `lib/app/features/render_quality/domain/render_quality.dart:1`; `lib/app/narrative/domain/narrative_anchor.dart:1,3`; `lib/app/narrative/domain/narrative_document.dart:1`; `lib/app/narrative/domain/section_geometry.dart:1` | These domain types currently import Flutter or `dart:ui`; move framework-specific types and annotations to an outer layer while preserving callers and adding focused unit coverage. | R1; Scout on touch |

## 2. Size (>500 lines)

Generated release outputs are listed separately because the measured size inventory includes them. They are regeneration targets, not hand-written refactoring targets.

| Hand-written source file | Lines | Target |
|---|---:|---|
| `tool/render_work_artifacts.mjs` | 1799 | R2 |
| `lib/app/domain/models/portfolio_document.dart` | 1586 | R1 |
| `lib/app/modules/home/sections/projects/widgets/project_atlas.dart` | 1356 | R1 |
| `tool/refresh_portfolio_data.mjs` | 879 | R2 |
| `lib/app/modules/home/sections/proof_section.dart` | 741 | R1 |
| `tool/init_portfolio.mjs` | 647 | R2 |
| `tool/verify_web_build.mjs` | 638 | R2 |
| `lib/app/modules/home/sections/packages/packages_section.dart` | 620 | R1 |
| `tool/sync_public_content.mjs` | 614 | R2 |
| `tool/measure_web_runtime.mjs` | 590 | R2 |
| `lib/app/modules/home/sections/proof/widgets/contribution_event_order_lab.dart` | 583 | R1 |
| `lib/app/modules/home/sections/home_section.dart` | 572 | R1 |
| `lib/app/controllers/scroll_controller.dart` | 525 | R2 |
| `tool/prepare_web_release.mjs` | 523 | R2 |

| Test or test-support file | Lines | Target |
|---|---:|---|
| `tests/e2e/smoke.spec.ts` | 1362 | R2 |
| `test/unit/domain/portfolio_document_test.dart` | 709 | R2 |
| `tool/test_refresh_portfolio_data.mjs` | 680 | R2 |
| `tests/e2e-prod/portfolio.spec.ts` | 590 | R2 |
| `tests/e2e/visual.spec.ts` | 520 | R2 |

| Generated tracked release output | Lines | Target |
|---|---:|---|
| `build/web/main.dart.js` | 102481 | R3 · tracking policy decision |
| `build/web/main.dart.mjs` | 830 | R3 · tracking policy decision |

## 3. Code quality

Measured 2026-09-24 over tracked Dart and TypeScript sources (generated files excluded): legacy Riverpod APIs 0,
`TODO`/`FIXME` 0, TypeScript `any` 0, empty `catch` blocks 0.

| Where | Rule | Status | Target |
|---|---|---|---|
| `lib/app/domain/models/portfolio_document.dart` (53), `lib/app/narrative/domain/narrative_document.dart` (6) | `dynamic` in the domain (57 lines; 87 in `lib/`, 263 with tests) | JSON maps leak into domain types | R1 (typed parsing at the data boundary) |
| `lib/app/features/language/application/language_cubit.dart:93`, `lib/app/data/providers/bundle_asset_loader.dart` | `dynamic` traversal of translation JSON | untyped lookups | Scout |
| `tool/prepare_web_release.mjs:275,278` | silent fallback in `catch` while parsing optional stored locale state | intent undocumented, untested | Scout |

`setState` appears in 22 lines across 10 files for local, transient widget state (menus, hover, focus), which these
rules allow; state that carries application meaning moves to a Cubit when the file is touched.

## 4. Document discrepancies

No verified code/document contradiction is established by the current evidence. `README.md` documents `npm run build:release` as the release command and separately lists the maintainer suite; both align with the package scripts and CI steps. `docs/DEPLOY.md` describes static output, consistent with the Flutter Web release model.
