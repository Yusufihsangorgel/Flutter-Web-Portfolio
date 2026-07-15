<div align="center">

# Flutter Portfolio Template

A production-ready personal portfolio template built with Flutter. The current demo presents a senior Flutter engineer's experience and selected products; forks can replace the public content through the locale JSON files without rewriting the interface.

![Flutter](https://img.shields.io/badge/Flutter-3.41-02569B?logo=flutter)
![Dart](https://img.shields.io/badge/Dart-3.11-0175C2?logo=dart)
![License](https://img.shields.io/badge/License-MIT-green)

[**Live Demo**](https://developeryusuf.com)

</div>

## Customize the portfolio

Edit `assets/i18n/*.json` to change the role, biography, experience, skills, working principles, projects, and interface labels. Keep the same keys in every locale so the translation catalog remains type-safe.

The public demo intentionally avoids personal contact details. Add only the identity and links you are comfortable publishing.

Useful keyboard shortcuts:

- `Ctrl/Cmd + K` — open the keyboard-driven command palette.

## Included

- Responsive layouts for mobile, tablet, and desktop.
- English, Turkish, German, French, Spanish, Arabic with RTL, and Hindi.
- Accessible headings, keyboard navigation, skip links, focus states, and reduced-motion support.
- Data-driven experience, skills, principles, and project sections.
- A single first-frame handoff from the HTML loading shell to the Flutter hero.
- Dart WebAssembly and SkWasm release with a JavaScript and CanvasKit fallback.
- Playwright coverage for loading, accessibility, localization, routing, and release assets.

---

## Quick Start

```bash
git clone <your-fork-url>
cd Flutter-Web-Portfolio
flutter pub get
flutter run -d chrome
```

Build the same dual-runtime release used by CI:

```bash
flutter build web --release --wasm --no-web-resources-cdn
npm run prepare:bundle
npm run verify:bundle
```

The output contains both `main.dart.wasm` and `main.dart.js`. Compatible browsers run the Wasm/SkWasm path; Flutter selects the JavaScript/CanvasKit path when needed.

Typography is bundled locally as variable Inter, Space Grotesk, and JetBrains Mono assets. Their SIL Open Font License texts are kept beside the font files under `assets/fonts/`, so the first render does not depend on a font CDN.

### Required headers for threaded SkWasm

The included Docker image serves:

```text
Cross-Origin-Opener-Policy: same-origin
Cross-Origin-Embedder-Policy: credentialless
```

These headers make the page cross-origin isolated where the browser supports it. The release tests verify the contract against both the local server and the live deployment.

## Make It Yours

| What | File | Details |
|------|------|---------|
| Public content | `assets/i18n/*.json` | Project evidence, skills, and localized interface copy |
| Your meta tags | `web/index.html` | Title, OG tags, analytics, structured data |
| Social preview | `tool/social_card.html` | Deterministic 1200×630 source; run `npm run render:social-card` after editing |
| Scene palette | `lib/app/core/constants/scene_configs.dart` | Gradients, accents, particle speed, vignette |

---

## Architecture

```
main.dart
└── await AppDependencies.bootstrap()
    ├── storage + translation repository
    ├── LanguageCubit
    └── explicit Cubit + repository graph
        └── MaterialApp
            └── HomeView
                ├── AppScrollController → URL history + measured chapter geometry
                ├── SceneDirector → geometry-aligned SceneConfig interpolation
                └── CustomPaint layers → mesh, grain, and particles
```

The state boundary is intentional:

- **BLoC/Cubit** owns application state. Language changes are ordered, testable, and protected against stale requests overwriting newer choices; scene and scroll state use immutable snapshots.
- **Widget-local state** is reserved for short-lived hover, focus, and presentation details. High-frequency painting never traverses the application state graph.
- **Browser history is not a page router.** This is one document; `AppScrollController` synchronizes `#/section` URLs directly with visible sections and back/forward navigation.
- **Bootstrap completes before `runApp`.** Storage and the selected locale cannot race the first widget build.

Key implementation files:

| Concern | File |
|---|---|
| Deterministic composition root | `lib/app/app_dependencies.dart` |
| Locale state and concurrency | `lib/app/features/language/application/language_cubit.dart` |
| Browser history + section detection | `lib/app/controllers/scroll_controller.dart` |
| Geometry-aligned scene interpolation | `lib/app/controllers/scene_director.dart` |
| Particle spatial grid | `lib/app/widgets/constellation_particles.dart` |
| Custom mesh and grain painter | `lib/app/widgets/background/cinematic_background.dart` |

---

## Tech Stack

| | |
|---|---|
| **Framework** | Flutter 3.41 · Dart 3.11 · WebAssembly release target |
| **Application state** | `flutter_bloc` — explicit dependencies and immutable snapshots |
| **Render coordination** | Cubit selectors + painter-local `Listenable` updates |
| **i18n** | Application-owned JSON repository + `LanguageCubit` — 7 languages, ordered runtime switching |
| **Fonts** | Local variable Inter, JetBrains Mono, and Space Grotesk assets with adjacent SIL Open Font Licenses |
| **CI/CD** | GitHub Actions — pinned Flutter toolchain, fatal-info analysis, tests, bundle budget, browser smoke tests |
| **UI layer** | Flutter widgets and custom painters; no web component library |

## Verification

Run the same quality gates as CI:

```bash
flutter analyze --fatal-infos
flutter test
npm run verify:source
flutter build web --release --wasm --no-web-resources-cdn
npm run prepare:bundle
npm run verify:bundle
npm test
npm run test:e2e:prod
```

The local browser suite runs desktop and mobile in parallel against the release
artifact. The production suite intentionally uses one worker against the live
Wasm deployment, so limited client bandwidth cannot turn parallel downloads
into false boot-time failures. Both suites verify that the Open Graph image is
a real PNG at the declared 1200×630 large-card dimensions.

For visual QA of the instant shell on a constrained connection, the local
server can delay only Wasm responses without changing application code:

```bash
WASM_DELAY_MS=5000 PORT=4174 node tool/serve_web.mjs
```

Tests cover pure state transitions, uneven chapter geometry, out-of-order locale requests, repositories, responsive widgets, the command palette, and the complete professional narrative. The source-graph gate also rejects Dart files that are no longer reachable from `lib/main.dart`, so retired features cannot survive as dormant production code.

The release preparation step removes renderer debug symbol maps, versions app entrypoints with a content hash, and moves renderer binaries below Flutter's exact engine revision. Nginx can therefore cache those large immutable responses for a year without pairing a new bootstrap with stale runtime bytes. The bundle gate rejects unversioned artifacts, caps the complete public release at 36 MiB, `main.dart.wasm` at 3 MiB, and the JavaScript fallback at 4 MiB. It also verifies the Wasm header, dual-runtime build configuration, custom first-frame bootstrap, same-origin fallback fonts, and the fetch-free retirement worker used to remove legacy service-worker registrations.

---

## Deploy

**GitHub Pages** — set source to GitHub Actions in repo settings. Auto-deploys on push. Pages does not expose custom response-header configuration, so the renderer can run single-threaded there; use the included Nginx image when cross-origin isolation is required.

**Docker** — build Wasm first, then package the static output:

```bash
flutter build web --release --wasm --no-web-resources-cdn
npm run prepare:bundle
docker build -t flutter-web-portfolio .
```

---

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md).

## License

MIT — see [LICENSE](LICENSE).
