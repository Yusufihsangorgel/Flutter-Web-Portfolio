## Summary

Describe the change and why it is needed.

## Changes

-

## Checks

Follow the [architecture rules](../docs/ARCHITECTURE-RULES.md) and
[CONTRIBUTING.md](../CONTRIBUTING.md). CI uses Flutter 3.47.5 from
[`tool/quality/toolchain.json`](../tool/quality/toolchain.json), its bundled Dart
3.13.4, and Node.js 24.18.0.

These workflows run on the pull request:

- [ ] `ci.yml` analyze — content/tooling contracts, strings/fonts/artifacts, typecheck, lint, format, root/package strict analysis, shrink-only Dart metrics, source/history audits
- [ ] `ci.yml` test — root coverage (domain 99%, application 92%) and package tests
- [ ] `ci.yml` build — Wasm release, résumé checks, bundle/exact-source verification, container, clone, browser, runtime, Lighthouse and release packaging
- [ ] `architecture.yml` — blocking architecture calibration and import rules when its path filter matches
- [ ] `codeql.yml` — code scanning
- [ ] `dependency-review.yml` — dependency review
- [ ] `pr-title.yml` — Conventional Commits title

The title must follow [Conventional Commits](https://www.conventionalcommits.org/),
for example `fix(web): wait for the first rendered frame`.

Checks that CI cannot make:

- [ ] Behavior changes include focused tests
- [ ] Documentation is updated where it changed
- [ ] Changed-file line counts meet the file limits; remaining touched debt is fixed or recorded

See [Quality gates](../README.md#quality-gates) for exact commands. Main-only CI builds also attest the verified release.

## Screenshots

Add before and after screenshots for visual changes.

## Related issues

Closes #
