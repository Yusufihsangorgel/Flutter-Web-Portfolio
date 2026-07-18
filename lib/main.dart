import 'dart:async';
import 'dart:developer' as dev;

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_bloc/flutter_bloc.dart'
    show BlocBuilder, RepositoryProvider;

import 'package:flutter_web_portfolio/app/app_dependencies.dart';
import 'package:flutter_web_portfolio/app/features/language/application/language_cubit.dart';
import 'package:flutter_web_portfolio/app/core/theme/app_theme.dart';
import 'package:flutter_web_portfolio/app/domain/models/portfolio_document.dart';
import 'package:flutter_web_portfolio/app/data/providers/bundle_asset_loader.dart';
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
          statusBarIconBrightness: Brightness.dark,
          statusBarBrightness: Brightness.light,
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
        final languageCode = url_strategy.getHtmlLanguage();
        final copy = await _loadBootstrapFailureCopy(languageCode);
        runApp(_BootstrapFailureApp(languageCode: languageCode, copy: copy));
      }
    },
    (error, stack) {
      dev.log('Uncaught error', name: 'Main', error: error, stackTrace: stack);
    },
  );
}

Future<_BootstrapFailureCopy> _loadBootstrapFailureCopy(
  String languageCode,
) async {
  try {
    final catalog = await BundleAssetLoader().loadTranslations(languageCode);
    final accessibility = catalog['accessibility'];
    if (accessibility is Map<String, dynamic>) {
      final title = accessibility['load_failure'];
      final retry = accessibility['retry'];
      if (title is String &&
          title.trim().isNotEmpty &&
          retry is String &&
          retry.trim().isNotEmpty) {
        return _BootstrapFailureCopy(title.trim(), retry.trim());
      }
    }
  } on Object catch (error, stackTrace) {
    dev.log(
      'Failed to localize bootstrap recovery',
      name: 'Main',
      error: error,
      stackTrace: stackTrace,
    );
  }
  return const _BootstrapFailureCopy(
    'The portfolio could not load. Please try again.',
    'Retry',
  );
}

@immutable
final class _BootstrapFailureCopy {
  const _BootstrapFailureCopy(this.message, this.retry);

  final String message;
  final String retry;
}

class _BootstrapFailureApp extends StatelessWidget {
  const _BootstrapFailureApp({required this.languageCode, required this.copy});

  final String languageCode;
  final _BootstrapFailureCopy copy;

  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: AppTheme.light,
    locale: Locale(languageCode),
    localizationsDelegates: const [
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
    ],
    supportedLocales: [Locale(languageCode)],
    home: Scaffold(
      backgroundColor: const Color(0xFFF2EEE5),
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
                  color: Color(0xFF1E51FF),
                ),
                const SizedBox(height: 20),
                Text(
                  copy.message,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                if (kIsWeb) ...[
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: url_strategy.reloadPage,
                    icon: const Icon(Icons.refresh_rounded),
                    label: Text(copy.retry),
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
          final currentLocale = state.locale;
          final portfolio = RepositoryProvider.of<PortfolioDocument>(context);
          final appTitle = portfolio.site.title;

          return MaterialApp(
            title: appTitle,
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light,
            themeMode: ThemeMode.light,
            locale: currentLocale,
            localizationsDelegates: [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
            ],
            supportedLocales: [
              for (final locale in portfolio.site.locales) Locale(locale),
            ],
            home: const HomeView(),
          );
        },
      );
}
