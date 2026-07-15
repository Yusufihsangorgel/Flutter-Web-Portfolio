import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:flutter_web_portfolio/app/controllers/scene_director.dart';
import 'package:flutter_web_portfolio/app/controllers/scroll_controller.dart';
import 'package:flutter_web_portfolio/app/data/providers/assets_provider.dart';
import 'package:flutter_web_portfolio/app/data/providers/local_storage_provider.dart';
import 'package:flutter_web_portfolio/app/data/repositories/language_repository_impl.dart';
import 'package:flutter_web_portfolio/app/data/repositories/portfolio_repository_impl.dart';
import 'package:flutter_web_portfolio/app/domain/models/portfolio_document.dart';
import 'package:flutter_web_portfolio/app/features/language/application/language_cubit.dart';
import 'package:flutter_web_portfolio/app/features/render_quality/application/render_quality_controller.dart';
import 'package:flutter_web_portfolio/app/narrative/domain/narrative_document.dart';
import 'package:flutter_web_portfolio/app/utils/render_quality_sync.dart';

/// Explicit, application-owned dependency graph.
///
/// Construction order and disposal order are visible here. No global service
/// locator or hidden registration lifecycle is involved.
final class AppDependencies {
  AppDependencies._({
    required this.languageCubit,
    required this.portfolio,
    required this.narrative,
    required this.scrollController,
    required this.sceneDirector,
    required this.renderQualityController,
  });

  final LanguageCubit languageCubit;
  final PortfolioDocument portfolio;
  final NarrativeDocument narrative;
  final AppScrollController scrollController;
  final SceneDirector sceneDirector;
  final RenderQualityController renderQualityController;

  static Future<AppDependencies> bootstrap() async {
    final assetsProvider = AssetsProvider();
    final portfolio = await PortfolioRepositoryImpl(
      assetsProvider: assetsProvider,
    ).load();
    final narrative = NarrativeDocument.fromJson(
      await assetsProvider.loadNarrative(),
    ).forActiveSections(portfolio.activeSections);
    final storageProvider = await LocalStorageProvider().init();
    final languageRepository = LanguageRepositoryImpl(
      assetsProvider: assetsProvider,
      localStorageProvider: storageProvider,
    );
    final languageCubit = LanguageCubit(languageRepository: languageRepository);
    await languageCubit.initialize();

    final scrollController = AppScrollController(narrative: narrative);
    final sceneDirector = SceneDirector(scrollController: scrollController);
    final renderQualityController = RenderQualityController()
      ..startMonitoring();
    syncRenderQualityAttributes(
      quality: renderQualityController.state.quality.name,
      reason: renderQualityController.state.reason.name,
    );

    return AppDependencies._(
      languageCubit: languageCubit,
      portfolio: portfolio,
      narrative: narrative,
      scrollController: scrollController,
      sceneDirector: sceneDirector,
      renderQualityController: renderQualityController,
    );
  }

  Future<void> dispose() async {
    await renderQualityController.close();
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
  Widget build(BuildContext context) =>
      RepositoryProvider<PortfolioDocument>.value(
        value: widget.dependencies.portfolio,
        child: RepositoryProvider<NarrativeDocument>.value(
          value: widget.dependencies.narrative,
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
              BlocProvider<RenderQualityController>.value(
                value: widget.dependencies.renderQualityController,
              ),
            ],
            child: BlocListener<RenderQualityController, RenderQualityState>(
              listenWhen: (previous, current) =>
                  previous.quality != current.quality ||
                  previous.reason != current.reason ||
                  previous.reducedMotion != current.reducedMotion,
              listener: (context, state) => syncRenderQualityAttributes(
                quality: state.quality.name,
                reason: state.reason.name,
              ),
              child: widget.child,
            ),
          ),
        ),
      );
}
