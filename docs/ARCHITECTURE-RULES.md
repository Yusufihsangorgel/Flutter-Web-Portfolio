# Flutter Web Portfolio — Architecture Rules (binding)

Version 2 · 2026-09-29 · Scope: every contributor changing code, tests, CI, or UI in this repository.

This document defines the repository's binding code-structure rules. The current import gate is
[`quality/architecture-rules.json`](../quality/architecture-rules.json). For architecture, these rules take precedence
over general repository documentation. The gate still contains legacy package deny entries and a provider-named UI
exception; synchronize that configuration in the same release before claiming full mechanical coverage of this version.

## 1. This repository’s architecture

| Package | Responsibility | Technology |
|---|---|---|
| `lib/` | Flutter Web portfolio application | Flutter, Dart `>=3.12.0 <4.0.0`, `flutter_bloc`, `shared_preferences`, `url_launcher`, `web` |
| `packages/adaptive_render_budget/` | Local adaptive rendering budget package | Dart and Flutter; path dependency of the application |
| `tool/` | Content, template, release, and verification tooling | Node.js ESM and Dart |
| `test/`, `tests/` | Flutter unit/widget tests and browser tests | `flutter_test`, Playwright, TypeScript |
| `build/web/` | Generated static web release output | Flutter Web; no runtime backend in this repository |

### 1.1 Application layers

`lib/main.dart` starts the application and hands off to `lib/app/app_dependencies.dart`, the composition root.
`AppDependencies.bootstrap()` assembles data adapters, domain objects, and controllers; `AppRuntime` provides state to
the widget tree.

`lib/app/modules/home/` and `lib/app/widgets/` are presentation. Presentation may use application-layer Cubits and
controllers, including `lib/app/features/*/application/`, `lib/app/controllers/`, and
`lib/app/narrative/application/`; it must not access data adapters or I/O directly. `lib/app/core/` holds shared
constants and theme values. Feature code does not import other features.

`lib/app/domain/`, `lib/app/features/*/domain/`, and `lib/app/narrative/domain/` hold domain models and contracts.
Domain code is plain Dart: no Flutter, `dart:ui`, data, presentation, or application imports. Data adapters in
`lib/app/data/providers/` and `lib/app/data/repositories/` implement domain contracts for assets and preferences.
`lib/app/narrative/rendering/` is presentation support; `lib/app/utils/` contains platform helpers.

The direction is presentation → application → domain ← data. `AppDependencies.bootstrap()` is the explicit
composition root that supplies adapters and controllers. The five existing domain purity violations are listed in
[`docs/TECH-DEBT.md`](TECH-DEBT.md) and the architecture baseline; they are not new-code precedents.

The browser application is Flutter Web; there is no separate HTML/TypeScript page hierarchy. The deployed site is
static output under `build/web/`. Node tooling may access external sources, but that does not create a runtime HTTP
layer in the Flutter application.

### 1.2 Import direction

The “Must not import” column is the intended rule. The checker currently enforces import patterns only, with the
configuration drift noted above; it does not inspect runtime calls or architectural intent.

| Layer | May import | Must not import |
|---|---|---|
| `modules/**` pages and sections | Flutter UI, `core/`, application Cubits/controllers, domain types, shared widgets | `data/**`, repository implementations, direct asset/preference I/O |
| `widgets/**` shared UI | Flutter UI, `core/`, application Cubits/controllers, domain types, shared widgets | `modules/**`, `data/**`, repository implementations, direct asset/preference I/O |
| `features/<a>/**` | Its own feature and shared application/domain layers | `features/<b>/**` for `b != a` |
| `domain/**` | Dart core libraries only | Flutter, `dart:ui`, third-party packages, data, presentation, application, or rendering layers |
| `data/**` | Domain contracts and data dependencies | `modules/**`, `widgets/**`, `controllers/**`, `features/**`, `narrative/**` |
| Composition root | Wiring of domain contracts, data adapters, features, and controllers | Hidden global registration or service-locator wiring |

### 1.3 Mechanical architecture checks

| Rule | Enforced restriction |
|---|---|
| `F-ISOLATION` | A feature cannot import another feature. Shared code belongs in an appropriate shared layer. |
| `F-UI-NO-IO` | UI groups cannot import the preference adapter's `shared_preferences` package; direct asset/preference I/O is also prohibited by review. The present config lists unused package patterns pending synchronization. |
| `F-UI-NO-REPO` | UI groups cannot import `data/**`. The current checker has a provider-named exception pending removal. |
| `P-DATA-DOWN` | `data/**` cannot import modules, widgets, controllers, features, or narrative code. |
| `P-WIDGETS-NO-MODULES` | Shared widgets cannot import page modules. |
| `F-DOMAIN-PURE` | Domain may import Dart core libraries only; the current config also allows unused annotation package patterns pending synchronization. |
| `F-DOMAIN-INWARD` | Domain cannot import data, UI, controllers, feature application, or narrative application/rendering layers. |

The legacy `F-FORBIDDEN-SDK` rule still exists in the current JSON gate. Its unused-package list is not part of this
repository-specific policy; removing it requires a coordinated configuration and calibration change.

## 2. When adding new code

**New screen or section:** Add page composition under `lib/app/modules/home/sections/` and reusable UI under
`lib/app/widgets/` or the owning feature. Keep rendering, navigation, and interaction state separate from content parsing
and persistence.

**New state or controller:** Use the existing Cubit/controller approach. Put feature state with its feature application
code; put shared scroll or scene behavior under `lib/app/controllers/`. Wire instances through
`lib/app/app_dependencies.dart` and `AppRuntime`. Do not add a state-management package without an architecture decision.

**New business rule:** Put framework-independent rules and value types in the appropriate domain area. Keep imports
within the `F-DOMAIN-PURE` allow-list, and add focused tests under `test/unit/`. Adapt platform or Flutter types at the
application or rendering boundary.

**New data, local storage, or external access:** Load bundled documents through `lib/app/data/providers/`; keep
preference access behind its data provider and repository contracts. Inject implementations from the composition root.
The Flutter application has no runtime HTTP layer; adding one requires an architecture decision and must not put
network access in a page or widget.

**New portfolio content or translation:** Use the canonical content and locale assets under `assets/content/` and
`assets/i18n/`. Keep parsing and validation in the existing data/domain flow; run the content validation gates in §6.

**Browser-facing change:** Extend the Flutter page and section composition. Keep browser-specific interop in the
existing platform-helper structure under `lib/app/utils/`; do not create a parallel page stack for ordinary UI work.

**Test:** Put Dart unit and widget coverage under `test/unit/` and `test/widget/`; put browser behavior coverage under
`tests/e2e/`. Keep package-specific tests with `packages/adaptive_render_budget/test/`.

## 3. Spaghetti prohibitions

- Do not grow oversized UI files as the default extension point. `project_atlas.dart` is already 1,356 lines and
  `proof_section.dart` is 741 lines; extract focused widgets or state when changing these areas.
- Do not make a page or widget read repositories, data sources, or preferences directly.
- Do not make data code depend on presentation, controllers, features, or narrative layers.
- Do not add Flutter or `dart:ui` imports to domain code. The current five `F-DOMAIN-PURE` violations are
  recorded in `docs/TECH-DEBT.md`.
- Keep nested translation lookup and JSON handling out of unrelated widgets. `language_cubit.dart:93` currently uses
  a `dynamic` traversal value; treat this as a manual review point, not a configured architecture violation.
- Keep external-source fetches in tooling. The Flutter UI has no direct fetch path; Node tooling owns refresh and
  runtime-measurement requests.
- Preserve explicit dependency construction in `AppDependencies`; do not replace it with mutable global registration.

## 4. SOLID and clean architecture in this repository

- **Single Responsibility:** sections render content; Cubits and controllers own state and interaction; domain code
  owns rules and value types; data adapters own asset and preference access.
- **Open/Closed:** extend typed content and section behavior through focused types and composition instead of growing
  one parser, widget, or central conditional.
- **Liskov Substitution:** data adapters must honor the contracts they implement, including error and persistence
  behavior expected by their callers.
- **Interface Segregation:** keep domain contracts and state owners focused on the capability their consumers need.
- **Dependency Inversion:** UI depends on state and domain-facing APIs; the composition root supplies data
  implementations and shared controllers.

## 5. Technical debt policy

- **Zero new debt.** New or changed code must follow this document and the inline limits below.
- **Close or record what you find.** Debt in a touched file is fixed in the same work unit or recorded in
  `docs/TECH-DEBT.md` with file, rule, reason for deferral, target, and date.
- **Scout rule:** report before/after line count, architecture violations, and analyzer findings for each touched file.
  None may increase. For a file over 500 lines or already on the baseline, reduce at least one measure or record the
  debt.
- **Baseline only shrinks.** Never add entries to `quality/architecture-baseline.json`; remove a fixed entry in the
  same change using `check_architecture.py --shrink-baseline`.
- Close debt in a separate change. A bug fix in a file over 500 lines may add at most 10 lines; split a feature before
  adding it to such a file.
- Limits: production file 500 lines, test file 800 lines, function/member 60 lines, `build()` 100 lines,
  parameters 4, nesting depth 4, cyclomatic complexity 15. The architecture gate currently enforces import
  direction only. File, function, `build()`, parameter, nesting, and complexity limits are manual review criteria;
  automated metric enforcement is planned for a later release. Existing breaches and planned fixes are recorded in
  [`docs/TECH-DEBT.md`](TECH-DEBT.md).

## 6. Quality gates

`.github/workflows/architecture.yml` runs the architecture checker (warning mode, baseline 5) and its calibration
(blocking) on GitHub-hosted runners. Run both locally as well and record gate results with relevant counts.

| Command | Purpose | Mode |
|---|---|---|
| `python3 quality/check_architecture.py` | §1.3 import rules | Warning baseline: 5 · `NEW`/`STALE` = reject |
| `python3 -m unittest discover -s quality/tests -p 'test_architecture.py'` | Architecture-gate calibration | Blocking |
| `npm run verify:content && npm run portfolio:validate` | Content synchronization and schema validation | Blocking · CI |
| `npm run test:template && npm run test:release-security && npm run test:refresh && npm run test:content` | Template, release-security, refresh, and content checks | Blocking · CI |
| `npm run verify:hosting && npm run verify:community && npm run audit:sources && npm run audit:history` | Hosting, community, source, and history checks | Blocking · CI |
| `npm run typecheck && npm run verify:source` | TypeScript and reachable Dart-source checks | Blocking · CI |
| `dart format --output=none --set-exit-if-changed lib test tool && flutter analyze --fatal-infos && flutter test` | Formatting, analysis, and Flutter tests | Blocking · CI |
| `npm run test:clone && npm test` | Clone and Playwright checks | Blocking · CI |
| `npm run prepare:source && flutter build web --release --wasm --no-web-resources-cdn && npm run prepare:bundle && npm run verify:bundle` | Release source preparation, Wasm build, and bundle verification | Blocking · CI |
| `docker build --tag flutter-web-portfolio:ci . && npm run verify:runtime` | Container packaging and runtime budget | Blocking · CI |
| `npm run build:release` | Maintainer release build | Blocking · documented release command |

## 7. Change rejection criteria

Reject a change if any of the following is true:

1. The architecture checker reports a `NEW` or `STALE` entry.
2. A required §6 gate fails or its result is not recorded with relevant counts.
3. The change violates any §1.3 rule or adds a direct UI I/O or repository dependency.
4. A new production file exceeds 500 lines, a new test file exceeds 800 lines, a function exceeds 60, `build()` exceeds 100, complexity exceeds 15, a function has
   more than 4 parameters, or nesting exceeds 4.
5. It adds a package, state-management library, HTTP client, or architectural layer without an architecture decision.
6. A UI change bypasses the existing theme, content, accessibility, or state boundaries.
7. Behavior changes without focused tests and evidence that the relevant gates pass.
8. Existing debt in a touched file is neither fixed nor recorded; or the architecture baseline grows.
9. Public output contains a secret or personal data, or the change cannot be justified from repository evidence.
