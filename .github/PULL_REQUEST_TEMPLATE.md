## Summary

Describe the change and why it is needed.

## Changes

-

## Checks

Follow the [architecture rules](../blob/main/docs/ARCHITECTURE-RULES.md) and
[CONTRIBUTING.md](../blob/main/CONTRIBUTING.md). CI uses Flutter 3.47.5 from
[`tool/toolchain.json`](../blob/main/tool/toolchain.json), its bundled Dart
3.13.4, and Node.js 24.18.0.

These workflows run on the pull request:

- [ ] `ci.yml` — toolchain, content, source, analysis, test, build, clean clone, browser, and runtime checks
- [ ] `architecture.yml` — architecture calibration and import rules when its path filter matches
- [ ] `codeql.yml` — code scanning
- [ ] `dependency-review.yml` — dependency review
- [ ] `pr-title.yml` — Conventional Commits title

The title must follow [Conventional Commits](https://www.conventionalcommits.org/),
for example `fix(web): wait for the first rendered frame`.

Checks that CI cannot make:

- [ ] Behavior changes include focused tests
- [ ] Documentation is updated where it changed

## Screenshots

Add before and after screenshots for visual changes.

## Related issues

Closes #
