import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_web_portfolio/app/controllers/scene_director.dart';
import 'package:flutter_web_portfolio/app/controllers/scroll_controller.dart';
import 'package:flutter_web_portfolio/app/core/constants/app_dimensions.dart';
import 'package:flutter_web_portfolio/app/widgets/narrative_stage.dart';

import '../helpers/narrative_fixture.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('keeps the 390px hero trace outside its text column', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    final scroll = AppScrollController(narrative: loadNarrativeFixture());
    final scenes = SceneDirector(scrollController: scroll);
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.binding.setSurfaceSize(null);
      await scenes.close();
      await scroll.close();
    });

    for (final direction in TextDirection.values) {
      await tester.pumpWidget(
        MultiRepositoryProvider(
          providers: [
            RepositoryProvider<AppScrollController>.value(value: scroll),
            RepositoryProvider<SceneDirector>.value(value: scenes),
          ],
          child: MaterialApp(
            home: Directionality(
              textDirection: direction,
              child: const Stack(children: [NarrativeStage()]),
            ),
          ),
        ),
      );

      final stage = find.byKey(const ValueKey('narrative-stage'));
      final clip = tester.widget<ClipRect>(
        find.ancestor(of: stage, matching: find.byType(ClipRect)).first,
      );
      final drawingBounds = clip.clipper!.getClip(const Size(390, 844));
      const gutter = AppDimensions.sectionPaddingMobile;
      const heroTextColumn = Rect.fromLTRB(gutter, 0, 390 - gutter, 844);
      expect(drawingBounds.intersect(heroTextColumn).isEmpty, isTrue);
    }
  });

  for (final direction in TextDirection.values) {
    testWidgets(
      'stays decorative and pointer-transparent in ${direction.name}',
      (tester) async {
        final scroll = AppScrollController(narrative: loadNarrativeFixture());
        final scenes = SceneDirector(scrollController: scroll);
        addTearDown(() async {
          await tester.pumpWidget(const SizedBox.shrink());
          await scenes.close();
          await scroll.close();
        });

        await tester.pumpWidget(
          MultiRepositoryProvider(
            providers: [
              RepositoryProvider<AppScrollController>.value(value: scroll),
              RepositoryProvider<SceneDirector>.value(value: scenes),
            ],
            child: MaterialApp(
              home: Directionality(
                textDirection: direction,
                child: const Stack(children: [NarrativeStage()]),
              ),
            ),
          ),
        );
        await tester.pump();

        final stage = find.byKey(const ValueKey('narrative-stage'));
        expect(stage, findsOneWidget);
        expect(
          find.ancestor(
            of: stage,
            matching: find.byWidgetPredicate(
              (widget) => widget is IgnorePointer && widget.ignoring,
            ),
          ),
          findsOneWidget,
        );
        expect(
          find.ancestor(of: stage, matching: find.byType(ExcludeSemantics)),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);
      },
    );
  }
}
