# Contributing

Keep changes focused and follow the [architecture rules](docs/ARCHITECTURE-RULES.md).
They define the layers, the import rules, the size limits, and how technical
debt is handled. Put portfolio facts in `assets/content/portfolio.json` and
interface text in `assets/i18n/`.

## Toolchain

The repository pins Flutter 3.47.5 in [`tool/quality/toolchain.json`](tool/quality/toolchain.json).
Use its bundled Dart 3.13.4 and Node.js 24.18.0 (see `.nvmrc`).
`npm run verify:toolchain` reports a mismatch.

## Before you open a pull request

Install dependencies with `flutter pub get`, `npm ci`, and
`npm run setup:browsers`. Then run the checks that match your change:

```bash
dart format --output=none --set-exit-if-changed lib test tool
flutter analyze --fatal-infos
flutter test
npm run verify:content
npm run verify:community
npm run typecheck
npm run lint
npm run format:check
dart run tool/quality/dart_metrics_test.dart
dart run tool/quality/dart_metrics.dart --base-ref "$BASE_SHA"
python3 -m unittest discover -s quality/tests -p 'test_architecture.py'
python3 quality/check_architecture.py
```

The full command list is under [Quality gates](README.md#quality-gates) in the
README, and the release and hosting steps are in the
[template guide](docs/TEMPLATE.md). Add or update focused tests for behavior
changes. For changes to application structure, state, or rendering, read the
architecture rules before you edit.

Set `BASE_SHA` to the PR base revision for the metrics ratchet. Without a base
revision, `dart run tool/quality/dart_metrics.dart` checks current code against
the recorded baseline but cannot compare its growth with another revision.

## Pull request checks

The workflows are in `.github/workflows/`. A pull request has to pass:

| Workflow | Checks |
|---|---|
| `ci.yml` | Toolchain; content, starter, strings, fonts, artifacts, résumé, hosting, audit and tooling tests; type/lint/format; strict root/package analysis; shrinking Dart metrics; root/package tests and layer coverage; Wasm build, résumé determinism, bundle/source manifest, container, clean clone, browser, runtime and Lighthouse checks; release artifact packaging |
| `architecture.yml` | Blocking `Architecture gate calibration` and `Architecture import rules`; runs when `lib/`, `quality/`, architecture rules, or the workflow changes |
| `codeql.yml` | Code scanning |
| `dependency-review.yml` | Dependency review |
| `pr-title.yml` | Pull request title format |

The `attest` job runs only for successful `main` push or manual CI builds. It verifies the release checksum and records
artifact provenance. PR builds produce the tested artifact without that main-only attestation.

## Pull request titles

Titles use [Conventional Commits](https://www.conventionalcommits.org/):
`type(scope): subject`. The types are `build`, `chore`, `ci`, `docs`, `feat`,
`fix`, `perf`, `refactor`, `revert`, `style`, and `test`. The scope is optional
and lowercase, and the subject has at most 72 characters. For example:
`fix(web): wait for the first rendered frame`.

Describe the change and its effect in the description. Include screenshots for
visual changes and link related issues.

By contributing, you agree that your contributions will be licensed under the
[MIT License](LICENSE).
