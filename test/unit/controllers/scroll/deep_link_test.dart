import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_web_portfolio/app/controllers/scroll/browser_history.dart';
import 'package:flutter_web_portfolio/app/controllers/scroll_controller.dart';
import 'package:flutter_web_portfolio/app/narrative/domain/narrative_document.dart';

import '../../../helpers/narrative_fixture.dart';

final class FakeBrowserHistory implements BrowserHistory {
  FakeBrowserHistory(this.hash);

  @override
  String hash;
  String reloadSection = '';
  final pushes = <String>[];
  final replacements = <String>[];
  void Function(String)? _listener;

  @override
  String takeReloadSection() {
    final section = reloadSection;
    reloadSection = '';
    return section;
  }

  @override
  void pushHash(String section) => pushes.add(section);

  @override
  void replaceHash(String section) => replacements.add(section);

  @override
  void Function() onPopState(void Function(String hash) callback) {
    _listener = callback;
    return () => _listener = null;
  }

  void popTo(String section) {
    hash = section;
    _listener?.call(section);
  }
}

Widget chapterDocument(
  AppScrollController controller, {
  double homeHeight = 900,
}) => MaterialApp(
  home: CustomScrollView(
    controller: controller.scrollController,
    slivers: [
      SliverToBoxAdapter(
        child: Column(
          children: [
            for (final chapter in controller.narrative.chapters)
              SizedBox(
                key: controller.keyFor(chapter.id),
                height: chapter.id == SectionId.home ? homeHeight : 900,
              ),
          ],
        ),
      ),
    ],
  ),
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('restores a deep link and holds its chapter through reflow', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1200, 800));
    final history = FakeBrowserHistory('packages');
    final controller = AppScrollController(
      narrative: loadNarrativeFixture(),
      browserHistory: history,
    );
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox.shrink());
      await controller.close();
      await tester.binding.setSurfaceSize(null);
    });

    await tester.pumpWidget(chapterDocument(controller));
    controller.handleInitialDeepLink();
    await tester.pump();
    final before = controller.scrollController.offset;
    expect(controller.activeSection, 'packages');
    expect(before, controller.geometry.sectionFor('packages')!.top);
    expect(history.pushes, isEmpty);

    await tester.pumpWidget(chapterDocument(controller, homeHeight: 1300));
    controller.markGeometryDirty();
    await tester.pump();
    await tester.pump();
    expect(controller.scrollController.offset, closeTo(before + 400, 1));
    expect(controller.activeSection, 'packages');

    await tester.sendKeyDownEvent(LogicalKeyboardKey.arrowDown);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.arrowDown);
    final releasedOffset = controller.scrollController.offset;
    await tester.pumpWidget(chapterDocument(controller, homeHeight: 1600));
    controller.markGeometryDirty();
    await tester.pump();
    await tester.pump();
    expect(controller.scrollController.offset, closeTo(releasedOffset, 1));
  });

  testWidgets('popstate moves to its chapter without pushing history', (
    tester,
  ) async {
    final history = FakeBrowserHistory('packages');
    final controller = AppScrollController(
      narrative: loadNarrativeFixture(),
      browserHistory: history,
    );
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox.shrink());
      await controller.close();
    });
    await tester.pumpWidget(chapterDocument(controller));
    controller.handleInitialDeepLink();
    history.popTo('about');
    await tester.pump();
    expect(controller.activeSection, 'about');
    expect(
      controller.scrollController.offset,
      controller.geometry.sectionFor('about')!.top,
    );
    expect(history.pushes, isEmpty);
  });

  testWidgets('external scrolling releases the deep link anchor', (
    tester,
  ) async {
    final history = FakeBrowserHistory('packages');
    final controller = AppScrollController(
      narrative: loadNarrativeFixture(),
      browserHistory: history,
    );
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox.shrink());
      await controller.close();
    });
    await tester.pumpWidget(chapterDocument(controller));
    controller.handleInitialDeepLink();
    await tester.pump();
    final writingTop = controller.geometry.sectionFor('writing')!.top;
    controller.scrollController.jumpTo(writingTop);
    await tester.pump();
    controller.markGeometryDirty();
    await tester.pump();
    expect(controller.scrollController.offset, closeTo(writingTop, 1));
    expect(controller.activeSection, 'writing');
    expect(history.replacements, contains('writing'));
  });

  testWidgets('a saved reload section wins over the address hash', (
    tester,
  ) async {
    final history = FakeBrowserHistory('about')..reloadSection = 'proof';
    final controller = AppScrollController(
      narrative: loadNarrativeFixture(),
      browserHistory: history,
    );
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox.shrink());
      await controller.close();
    });
    await tester.pumpWidget(chapterDocument(controller));
    controller.handleInitialDeepLink();
    await tester.pump();

    expect(controller.activeSection, 'proof');
    expect(
      controller.scrollController.offset,
      controller.geometry.sectionFor('proof')!.top,
    );
    expect(history.replacements, ['proof']);
  });

  testWidgets('an unknown hash falls back to the document start', (
    tester,
  ) async {
    final history = FakeBrowserHistory('unknown-chapter');
    final controller = AppScrollController(
      narrative: loadNarrativeFixture(),
      browserHistory: history,
    );
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox.shrink());
      await controller.close();
    });
    await tester.pumpWidget(chapterDocument(controller));
    controller.handleInitialDeepLink();
    await tester.pump();

    expect(history.replacements, ['home']);
    expect(controller.activeSection, 'home');
    expect(controller.scrollController.offset, 0);
  });

  testWidgets('passive progress replaces and explicit navigation pushes', (
    tester,
  ) async {
    final history = FakeBrowserHistory('');
    final controller = AppScrollController(
      narrative: loadNarrativeFixture(),
      browserHistory: history,
    );
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox.shrink());
      await controller.close();
    });
    await tester.pumpWidget(chapterDocument(controller));
    controller.refreshSectionGeometry();
    controller.scrollController.jumpTo(
      controller.geometry.sectionFor('proof')!.top,
    );
    await tester.pump();
    expect(history.replacements, contains('proof'));
    expect(history.pushes, isEmpty);

    controller
      ..setReduceMotion(true)
      ..scrollToSection('projects');
    await tester.pump();
    expect(history.pushes, ['projects']);
  });
}
