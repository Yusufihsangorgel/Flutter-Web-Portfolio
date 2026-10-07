import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_web_portfolio/app/app_dependencies.dart';
import 'package:flutter_web_portfolio/app/controllers/scene_director.dart';
import 'package:flutter_web_portfolio/app/controllers/scroll_controller.dart';
import 'package:flutter_web_portfolio/app/features/language/application/language_cubit.dart';
import 'package:flutter_web_portfolio/app/features/render_quality/application/render_quality_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../support/fake_app_logger.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  test(
    'dispose closes every state owner and leaves no timer running',
    () async {
      final timers = _TimerLedger();
      final dependencies = await timers.track(
        () => AppDependencies.bootstrap(logger: FakeAppLogger()),
      );
      expect(
        _owners(dependencies).map((owner) => owner.isClosed),
        everyElement(isFalse),
      );

      await timers.track(dependencies.dispose);

      expect(
        _owners(dependencies).map((owner) => owner.isClosed),
        everyElement(isTrue),
      );
      expect(timers.active, isEmpty);
      expect(
        () => dependencies.scrollController.scrollController.addListener(() {}),
        throwsFlutterError,
      );
      expect(
        () =>
            dependencies.scrollController.narrativePosition.addListener(() {}),
        throwsFlutterError,
      );
    },
  );

  testWidgets('AppRuntime provides the bootstrapped state owners and closes them '
      'on unmount', (tester) async {
    // Assets and preferences load through real I/O, not the fake clock.
    final dependencies = (await tester.runAsync(
      () => AppDependencies.bootstrap(logger: FakeAppLogger()),
    ))!;
    final provided = <Type, Object>{};

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
      // Unmount in real time: the close chain awaits futures bootstrap made there.
      await tester.runAsync(() => _unmountAndAwaitClose(tester, dependencies));
    }

    expect(
      _owners(dependencies).map((owner) => owner.isClosed),
      everyElement(isTrue),
    );
  });
}

List<BlocBase<Object?>> _owners(AppDependencies dependencies) => [
  dependencies.languageCubit,
  dependencies.scrollController,
  dependencies.sceneDirector,
  dependencies.renderQualityController,
];

Future<void> _unmountAndAwaitClose(
  WidgetTester tester,
  AppDependencies dependencies,
) async {
  // drain, not expectLater: an owner that never closes must fail, not stall.
  final closed = <Future<void>>[
    for (final owner in _owners(dependencies)) owner.stream.drain<void>(),
  ];
  await tester.pumpWidget(const SizedBox.shrink());
  await Future.wait(closed).timeout(
    const Duration(seconds: 5),
    onTimeout: () => fail('Unmounting AppRuntime left a state owner open.'),
  );
}

/// Records the timers a zone creates so a test can assert none outlives dispose.
final class _TimerLedger {
  final _timers = <Timer>[];

  Iterable<Timer> get active => _timers.where((timer) => timer.isActive);

  Future<T> track<T>(Future<T> Function() body) => runZoned(
    body,
    zoneSpecification: ZoneSpecification(
      createTimer: (self, parent, zone, duration, callback) =>
          _record(parent.createTimer(zone, duration, callback)),
      createPeriodicTimer: (self, parent, zone, period, callback) =>
          _record(parent.createPeriodicTimer(zone, period, callback)),
    ),
  );

  Timer _record(Timer timer) {
    _timers.add(timer);
    return timer;
  }
}
