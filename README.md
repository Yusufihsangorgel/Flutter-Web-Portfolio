# Flutter Web Portfolio

<p align="center">
  <img src="assets/images/preview.png" alt="Flutter Web Portfolio Preview" width="800">
</p>

Modern, interactive and customizable Flutter Web portfolio template. The ideal solution for quickly creating and publishing your personal website.

[![Flutter Version](https://img.shields.io/badge/Flutter-3.19.0+-blue.svg)](https://flutter.dev/)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)
[![Stars](https://img.shields.io/github/stars/yourusername/flutter-web-portfolio?style=social)](https://github.com/yourusername/flutter-web-portfolio)

## ✨ Features

- 🚀 **Modern Design**: Impressive user interface with cosmic theme
- 📱 **Fully Responsive**: Perfect display on all devices (mobile, tablet, desktop)
- 🌐 **Multi-language Support**: Turkish, English, German, French, Arabic, and Hindi
- 🌙 **Dark Theme**: Sleek interface that's easy on the eyes
- 📄 **CV Download**: Visitors can easily download your resume
- 🔍 **SEO Friendly**: Optimized structure for search engines
- 🎯 **Animations**: Eye-catching, fluid animations
- 🧩 **Modular Structure**: Easily customizable sections
- 🔄 **GetX State Management**: Efficient state management
- 📊 **Skills Showcase**: Display your talents in a galaxy view
- 💼 **Project Showcase**: Show your projects in impressive windows
- 📞 **Contact Form**: Form for visitors to reach you
- 🧹 **Clean Architecture**: Sustainable and testable code structure

## 🚀 Quick Start

### Requirements

- Flutter SDK (3.19.0 or higher)
- Dart SDK (3.3.0 or higher)
- Git

### Installation

1. Fork or clone this repository:

```bash
git clone https://github.com/yourusername/flutter-web-portfolio.git
cd flutter-web-portfolio
```

2. Install dependencies:

```bash
flutter pub get
```

3. Run the project:

```bash
flutter run -d chrome
```

## 🎨 Customization

### 1. Personal Information and CV Data

Edit the language files in the `assets/i18n/` folder to update your personal information and CV data:

```json
{
  "app_name": "Your Name - Portfolio",
  "cv_data": {
    "personal_info": {
      "name": "Your Name",
      "title": "Your Title",
      "phone": "+90 123 456 7890",
      "email": "email@example.com",
      "github": "https://github.com/username",
      "linkedin": "https://linkedin.com/in/username",
      "bio": "A short description about yourself..."
    },
    "experiences": [
      {
        "title": "Your Job Title",
        "company": "Company Name",
        "period": "Start - End",
        "description": "Your job description and achievements"
      }
    ],
    "projects": [
      {
        "title": "Project Name",
        "description": "Project description",
        "url": "https://github.com/username/project",
        "image": "assets/images/project.png"
      }
    ],
    "education": [
      {
        "school": "School/University Name",
        "degree": "Department/Degree",
        "period": "Start - End"
      }
    ],
    "skills": [
      {
        "category": "Category Name",
        "items": ["Skill 1", "Skill 2", "Skill 3"]
      }
    ]
  }
}
```

### 2. CV File

Replace the `assets/data/cv.pdf` file with your own CV.

### 3. Language Settings

You can define supported languages in the `supportedLanguages` method in the `lib/app/controllers/language_controller.dart` file. To add a new language:

1. Add a new JSON file for the language to the `assets/i18n/` folder (e.g., `fr.json`).
2. Use `tr.json` or `en.json` as a reference and translate the content.

### 4. Color and Theme Customization

You can edit theme and color settings in the `lib/app/theme/app_theme.dart` file.

## 📱 Responsive Design

This portfolio template is optimized for all screen sizes:

- **Mobile**: 320px - 480px
- **Tablet**: 481px - 1024px
- **Desktop**: 1025px and above

## 🌐 Language Support

The following languages are supported:

- 🇹🇷 Turkish
- 🇬🇧 English
- 🇩🇪 German
- 🇫🇷 French
- 🇸🇦 Arabic
- 🇮🇳 Hindi

## 🧩 Project Architecture

The project is structured according to Clean Architecture principles:

```
lib/
├── app/
│   ├── bindings/          # Dependency injection
│   ├── controllers/       # Application controllers
│   ├── data/
│   │   ├── providers/     # Data providers
│   │   ├── repositories/  # Repository implementations
│   ├── domain/
│   │   ├── repositories/  # Repository interfaces
│   ├── modules/           # Screens and sections
│   ├── routes/            # Route management
│   ├── theme/             # Theme settings
│   ├── utils/             # Helper functions
│   ├── widgets/           # Reusable components
│   ├── models/            # Data models
│   └── localization/      # Multi-language support
├── main.dart              # Application entry
```

## 🔧 Using the Architecture

Follow these steps to add a new feature:

1. **Domain Layer**: Define the necessary repository interface in `app/domain/repositories`
2. **Data Layer**: Implement the repository in `app/data/repositories`
3. **Presentation Layer**: Create controller, view, and binding components

## 🚀 Deployment

### GitHub Pages

1. `flutter build web --release --base-href "/flutter-web-portfolio/"`
2. Push to the `gh-pages` branch

### Firebase Hosting

1. Install Firebase CLI
2. Run `firebase init` command
3. `flutter build web --release`
4. Run `firebase deploy` command

## 🤝 Contributing

We welcome your contributions! Please open an issue before sending a pull request.

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 📞 Contact

For questions or feedback, [open an issue](https://github.com/yourusername/flutter-web-portfolio/issues) or email me: your.email@example.com

---

⭐ If you like this project, don't forget to give it a star! ⭐
