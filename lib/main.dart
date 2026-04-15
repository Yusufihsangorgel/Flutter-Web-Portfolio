import 'dart:async';
import 'dart:developer' as dev;

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_i18n/flutter_i18n.dart';
import 'package:flutter_i18n/loaders/decoders/json_decode_strategy.dart';
import 'package:get/get.dart';

import 'package:flutter_web_portfolio/app/bindings/app_bindings.dart';
import 'package:flutter_web_portfolio/app/controllers/loading_controller.dart';
import 'package:flutter_web_portfolio/app/controllers/language_controller.dart';
import 'package:flutter_web_portfolio/app/core/constants/app_colors.dart';
import 'package:flutter_web_portfolio/app/core/theme/app_theme.dart';
import 'package:flutter_web_portfolio/app/routes/app_pages.dart';
import 'package:flutter_web_portfolio/app/widgets/loading_animation.dart';
import 'package:flutter_web_portfolio/app/widgets/mouse_interaction_wrapper.dart';

void main() {
  runZonedGuarded(
    () {
      WidgetsFlutterBinding.ensureInitialized();
      // Force the semantics tree to stay populated — screen readers and
      // Playwright semantics snapshots both rely on this on Flutter Web.
      SemanticsBinding.instance.ensureSemantics();

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
          statusBarIconBrightness: Brightness.light,
          statusBarBrightness: Brightness.dark,
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
    // Intentional console art for visitors inspecting DevTools.
    // ignore: avoid_print
    print('''

 ╔═══════════════════════════════╗
 ║   Flutter Developer Portfolio ║
 ║   Built with Clean Architecture
 ║   ─────────────────────────── ║
 ║   Psst... try Ctrl+K         ║
 ╚═══════════════════════════════╝

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
      var currentLocale = const Locale('en');
      var appTitle = 'Portfolio';
      var textDirection = TextDirection.ltr;

      if (Get.isRegistered<LanguageController>()) {
        final languageController = Get.find<LanguageController>();
        currentLocale = languageController.currentLocale;
        appTitle = languageController.appName;
        // Arabic is RTL
        if (languageController.currentLanguage == 'ar') {
          textDirection = TextDirection.rtl;
        }
      }

      return GetMaterialApp(
        title: appTitle,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.dark,
        darkTheme: AppTheme.dark,
        themeMode: ThemeMode.dark,
        transitionDuration: const Duration(milliseconds: 400),
        locale: currentLocale,
        fallbackLocale: const Locale('en'),
        localizationsDelegates: [
          FlutterI18nDelegate(
            translationLoader: FileTranslationLoader(
              fallbackFile: 'en',
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
          Locale('en'),
          Locale('tr'),
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

          Widget content = Container(
            color: loadingController.isLoading
                ? AppColors.background
                : Colors.transparent,
            child: loadingController.isLoading
                ? const LoadingAnimation()
                : wrappedApp,
          );

          // Wrap with Directionality for RTL languages (Arabic)
          content = Directionality(
            textDirection: textDirection,
            child: content,
          );

          if (!kIsWeb) return content;
          return MouseInteractionWrapper(child: content);
        },
      );
    });
  }
}
