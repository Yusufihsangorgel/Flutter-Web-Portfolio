# Repository tooling

The tools implement the template and static-release contracts in [ADR 0008](adr/0008-repository-tooling-scope.md).
Run commands from the repository root. [package.json](../package.json) and [.github/workflows/](../.github/workflows/)
are the source of truth for scripts and CI callers; imports describe helper consumers.

## Folder map

Entry points below are relative to their folder. Supporting folders have no standalone command.

| Folder | Purpose | Entry points | npm scripts / CI use |
|---|---|---|---|
| `tool/assets/` | Raster inspection and social-card rendering | `render_social_card.mjs` | `render:social-card`, `verify:social-card`, `prepare:source`; release builds |
| `tool/audit/` | Public-source and Git-history checks | `audit_public_sources.mjs`, `audit_repository_history.mjs` | `audit:sources`, `audit:history`, `test:audit`; CI analyze, refresh |
| `tool/content/` | Content synchronization, validation, string generation | `sync_public_content.mjs`, `validate_portfolio.dart`, `generate_app_strings.mjs` | `sync:content`, `verify:content`, `portfolio:validate`, `generate:strings`, `verify:strings`, `test:content`, `test:strings`; CI analyze, refresh, build |
| `tool/fonts/` | Font text extraction and subsetting | `subset_fonts.mjs` | `fonts:subset`, `verify:fonts`, `test:fonts`; CI analyze, refresh |
| `tool/public-content/` | Static metadata and host-security helpers | Imported modules | Content synchronization, `verify:hosting`, `test:hosting-security`; CI analyze |
| `tool/quality/` | Toolchain, coverage, community, source-graph checks | `verify_toolchain.mjs`, `coverage_gate.mjs`, `verify_community_files.mjs`, `verify_dart_reachability.mjs` | `verify:toolchain`, `verify:community`, `verify:source`, `test:tooling`; CI analyze, test, build |
| `tool/refresh/` | External-source adapters, merge rules, reports | `refresh_portfolio_data.mjs` | `refresh:data`, `test:refresh`; CI analyze, refresh |
| `tool/release/` | Release builds, documents, provenance, hosting checks | `build_portfolio.mjs`, `deploy_portfolio.mjs`, `prepare_web_release.mjs`, `verify_web_build.mjs` | `build:release`, `deploy`, `prepare:source`, `prepare:bundle`, `verify:bundle`, `verify:hosting`, `test:release-security`, `test:release-document`, `test:hosting-security`; CI analyze, build, deploy |
| `tool/runtime/` | Preview server, browser measurements, visual runner | `serve_web.mjs`, `measure_web_runtime.mjs`, `run_visual_in_docker.sh` | `measure:runtime`, `verify:runtime`, `test:visual:docker`; Playwright preview, CI build |
| `tool/shared/` | Executable, asset-path, static-path safety helpers | Imported modules | Content, template, release, and runtime consumers |
| `tool/template/` | Initializer, repository transaction, clone checks | `init_portfolio.mjs`, `test_template_clone.mjs` | `portfolio:init`, `test:template`, `test:starter`, `test:clone`; CI analyze, build |
| `tool/work_artifacts/` | Artifact rendering, encoding, digest verification | `render_work_artifacts.mjs` | `render:work-artifacts`, `verify:work-artifacts`, `test:work-artifacts`; conditional CI analyze steps |
| `tool/fixtures/` | Local coverage and refresh test data | None | Coverage and refresh tests |
| `tool/font_sources/` | Licensed source fonts and license notices | None | `fonts:subset`, `verify:fonts` |
| `tool/work_sources/` | Artifact source inputs, provenance, and manifest | None | Work-artifact rendering and verification |

## Adding a tool

1. Use the folder that owns its purpose; keep entry points thin and helpers focused.
   Share helpers through `tool/shared/` only when multiple tool areas need them.
2. Use ESM `.mjs` for Node tools. Add `// @ts-check` and JSDoc for input/output contracts;
   [tsconfig.tools.json](../tsconfig.tools.json) also enables checking across tool modules.
3. Put focused `test_*.mjs` tests beside the implementation. Use local fixtures and injected adapters;
   tests must not contact external services. Run the test entry point or `node --test` with explicit test files.
4. Wire user commands through `package.json`; add the relevant CI invocation when a check must block a release.
   Keep generated output and source-input digest contracts covered by tests.
5. Run `node --check path/to/tool.mjs`, the focused tests, `npm run lint`,
   `npm run format:check`, and `npm run typecheck`. Format with
   `npx --no-install prettier --write path/to/tool.mjs` before checking.
   Dart tools also require `dart format` and the applicable Flutter checks.

## Shared conventions

- Use the pinned Node 24 toolchain; [toolchain.json](../tool/quality/toolchain.json) and its verifier define exact versions.
- Do not add dependencies without review. Prefer Node built-ins and existing shared helpers.
- Keep external-source access in tooling; Flutter presentation has no runtime network layer.
- Keep tests deterministic and offline; isolate filesystem mutations in disposable fixtures and clean them up.
- Follow [architecture limits](ARCHITECTURE-RULES.md); fix or record touched debt in [TECH-DEBT.md](TECH-DEBT.md).
- Document folder responsibilities and command contracts here. Derive per-file callers and metrics from current code and checks.
