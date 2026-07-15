# Flutter Web Portfolio

A production Flutter Web document built around one continuous render system: typed external content, measured scroll geometry, a procedural scene, and a dual-runtime Wasm release.

[Live site](https://developeryusuf.com) · [Flutter Web first-frame issue](https://github.com/flutter/flutter/issues/189499) · [Engine patch](https://github.com/flutter/flutter/pull/189500)

This repository is the engineering artifact behind the portfolio, not a reusable identity template. The public record below is generated from `assets/content/portfolio.json`; widget and painter code contain no role, biography, experience, project, or contribution records.

<!-- portfolio-record:start -->
## Public engineering record

**Software Engineer.** I build cross-platform products and the systems that keep them reliable.

My work spans Flutter clients, local and real-time data, native integrations, Go services, queues, and production infrastructure. I stay close to the boundary where product behaviour becomes a systems problem.

Source status: `2026.07.15.3`, verified 2026-07-15 against the public GitHub and LinkedIn records declared in the manifest.

### Accepted upstream changes

| Project | Change | Merged | Evidence |
|---|---|---:|---|
| FlutterFire | Make Firebase core loading deterministic on WebKit | 2026-07-15 | [Pull request](https://github.com/firebase/flutterfire/pull/18443) |
| Flutter Form Builder | Reset unknown dropdown initial values on first build | 2026-07-14 | [Pull request](https://github.com/flutter-form-builder-ecosystem/flutter_form_builder/pull/1512) |
| Drift | Treat SQLite TRUE and 1 defaults as the same schema | 2026-07-14 | [Pull request](https://github.com/simolus3/drift/pull/3835) |
| Go Fiber Recipes | Add a Fiber and Asynq background-jobs recipe | 2026-07-12 | [Pull request](https://github.com/gofiber/recipes/pull/4997) |

### Public systems

| System | Engineering focus | Source |
|---|---|---|
| Flutter Web Portfolio | Keep the semantic document and high-frequency painter paths separate while one measured scroll model directs both. | [Repository](https://github.com/Yusufihsangorgel/Flutter-Web-Portfolio) |
| Queue Inspector MCP | Expose queue state, job detail, retries, and dead letters through explicit operations with conservative defaults. | [Repository](https://github.com/Yusufihsangorgel/queue-inspector-mcp) |
| Multi-tenant Gateway | Keep tenant context explicit from transport through policy rather than hiding it behind global state. | [Repository](https://github.com/Yusufihsangorgel/go-multitenant-gateway) |
| Redis Task Queue | Make failure states inspectable and scheduling behaviour deterministic without adding a runtime framework. | [Repository](https://github.com/Yusufihsangorgel/redis_task_queue) |
| Constellation Particles | Use spatial partitioning to avoid comparing every particle pair as the scene grows. | [Repository](https://github.com/Yusufihsangorgel/constellation_particles) |

### Work under review

- **Flutter:** [Wait for web rendering before the first-frame event](https://github.com/flutter/flutter/pull/189500) — Wait for outstanding scene renders and the next browser frame before dispatching the event; the pull request is ready for review with seven Chrome renderer and compiler suites passing.
<!-- portfolio-record:end -->

## Content contract

`assets/content/portfolio.json` is the canonical professional record. It contains the profile, experience, capabilities, verified contributions, public systems, story transitions, source provenance, and site metadata. `PortfolioDocument` parses it into immutable final classes and rejects unsupported schemas, duplicate evidence IDs, invalid URLs, missing chapters, and public-role drift.

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
                                │ measured chapter centres
                                ▼
AppScrollController ─────► SceneDirector
                                │ immutable SceneConfig snapshots
                                ▼
                     CinematicBackground / CustomPainter
```

The document and render loop have deliberately different update paths:

- The composition root loads and validates professional content before `runApp`.
- BLoC/Cubit owns language, scroll, and scene state through explicit dependencies and immutable snapshots.
- High-frequency ambient painting listens to painter-local animation rather than rebuilding the semantic document.
- Section positions are measured after layout. Scene interpolation follows real chapter centres instead of equal scroll bands.
- Browser history represents positions inside one document; it is not used as a page router.
- Reduced-motion sessions stop continuous animation while preserving the complete document and navigation model.

## First meaningful frame

The HTML layer is only a neutral compositor bed. It has no duplicate hero, navigation, or professional copy, and it never forces a service-worker cleanup reload. Flutter owns the first meaningful frame.

Cold SkWasm measurements showed that `flutter-first-frame` could precede visible compositor output by 90.3–143.0 ms. The reproducible finding is tracked in [flutter/flutter#189499](https://github.com/flutter/flutter/issues/189499); [flutter/flutter#189500](https://github.com/flutter/flutter/pull/189500) proposes waiting for outstanding scene renders and the next browser frame. The patch is under review with its engine tests passing across seven Chrome renderer/compiler suites.

The local handoff retains the neutral background for two browser frames after Flutter's event. This avoids a blank flash without presenting a second portfolio screen.

### Runtime measurement

The bootstrap publishes ordered User Timing marks for entrypoint loading, engine initialization, Flutter's first-frame event, compositor-safe reveal, and final bootstrap removal. A separate cold-context runner samples three launches plus a frame-by-frame full-document scroll, then reports median startup, p95 frame interval, long-task time, layout shift, and renderer transfer data.

```bash
# Serve build/web separately, then collect a three-run JSON report.
npm run measure:runtime

# Apply the checked-in median budget as a local release gate.
npm run verify:runtime
```

The budget is deliberately separate from content and presentation. It can evolve from measured hardware baselines without introducing device-specific branches into the Flutter document.

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
npm run verify:content
flutter analyze --fatal-infos
flutter test
flutter build web --release --wasm --no-web-resources-cdn
npm run prepare:bundle
npm run verify:bundle
npm test
```

The bundle gate checks Wasm headers, dual-runtime configuration, versioned entry points, self-hosted renderer assets, local font coverage, first-frame cleanup, service-worker retirement, and explicit size budgets. Playwright then exercises desktop and mobile semantics, locale/RTL switching, URL history, security headers, and release assets.

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
| Procedural render system | `lib/app/widgets/background/cinematic_background.dart` |
| Full-width system studies | `lib/app/modules/home/sections/projects/projects_section.dart` |
| Content synchronization | `tool/sync_public_content.mjs` |
| Runtime measurement | `tool/measure_web_runtime.mjs`, `tool/performance_budget.json` |
| Release integrity | `tool/prepare_web_release.mjs`, `tool/verify_web_build.mjs` |

## License

MIT. See [LICENSE](LICENSE).
