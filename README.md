# Flutter Web Portfolio

A production Flutter Web engineering record for Yusuf İhsan Görgel, backed by typed external content, measured section navigation, accessible responsive layouts, and a dual-runtime Wasm release.

<!-- portfolio-demo:start -->
[Live site](https://developeryusuf.com/) · [Flutter Web first-frame issue](https://github.com/flutter/flutter/issues/189499) · [Engine patch](https://github.com/flutter/flutter/pull/189500)
<!-- portfolio-demo:end -->

The site reads identity, biography, experience, work, links, and contributions from `assets/content/portfolio.json`; presentation code contains no Yusuf- or project-specific branches. The same validated content contract keeps the interface reusable without turning the public site into a generic demo. Interface translations stay in `assets/i18n/*.json`.

<!-- portfolio-record:start -->
## Public engineering record

**Yusuf İhsan Görgel — Software Engineer.** I’m a software engineer working across Flutter, Dart, Go, and production infrastructure.

Since 2021, I have built and maintained software for mobile devices, tablets, desktop operating systems, and the web. My work includes ERP and point-of-sale products, logistics workflows, digital publishing, backend services, and the release systems around them.

Source status: `2026.07.16.11`, verified 2026-07-16 against GitHub and LinkedIn and FugaSoft and Dorse and Medium.

### Accepted upstream changes

| Project | Change | Merged | Evidence |
|---|---|---:|---|
| Dart MCP | Separate server feature registration from legacy initialization | 2026-07-15 | [Pull request](https://github.com/dart-lang/ai/pull/524) |
| FlutterFire | Make Firebase core loading deterministic on WebKit | 2026-07-15 | [Pull request](https://github.com/firebase/flutterfire/pull/18443) |
| Flutter Form Builder | Reset unknown dropdown initial values on first build | 2026-07-14 | [Pull request](https://github.com/flutter-form-builder-ecosystem/flutter_form_builder/pull/1512) |
| Drift | Treat SQLite TRUE and 1 defaults as the same schema | 2026-07-14 | [Pull request](https://github.com/simolus3/drift/pull/3835) |
| Go Fiber Recipes | Add a Fiber and Asynq background-jobs recipe | 2026-07-12 | [Pull request](https://github.com/gofiber/recipes/pull/4997) |

### Selected work

| Project | Responsibility | Evidence |
|---|---|---|
| FugaSoft | I work primarily on the Flutter clients and the production concerns around offline data, native integrations, synchronisation, performance, release, and long-term maintenance. | [Project](https://fugasoft.com/) |
| Dorse | I developed the Flutter application and React web surface across live vehicle state, maps, REST and WebSocket flows, deployment, and QA coordination. | [Project](https://dorseapp.com/) |
| Aydınlık E-Gazete | At Promob TR, I worked on the Flutter client, API-backed issue flow, localisation, and mobile releases. | [Project](https://apps.apple.com/tr/app/ayd%C4%B1nl%C4%B1k-e-gazete/id1560103805) |
| Bilim ve Ütopya | At Promob TR, I worked on Flutter features, API integration, localisation, and release support. | [Project](https://apps.apple.com/tr/app/bilim-ve-%C3%BCtopya-e-dergi/id6478221195) |
| Galvapedia | I built the product with Flutter and a Node.js, Express, and MongoDB service layer. | [Project](https://apps.apple.com/tr/app/galvapedia/id1592744617) |
| Queue Inspector MCP | I designed the command surface, typed validation, queue adapters, and conservative state-changing operations. | [Project](https://github.com/Yusufihsangorgel/queue-inspector-mcp) |
| Multi-tenant Gateway | I designed and implemented the reference from transport and tenant resolution through policy, persistence, and test coverage. | [Project](https://github.com/Yusufihsangorgel/go-multitenant-gateway) |
| Redis Task Queue | I designed the public API, queue semantics, failure handling, and runnable examples. | [Project](https://github.com/Yusufihsangorgel/redis_task_queue) |
| Constellation Particles | I implemented the painter, pointer interaction, spatial partitioning, and package examples without runtime dependencies. | [Project](https://github.com/Yusufihsangorgel/constellation_particles) |
| Flutter Web Portfolio | I built and run the Flutter Web site, its external content pipeline, accessibility layer, browser regression suite, and production release. | [Project](https://developeryusuf.com) |

### Work under review

- **Flutter:** [Wait for web rendering before the first-frame event](https://github.com/flutter/flutter/pull/189500) — Wait for outstanding scene renders and the next browser frame before dispatching the event; the pull request is ready for review with seven Chrome renderer and compiler suites passing.
- **Flutter Packages:** [Ignore unrecognized SVG font-weight values](https://github.com/flutter/packages/pull/12199) — Treat unrecognized font-weight values as unspecified, preserve supported mappings, and cover the parser behaviour with the existing vector-graphics test suite.
- **MCP Kotlin SDK:** [Add SEP-2575 request metadata and discovery types](https://github.com/modelcontextprotocol/kotlin-sdk/pull/893) — Add typed experimental metadata accessors, server discovery types, polymorphic codecs, and malformed-input coverage.
<!-- portfolio-record:end -->

## Content contract

`assets/content/portfolio.json` is the canonical professional record. It contains the profile, contact details, explicit display-name composition, current-role markers, optional experience, capabilities, optional contributions and work, source provenance, and site metadata. Every work record owns a palette and a required, source-backed artifact; featured professional cases additionally carry challenge, approach, outcome, and linked evidence records, while supporting work declares its evidence group and spotlight. `PortfolioDocument` parses the record into immutable final classes and rejects unsupported schemas, duplicate content IDs, invalid URLs, malformed presentation colours, duplicate artifacts, incomplete featured cases, incomplete supporting records, missing featured work, and identity/metadata drift.

Analytics is opt-in through `site.analytics` in the same document. Remove that object for a tracking-free deployment; the synchronization step removes the script instead of inheriting this site's analytics account.

`assets/i18n/*.json` contains interface language only. All seven locale documents share one tested key schema; none may contain biography, experience, project, or contribution records.

Run the synchronization gate after changing the manifest:

```bash
npm run sync:content
npm run verify:content
```

The synchronization tool owns this README record, search/social metadata, structured data, and the web manifest. The social-card renderer reads the same JSON at render time.

## Rendering architecture

```text
assets/content/portfolio.json
        │ strict parse before runApp
        ▼
PortfolioDocument ───────────────┐
                                │
assets/presentation/narrative.json
        │ chapter order + motif  │
        ▼                        │
NarrativeDocument               │
        │                        │
assets/i18n/{locale}.json        │
        │ ordered async loading  │
        ▼                        ▼
LanguageCubit              semantic sections
                                │ measured chapter bounds
                                ▼
AppScrollController ─────► NarrativePosition
        │                       │
        │ browser history       ├────► SceneDirector
        │ + visible progress    │           │
        ▼                       ▼           ▼
chapter navigation      kinetic portals    ambient CustomPainter
```

The document and render loop have deliberately different update paths:

- The composition root loads and validates professional content before `runApp`.
- BLoC/Cubit owns language, scroll, and scene state through explicit dependencies and immutable snapshots.
- Ambient painting listens only to scene and pointer changes rather than rebuilding the semantic document or running an idle animation loop.
- Section positions are measured after layout. One boundary-local reading snapshot drives active navigation, URL state, scene interpolation, and every visible progress indicator.
- Responsive reflow preserves the reader's chapter-relative focal point instead of retaining a stale raw pixel offset.
- Browser history represents positions inside one document. An early popstate bridge prevents Flutter's root Navigator from consuming chapter navigation twice while preserving the command palette's normal modal lifecycle.
- Decorative chapter portals reuse the ambient motif endpoints, derive localized labels from external catalogs, mirror in RTL, and add no semantic nodes.
- Reduced-motion sessions suppress pointer motion and animated transitions while preserving the complete document and navigation model.

## First meaningful frame

The HTML layer contains a critical shell generated from the canonical portfolio manifest during release preparation. It is not a second content source: role, headline, focus areas, and content version are injected from `assets/content/portfolio.json`, then verified against that record. The shell gives a cold Wasm visit a meaningful first paint while Flutter initializes, and it never forces a service-worker cleanup reload.

The bootstrap treats Flutter's first-frame event as a rendering signal rather than proof that the browser compositor has already presented the pixels. This keeps the release strategy reusable across Flutter engine revisions and browsers instead of coupling the implementation to one upstream issue or patch.

The handoff retains the visually aligned critical shell for two browser frames after Flutter's event. This avoids a blank flash while the Flutter surface reaches the compositor, then removes the HTML layer once.

### Runtime measurement

The bootstrap publishes ordered User Timing marks for entrypoint loading, engine initialization, Flutter's first-frame event, compositor-safe reveal, and final bootstrap removal. A separate cold-context runner samples three launches plus a frame-by-frame full-document scroll, then reports median startup, refresh-cadence-normalized frame misses, long-task time, layout shift, and renderer transfer data. Raw frame intervals remain in the report.

```bash
# Serve build/web separately, then collect a three-run JSON report.
npm run measure:runtime

# Apply the checked-in median budget as a local release gate.
npm run verify:runtime

# On a compatible macOS runner, exercise every threshold on the native GPU.
PERF_CHROMIUM_ARGS='["--use-angle=metal"]' npm run verify:runtime
```

Headless Chromium normally reports a software graphics backend such as SwiftShader. The default gate still records every raw metric, but metrics declared in `hardware_only_metrics` are listed under `enforcement_skips` and accompanied by a console warning instead of being judged against software-GPU readback latency. All other thresholds remain enforced. Native-hardware and unknown backends enforce every threshold, so a failed backend diagnostic cannot silently weaken the gate.

The budget and its JSON Schema are deliberately separate from content and presentation. They can evolve from measured hardware baselines without introducing device-specific branches into the Flutter document.

## Release model

The release contains Dart WebAssembly/SkWasm plus Flutter's JavaScript/CanvasKit fallback. Renderer binaries and fallback fonts are same-origin. Entry points receive a content hash; renderer files live below Flutter's exact engine revision so immutable caching cannot pair a new bootstrap with stale binaries.

The included Nginx configuration serves the headers required for threaded SkWasm:

```text
Cross-Origin-Opener-Policy: same-origin
Cross-Origin-Embedder-Policy: credentialless
```

Build the release used by browser tests:

```bash
flutter pub get
npm ci
npx playwright install chromium
npm run verify:content
flutter analyze --fatal-infos
flutter test
npm run prepare:source
flutter build web --release --wasm --no-web-resources-cdn
npm run prepare:bundle
npm run verify:bundle
npm run test:visual
npm test
```

The source preparation step renders the social card and writes a source manifest into the Flutter asset bundle. The bundle gate rejects stale tracked output, then checks Wasm headers, dual-runtime configuration, versioned entry points, self-hosted renderer assets, local font coverage, first-frame cleanup, service-worker retirement, and explicit size budgets. Playwright exercises desktop and mobile semantics, locale/RTL switching, URL history, security headers, and release assets. Checked-in platform baselines lock the critical shell, personal hero, open-source chapter, and full-width work atlas across desktop, mobile, and tablet viewports with reduced motion enabled.

## Local development

```bash
flutter pub get
flutter run -d chrome
```

Useful controls:

- `Ctrl/Cmd + K` opens the keyboard command surface.
- Native browser back/forward follows section history.
- `WASM_DELAY_MS=5000 PORT=4174 node tool/serve_web.mjs` exposes the first-frame handoff under a constrained local load.

## Key implementation files

| Concern | Source |
|---|---|
| Canonical professional data | `assets/content/portfolio.json` |
| Strict content schema | `lib/app/domain/models/portfolio_document.dart` |
| Deterministic composition root | `lib/app/app_dependencies.dart` |
| Locale concurrency | `lib/app/features/language/application/language_cubit.dart` |
| Measured document geometry | `lib/app/controllers/scroll_controller.dart` |
| Scene interpolation | `lib/app/controllers/scene_director.dart` |
| Ambient render layer | `lib/app/widgets/background/cinematic_background.dart` |
| Scroll-driven chapter portals | `lib/app/widgets/narrative_chapter_handoff.dart`, `lib/app/narrative/rendering/narrative_handoff_geometry.dart` |
| Full-width selected-work atlas | `lib/app/modules/home/sections/projects/projects_section.dart`, `lib/app/modules/home/sections/projects/widgets/project_atlas.dart` |
| Content synchronization | `tool/sync_public_content.mjs` |
| Runtime measurement | `tool/measure_web_runtime.mjs`, `tool/performance_budget.json`, `tool/performance_budget.schema.json` |
| Responsive visual regression | `tests/e2e/visual.spec.ts`, `tests/e2e/visual.spec.ts-snapshots/` |
| Release integrity | `tool/prepare_web_release.mjs`, `tool/verify_web_build.mjs` |

## License

MIT. See [LICENSE](LICENSE).
