import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_web_portfolio/app/controllers/scene_director.dart';
import 'package:flutter_web_portfolio/app/controllers/scroll_controller.dart';
import 'package:flutter_web_portfolio/app/widgets/narrative_stage.dart';

import '../helpers/narrative_fixture.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

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
