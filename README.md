# Flutter Web Portfolio

[English](#english) | [Türkçe](#türkçe)

---

# <a name="english"></a>English

A modern, interactive and customizable Flutter Web portfolio template. Create a stunning professional portfolio website with minimal effort.

## Features

- Responsive design that works on mobile, tablet and desktop
- Light/dark theme with smooth transitions
- Multi-language support (English, Turkish, and easily extendable)
- Interactive terminal interface with custom commands
- Animated UI components for engaging user experience
- Easy CV download functionality
- Social media integration
- Cosmic animated background
- Material 3 design principles

## Quick Start Guide

Want to create your own portfolio website in minutes? Follow these steps:

1. **Fork this repository** to your GitHub account
2. **Clone your forked repository**:
   ```bash
   git clone https://github.com/YOUR_USERNAME/flutter-web-portfolio.git
   cd flutter-web-portfolio
   ```
3. **Install dependencies**:
   ```bash
   flutter pub get
   ```
4. **Customize your content**:

   - Edit language files in `/assets/i18n/` to update all text content
   - Replace `/assets/data/cv.pdf` with your own CV
   - Modify theme colors in `lib/app/controllers/theme_controller.dart`
   - Update your personal information and social media links in `lib/app/controllers/language_controller.dart`
   - Replace images in `/assets/images/` with your own photos

5. **Test your changes**:

   ```bash
   flutter run -d chrome
   ```

6. **Deploy to GitHub Pages**:
   ```bash
   flutter build web --base-href /flutter-web-portfolio/
   ```
   - Create a new branch called `gh-pages`
   - Copy the contents of the `build/web` directory to this branch
   - Push the branch to GitHub
   - Enable GitHub Pages in your repository settings to use the `gh-pages` branch

Alternatively, you can deploy to Firebase Hosting:

```bash
flutter build web
firebase init hosting
firebase deploy
```

## Advanced Customization

### Adding New Language

1. Create a new JSON file in `/assets/i18n/` (e.g., `es.json` for Spanish)
2. Copy the content from `en.json` and translate the values
3. Add the new language option in `lib/app/controllers/language_controller.dart`

### Modifying Sections

- All portfolio sections are located in `lib/app/modules/home/sections/`
- Each section is a standalone widget that you can modify or replace

### Adding New Terminal Commands

- Open `lib/app/modules/home/sections/about_section.dart`
- Add your custom command to the `_availableCommands` list
- Create a new method to handle your command and add it to the `_executeCommand` method

## Deployment Options

### GitHub Pages (Free)

1. Build your web app with the correct base URL:
   ```
   flutter build web --base-href /REPO_ADINIZ/
   ```
2. Push the contents of the `build/web` directory to the `gh-pages` branch
3. Enable GitHub Pages in your repository settings

### Firebase Hosting (Free tier available)

1. Create a Firebase project at https://console.firebase.google.com/
2. Install Firebase CLI: `npm install -g firebase-tools`
3. Login to Firebase: `firebase login`
4. Initialize hosting:
   ```
   flutter build web
   firebase init hosting
   ```
5. Deploy: `firebase deploy`

### Custom Domain

Both GitHub Pages and Firebase Hosting support custom domains. Follow their documentation to set up your personal domain.

---

# <a name="türkçe"></a>Türkçe

Modern, interaktif ve özelleştirilebilir bir Flutter Web portföy şablonu. Minimal çaba ile etkileyici bir profesyonel portföy web sitesi oluşturun.

## Özellikler

- Mobil, tablet ve masaüstünde çalışan responsive tasarım
- Yumuşak geçişli açık/koyu tema desteği
- Çoklu dil desteği (İngilizce, Türkçe ve kolayca genişletilebilir)
- Özel komutlara sahip interaktif terminal arayüzü
- Kullanıcı deneyimini artıran animasyonlu UI bileşenleri
- Kolay CV indirme fonksiyonu
- Sosyal medya entegrasyonu
- Kozmik animasyonlu arka plan
- Material 3 tasarım prensipleri

## Hızlı Başlangıç Rehberi

Dakikalar içinde kendi portföy sitenizi oluşturmak ister misiniz? Bu adımları izleyin:

1. **Bu repository'yi fork edin** GitHub hesabınıza
2. **Fork ettiğiniz repository'yi klonlayın**:
   ```bash
   git clone https://github.com/KULLANICI_ADINIZ/flutter-web-portfolio.git
   cd flutter-web-portfolio
   ```
3. **Bağımlılıkları yükleyin**:
   ```bash
   flutter pub get
   ```
4. **İçeriğinizi özelleştirin**:

   - `/assets/i18n/` klasöründeki dil dosyalarını düzenleyerek tüm metin içeriğini güncelleyin
   - `/assets/data/cv.pdf` dosyasını kendi CV'niz ile değiştirin
   - `lib/app/controllers/theme_controller.dart` dosyasındaki tema renklerini değiştirin
   - `lib/app/controllers/language_controller.dart` dosyasındaki kişisel bilgilerinizi ve sosyal medya bağlantılarınızı güncelleyin
   - `/assets/images/` klasöründeki görselleri kendi fotoğraflarınızla değiştirin

5. **Değişikliklerinizi test edin**:

   ```bash
   flutter run -d chrome
   ```

6. **GitHub Pages'e deploy edin**:
   ```bash
   flutter build web --base-href /flutter-web-portfolio/
   ```
   - `gh-pages` adında yeni bir branch oluşturun
   - `build/web` dizininin içeriğini bu branch'e kopyalayın
   - Branch'i GitHub'a push edin
   - Repository ayarlarınızdan GitHub Pages'i etkinleştirin ve `gh-pages` branch'ini kullanın

Alternatif olarak, Firebase Hosting'e deploy edebilirsiniz:

```bash
flutter build web
firebase init hosting
firebase deploy
```

## İleri Düzey Özelleştirme

### Yeni Dil Ekleme

1. `/assets/i18n/` klasöründe yeni bir JSON dosyası oluşturun (örn. İspanyolca için `es.json`)
2. `en.json` dosyasının içeriğini kopyalayın ve değerleri çevirin
3. `lib/app/controllers/language_controller.dart` dosyasına yeni dil seçeneğini ekleyin

### Bölümleri Değiştirme

- Tüm portföy bölümleri `lib/app/modules/home/sections/` klasöründe bulunur
- Her bölüm, değiştirebileceğiniz veya değiştirebileceğiniz bağımsız bir widget'tır

### Yeni Terminal Komutları Ekleme

- `lib/app/modules/home/sections/about_section.dart` dosyasını açın
- Özel komutunuzu `_availableCommands` listesine ekleyin
- Komutunuzu işlemek için yeni bir metot oluşturun ve `_executeCommand` metoduna ekleyin

## Yayınlama Seçenekleri

### GitHub Pages (Ücretsiz)

1. Web uygulamanızı doğru temel URL ile build edin:
   ```
   flutter build web --base-href /REPO_ADINIZ/
   ```
2. `build/web` dizininin içeriğini `gh-pages` branch'ine push edin
3. Repository ayarlarınızdan GitHub Pages'i etkinleştirin

### Firebase Hosting (Ücretsiz katman mevcut)

1. https://console.firebase.google.com/ adresinden bir Firebase projesi oluşturun
2. Firebase CLI'yi yükleyin: `npm install -g firebase-tools`
3. Firebase'e giriş yapın: `firebase login`
4. Hosting'i başlatın:
   ```
   flutter build web
   firebase init hosting
   ```
5. Deploy edin: `firebase deploy`

### Özel Domain

Hem GitHub Pages hem de Firebase Hosting özel alan adlarını destekler. Kişisel alan adınızı ayarlamak için dokümantasyonlarını takip edin.

## Lisans

Bu proje MIT lisansı altında lisanslanmıştır - detaylar için [LICENSE](LICENSE) dosyasına bakın.
