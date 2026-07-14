# Contributing

Thanks for your interest in contributing to this project. Here's how to get started.

## Getting Started

1. **Fork** the repository
2. **Clone** your fork:
   ```bash
   git clone <your-fork-url>
   cd Flutter-Web-Portfolio
   ```
3. **Install dependencies:**
   ```bash
   flutter pub get
   ```
4. **Create a branch** for your change:
   ```bash
   git checkout -b feature/your-feature-name
   ```

## Development Workflow

### Before You Code

- Check the repository issue tracker to avoid duplicate work
- For large changes, open an issue first to discuss the approach

### While You Code

- Follow the existing code style and architecture patterns
- Use `final class` / `abstract interface class` where appropriate (Dart 3.x)
- Keep widgets small and composable — see `lib/app/widgets/` for examples
- Add tests for new controllers, models, and widgets

### Before You Submit

All quality gates must pass:

```bash
# Canonical Dart 3.11 formatting
dart format --output=none --set-exit-if-changed lib test

# Static analysis — zero warnings, zero infos
flutter analyze --fatal-infos

# All tests pass
flutter test

# Dual-runtime release build
flutter build web --release --wasm --no-web-resources-cdn

# Bundle integrity and browser smoke tests
npm ci
npm run verify:bundle
npm test
```

## Pull Request Process

1. **Push** your branch to your fork
2. **Open a PR** against the `main` branch
3. **Fill out the PR template** — describe what changed and why
4. **Wait for CI** — the GitHub Actions pipeline runs analyze, test, and build
5. **Address review feedback** if any

### PR Guidelines

- Keep PRs focused — one feature or fix per PR
- Write a clear title and description
- Include screenshots for visual changes
- Reference related issues with `Closes #123`

## Code Style

- Use `flutter analyze --fatal-infos` as the style authority
- Prefer `const` constructors wherever possible
- Use `switch` expressions over `if/else` chains for type matching
- Document public APIs with `///` doc comments
- Name files with `snake_case`, classes with `PascalCase`

## Project Structure

```
lib/app/
├── controllers/    # Frame-adjacent scroll, scene, cursor, and sound state
├── core/           # Constants and theme definitions
├── data/           # Models, providers, repository implementations
├── domain/         # Entities and abstract interfaces
├── features/       # Vertically sliced application features
├── modules/        # Page modules and sections
├── utils/          # Platform-aware utilities
└── widgets/        # Reusable UI and custom painters
```

When adding a new widget:
1. Create it in `lib/app/widgets/`
2. Add a corresponding test in `test/widget/`

Application features with state, infrastructure, and presentation code belong
under `lib/app/features/<feature>/`. Keep frame-frequency state out of Cubits;
use a synchronous `Listenable` when a value can change every rendered frame.

## Reporting Bugs

Use the repository bug report template and include:
- Flutter version (`flutter --version`)
- Browser and OS
- Steps to reproduce
- Expected vs actual behavior

## License

By contributing, you agree that your contributions will be licensed under the [MIT License](LICENSE).
