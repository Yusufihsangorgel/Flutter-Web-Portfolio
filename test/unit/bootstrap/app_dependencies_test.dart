import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_web_portfolio/app/app_dependencies.dart';
import 'package:flutter_web_portfolio/app/controllers/scene_director.dart';
import 'package:flutter_web_portfolio/app/controllers/scroll_controller.dart';
import 'package:flutter_web_portfolio/app/core/logging/app_logger.dart';
import 'package:flutter_web_portfolio/app/features/language/application/language_cubit.dart';
import 'package:flutter_web_portfolio/app/features/render_quality/application/render_quality_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  testWidgets('provides and closes the bootstrapped state owners', (
    tester,
  ) async {
    final dependencies = await AppDependencies.bootstrap(logger: _FakeLogger());
    final provided = <Type, Object>{};
    final closed = <Future<void>>[
      expectLater(dependencies.languageCubit.stream, emitsDone),
      expectLater(dependencies.scrollController.stream, emitsDone),
      expectLater(dependencies.sceneDirector.stream, emitsDone),
      expectLater(dependencies.renderQualityController.stream, emitsDone),
    ];

    try {
      await tester.pumpWidget(
        AppRuntime(
          dependencies: dependencies,
          child: Builder(
            builder: (context) {
              provided[LanguageCubit] = context.read<LanguageCubit>();
              provided[AppScrollController] = context
                  .read<AppScrollController>();
              provided[SceneDirector] = context.read<SceneDirector>();
              provided[RenderQualityController] = context
                  .read<RenderQualityController>();
              return const SizedBox.shrink();
            },
          ),
        ),
      );

      expect(provided[LanguageCubit], same(dependencies.languageCubit));
      expect(
        provided[AppScrollController],
        same(dependencies.scrollController),
      );
      expect(provided[SceneDirector], same(dependencies.sceneDirector));
      expect(
        provided[RenderQualityController],
        same(dependencies.renderQualityController),
      );
    } finally {
      await tester.pumpWidget(const SizedBox.shrink());
      await Future.wait(closed);
    }

    expect(dependencies.languageCubit.isClosed, isTrue);
    expect(dependencies.scrollController.isClosed, isTrue);
    expect(dependencies.sceneDirector.isClosed, isTrue);
    expect(dependencies.renderQualityController.isClosed, isTrue);
  });
}

final class _FakeLogger implements AppLogger {
  @override
  void info(String message, {Object? error, StackTrace? stackTrace}) {}

  @override
  void warning(String message, {Object? error, StackTrace? stackTrace}) {}

  @override
  void error(String message, {Object? error, StackTrace? stackTrace}) {}
}
