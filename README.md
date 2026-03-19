# Flutter Web Portfolio

Modern, interactive, and fully customizable Flutter Web portfolio built with Clean Architecture principles, GetX state management, and Dart 3.x features.

[![CI](https://github.com/Yusufihsangorgel/Flutter-Web-Portfolio/actions/workflows/ci.yml/badge.svg)](https://github.com/Yusufihsangorgel/Flutter-Web-Portfolio/actions)
[![Flutter](https://img.shields.io/badge/Flutter-3.27+-blue.svg)](https://flutter.dev/)
[![Dart](https://img.shields.io/badge/Dart-3.7+-0175C2.svg)](https://dart.dev/)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

## Features

- **Clean Architecture** with domain/data/presentation layers and SOLID principles
- **Fully Responsive** — mobile, tablet, and desktop optimized
- **Multi-language Support** — Turkish, English, German, French, Spanish
- **Cosmic Theme** — interactive background with orbital rocket physics, star field, and moon
- **Galaxy Skills View** — draggable skill planets in an orbital layout
- **Desktop Window Simulator** — projects displayed in a simulated OS environment
- **Interactive Terminal** — about section with a working terminal emulator
- **Holographic Contact Form** — custom shader-based visual effects
- **Modern Dart 3.x** — switch expressions, sealed classes, pattern matching, class modifiers
- **Unit & Widget Tests** with CI pipeline (GitHub Actions)

## Quick Start

**Requirements:** Flutter SDK 3.27+ / Dart SDK 3.7+

```bash
git clone https://github.com/Yusufihsangorgel/Flutter-Web-Portfolio.git
cd Flutter-Web-Portfolio
flutter pub get
flutter run -d chrome
```

## Architecture

```
lib/
├── app/
│   ├── bindings/              # Dependency injection (GetX bindings)
│   ├── controllers/           # Global controllers (theme, language, scroll, background)
│   ├── core/
│   │   ├── constants/         # AppColors, Breakpoints, Durations
│   │   └── theme/             # Unified AppTheme (Material 3)
│   ├── data/
│   │   ├── models/            # Data models (ProjectModel)
│   │   ├── providers/         # Asset & storage providers
│   │   └── repositories/      # Repository implementations
│   ├── domain/
│   │   ├── entities/          # Domain entities (Project, Experience, Skill)
│   │   └── repositories/      # Abstract interface contracts
│   ├── modules/
│   │   └── home/
│   │       ├── bindings/
│   │       ├── controllers/
│   │       └── sections/      # Feature sections (contact/, projects/, skills/, etc.)
│   ├── routes/
│   ├── utils/                 # ResponsiveUtils, UrlLauncherUtils
│   └── widgets/               # Reusable widgets (background/, terminal/, etc.)
└── main.dart
```

**Key patterns:**
- Repository interfaces use `abstract interface class` (Dart 3.x)
- Entities use `final class` / `base class` modifiers
- Constants use `final class` with private constructors
- Responsive layout via `switch` expressions with relational patterns

## Customization

### Personal Data

Edit the JSON files in `assets/i18n/` to update your information:

```json
{
  "app_name": "Your Name - Portfolio",
  "cv_data": {
    "personal_info": { "name": "...", "title": "...", "bio": "..." },
    "experiences": [{ "company": "...", "position": "..." }],
    "projects": [{ "title": "...", "description": "...", "url": "..." }],
    "skills": [{ "category": "Mobile", "items": ["Flutter", "Dart"] }]
  }
}
```

### Theme

Modify colors in `lib/app/core/constants/app_colors.dart` and theme in `lib/app/core/theme/app_theme.dart`.

### CV File

Replace `assets/data/cv.pdf` with your own resume.

### Adding Languages

1. Create a new JSON file in `assets/i18n/` (e.g., `ja.json`)
2. Add the locale to `supportedLocales` in `main.dart`
3. Add the language entry in `LanguageRepositoryImpl`

## Deployment

### GitHub Pages

```bash
flutter build web --release --base-href "/Flutter-Web-Portfolio/"
# Push build/web contents to gh-pages branch
```

### Firebase Hosting

```bash
flutter build web --release
firebase deploy
```

## Testing

```bash
flutter test          # Run all tests
flutter analyze       # Static analysis
```

## License

MIT License — see [LICENSE](LICENSE) for details.
