# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- **Engineering Lab** with live runtime, renderer, isolation, and rolling Flutter `FrameTiming` telemetry
- **Deterministic application bootstrap** and concurrency-safe `LanguageCubit`
- **Desktop and mobile Playwright smoke tests** for Wasm, first frame, runtime inspection, and browser history
- **Bundle integrity gate** with explicit Wasm and JavaScript budgets
- **Accessible bootstrap recovery** when the Flutter engine cannot start
- **Deterministic social preview pipeline** with a 1200×630, repository-rendered Open Graph card
- **Semantic production smoke suite** with serialized live Wasm verification
- **Instant engineering shell** that renders accessible, indexable content before Flutter's first frame
- **Release preparation gate** that strips renderer symbol maps and budgets the complete public artifact

### Changed

- Release builds now ship Dart WebAssembly + SkWasm with a JavaScript/CanvasKit fallback
- Renderer binaries are self-hosted instead of fetched from Flutter's public CDN
- Inter, Space Grotesk, and JetBrains Mono are bundled as local variable fonts; the font CDN preconnect was removed
- Dart sources and tests use the Dart 3.11 formatter as a CI-enforced baseline
- Contact drafts open the visitor's mail client; the UI no longer claims delivery before the visitor sends
- Browser history is synchronized directly by the scroll controller instead of a page router
- Reduced-motion preferences stop continuous scene animation and bypass the cinematic preloader
- The verified `build/web` release artifact is committed for the lightweight Nginx packaging path; private CV and portrait assets were removed from both source and output
- Unverifiable named endorsements were replaced by repository-backed engineering evidence
- GitHub Actions run on Node 24 releases pinned to immutable commit SHAs
- Open Graph and Twitter previews now use the engineering showcase card instead of the generic application icon
- Production verification no longer executes one-off coordinate-driven audit scripts in parallel
- Package metadata and the footer now agree on version 1.1.0

### Fixed

- Slow locale requests can no longer overwrite a newer language choice
- Browser back/forward no longer pushes a duplicate history entry
- Stable Wasm filenames are revalidated instead of receiving a one-year immutable cache policy
- Nginx serves Dart's `.mjs` support runtime with a JavaScript MIME type under `nosniff`
- Unsupported public project metrics were removed from all seven locale documents
- Legacy Flutter service workers now unregister themselves and return controlled clients to the network
- Same-origin fallback fonts resolve correctly for both root and repository-subpath deployments
- Renderer debug symbol maps are no longer published by Docker or GitHub Pages releases
- Stable Flutter entrypoint names now carry a content hash and renderer URLs include the exact engine revision, enabling cache-safe one-year binary responses

## [1.1.0] - 2026-03-23

### Added

- **System theme detection** — auto-detects OS dark/light preference, follows system changes unless manually overridden
- **Typewriter cycling** — hero subtitle types, erases, and retypes multiple role descriptions in a loop (7 languages)
- **Cursor trail effect** — 8-point fading particle trail following the custom cursor
- **Project category filtering** — filter projects by category (All/Mobile/Web/Backend) with animated chip transitions
- **GitHub contribution heatmap** — 90-day activity grid via Events API with 4 intensity levels
- **Section progress arc** — circular arc around active scroll dot showing section visibility progress
- **Case study images** — optional image support in project case studies (problem/solution/result)
- **Testimonials auto-carousel** — auto-rotating PageView on mobile/tablet with dot indicators

### Improved

- **Test coverage** expanded from 184 to 185 tests (6 new test files)
- **i18n completeness** — moved all hardcoded strings to 7-language JSON files (blog, sidebar, experience, 404, project links)
- **Accessibility** — Semantics on buttons/images/links, ExcludeSemantics on decorative widgets, keyboard navigation
- **Light mode** — theme-aware colors across 15+ widgets (borders, backgrounds, focus rings)
- **API resilience** — 10-15s HTTP timeouts on all providers, blog error state with retry, GitHub cached indicator
- **Mobile UX** — textInputAction on contact form fields, responsive improvements
- **SEO** — og:image:alt, og:locale meta tags
- **PWA** — manifest orientation "any", categories field
- **Smooth theme transition** — 400ms animated color change on theme toggle
- **Blog error handling** — separate error/empty/loading states with retry button
- **README** — updated test count, documented all new features, easter egg mention

## [1.0.0] - 2026-03-20

### Added

- **Cinematic design system** with 5 movie-inspired scene palettes (Blade Runner 2049, Dune, The Matrix, Spider-Verse, Interstellar)
- **SceneDirector** scroll-driven state machine with 200px crossfade transition zones
- **CinematicBackground** animated mesh gradient with Lissajous-curve blob movement, vignette overlay, and procedural film grain
- **ConstellationParticles** interactive particle field with spatial-grid O(n) neighbor lookups
- **CustomCursor** with outer ring, inner dot, spotlight glow, and hover expansion
- **8 portfolio sections**: Hero, About, Experience, Testimonials, Blog, Projects, Contact, Footer
- **Interactive terminal** in About section with 10+ commands (help, about, skills, experience, education, projects, contact, social, download-cv, clear)
- **Command palette** (Ctrl+K / Cmd+K) with fuzzy search across navigation, language, and action commands
- **Konami code easter egg** triggering Matrix digital rain overlay
- **3D skill orbit** visualization with depth-based scaling and category tooltips
- **Medium RSS blog integration** via rss2json API
- **GitHub activity widget** with live API stats (repos, followers, stars)
- **Contact form** with Formspree integration and validation
- **Project case study cards** with problem/solution/result breakdowns and multi-link support
- **Testimonials carousel** with colleague and mentor quotes
- **7-language internationalization** (English, Turkish, German, French, Spanish, Arabic RTL, Hindi)
- **Dark/light theme** with localStorage persistence
- **31 custom widgets** (magnetic buttons, text scramble, shader text reveal, skeleton shimmer, scroll indicators, etc.)
- **Social sidebars** with fixed icon links and vertical line (desktop)
- **Scroll progress dots** showing current section position
- **Back-to-top button** with scroll-triggered visibility
- **Skip-to-content link** for keyboard accessibility
- **Deep linking** with hash-based URL routing and section auto-scroll
- **Responsive layouts** for mobile (<600px), tablet (600-1200px), and desktop (1200px+)
- **185 automated tests** (unit + widget) covering controllers, constants, models, and interactive components
- **GitHub Actions CI/CD** pipeline: analyze, test, build (JS + WASM), and auto-deploy to GitHub Pages
- **PWA manifest** for installable web app experience
- **Clean Architecture** with domain/data/presentation layers and Dependency Inversion
- **Modern Dart 3.x** patterns: `abstract interface class`, `final class`, switch expressions, pattern matching
