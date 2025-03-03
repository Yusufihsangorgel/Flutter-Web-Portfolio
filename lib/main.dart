import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'dart:async';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:flutter_web_portfolio/app/bindings/app_bindings.dart';
import 'package:flutter_web_portfolio/app/controllers/theme_controller.dart';
import 'package:flutter_web_portfolio/app/controllers/language_controller.dart';
import 'package:flutter_web_portfolio/app/controllers/scroll_controller.dart';
import 'package:flutter_web_portfolio/app/controllers/shared_background_controller.dart';
import 'package:flutter_web_portfolio/app/data/providers/local_storage_provider.dart';
import 'package:flutter_web_portfolio/app/routes/app_pages.dart';
import 'package:flutter_web_portfolio/app/theme/app_theme.dart';
import 'package:flutter_web_portfolio/app/widgets/loading_animation.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_web_portfolio/app/widgets/mouse_effects.dart';
import 'package:flutter_web_portfolio/app/widgets/language_switcher.dart';
import 'package:flutter_web_portfolio/app/widgets/mouse_interaction_wrapper.dart';
import 'package:flutter_i18n/flutter_i18n.dart';
import 'package:flutter_i18n/loaders/decoders/json_decode_strategy.dart';
import 'package:flutter_i18n/loaders/file_translation_loader.dart';

void main() {
  // Zone hatalarını önlemek için aynı zone'da tüm işlemleri gerçekleştir
  runZonedGuarded(
    () {
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
    },
    (error, stack) {
      debugPrint('🔴 Uncaught error: $error');
      debugPrint(stack.toString());
    },
  );
}

/// Yükleme durumunu yöneten controller
class LoadingController extends GetxController {
  final RxBool _isLoading = true.obs;
  bool get isLoading => _isLoading.value;

  void setLoading(bool loading) {
    _isLoading.value = loading;
  }
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

    // Controller'ların başlatıldığından emin ol
    debugPrint("⏳ Controller'lar kontrol ediliyor...");

    // Ek kaynakları yükle - örneğin ön bellekleme, önceden hesaplama vb.
    await _preloadAdditionalResources();

    // Tema kontrolcüsünün hazır olmasını bekle
    final themeController = Get.find<ThemeController>();

    // Dil kontrolcüsü hazır olmayabilir - silent fail
    try {
      final languageController = Get.find<LanguageController>();
      await languageController.loadSavedLanguage();
      debugPrint(
        "✅ Dil ayarları yüklendi: ${languageController.currentLanguage}",
      );
    } catch (e) {
      debugPrint("⚠️ Dil yüklenirken hata: $e");
    }

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
    debugPrint("❌ Loading error: $e");
  } finally {
    // Yükleme tamamlandı
    loadingController.setLoading(false);
    debugPrint("✅ Uygulama yükleme tamamlandı!");
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
    // ThemeController her zaman mevcut olmalı
    final themeController = Get.find<ThemeController>();
    final loadingController = Get.find<LoadingController>();

    return Obx(() {
      // LanguageController bulunamadığında bile uygulama çalışmalı
      Locale currentLocale = const Locale('tr');
      String appTitle = 'Portfolio';

      // LanguageController için hata toleransı
      try {
        final languageController = Get.find<LanguageController>();
        currentLocale = languageController.currentLocale;
        appTitle = languageController.appName;
      } catch (e) {
        debugPrint(
          "⚠️ LanguageController bulunamadı, varsayılan değerler kullanılıyor",
        );
      }

      return GetMaterialApp(
        title: appTitle,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.dark, // Her zaman koyu tema
        locale: currentLocale,
        fallbackLocale: const Locale('tr'),

        // i18n yapılandırması
        localizationsDelegates: [
          FlutterI18nDelegate(
            translationLoader: FileTranslationLoader(
              fallbackFile: 'tr',
              basePath: 'assets/i18n',
              forcedLocale: currentLocale,
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
        supportedLocales: const [
          Locale('tr'),
          Locale('en'),
          Locale('de'),
          Locale('fr'),
          Locale('es'),
        ],

        getPages: AppPages.routes,
        initialRoute: AppPages.INITIAL,
        defaultTransition: Transition.fadeIn,

        // Responsive tasarım ve fare efekti ekleme
        builder: (context, child) {
          // Flutter I18n delegate ile sar
          final wrappedApp = FlutterI18n.rootAppBuilder()(context, child);

          // Yükleme ekranı kontrol
          final themedWidget = Container(
            color:
                loadingController.isLoading
                    ? themeController.backgroundColor
                    : Colors.transparent,
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
