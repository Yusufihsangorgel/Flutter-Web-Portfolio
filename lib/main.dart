import 'dart:async';
import 'dart:developer' as dev;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_i18n/flutter_i18n.dart';
import 'package:flutter_i18n/loaders/decoders/json_decode_strategy.dart';
import 'package:get/get.dart';

import 'package:flutter_web_portfolio/app/bindings/app_bindings.dart';
import 'package:flutter_web_portfolio/app/controllers/loading_controller.dart';
import 'package:flutter_web_portfolio/app/controllers/language_controller.dart';
import 'package:flutter_web_portfolio/app/controllers/theme_controller.dart';
import 'package:flutter_web_portfolio/app/core/constants/app_colors.dart';
import 'package:flutter_web_portfolio/app/core/theme/app_theme.dart';
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

      _printConsoleAsciiArt();

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

void _printConsoleAsciiArt() {
  if (kIsWeb) {
    // ignore: avoid_print
    print('''

 __   __  _______  _______
|  | |  ||       ||       |
|  |_|  ||    ___||    ___|
|       ||   | __ |   | __
|_     _||   ||  ||   ||  |
  |   |  |   |_| ||   |_| |
  |___|  |_______||_______|

  Yusuf Ihsan Gorgel
  Mobile Software Engineer
  -------------------------
  Psst... try Ctrl+K

''');
  }
}

Future<void> initializeApp(LoadingController loadingController) async {
  try {
    final languageController = Get.find<LanguageController>();
    await languageController.loadSavedLanguage();
  } catch (e) {
    dev.log('App initialization failed', name: 'Main', error: e);
  } finally {
    loadingController.setLoading(false);
  }
}

/// Root application widget.
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final loadingController = Get.find<LoadingController>();

    return Obx(() {
      var currentLocale = const Locale('tr');
      var appTitle = 'Portfolio';

      if (Get.isRegistered<LanguageController>()) {
        final languageController = Get.find<LanguageController>();
        currentLocale = languageController.currentLocale;
        appTitle = languageController.appName;
      }

      // Determine active theme from ThemeController
      final isDark = Get.isRegistered<ThemeController>()
          ? Get.find<ThemeController>().isDarkMode.value
          : true;
      final activeTheme = isDark ? AppTheme.dark : AppTheme.light;
      final activeThemeMode = isDark ? ThemeMode.dark : ThemeMode.light;

      return GetMaterialApp(
        title: appTitle,
        debugShowCheckedModeBanner: false,
        theme: activeTheme,
        darkTheme: AppTheme.dark,
        themeMode: activeThemeMode,
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
          Locale('ar'),
          Locale('hi'),
        ],
        getPages: AppPages.routes,
        unknownRoute: AppPages.unknownRoute,
        initialRoute: AppPages.initial,
        defaultTransition: Transition.fadeIn,
        builder: (context, child) {
          final wrappedApp = FlutterI18n.rootAppBuilder()(context, child);

          final content = Container(
            color: loadingController.isLoading
                ? AppColors.background
                : Colors.transparent,
            child: loadingController.isLoading
                ? const LoadingAnimation()
                : wrappedApp,
          );

          if (!kIsWeb) return content;
          return MouseInteractionWrapper(child: content);
        },
      );
    });
  }
}
