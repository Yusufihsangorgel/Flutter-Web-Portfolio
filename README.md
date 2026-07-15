# Flutter Web Portfolio

A production-ready Flutter Web portfolio template with typed external content, measured section navigation, accessible responsive layouts, and a dual-runtime Wasm release.

<!-- portfolio-demo:start -->
[Live site](https://developeryusuf.com/) · [Flutter Web first-frame issue](https://github.com/flutter/flutter/issues/189499) · [Engine patch](https://github.com/flutter/flutter/pull/189500)
<!-- portfolio-demo:end -->

The live demo is generated from one public professional record, while the interface remains a reusable template. Replace `assets/content/portfolio.json` to change the identity, biography, experience, work, links, and contributions without rewriting the widgets. Interface translations stay in `assets/i18n/*.json`.

<!-- portfolio-record:start -->
## Public engineering record

**Yusuf İhsan Görgel — Software Engineer.** I build cross-platform software, then stay for the hard parts.

I work across Flutter, Dart, and Go, turning product ideas into software that holds up on real devices, unreliable networks, and long-lived release cycles.

Source status: `2026.07.15.6`, verified 2026-07-15 against GitHub and LinkedIn.

### Accepted upstream changes

| Project | Change | Merged | Evidence |
|---|---|---:|---|
| FlutterFire | Make Firebase core loading deterministic on WebKit | 2026-07-15 | [Pull request](https://github.com/firebase/flutterfire/pull/18443) |
| Flutter Form Builder | Reset unknown dropdown initial values on first build | 2026-07-14 | [Pull request](https://github.com/flutter-form-builder-ecosystem/flutter_form_builder/pull/1512) |
| Drift | Treat SQLite TRUE and 1 defaults as the same schema | 2026-07-14 | [Pull request](https://github.com/simolus3/drift/pull/3835) |
| Go Fiber Recipes | Add a Fiber and Asynq background-jobs recipe | 2026-07-12 | [Pull request](https://github.com/gofiber/recipes/pull/4997) |

### Selected work

| Project | Responsibility | Evidence |
|---|---|---|
| Dorse | I worked across the Flutter application and React web surface, including live vehicle state, maps, API flows, deployment, and QA coordination. | [Project](https://dorseapp.com/) |
| Queue Inspector MCP | I designed the command surface, typed validation, queue adapters, and conservative state-changing operations. | [Project](https://github.com/Yusufihsangorgel/queue-inspector-mcp) |
| Multi-tenant Gateway | I designed and implemented the complete reference from transport and tenant resolution through policy and test coverage. | [Project](https://github.com/Yusufihsangorgel/go-multitenant-gateway) |
| Aydınlık E-Gazete | I delivered Flutter client work across presentation, API integration, and store-ready releases. | [Project](https://apps.apple.com/us/app/ayd%C4%B1nl%C4%B1k-e-gazete/id1560103805) |
| Bilim ve Ütopya E-Dergi | I built Flutter client features, API integration, localisation, and mobile release workflows. | [Project](https://apps.apple.com/tr/app/bilim-ve-%C3%BCtopya-e-dergi/id6478221195) |
| Redis Task Queue | I designed the public API, queue semantics, failure handling, and runnable examples. | [Project](https://github.com/Yusufihsangorgel/redis_task_queue) |
| Constellation Particles | I implemented the painter, pointer interaction, spatial partitioning, and package examples without runtime dependencies. | [Project](https://github.com/Yusufihsangorgel/constellation_particles) |
| Flutter Web Portfolio | I built the content schema, Flutter interface, renderer handoff, browser tests, runtime budgets, and deployment path. | [Project](https://github.com/Yusufihsangorgel/Flutter-Web-Portfolio) |

### Work under review

- **Flutter:** [Wait for web rendering before the first-frame event](https://github.com/flutter/flutter/pull/189500) — Wait for outstanding scene renders and the next browser frame before dispatching the event; the pull request is ready for review with seven Chrome renderer and compiler suites passing.
- **MCP Kotlin SDK:** [Add SEP-2575 request metadata and discovery types](https://github.com/modelcontextprotocol/kotlin-sdk/pull/893) — Add typed experimental metadata accessors, server discovery types, polymorphic codecs, and malformed-input coverage.
<!-- portfolio-record:end -->

## Content contract

`assets/content/portfolio.json` is the canonical professional record. It contains the profile, explicit display-name composition, optional experience, capabilities, optional contributions and work, source provenance, and site metadata. Featured work carries challenge, approach, outcome, and linked evidence records. `PortfolioDocument` parses it into immutable final classes and rejects unsupported schemas, duplicate content IDs, invalid URLs, incomplete featured case studies, missing featured work, and identity/metadata drift.

Analytics is opt-in through `site.analytics` in the same document. Remove that object for a tracking-free template; the synchronization step removes the script instead of inheriting the demo site's analytics account.

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
assets/i18n/{locale}.json        │
        │ ordered async loading  │
        ▼                        ▼
LanguageCubit              semantic sections
                                │ measured section centres
                                ▼
AppScrollController ─────► SceneDirector
                                │ immutable SceneConfig snapshots
                                ▼
                     restrained ambient CustomPainter
```

The document and render loop have deliberately different update paths:

- The composition root loads and validates professional content before `runApp`.
- BLoC/Cubit owns language, scroll, and scene state through explicit dependencies and immutable snapshots.
- Ambient painting listens only to scene and pointer changes rather than rebuilding the semantic document or running an idle animation loop.
- Section positions are measured after layout. Scene interpolation follows real chapter centres instead of equal scroll bands.
- Browser history represents positions inside one document; it is not used as a page router.
- Reduced-motion sessions suppress pointer motion and animated transitions while preserving the complete document and navigation model.

## First meaningful frame

The HTML layer contains a critical shell generated from the canonical portfolio manifest during release preparation. It is not a second content source: role, headline, focus areas, and content version are injected from `assets/content/portfolio.json`, then verified against that record. The shell gives a cold Wasm visit a meaningful first paint while Flutter initializes, and it never forces a service-worker cleanup reload.

The bootstrap treats Flutter's first-frame event as a rendering signal rather than proof that the browser compositor has already presented the pixels. This keeps the release strategy reusable across Flutter engine revisions and browsers instead of coupling the template to one upstream issue or patch.

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

The source preparation step renders the social card and writes a source manifest into the Flutter asset bundle. The bundle gate rejects stale tracked output, then checks Wasm headers, dual-runtime configuration, versioned entry points, self-hosted renderer assets, local font coverage, first-frame cleanup, service-worker retirement, and explicit size budgets. Playwright exercises desktop and mobile semantics, locale/RTL switching, URL history, security headers, and release assets. Twelve checked-in screenshots lock the critical shell, hero, open-source chapter, and work chapter across desktop, mobile, and tablet viewports with reduced motion enabled.

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
| Editorial selected-work index | `lib/app/modules/home/sections/projects/projects_section.dart` |
| Content synchronization | `tool/sync_public_content.mjs` |
| Runtime measurement | `tool/measure_web_runtime.mjs`, `tool/performance_budget.json`, `tool/performance_budget.schema.json` |
| Responsive visual regression | `tests/e2e/visual.spec.ts`, `tests/e2e/visual.spec.ts-snapshots/` |
| Release integrity | `tool/prepare_web_release.mjs`, `tool/verify_web_build.mjs` |

## License

MIT. See [LICENSE](LICENSE).
