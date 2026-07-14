import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:flutter_web_portfolio/app/controllers/cursor_controller.dart';
import 'package:flutter_web_portfolio/app/controllers/personalization_controller.dart';
import 'package:flutter_web_portfolio/app/controllers/scene_director.dart';
import 'package:flutter_web_portfolio/app/controllers/scroll_controller.dart';
import 'package:flutter_web_portfolio/app/controllers/sound_controller.dart';
import 'package:flutter_web_portfolio/app/data/providers/assets_provider.dart';
import 'package:flutter_web_portfolio/app/data/providers/github_provider.dart';
import 'package:flutter_web_portfolio/app/data/providers/local_storage_provider.dart';
import 'package:flutter_web_portfolio/app/data/providers/medium_provider.dart';
import 'package:flutter_web_portfolio/app/data/repositories/language_repository_impl.dart';
import 'package:flutter_web_portfolio/app/features/language/application/language_cubit.dart';
import 'package:flutter_web_portfolio/app/services/visitor_analytics.dart';

/// Explicit, application-owned dependency graph.
///
/// Construction order and disposal order are visible here. No global service
/// locator or hidden registration lifecycle is involved.
final class AppDependencies {
  AppDependencies._({
    required this.languageCubit,
    required this.scrollController,
    required this.sceneDirector,
    required this.cursorController,
    required this.soundController,
    required this.personalizationController,
    required this.mediumProvider,
    required this.githubProvider,
  });

  final LanguageCubit languageCubit;
  final AppScrollController scrollController;
  final SceneDirector sceneDirector;
  final CursorController cursorController;
  final SoundController soundController;
  final PersonalizationController personalizationController;
  final MediumProvider mediumProvider;
  final GitHubProvider githubProvider;

  static Future<AppDependencies> bootstrap() async {
    final assetsProvider = AssetsProvider();
    final storageProvider = await LocalStorageProvider().init();
    final languageRepository = LanguageRepositoryImpl(
      assetsProvider: assetsProvider,
      localStorageProvider: storageProvider,
    );
    final languageCubit = LanguageCubit(languageRepository: languageRepository);
    await languageCubit.initialize();

    final scrollController = AppScrollController();
    final sceneDirector = SceneDirector(scrollController: scrollController);
    final cursorController = CursorController();
    final soundController = SoundController();
    final personalizationController = PersonalizationController(
      analytics: VisitorAnalytics(storageProvider: storageProvider),
    );

    return AppDependencies._(
      languageCubit: languageCubit,
      scrollController: scrollController,
      sceneDirector: sceneDirector,
      cursorController: cursorController,
      soundController: soundController,
      personalizationController: personalizationController,
      mediumProvider: MediumProvider(),
      githubProvider: GitHubProvider(),
    );
  }

  Future<void> dispose() async {
    await sceneDirector.close();
    await scrollController.close();
    await cursorController.close();
    await soundController.close();
    await personalizationController.close();
    await languageCubit.close();
  }
}

/// Owns the dependency graph and exposes explicit providers to the widget tree.
final class AppRuntime extends StatefulWidget {
  const AppRuntime({
    super.key,
    required this.dependencies,
    required this.child,
  });

  final AppDependencies dependencies;
  final Widget child;

  @override
  State<AppRuntime> createState() => _AppRuntimeState();
}

final class _AppRuntimeState extends State<AppRuntime> {
  @override
  void dispose() {
    unawaited(widget.dependencies.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MultiRepositoryProvider(
    providers: [
      RepositoryProvider<MediumProvider>.value(
        value: widget.dependencies.mediumProvider,
      ),
      RepositoryProvider<GitHubProvider>.value(
        value: widget.dependencies.githubProvider,
      ),
    ],
    child: MultiBlocProvider(
      providers: [
        BlocProvider<LanguageCubit>.value(
          value: widget.dependencies.languageCubit,
        ),
        BlocProvider<AppScrollController>.value(
          value: widget.dependencies.scrollController,
        ),
        BlocProvider<SceneDirector>.value(
          value: widget.dependencies.sceneDirector,
        ),
        BlocProvider<CursorController>.value(
          value: widget.dependencies.cursorController,
        ),
        BlocProvider<SoundController>.value(
          value: widget.dependencies.soundController,
        ),
        BlocProvider<PersonalizationController>.value(
          value: widget.dependencies.personalizationController,
        ),
      ],
      child: widget.child,
    ),
  );
}
