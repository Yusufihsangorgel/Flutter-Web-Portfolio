import 'dart:async';
import 'dart:developer' as dev;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:flutter_i18n/flutter_i18n.dart';
import 'package:flutter_i18n/loaders/decoders/json_decode_strategy.dart';
import 'package:get/get.dart';

import 'package:flutter_web_portfolio/app/bindings/app_bindings.dart';
import 'package:flutter_web_portfolio/app/controllers/theme_controller.dart';
import 'package:flutter_web_portfolio/app/controllers/language_controller.dart';
import 'package:flutter_web_portfolio/app/routes/app_pages.dart';
import 'package:flutter_web_portfolio/app/widgets/loading_animation.dart';
import 'package:flutter_web_portfolio/app/widgets/mouse_interaction_wrapper.dart';

void main() {
  runZonedGuarded(
    () {
      WidgetsFlutterBinding.ensureInitialized();

      FlutterError.onError = (FlutterErrorDetails details) {
        FlutterError.presentError(details);
        dev.log('Flutter error', name: 'Main', error: details.exception);
      };

      AppBindings().dependencies();

      final loadingController = Get.put(LoadingController(), permanent: true);

      SystemChrome.setSystemUIOverlayStyle(
        const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
          statusBarBrightness: Brightness.light,
        ),
      );

      initializeApp(loadingController).then((_) {
        runApp(const MyApp());
      });
    },
    (error, stack) {
      dev.log('Uncaught error', name: 'Main', error: error, stackTrace: stack);
    },
  );
}

class LoadingController extends GetxController {
  final RxBool _isLoading = true.obs;
  bool get isLoading => _isLoading.value;

  void setLoading(bool loading) {
    _isLoading.value = loading;
  }
}

Future<void> initializeApp(LoadingController loadingController) async {
  try {
    if (!kIsWeb) {
      try {
        FlutterNativeSplash.preserve(widgetsBinding: WidgetsBinding.instance);
      } catch (_) {}
    }

    Get.find<ThemeController>();

    try {
      final languageController = Get.find<LanguageController>();
      await languageController.loadSavedLanguage();
    } catch (_) {}

    if (!kIsWeb) {
      try {
        FlutterNativeSplash.remove();
      } catch (_) {}
    }
  } catch (e) {
    dev.log('App initialization failed', name: 'Main', error: e);
  } finally {
    loadingController.setLoading(false);
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeController = Get.find<ThemeController>();
    final loadingController = Get.find<LoadingController>();

    return Obx(() {
      Locale currentLocale = const Locale('tr');
      String appTitle = 'Portfolio';

      try {
        final languageController = Get.find<LanguageController>();
        currentLocale = languageController.currentLocale;
        appTitle = languageController.appName;
      } catch (_) {}

      return GetMaterialApp(
        title: appTitle,
        debugShowCheckedModeBanner: false,
        theme: themeController.darkTheme,
        darkTheme: themeController.darkTheme,
        themeMode: ThemeMode.dark,
        locale: currentLocale,
        fallbackLocale: const Locale('tr'),
        localizationsDelegates: [
          FlutterI18nDelegate(
            translationLoader: FileTranslationLoader(
              fallbackFile: 'tr',
              basePath: 'assets/i18n',
              forcedLocale: currentLocale,
              decodeStrategies: [JsonDecodeStrategy()],
            ),
          ),
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [
          Locale('tr'),
          Locale('en'),
          Locale('de'),
          Locale('fr'),
          Locale('es'),
        ],
        getPages: AppPages.routes,
        initialRoute: AppPages.initial,
        defaultTransition: Transition.fadeIn,
        builder: (context, child) {
          final wrappedApp = FlutterI18n.rootAppBuilder()(context, child);

          final content = Container(
            color: loadingController.isLoading
                ? themeController.backgroundColor
                : Colors.transparent,
            child: loadingController.isLoading
                ? const LoadingAnimation()
                : _buildResponsiveWrapper(context, wrappedApp),
          );

          if (!kIsWeb) return content;
          return MouseInteractionWrapper(child: content);
        },
      );
    });
  }

  Widget _buildResponsiveWrapper(BuildContext context, Widget? child) => MediaQuery(
      data: MediaQuery.of(context).copyWith(
        textScaler: TextScaler.linear(
          MediaQuery.of(context).size.width <= 600 ? 0.9 : 1.0,
        ),
      ),
      child: child ?? const SizedBox.shrink(),
    );
}
