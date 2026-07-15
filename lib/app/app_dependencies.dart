import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:flutter_web_portfolio/app/controllers/scene_director.dart';
import 'package:flutter_web_portfolio/app/controllers/scroll_controller.dart';
import 'package:flutter_web_portfolio/app/data/providers/assets_provider.dart';
import 'package:flutter_web_portfolio/app/data/providers/local_storage_provider.dart';
import 'package:flutter_web_portfolio/app/data/repositories/language_repository_impl.dart';
import 'package:flutter_web_portfolio/app/features/language/application/language_cubit.dart';

/// Explicit, application-owned dependency graph.
///
/// Construction order and disposal order are visible here. No global service
/// locator or hidden registration lifecycle is involved.
final class AppDependencies {
  AppDependencies._({
    required this.languageCubit,
    required this.scrollController,
    required this.sceneDirector,
  });

  final LanguageCubit languageCubit;
  final AppScrollController scrollController;
  final SceneDirector sceneDirector;

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

    return AppDependencies._(
      languageCubit: languageCubit,
      scrollController: scrollController,
      sceneDirector: sceneDirector,
    );
  }

  Future<void> dispose() async {
    await sceneDirector.close();
    await scrollController.close();
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
  Widget build(BuildContext context) => MultiBlocProvider(
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
    ],
    child: widget.child,
  );
}
