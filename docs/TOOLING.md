# Repository tooling

The tools implement the template and static-release contracts in [ADR 0008](adr/0008-repository-tooling-scope.md). Run commands from the repository root. Node entrypoints remain exposed through the existing npm script names.

## Folder map

| Folder | Responsibility |
|---|---|
| `tool/assets/` | Raster inspection and social-card rendering |
| `tool/audit/` | Public-source and Git-history verification |
| `tool/content/` | Content synchronization, Dart validation, and string generation |
| `tool/fonts/` | Font text extraction, subsets, and tests |
| `tool/public-content/` | Metadata rendering and static-host security policies |
| `tool/quality/` | Pinned toolchain, coverage, community, and source-graph checks |
| `tool/refresh/` | Source adapters, merge rules, reports, and refresh tests |
| `tool/release/` | Build/deploy commands, release documents, headers, provenance, and hosting checks |
| `tool/runtime/` | Preview server, browser measurements, budgets, and visual runner |
| `tool/shared/` | Safe executable, asset, and static-path helpers |
| `tool/template/` | Initializer input, repository transaction, neutral README, and template tests |
| `tool/work_artifacts/` | Artifact plan, rendering families, encoding, digest, and verification |
| `tool/fixtures/` | Local coverage and refresh fixtures |
| `tool/font_sources/` | Licensed source fonts and license notices |
| `tool/work_sources/` | Artifact source captures, provenance ledger, and manifest |

`tool/quality/toolchain.json` keeps the toolchain pins with their verifier. Existing folders keep their names. No tool is removed: each production entrypoint or helper has a script, import, workflow, test, or documented manual caller. Dynamic refresh fixture names are resolved by `refreshFixture()` and the mock fetch adapter; font licenses remain with source fonts. Source captures also participate in the artifact input digest.

## Moves and source metrics

The 59 moves were verified byte-for-byte before path corrections and formatting. Counts use physical lines; the before column is the task starting tree. The split entrypoint counts exclude their new helper modules, listed below. Import-gate violations for the Node files remain zero. Tool JavaScript checking started with 58 diagnostics and ends with zero; ESLint and the source metric checks end with zero findings.

| Original file | Current file | Lines before → after | Initial type findings |
|---|---|---:|---:|
| `tool/audit_public_sources.mjs` | `tool/audit/audit_public_sources.mjs` | 146 → 146 | 1 |
| `tool/audit_repository_history.mjs` | `tool/audit/audit_repository_history.mjs` | 230 → 212 | 0 |
| `tool/test_audit_repository_history.mjs` | `tool/audit/test_audit_repository_history.mjs` | 96 → 97 | 2 |
| `tool/generate_app_strings.mjs` | `tool/content/generate_app_strings.mjs` | 173 → 223 | 0 |
| `tool/render_llms_txt.mjs` | `tool/content/render_llms_txt.mjs` | 142 → 140 | 0 |
| `tool/sync_public_content.mjs` | `tool/content/sync_public_content.mjs` | 318 → 298 | 0 |
| `tool/test_generate_app_strings.mjs` | `tool/content/test_generate_app_strings.mjs` | 73 → 84 | 0 |
| `tool/test_sync_public_content.mjs` | `tool/content/test_sync_public_content.mjs` | 168 → 168 | 0 |
| `tool/validate_portfolio.dart` | `tool/content/validate_portfolio.dart` | 34 → 36 | 0 |
| `tool/build_portfolio.mjs` | `tool/release/build_portfolio.mjs` | 66 → 60 | 0 |
| `tool/deploy_portfolio.mjs` | `tool/release/deploy_portfolio.mjs` | 192 → 172 | 1 |
| `tool/hosted_build.sh` | `tool/release/hosted_build.sh` | 57 → 57 | 0 |
| `tool/prepare_web_release.mjs` | `tool/release/prepare_web_release.mjs` | 397 → 408 | 0 |
| `tool/render_static_document.mjs` | `tool/release/render_static_document.mjs` | 127 → 157 | 1 |
| `tool/resolve_pages_base_href.mjs` | `tool/release/resolve_pages_base_href.mjs` | 70 → 61 | 1 |
| `tool/source_manifest.mjs` | `tool/release/source_manifest.mjs` | 88 → 74 | 0 |
| `tool/static_header_policy.mjs` | `tool/release/static_header_policy.mjs` | 73 → 77 | 0 |
| `tool/test_release_security.mjs` | `tool/release/test_release_security.mjs` | 541 → 4 | 5 |
| `tool/test_render_static_document.mjs` | `tool/release/test_render_static_document.mjs` | 54 → 75 | 0 |
| `tool/test_verify_release_document.mjs` | `tool/release/test_verify_release_document.mjs` | 191 → 383 | 4 |
| `tool/verify_hosting_configs.mjs` | `tool/release/verify_hosting_configs.mjs` | 298 → 280 | 5 |
| `tool/verify_web_build.mjs` | `tool/release/verify_web_build.mjs` | 481 → 435 | 0 |
| `tool/test_verify_hosting_configs.mjs` | `tool/release/test_verify_hosting_configs.mjs` | 84 → 189 | 2 |
| `tool/write_source_manifest.mjs` | `tool/release/write_source_manifest.mjs` | 15 → 10 | 0 |
| `tool/raster_inspector.mjs` | `tool/assets/raster_inspector.mjs` | 276 → 312 | 0 |
| `tool/render_social_card.mjs` | `tool/assets/render_social_card.mjs` | 208 → 190 | 2 |
| `tool/social_card.html` | `tool/assets/social_card.html` | 126 → 126 | 0 |
| `tool/social_card_fingerprint.mjs` | `tool/assets/social_card_fingerprint.mjs` | 63 → 59 | 0 |
| `tool/init_portfolio.mjs` | `tool/template/init_portfolio.mjs` | 672 → 145 | 0 |
| `tool/package_links.mjs` | `tool/template/package_links.mjs` | 42 → 51 | 0 |
| `tool/smoke_clean_template.mjs` | `tool/template/smoke_clean_template.mjs` | 139 → 140 | 1 |
| `tool/starter_readme.mjs` | `tool/template/starter_readme.mjs` | 14 → 15 | 0 |
| `tool/template_identity_markers.mjs` | `tool/template/template_identity_markers.mjs` | 95 → 104 | 0 |
| `tool/test_package_links.mjs` | `tool/template/test_package_links.mjs` | 33 → 39 | 1 |
| `tool/test_portfolio_init.mjs` | `tool/template/test_portfolio_init.mjs` | 234 → 328 | 0 |
| `tool/test_starter_readme.mjs` | `tool/template/test_starter_readme.mjs` | 47 → 52 | 1 |
| `tool/test_template_clone.mjs` | `tool/template/test_template_clone.mjs` | 406 → 380 | 1 |
| `tool/font_text_sources.mjs` | `tool/fonts/font_text_sources.mjs` | 116 → 117 | 0 |
| `tool/subset_fonts.mjs` | `tool/fonts/subset_fonts.mjs` | 217 → 221 | 0 |
| `tool/test_subset_fonts.mjs` | `tool/fonts/test_subset_fonts.mjs` | 66 → 79 | 0 |
| `tool/coverage_gate.mjs` | `tool/quality/coverage_gate.mjs` | 142 → 152 | 0 |
| `tool/coverage_thresholds.json` | `tool/quality/coverage_thresholds.json` | 4 → 4 | 0 |
| `tool/test_coverage_gate.mjs` | `tool/quality/test_coverage_gate.mjs` | 75 → 81 | 0 |
| `tool/verify_community_files.mjs` | `tool/quality/verify_community_files.mjs` | 94 → 83 | 0 |
| `tool/verify_dart_reachability.mjs` | `tool/quality/verify_dart_reachability.mjs` | 84 → 82 | 0 |
| `tool/verify_toolchain.mjs` | `tool/quality/verify_toolchain.mjs` | 81 → 68 | 0 |
| `tool/measure_web_runtime.mjs` | `tool/runtime/measure_web_runtime.mjs` | 157 → 131 | 0 |
| `tool/performance_budget.json` | `tool/runtime/performance_budget.json` | 54 → 54 | 0 |
| `tool/performance_budget.schema.json` | `tool/runtime/performance_budget.schema.json` | 168 → 168 | 0 |
| `tool/serve_web.mjs` | `tool/runtime/serve_web.mjs` | 116 → 112 | 0 |
| `tool/run_visual_in_docker.sh` | `tool/runtime/run_visual_in_docker.sh` | 56 → 56 | 0 |
| `tool/cli_safety.mjs` | `tool/shared/cli_safety.mjs` | 104 → 89 | 0 |
| `tool/safe_public_asset_path.mjs` | `tool/shared/safe_public_asset_path.mjs` | 60 → 60 | 0 |
| `tool/safe_static_path.mjs` | `tool/shared/safe_static_path.mjs` | 45 → 45 | 0 |
| `tool/refresh_portfolio_data.mjs` | `tool/refresh/refresh_portfolio_data.mjs` | 247 → 305 | 5 |
| `tool/test_refresh_portfolio_data.mjs` | `tool/refresh/test_refresh_portfolio_data.mjs` | 645 → 7 | 2 |
| `tool/test_public_content_security.mjs` | `tool/public-content/test_public_content_security.mjs` | 133 → 194 | 1 |
| `tool/render_work_artifacts.mjs` | `tool/work_artifacts/render_work_artifacts.mjs` | 1736 → 50 | 0 |
| `tool/toolchain.json` | `tool/quality/toolchain.json` | 6 → 6 | 0 |

## Splits

| Former file | Modules |
|---|---|
| `render_work_artifacts.mjs` (1,736) | Entry 50; plan 273; renderer context 76; architecture 330; landscape 164; compact release 203; Dorse 368; gateway 293; product 95; release 263; template interpolation 14. |
| `init_portfolio.mjs` (672) | Entry 145; input/document helpers 337; repository transaction 210. |
| `test_refresh_portfolio_data.mjs` (645) | Entry 7; package/contribution cases 424; writing cases 234; shared harness 42. |
| `test_release_security.mjs` (541) | Entry 4; static contracts 402; preview contracts 61; raster/fingerprint cases 65. |

The renderer comparison checks the original and split HTML and output names for all 18 jobs without Chromium or remote requests. Rendered image bytes stay unchanged; the manifest input digest is updated for the new source layout. The initializer snapshots the complete artifact module directory, restores it on failure, and removes it on successful template initialization.

## Existing module metrics

| File | Lines before → after |
|---|---:|
| `tool/fixtures/refresh/mock-fetch.mjs` | 24 → 34 |
| `tool/public-content/hosting_security.mjs` | 66 → 115 |
| `tool/public-content/renderers.mjs` | 332 → 317 |
| `tool/public-content/security.mjs` | 69 → 78 |
| `tool/refresh/args.mjs` | 34 → 33 |
| `tool/refresh/feeds.mjs` | 128 → 128 |
| `tool/refresh/github.mjs` | 87 → 88 |
| `tool/refresh/http.mjs` | 83 → 92 |
| `tool/refresh/incident.test.mjs` | 226 → 302 |
| `tool/refresh/merge.mjs` | 67 → 76 |
| `tool/refresh/pub.mjs` | 73 → 92 |
| `tool/refresh/report.mjs` | 65 → 73 |
| `tool/release/bundle_helpers.mjs` | 88 → 111 |
| `tool/release/not_found_page.mjs` | 22 → 22 |
| `tool/release/render_release_index.mjs` | 19 → 25 |
| `tool/release/verify_document.mjs` | 166 → 266 |
| `tool/release/verify_static_404.mjs` | 93 → 98 |
| `tool/runtime/measure_run.mjs` | 345 → 323 |
| `tool/runtime/runtime_support.mjs` | 280 → 258 |
| `tool/work_artifacts/encoder.mjs` | 84 → 77 |
| `tool/work_artifacts/manifest.mjs` | 199 → 196 |
| `tool/work_artifacts/page.mjs` | 87 → 91 |
| `tool/work_artifacts/test_work_artifacts.mjs` | 126 → 144 |

All JavaScript files have zero current lint and type findings. Line increases within the file limits come from formatting, JSDoc, or extracted validation steps; no source-limit or import-baseline entry is added.

## Caller inventory

This inventory covers every original file under `tool/`, excluding `tool/resume/`. Callers include the original entrypoint contract; extracted initializer, renderer, and security modules now carry the corresponding imports and checks. Paths below show the new layout. Supporting modules added by the splits are imported by their entrypoints; the manifest hashes every rendering module except test files.

| File | Callers or retained contract |
|---|---|
| `tool/audit/audit_public_sources.mjs` | `package.json` |
| `tool/audit/audit_repository_history.mjs` | `package.json`, `tool/audit/test_audit_repository_history.mjs` |
| `tool/release/build_portfolio.mjs` | `package.json`, `tool/release/test_release_security.mjs`, `tool/release/deploy_portfolio.mjs`, `docs/adr/0003-dual-wasm-javascript-runtime.md` |
| `tool/shared/cli_safety.mjs` | `tool/template/init_portfolio.mjs`, `tool/release/test_release_security.mjs`, `tool/quality/verify_toolchain.mjs`, `tool/template/test_portfolio_init.mjs`, `tool/template/test_template_clone.mjs`, `tool/release/build_portfolio.mjs`, `tool/release/deploy_portfolio.mjs`, `tool/release/not_found_page.mjs` |
| `tool/quality/coverage_gate.mjs` | `.github/workflows/ci.yml`, `tool/quality/test_coverage_gate.mjs` |
| `tool/quality/coverage_thresholds.json` | `tool/quality/coverage_gate.mjs` |
| `tool/release/deploy_portfolio.mjs` | `package.json`, `tool/release/test_release_security.mjs`, `tool/release/verify_hosting_configs.mjs` |
| `tool/fixtures/lcov/below.lcov` | `tool/quality/test_coverage_gate.mjs` |
| `tool/fixtures/lcov/equal.lcov` | `tool/quality/test_coverage_gate.mjs` |
| `tool/fixtures/lcov/thirds.lcov` | `tool/quality/test_coverage_gate.mjs` |
| `tool/fixtures/refresh/cli-document.json` | `tool/refresh/incident.test.mjs` |
| `tool/fixtures/refresh/mock-fetch.mjs` | `tool/refresh/incident.test.mjs` |
| `tool/fixtures/refresh/pub-metrics-confirmed.json` | `tool/refresh/incident.test.mjs (dynamic fixture name)`, `tool/fixtures/refresh/mock-fetch.mjs (dynamic fixture name)` |
| `tool/fixtures/refresh/pub-metrics-missing-report.json` | `tool/refresh/incident.test.mjs (dynamic fixture name)`, `tool/fixtures/refresh/mock-fetch.mjs (dynamic fixture name)` |
| `tool/fixtures/refresh/pub-metrics-pending.json` | `tool/refresh/incident.test.mjs (dynamic fixture name)`, `tool/fixtures/refresh/mock-fetch.mjs (dynamic fixture name)` |
| `tool/fixtures/refresh/pub-metrics-sums-disagree.json` | `tool/refresh/incident.test.mjs (dynamic fixture name)`, `tool/fixtures/refresh/mock-fetch.mjs (dynamic fixture name)` |
| `tool/fixtures/refresh/pub-score-pending.json` | `tool/refresh/incident.test.mjs (dynamic fixture name)`, `tool/fixtures/refresh/mock-fetch.mjs (dynamic fixture name)` |
| `tool/font_sources/inter/Inter-Variable.ttf` | `tool/fonts/subset_fonts.mjs`, `tests/e2e/smoke.spec.ts`, `tests/e2e/fonts.spec.ts`, `tests/e2e-prod/portfolio.spec.ts` |
| `tool/font_sources/inter/OFL.txt` | Source font license notice |
| `tool/font_sources/jetbrains_mono/JetBrainsMono-Variable.ttf` | `tool/fonts/subset_fonts.mjs`, `tool/assets/render_social_card.mjs`, `tests/e2e/fonts.spec.ts` |
| `tool/font_sources/jetbrains_mono/OFL.txt` | Source font license notice |
| `tool/font_sources/space_grotesk/OFL.txt` | Source font license notice |
| `tool/font_sources/space_grotesk/SpaceGrotesk-Variable.ttf` | `tool/fonts/subset_fonts.mjs`, `tool/assets/social_card.html`, `tool/assets/render_social_card.mjs`, `tests/e2e/fonts.spec.ts` |
| `tool/fonts/font_text_sources.mjs` | `tool/fonts/test_subset_fonts.mjs`, `tool/fonts/subset_fonts.mjs` |
| `tool/content/generate_app_strings.mjs` | `package.json`, `tool/content/test_generate_app_strings.mjs` |
| `tool/release/hosted_build.sh` | `README.md`, `netlify.toml`, `vercel.json`, `.github/workflows/ci.yml`, `tool/release/test_release_security.mjs`, `tool/release/verify_hosting_configs.mjs`, `docs/DEPLOY.md` |
| `tool/template/init_portfolio.mjs` | `package.json`, `tool/release/test_release_security.mjs`, `tool/template/test_portfolio_init.mjs`, `tool/template/test_template_clone.mjs`, `docs/TECH-DEBT.md` |
| `tool/runtime/measure_web_runtime.mjs` | `package.json`, `docs/TECH-DEBT.md` |
| `tool/template/package_links.mjs` | `package.json`, `tool/template/init_portfolio.mjs`, `tool/template/test_package_links.mjs`, `tool/template/test_portfolio_init.mjs` |
| `tool/runtime/performance_budget.json` | `tool/runtime/measure_web_runtime.mjs` |
| `tool/runtime/performance_budget.schema.json` | `tool/runtime/measure_web_runtime.mjs`, `tool/runtime/performance_budget.json` |
| `tool/release/prepare_web_release.mjs` | `package.json`, `tool/release/verify_hosting_configs.mjs`, `docs/TECH-DEBT.md`, `docs/adr/0001-flutter-web-document-first-portfolio.md`, `docs/adr/0006-locales-and-font-loading.md` |
| `tool/public-content/hosting_security.mjs` | `tool/release/verify_hosting_configs.mjs`, `tool/release/test_verify_hosting_configs.mjs` |
| `tool/public-content/renderers.mjs` | `tool/content/sync_public_content.mjs`, `tool/public-content/test_public_content_security.mjs` |
| `tool/public-content/security.mjs` | `package.json`, `tool/content/sync_public_content.mjs`, `tool/public-content/test_public_content_security.mjs`, `tool/release/verify_hosting_configs.mjs`, `tool/release/test_verify_hosting_configs.mjs`, `tool/public-content/hosting_security.mjs`, `tool/public-content/renderers.mjs` |
| `tool/assets/raster_inspector.mjs` | `tool/release/test_release_security.mjs`, `tool/release/verify_web_build.mjs`, `tool/assets/render_social_card.mjs`, `tool/work_artifacts/test_work_artifacts.mjs`, `tool/work_artifacts/manifest.mjs` |
| `tool/refresh/args.mjs` | `tool/refresh/refresh_portfolio_data.mjs` |
| `tool/refresh/feeds.mjs` | `tool/refresh/refresh_portfolio_data.mjs`, `tool/refresh/merge.mjs` |
| `tool/refresh/github.mjs` | `tool/refresh/refresh_portfolio_data.mjs` |
| `tool/refresh/http.mjs` | `tool/refresh/refresh_portfolio_data.mjs`, `tool/refresh/feeds.mjs` |
| `tool/refresh/incident.test.mjs` | `tool/refresh/test_refresh_portfolio_data.mjs` |
| `tool/refresh/merge.mjs` | `tool/refresh/refresh_portfolio_data.mjs` |
| `tool/refresh/pub.mjs` | `tool/refresh/refresh_portfolio_data.mjs` |
| `tool/refresh/report.mjs` | `tool/refresh/refresh_portfolio_data.mjs` |
| `tool/refresh/refresh_portfolio_data.mjs` | `package.json`, `.github/workflows/refresh.yml`, `tool/refresh/test_refresh_portfolio_data.mjs`, `tool/refresh/incident.test.mjs`, `docs/TECH-DEBT.md`, `docs/AUTOMATION.md` |
| `tool/release/bundle_helpers.mjs` | `tool/release/prepare_web_release.mjs`, `tool/release/verify_web_build.mjs`, `tool/release/test_verify_release_document.mjs` |
| `tool/release/not_found_page.mjs` | `tool/release/prepare_web_release.mjs`, `tool/release/test_verify_release_document.mjs`, `tool/release/verify_static_404.mjs` |
| `tool/release/render_release_index.mjs` | `tool/release/prepare_web_release.mjs`, `tool/release/test_verify_release_document.mjs` |
| `tool/release/verify_document.mjs` | `tool/release/verify_web_build.mjs`, `tool/release/test_verify_release_document.mjs` |
| `tool/release/verify_static_404.mjs` | `tool/release/verify_web_build.mjs`, `tool/release/test_verify_release_document.mjs` |
| `tool/content/render_llms_txt.mjs` | `tool/content/sync_public_content.mjs`, `tool/content/test_sync_public_content.mjs` |
| `tool/assets/render_social_card.mjs` | `package.json`, `tool/template/init_portfolio.mjs`, `tool/release/test_release_security.mjs`, `tool/template/test_portfolio_init.mjs` |
| `tool/release/render_static_document.mjs` | `package.json`, `tool/release/prepare_web_release.mjs`, `tool/release/test_render_static_document.mjs`, `tool/release/verify_document.mjs`, `docs/adr/0002-hash-routing-static-semantic-document.md` |
| `tool/work_artifacts/render_work_artifacts.mjs` | `package.json`, `.github/workflows/ci.yml`, `tool/template/init_portfolio.mjs`, `tool/template/test_template_clone.mjs`, `tool/work_sources/README.md`, `tool/work_artifacts/test_work_artifacts.mjs`, `tool/work_artifacts/manifest.mjs`, `docs/TECH-DEBT.md` |
| `tool/release/resolve_pages_base_href.mjs` | `.github/workflows/deploy.yml`, `tool/release/verify_hosting_configs.mjs` |
| `tool/runtime/run_visual_in_docker.sh` | `package.json` |
| `tool/runtime/measure_run.mjs` | `tool/runtime/measure_web_runtime.mjs` |
| `tool/runtime/runtime_support.mjs` | `tool/runtime/measure_web_runtime.mjs` |
| `tool/shared/safe_public_asset_path.mjs` | `tool/release/source_manifest.mjs`, `tool/release/verify_web_build.mjs`, `tool/assets/render_social_card.mjs`, `tool/template/test_portfolio_init.mjs` |
| `tool/shared/safe_static_path.mjs` | `tool/runtime/serve_web.mjs`, `tool/release/test_release_security.mjs`, `tool/template/smoke_clean_template.mjs` |
| `tool/runtime/serve_web.mjs` | `playwright.config.ts`, `tool/release/test_release_security.mjs`, `tool/runtime/runtime_support.mjs`, `docs/TEMPLATE.md`, `docs/DEPLOY.md`, `docs/CUSTOMIZE.md` |
| `tool/template/smoke_clean_template.mjs` | `tool/template/test_template_clone.mjs` |
| `tool/assets/social_card.html` | `tool/release/test_release_security.mjs`, `tool/assets/render_social_card.mjs`, `docs/CUSTOMIZE.md` |
| `tool/assets/social_card_fingerprint.mjs` | `tool/release/test_release_security.mjs`, `tool/assets/render_social_card.mjs` |
| `tool/release/source_manifest.mjs` | `package.json`, `tool/template/init_portfolio.mjs`, `tool/release/test_release_security.mjs`, `tool/release/verify_web_build.mjs`, `tool/release/write_source_manifest.mjs` |
| `tool/template/starter_readme.mjs` | `package.json`, `tool/template/init_portfolio.mjs`, `tool/template/test_starter_readme.mjs` |
| `tool/release/static_header_policy.mjs` | `tool/runtime/serve_web.mjs`, `tool/release/test_release_security.mjs`, `tool/public-content/hosting_security.mjs` |
| `tool/fonts/subset_fonts.mjs` | `package.json`, `tool/fonts/test_subset_fonts.mjs` |
| `tool/content/sync_public_content.mjs` | `package.json`, `tool/template/init_portfolio.mjs`, `tool/template/test_template_clone.mjs`, `docs/TECH-DEBT.md`, `docs/CUSTOMIZE.md` |
| `tool/template/template_identity_markers.mjs` | `tool/template/test_starter_readme.mjs`, `tool/template/test_portfolio_init.mjs`, `tool/template/test_template_clone.mjs` |
| `tool/audit/test_audit_repository_history.mjs` | `package.json: test:audit`, `.github/workflows/ci.yml` |
| `tool/quality/test_coverage_gate.mjs` | `.github/workflows/ci.yml` |
| `tool/content/test_generate_app_strings.mjs` | `package.json` |
| `tool/template/test_package_links.mjs` | `package.json` |
| `tool/template/test_portfolio_init.mjs` | `package.json` |
| `tool/public-content/test_public_content_security.mjs` | `package.json` |
| `tool/refresh/test_refresh_portfolio_data.mjs` | `package.json` |
| `tool/release/test_release_security.mjs` | `package.json` |
| `tool/release/test_render_static_document.mjs` | `package.json` |
| `tool/template/test_starter_readme.mjs` | `package.json` |
| `tool/fonts/test_subset_fonts.mjs` | `package.json` |
| `tool/content/test_sync_public_content.mjs` | `package.json` |
| `tool/template/test_template_clone.mjs` | `package.json` |
| `tool/release/test_verify_hosting_configs.mjs` | `package.json` |
| `tool/release/test_verify_release_document.mjs` | `package.json` |
| `tool/quality/toolchain.json` | `README.md`, `CONTRIBUTING.md`, `.github/PULL_REQUEST_TEMPLATE.md`, `.github/workflows/refresh.yml`, `tool/release/prepare_web_release.mjs`, `tool/release/verify_web_build.mjs`, `tool/quality/verify_toolchain.mjs`, `tool/release/verify_hosting_configs.mjs`, `tool/release/hosted_build.sh`, `docs/TEMPLATE.md`, `docs/DEPLOY.md`, `docs/adr/0007-adaptive-render-budget.md` |
| `tool/content/validate_portfolio.dart` | `package.json`, `tool/template/test_portfolio_init.mjs`, `docs/adr/0005-strict-json-content-contract.md` |
| `tool/quality/verify_community_files.mjs` | `package.json` |
| `tool/quality/verify_dart_reachability.mjs` | `package.json` |
| `tool/release/verify_hosting_configs.mjs` | `package.json` |
| `tool/quality/verify_toolchain.mjs` | `package.json`, `README.md`, `.github/workflows/refresh.yml`, `.github/workflows/visual-baselines.yml`, `.github/workflows/deploy.yml`, `.github/workflows/ci.yml`, `tool/release/verify_hosting_configs.mjs`, `tool/release/build_portfolio.mjs`, `tool/release/hosted_build.sh` |
| `tool/release/verify_web_build.mjs` | `package.json`, `tool/release/verify_hosting_configs.mjs`, `tool/release/deploy_portfolio.mjs`, `docs/TECH-DEBT.md`, `docs/adr/0002-hash-routing-static-semantic-document.md`, `docs/adr/0003-dual-wasm-javascript-runtime.md` |
| `tool/work_artifacts/encoder.mjs` | `tool/template/test_portfolio_init.mjs`, `tool/work_artifacts/render_work_artifacts.mjs`, `tool/work_artifacts/test_work_artifacts.mjs` |
| `tool/work_artifacts/manifest.mjs` | `package.json`, `tool/template/init_portfolio.mjs`, `tool/release/test_release_security.mjs`, `tool/release/verify_web_build.mjs`, `tool/release/write_source_manifest.mjs`, `tool/work_artifacts/render_work_artifacts.mjs`, `tool/work_artifacts/test_work_artifacts.mjs` |
| `tool/work_artifacts/page.mjs` | `tool/release/prepare_web_release.mjs`, `tool/release/test_verify_release_document.mjs`, `tool/work_artifacts/render_work_artifacts.mjs`, `tool/release/verify_static_404.mjs` |
| `tool/work_artifacts/test_work_artifacts.mjs` | `package.json` |
| `tool/work_sources/README.md` | `README.md`, `CONTRIBUTING.md`, `.github/workflows/refresh.yml`, `tool/template/init_portfolio.mjs`, `tool/quality/verify_community_files.mjs`, `tool/content/sync_public_content.mjs`, `tool/audit/test_audit_repository_history.mjs`, `tool/template/test_portfolio_init.mjs`, `tool/template/test_template_clone.mjs`, `tool/work_artifacts/test_work_artifacts.mjs` |
| `tool/work_sources/artifact-manifest.json` | `tool/work_artifacts/render_work_artifacts.mjs`, `tool/work_sources/README.md`, `tool/work_artifacts/manifest.mjs` |
| `tool/work_sources/aydinlik-edition.png` | `tool/work_artifacts/render_work_artifacts.mjs` |
| `tool/work_sources/aydinlik-icon.jpg` | `tool/work_artifacts/render_work_artifacts.mjs` |
| `tool/work_sources/aydinlik-reader.jpg` | `tool/work_artifacts/render_work_artifacts.mjs` |
| `tool/work_sources/bilim-archive.png` | `tool/work_artifacts/render_work_artifacts.mjs` |
| `tool/work_sources/bilim-cover.jpg` | `tool/work_artifacts/render_work_artifacts.mjs` |
| `tool/work_sources/bilim-icon.jpg` | `tool/work_artifacts/render_work_artifacts.mjs` |
| `tool/work_sources/constellation-demo.png` | `tool/work_artifacts/render_work_artifacts.mjs`, `tool/work_sources/README.md` |
| `tool/work_sources/dorse-vehicle-settings.jpeg` | `tool/work_artifacts/render_work_artifacts.mjs`, `tool/work_sources/README.md` |
| `tool/work_sources/fugasoft-solutions.png` | `tool/work_artifacts/render_work_artifacts.mjs`, `tool/work_sources/README.md` |
| `tool/work_sources/go-multitenant-gateway-server.go.txt` | `tool/work_artifacts/render_work_artifacts.mjs`, `tool/work_sources/README.md` |
| `tool/work_sources/redis-task-queue-cover.png` | `tool/work_sources/README.md` |
| `tool/release/write_source_manifest.mjs` | `package.json`, `tool/template/init_portfolio.mjs` |

## Checks

CI analyze runs `npm run typecheck`, `npm run lint`, and `npm run format:check`. `npm run test:tooling` calibrates recommended rules and the custom parameter limit with failing and passing examples. The existing strict TypeScript browser-test project is unchanged. The second project extends it to check JavaScript inference and JSDoc in `tool/**/*.mjs`; JavaScript parameters can remain inferred. No file-level type suppression or ESLint rule suppression is used. ESLint also enforces 500 file lines, 60 function lines, four parameters, four nesting levels, and complexity 15.

The template transaction and artifact digest tests cover relocated helpers. Release-security checks retain all 77 original assertion sites: 60 static, nine preview, and eight raster. Static checks run first and can also run independently with `node tool/release/test_release_security_static.mjs` when the environment prohibits preview sockets. Release source preparation must be rerun before a release because the source manifest and social-card fingerprint include tool inputs. Browser suites and release builds retain their existing CI placement.

## Local verification — 2026-10-07

The analyze job contains 25 npm script checks: 23 passed and two could not complete because of environment restrictions. All commands used the pinned Node and Flutter toolchains.

| Command | Result |
|---|---|
| `npm run verify:content` | Passed; public content synchronized |
| `npm run portfolio:validate` | Passed; seven sections |
| `npm run test:template` | Passed; initialization, removal, and rollback contracts |
| `npm run test:starter` | Passed; four tests |
| `npm run test:release-security` | Static contracts passed; preview socket denied with `EPERM` |
| `npm run test:release-document` | Passed; 35 tests |
| `npm run test:hosting-security` | Passed; hosting and public-content contracts |
| `npm run test:refresh` | Passed; 58 cases |
| `npm run test:content` | Passed; synchronization contracts |
| `npm run test:strings` | Passed; eight tests |
| `npm run verify:strings` | Passed; generated strings synchronized |
| `npm run verify:fonts` | Passed; font subsets synchronized |
| `npm run test:fonts` | Passed; seven tests |
| `npm run test:work-artifacts` | Passed; six tests |
| `npm run verify:work-artifacts` | Passed; 18 artifacts |
| `npm run verify:hosting` | Passed; five hosting configurations |
| `npm run verify:community` | Passed; community contracts |
| `npm run audit:sources` | Blocked by external-source DNS resolution |
| `npm run audit:history` | Passed; zero findings |
| `npm run test:audit` | Passed; seven calibration scenarios |
| `npm run test:tooling` | Passed; three lint calibration tests |
| `npm run typecheck` | Passed; zero diagnostics in both projects |
| `npm run lint` | Passed; zero findings |
| `npm run format:check` | Passed; all matching files formatted |
| `npm run verify:source` | Passed; 108 Dart files reachable |
| `node tool/release/test_release_security_static.mjs` | Passed; 68 assertion sites including raster tests |
| `node --check` for every `tool/**/*.mjs` | Passed; 93 files |
| `node tool/quality/verify_toolchain.mjs --current` | Passed; all pins match |
| `node tool/quality/test_coverage_gate.mjs` | Passed; four tests |
| `bash -n tool/release/hosted_build.sh` and `bash -n tool/runtime/run_visual_in_docker.sh` | Passed |
| `python3 quality/check_architecture.py` | Passed; four baseline violations, zero new, zero stale, 523 imports |
| `python3 -m unittest discover -s quality/tests -p 'test_architecture.py'` | Passed; six calibration tests |
| `dart format --output=none --set-exit-if-changed lib test tool` | Passed; 163 files, zero changes |
| `flutter analyze --fatal-infos` | Dependency advisory request blocked by DNS |
| `flutter analyze --no-pub --fatal-infos` | Passed; zero issues |
| `flutter test` / `flutter test --no-pub` | Blocked by dependency DNS / local test-server socket restriction |
| Original/split artifact HTML comparison | Passed; 18 output names and documents identical |
| `git diff --check` | Passed |

The coordinator must rerun the blocked checks and the existing clone, browser, and release-build suites in their supported environment. Generated source manifests and social-card fingerprints outside `tool/` remain for release preparation. The architecture policy still describes a five-entry baseline; the current checker and baseline have four entries, so the coordinator-owned policy text needs synchronization. Historical path exclusions in the Git-history auditor deliberately retain both layouts.

## Changed files

The move table above lists every relocated file. New helper and declaration files:

- `tool/refresh/test_refresh_packages.mjs`
- `tool/refresh/test_refresh_writing.mjs`
- `tool/refresh/test_support.mjs`
- `tool/quality/test_tooling_config.mjs`
- `tool/release/test_preview_security.mjs`
- `tool/release/test_raster_security.mjs`
- `tool/release/test_release_security_static.mjs`
- `tool/runtime/browser_metrics.d.ts`
- `tool/template/portfolio_init_input.mjs`
- `tool/template/portfolio_init_repository.mjs`
- `tool/work_artifacts/architecture_boards.mjs`
- `tool/work_artifacts/artifact_plan.mjs`
- `tool/work_artifacts/compact_landscape_board.mjs`
- `tool/work_artifacts/compact_release_board.mjs`
- `tool/work_artifacts/dorse_boards.mjs`
- `tool/work_artifacts/gateway_board.mjs`
- `tool/work_artifacts/product_boards.mjs`
- `tool/work_artifacts/release_board.mjs`
- `tool/work_artifacts/renderer.mjs`
- `tool/work_artifacts/template.mjs`

Caller, documentation, and configuration updates:

- `.github/PULL_REQUEST_TEMPLATE.md`
- `.github/workflows/ci.yml`
- `.github/workflows/deploy.yml`
- `.github/workflows/refresh.yml`
- `.github/workflows/visual-baselines.yml`
- `CONTRIBUTING.md`
- `README.md`
- `docs/AUTOMATION.md`
- `docs/CUSTOMIZE.md`
- `docs/DEPLOY.md`
- `docs/TECH-DEBT.md`
- `docs/TEMPLATE.md`
- `docs/adr/0001-flutter-web-document-first-portfolio.md`
- `docs/adr/0002-hash-routing-static-semantic-document.md`
- `docs/adr/0003-dual-wasm-javascript-runtime.md`
- `docs/adr/0005-strict-json-content-contract.md`
- `docs/adr/0006-locales-and-font-loading.md`
- `docs/adr/0007-adaptive-render-budget.md`
- `docs/adr/0008-repository-tooling-scope.md`
- `lighthouserc.json`
- `netlify.toml`
- `package.json`
- `playwright.config.ts`
- `vercel.json`
- `.prettierignore`
- `.prettierrc.json`
- `docs/TOOLING.md`
- `eslint.config.mjs`
- `tsconfig.tools.json`

Existing tool modules updated in place:

- `tool/fixtures/refresh/mock-fetch.mjs`
- `tool/public-content/hosting_security.mjs`
- `tool/public-content/renderers.mjs`
- `tool/public-content/security.mjs`
- `tool/refresh/args.mjs`
- `tool/refresh/feeds.mjs`
- `tool/refresh/github.mjs`
- `tool/refresh/http.mjs`
- `tool/refresh/incident.test.mjs`
- `tool/refresh/merge.mjs`
- `tool/refresh/pub.mjs`
- `tool/refresh/report.mjs`
- `tool/release/bundle_helpers.mjs`
- `tool/release/not_found_page.mjs`
- `tool/release/render_release_index.mjs`
- `tool/release/verify_document.mjs`
- `tool/release/verify_static_404.mjs`
- `tool/runtime/measure_run.mjs`
- `tool/runtime/runtime_support.mjs`
- `tool/work_artifacts/encoder.mjs`
- `tool/work_artifacts/manifest.mjs`
- `tool/work_artifacts/page.mjs`
- `tool/work_artifacts/test_work_artifacts.mjs`
- `tool/work_sources/README.md`
- `tool/work_sources/artifact-manifest.json`
