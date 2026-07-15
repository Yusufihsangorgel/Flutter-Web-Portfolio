import 'dart:async';
import 'dart:developer' as dev;

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_bloc/flutter_bloc.dart' show BlocBuilder, BlocProvider;

import 'package:flutter_web_portfolio/app/app_dependencies.dart';
import 'package:flutter_web_portfolio/app/features/language/application/language_cubit.dart';
import 'package:flutter_web_portfolio/app/core/theme/app_theme.dart';
import 'package:flutter_web_portfolio/app/modules/home/home_view.dart';
import 'package:flutter_web_portfolio/app/utils/web_url_strategy.dart'
    as url_strategy;

void main() {
  runZonedGuarded(
    () async {
      WidgetsFlutterBinding.ensureInitialized();
      // Force the semantics tree to stay populated — screen readers and
      // Playwright semantics snapshots both rely on this on Flutter Web.
      SemanticsBinding.instance.ensureSemantics();

      FlutterError.onError = (FlutterErrorDetails details) {
        FlutterError.presentError(details);
        dev.log('Flutter error', name: 'Main', error: details.exception);
      };

      SystemChrome.setSystemUIOverlayStyle(
        const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
          statusBarBrightness: Brightness.dark,
        ),
      );

      try {
        final dependencies = await AppDependencies.bootstrap();
        runApp(AppRuntime(dependencies: dependencies, child: const MyApp()));
      } catch (error, stackTrace) {
        dev.log(
          'Application bootstrap failed',
          name: 'Main',
          error: error,
          stackTrace: stackTrace,
        );
        runApp(const _BootstrapFailureApp());
      }
    },
    (error, stack) {
      dev.log('Uncaught error', name: 'Main', error: error, stackTrace: stack);
    },
  );
}

class _BootstrapFailureApp extends StatelessWidget {
  const _BootstrapFailureApp();

  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: AppTheme.dark,
    home: Scaffold(
      backgroundColor: const Color(0xFF00101F),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.sync_problem_rounded,
                  size: 42,
                  color: Color(0xFF12B8D0),
                ),
                const SizedBox(height: 20),
                Text(
                  'The experience could not start',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 10),
                Text(
                  'No data was changed. Reload the page to try the bootstrap sequence again.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                if (kIsWeb) ...[
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: url_strategy.reloadPage,
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('Reload page'),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

/// Root application widget.
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) =>
      BlocBuilder<LanguageCubit, LanguageState>(
        builder: (context, state) {
          final languageCubit = BlocProvider.of<LanguageCubit>(context);
          final currentLocale = state.locale;
          final appTitle = languageCubit.appName;

          return MaterialApp(
            title: appTitle,
            debugShowCheckedModeBanner: false,
            theme: AppTheme.dark,
            darkTheme: AppTheme.dark,
            themeMode: ThemeMode.dark,
            locale: currentLocale,
            localizationsDelegates: [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
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
            home: const HomeView(),
          );
        },
      );
}
