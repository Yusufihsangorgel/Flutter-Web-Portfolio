import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'dart:async';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:flutter_web_portfolio/app/controllers/app_bindings.dart';
import 'package:flutter_web_portfolio/app/controllers/theme_controller.dart';
import 'package:flutter_web_portfolio/app/controllers/language_controller.dart';
import 'package:flutter_web_portfolio/app/routes/app_pages.dart';
import 'package:flutter_web_portfolio/app/widgets/loading_animation.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_web_portfolio/app/widgets/mouse_effects.dart';
import 'package:flutter_i18n/flutter_i18n.dart';
import 'package:flutter_i18n/loaders/decoders/json_decode_strategy.dart';
import 'package:flutter_i18n/loaders/file_translation_loader.dart';

// Dil değiştirme widget'ı
class LanguageSwitcher extends StatelessWidget {
  const LanguageSwitcher({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final languageController = Get.find<LanguageController>();

    return Obx(() {
      return PopupMenuButton<String>(
        offset: const Offset(0, 40),
        icon: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              languageController.languageInfo['flag'] ?? '🌐',
              style: const TextStyle(fontSize: 24),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.arrow_drop_down, color: Colors.white),
          ],
        ),
        color: Colors.grey[900],
        onSelected: (String languageCode) {
          languageController.changeLanguage(languageCode);
        },
        itemBuilder: (BuildContext context) {
          return LanguageController.supportedLanguages.keys.map((
            String languageCode,
          ) {
            final languageName = LanguageController.getLanguageName(
              languageCode,
            );
            final flag = LanguageController.getLanguageFlag(languageCode);

            return PopupMenuItem<String>(
              value: languageCode,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Text(flag, style: const TextStyle(fontSize: 24)),
                  const SizedBox(width: 12),
                  Text(
                    languageName,
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight:
                          languageController.currentLanguage == languageCode
                              ? FontWeight.bold
                              : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            );
          }).toList();
        },
      );
    });
  }
}

void main() {
  // Zone hatalarını önlemek için aynı zone'da tüm işlemleri gerçekleştir
  runZonedApp();
}

void runZonedApp() {
  // Flutter bağlantılarını başlat
  WidgetsFlutterBinding.ensureInitialized();

  // Hata ayıklama için
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    debugPrint('Flutter Error: ${details.exception}');
  };

  // Controller bağlamalarını başlat
  AppBindings().dependencies();

  // Loading controller'ı oluştur
  final loadingController = Get.put(LoadingController(), permanent: true);

  // Sistem UI ayarları
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
    ),
  );

  // Uygulama başlatma işlemi
  initializeApp(loadingController).then((_) {
    runApp(const MyApp());
  });
}

/// Uygulama başlatma işlemi
Future<void> initializeApp(LoadingController loadingController) async {
  try {
    // Native splash ekranını tutmaya devam et (arka planda veriler yüklenirken)
    // Web platformunda bu çağrıyı atlıyoruz
    if (!kIsWeb) {
      try {
        FlutterNativeSplash.preserve(widgetsBinding: WidgetsBinding.instance);
      } catch (e) {
        debugPrint("Native splash preserve error: $e");
      }
    }

    // Uygulama verilerinin yüklenmesini bekle
    final languageController = Get.find<LanguageController>();
    await languageController.loadSavedLanguage();

    // Tema verilerinin yüklenmesini bekle - tema zaten ThemeController'da yükleniyor
    // ThemeController'ın GetX dependency injection ile initialize olmasını bekle
    await Future.delayed(const Duration(milliseconds: 300));

    // Ek kaynakları yükle - örneğin ön bellekleme, önceden hesaplama vb.
    await _preloadAdditionalResources();

    // Web için yükleme ekranını biraz daha göster (kullanıcı deneyimi için)
    await Future.delayed(const Duration(seconds: 1));

    // Native splash ekranını kaldır, artık uygulama hazır
    // Web platformunda bu çağrıyı atlıyoruz
    if (!kIsWeb) {
      try {
        FlutterNativeSplash.remove();
      } catch (e) {
        debugPrint("Native splash removal error: $e");
      }
    }
  } catch (e) {
    debugPrint("Loading error: $e");
  } finally {
    // Yükleme tamamlandı
    loadingController._isLoading.value = false;
  }
}

/// Ek kaynakları yükle
Future<void> _preloadAdditionalResources() async {
  // Önceden yüklenecek görseller, veriler vs.
  try {
    // Örnek: Kritik görsellerin önbelleğe alınması
    // precacheImage(AssetImage('assets/images/example.png'), Get.context!);

    // Diğer asenkron yükleme işlemleri burada yapılabilir
    await Future.delayed(const Duration(milliseconds: 200));
  } catch (e) {
    debugPrint("Preload error: $e");
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeController = Get.find<ThemeController>();
    final languageController = Get.find<LanguageController>();
    final loadingController = Get.find<LoadingController>();

    return Obx(() {
      return GetMaterialApp(
        title: languageController.appName,
        debugShowCheckedModeBanner: false,
        theme: themeController.darkTheme, // Sadece koyu tema kullan
        darkTheme: themeController.darkTheme,
        themeMode: ThemeMode.dark, // Her zaman koyu tema
        locale: languageController.currentLocale,
        fallbackLocale: const Locale('tr'),

        // i18n yapılandırması
        localizationsDelegates: [
          FlutterI18nDelegate(
            translationLoader: FileTranslationLoader(
              fallbackFile: 'tr',
              basePath: 'assets/i18n',
              forcedLocale: languageController.currentLocale,
              decodeStrategies: [JsonDecodeStrategy()],
            ),
            missingTranslationHandler: (key, locale) {
              debugPrint('--- Missing translation: $key, locale: $locale');
            },
          ),
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],

        // Desteklenen diller
        supportedLocales: LanguageController.supportedLanguages.values.toList(),
        getPages: AppPages.routes,
        initialRoute: AppPages.initial,
        defaultTransition: Transition.fadeIn,

        // Responsive tasarım ve fare efekti ekleme
        builder: (context, child) {
          // Flutter I18n delegate ile sar
          final wrappedApp = FlutterI18n.rootAppBuilder()(context, child);

          // Yükleme ekranı kontrol
          final themedWidget = Container(
            color: themeController.backgroundColor,
            child:
                loadingController.isLoading
                    ? const LoadingAnimation()
                    : _buildResponsiveWrapper(context, wrappedApp),
          );

          // Web olmayan platformlar için fare efekti eklemeyelim
          if (!kIsWeb) return themedWidget;

          // Web için fare efekti wrapper'ını ekleyelim
          return MouseInteractionWrapper(child: themedWidget);
        },
      );
    });
  }

  // Responsive tasarım için bir wrapper
  Widget _buildResponsiveWrapper(BuildContext context, Widget? child) {
    return MediaQuery(
      // Ekran boyutuna göre metin ölçeğini ayarla
      data: MediaQuery.of(context).copyWith(
        textScaleFactor: MediaQuery.of(context).size.width <= 600 ? 0.9 : 1.0,
      ),
      child: child ?? Container(),
    );
  }
}

/// Fare etkileşimlerini yöneten wrapper widget
class MouseInteractionWrapper extends StatelessWidget {
  final Widget child;

  const MouseInteractionWrapper({Key? key, required this.child})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Tema kontrolcüsü
    final ThemeController themeController = Get.find<ThemeController>();

    // Fare ışığı rengi
    final Color lightColor = themeController.primaryColor;

    // Fare takip eden ışık efekti
    return MouseLight(
      lightColor: lightColor,
      lightSize: 300, // Işık boyutu
      intensity: 0.15, // Işık yoğunluğu
      child: child,
    );
  }
}

/// Uygulamanın yükleme sürecini yöneten controller
class LoadingController extends GetxController {
  final RxBool _isLoading = true.obs;
  bool get isLoading => _isLoading.value;
}
