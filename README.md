<div align="center">

# Flutter Web, pushed beyond the usual portfolio

A graphics-heavy, responsive portfolio built entirely with Flutter widgets and custom painters. The release build ships Dart WebAssembly + SkWasm with a JavaScript/CanvasKit fallback.

![Flutter](https://img.shields.io/badge/Flutter-3.41-02569B?logo=flutter)
![Dart](https://img.shields.io/badge/Dart-3.11-0175C2?logo=dart)
![License](https://img.shields.io/badge/License-MIT-green)

[**Live Demo**](https://developeryusuf.com)

</div>

## This is the demo

The page is not a video, a DOM mockup, or a wrapper around a JavaScript animation library. Scroll position drives a scene state machine; that state feeds gradients, particles, accents, vignette intensity, and section transitions on Flutter's canvas.

Before that canvas is ready, the server-rendered instant shell paints the same
engineering thesis directly from `index.html`. It remains useful on a cold or
constrained connection, exposes an accessible busy state, and hands off only
after Flutter emits its first-frame event.

Open the live site and press:

- `Ctrl/Cmd + Shift + L` — inspect the active runtime, renderer, browser isolation, and live frame timings.
- `Ctrl/Cmd + K` — open the keyboard-driven command palette.

The Engineering Lab reports values from the current browser session. It deliberately does not publish a fixed FPS score or a hand-picked benchmark.

## What makes it interesting

🎬 **Cinematic Backgrounds** — 5 movie-inspired palettes that crossfade as you scroll

✨ **Particle System** — spatial grid with O(n) neighbor lookups, cursor repulsion, connecting lines

🎥 **Procedural Film Grain** — a cached 256×256 texture created via `PictureRecorder` and tiled by a custom painter

🧪 **Engineering Lab** — runtime capability probe plus a rolling `FrameTiming` p50/p95 trace

⌨️ **Command Palette** — Ctrl+K fuzzy search across navigation, languages, and actions

🌍 **7 Languages** — English, Turkish, German, French, Spanish, Arabic (RTL), Hindi

🎯 **Scroll Animations** — fade-in reveals, magnetic buttons, text scramble, shader wipes

🔊 **Sound Design** — Web Audio API synthesized hover, click, and ambient sounds

🎮 **Easter Egg** — Konami code triggers Matrix digital rain

📱 **Responsive** — mobile, tablet, and desktop breakpoints

♿ **Accessible Controls** — semantics, keyboard navigation, skip link, focus states, and reduced-motion-aware dialogs

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
```

The output contains both `main.dart.wasm` and `main.dart.js`. Compatible browsers run the Wasm/SkWasm path; Flutter selects the JavaScript/CanvasKit path when needed.

Typography is bundled locally as variable Inter, Space Grotesk, and JetBrains Mono assets. Their SIL Open Font License texts are kept beside the font files under `assets/fonts/`, so the first render does not depend on a font CDN.

### Required headers for threaded SkWasm

The included Docker image serves:

```text
Cross-Origin-Opener-Policy: same-origin
Cross-Origin-Embedder-Policy: credentialless
```

These headers make the page cross-origin isolated where the browser supports it. The Engineering Lab shows the result at runtime instead of assuming the deployment is configured correctly.

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
                ├── AppScrollController → URL history + section offsets
                ├── SceneDirector → interpolated SceneConfig
                └── CustomPaint layers → mesh, grain, particles, cursor
```

The state boundary is intentional:

- **BLoC/Cubit** owns application state. Language changes are ordered, testable, and protected against stale requests overwriting newer choices; scene, scroll, cursor, sound, and personalization state use immutable snapshots.
- **Widget-local `Listenable` state** owns pointer coordinates and spring physics that can change every rendered frame. High-frequency motion never traverses the application state graph.
- **Browser history is not a page router.** This is one document; `AppScrollController` synchronizes `#/section` URLs directly with visible sections and back/forward navigation.
- **Bootstrap completes before `runApp`.** Storage and the selected locale cannot race the first widget build.

Key implementation files:

| Concern | File |
|---|---|
| Deterministic composition root | `lib/app/app_dependencies.dart` |
| Locale state and concurrency | `lib/app/features/language/application/language_cubit.dart` |
| Runtime/frame telemetry | `lib/app/features/engineering_lab/` |
| Browser history + section detection | `lib/app/controllers/scroll_controller.dart` |
| Scene interpolation | `lib/app/controllers/scene_director.dart` |
| Particle spatial grid | `lib/app/widgets/constellation_particles.dart` |
| Custom mesh and grain painter | `lib/app/widgets/background/cinematic_background.dart` |

---

## Tech Stack

| | |
|---|---|
| **Framework** | Flutter 3.41 · Dart 3.11 · WebAssembly release target |
| **Application state** | `flutter_bloc` — explicit dependencies and immutable snapshots |
| **Render coordination** | Cubit selectors + widget-local `ValueNotifier`/`Listenable` physics |
| **i18n** | [flutter_i18n](https://pub.dev/packages/flutter_i18n) — 7 languages, runtime switching |
| **Fonts** | Local variable Inter, JetBrains Mono, and Space Grotesk assets with adjacent SIL Open Font Licenses |
| **CI/CD** | GitHub Actions — pinned Flutter toolchain, fatal-info analysis, tests, bundle budget, browser smoke tests |
| **UI layer** | Flutter widgets and custom painters; no web component library |

## Verification

Run the same quality gates as CI:

```bash
flutter analyze --fatal-infos
flutter test
flutter build web --release --wasm --no-web-resources-cdn
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

Tests cover pure state transitions, out-of-order locale requests, repositories, scene configuration, responsive widgets, the command palette, and narrow-screen Engineering Lab layout.

The bundle gate currently caps `main.dart.wasm` at 3 MiB and the JavaScript fallback at 4 MiB. It also verifies the Wasm header, dual-runtime build configuration, custom first-frame bootstrap, same-origin fallback fonts, and the fetch-free retirement worker used to remove legacy service-worker registrations.

---

## Deploy

**GitHub Pages** — set source to GitHub Actions in repo settings. Auto-deploys on push. Pages does not expose custom response-header configuration, so the renderer can run single-threaded there; use the included Nginx image when cross-origin isolation is required.

**Docker** — build Wasm first, then package the static output:

```bash
flutter build web --release --wasm --no-web-resources-cdn
docker build -t flutter-web-portfolio .
```

---

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md).

## License

MIT — see [LICENSE](LICENSE).
