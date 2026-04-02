# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

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
