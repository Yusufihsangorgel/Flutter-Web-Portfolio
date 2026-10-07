import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/scroll_navigation_fixture.dart';

void main() {
  _backToTopTests();
  _backToTopSpaceTest();
  _reducedMotionReflowTest();
  _chapterNavigationTests();
  _supersedingNavigationTest();
  _interruptedNavigationTests();
  _nonScrollKeyTest();
  _noOpScrollKeyTest();
  _deepLinkTests();
}

/// The back-to-top link as assistive technology sees it.
SemanticsFinder get _backToTop => find.semantics.byLabel('Back to top');

/// Runs [body] with semantics on and releases them before the test ends.
Future<void> _withSemantics(
  WidgetTester tester,
  Future<void> Function() body,
) async {
  final semantics = tester.ensureSemantics();
  try {
    await body();
  } finally {
    semantics.dispose();
  }
}

void _backToTopTests() {
  testWidgets(
    'Enter reaches the top despite geometry changes during navigation',
    (tester) => _withSemantics(tester, () async {
      final fixture = ScrollNavigationFixture(tester);
      await fixture.mount();
      await fixture.readAt(3500);
      fixture.backToTopFocus.requestFocus();
      await tester.pump();
      expect(_backToTop, findsOne);

      fixture.controller.markGeometryDirty();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      expect(fixture.controller.scrollController.offset, greaterThan(500));
      await fixture.reflow();
      await fixture.settle();

      expect(fixture.history.pushes, ['home']);
      expect(fixture.controller.scrollController.offset, closeTo(0, 0.5));
      expect(_backToTop, findsNothing);
    }),
  );

  testWidgets(
    'reduced-motion Enter discards an already queued reading anchor',
    (tester) => _withSemantics(tester, () async {
      final fixture = ScrollNavigationFixture(tester);
      await fixture.mount();
      await fixture.readAt(3500);
      fixture.backToTopFocus.requestFocus();
      await tester.pump();
      fixture.controller
        ..setReduceMotion(true)
        ..markGeometryDirty();

      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await fixture.settle();

      expect(fixture.history.pushes, ['home']);
      expect(fixture.controller.scrollController.offset, closeTo(0, 0.5));
      expect(_backToTop, findsNothing);
    }),
  );
}

void _backToTopSpaceTest() {
  testWidgets(
    'Space preserves the back-to-top link activation contract',
    (tester) => _withSemantics(tester, () async {
      final fixture = ScrollNavigationFixture(tester);
      await fixture.mount();
      await fixture.readAt(3500);
      fixture.backToTopFocus.requestFocus();
      await tester.pump();

      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await fixture.settle();

      expect(fixture.history.pushes, isEmpty);
      expect(fixture.controller.scrollController.offset, closeTo(3500, 0.5));
      expect(_backToTop, findsOne);
    }),
  );
}

void _chapterNavigationTests() {
  testWidgets(
    'chapter navigation measures reflow without restoring the reader',
    (tester) async {
      final fixture = ScrollNavigationFixture(tester);
      await fixture.mount();
      await fixture.readAt(3500);
      fixture.controller
        ..markGeometryDirty()
        ..scrollToSection('experience');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      final inFlightOffset = fixture.controller.scrollController.offset;
      await fixture.reflow();

      expect(fixture.controller.geometry.sectionFor('experience')!.top, 1300);
      expect(
        fixture.controller.scrollController.offset,
        closeTo(inFlightOffset, 0.5),
      );
      await fixture.settle();
      expect(fixture.controller.scrollController.offset, closeTo(1300, 0.5));
      expect(fixture.controller.activeSection, 'experience');
    },
  );

  testWidgets('completion reaches a chapter moved during the last frame', (
    tester,
  ) async {
    final fixture = ScrollNavigationFixture(tester);
    await fixture.mount();
    await fixture.readAt(3500);
    fixture.controller.scrollToSection('experience');
    await tester.pump();
    fixture.homeHeight.value = 1300;
    fixture.controller.markGeometryDirty(preserveReadingAnchor: false);
    await tester.pump(const Duration(milliseconds: 800));
    await fixture.settle();

    expect(fixture.controller.geometry.sectionFor('experience')!.top, 1300);
    expect(fixture.controller.scrollController.offset, closeTo(1300, 0.5));
  });
}

void _supersedingNavigationTest() {
  testWidgets('a superseding chapter navigation owns the final target', (
    tester,
  ) async {
    final fixture = ScrollNavigationFixture(tester);
    await fixture.mount();
    await fixture.readAt(3500);
    fixture.controller.scrollToSection('experience');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    fixture.controller.scrollToSection('writing');
    await fixture.reflow();
    await fixture.settle();

    expect(fixture.controller.scrollController.offset, closeTo(4900, 0.5));
    expect(fixture.controller.activeSection, 'writing');
    expect(fixture.history.pushes, ['experience', 'writing']);
  });
}

void _reducedMotionReflowTest() {
  testWidgets(
    'reduced-motion navigation suppresses geometry callbacks on jump',
    (tester) => _withSemantics(tester, () async {
      final fixture = ScrollNavigationFixture(tester);
      await fixture.mount();
      await fixture.readAt(3500);
      fixture.backToTopFocus.requestFocus();
      await tester.pump();
      fixture.controller.setReduceMotion(true);
      void geometryChanged() {
        if (fixture.controller.scrollController.offset == 0) {
          fixture.controller.markGeometryDirty();
        }
      }

      fixture.controller.scrollController.addListener(geometryChanged);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await fixture.settle();

      expect(fixture.controller.scrollController.offset, closeTo(0, 0.5));
      expect(_backToTop, findsNothing);
    }),
  );
}

void _interruptedNavigationTests() {
  testWidgets('wheel scrolling cancels final navigation correction', (
    tester,
  ) async {
    final fixture = ScrollNavigationFixture(tester);
    await fixture.mount();
    await fixture.readAt(3500);
    fixture.controller.scrollToSection('home');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    await tester.sendEventToBinding(
      const PointerScrollEvent(
        position: Offset(100, 100),
        scrollDelta: Offset(0, 120),
      ),
    );
    final interruptedOffset = fixture.controller.scrollController.offset;
    await fixture.settle();

    expect(interruptedOffset, greaterThan(500));
    expect(
      fixture.controller.scrollController.offset,
      closeTo(interruptedOffset, 0.5),
    );
    expect(fixture.controller.activeSection, isNot('home'));
  });

  testWidgets('drag scrolling cancels final navigation correction', (
    tester,
  ) async {
    final fixture = ScrollNavigationFixture(tester);
    await fixture.mount();
    await fixture.readAt(3500);
    fixture.controller.scrollToSection('home');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    final gesture = await tester.startGesture(const Offset(100, 200));
    await gesture.moveBy(const Offset(0, -100));
    await tester.pump(const Duration(milliseconds: 100));
    final interruptedOffset = fixture.controller.scrollController.offset;
    await gesture.cancel();
    await fixture.settle();

    expect(interruptedOffset, greaterThan(500));
    expect(
      fixture.controller.scrollController.offset,
      closeTo(interruptedOffset, 0.5),
    );
  });
}

void _nonScrollKeyTest() {
  testWidgets('a non-scroll key keeps navigation guarded through reflow', (
    tester,
  ) async {
    final fixture = ScrollNavigationFixture(tester);
    await fixture.mount();
    await fixture.readAt(3500);
    fixture.controller.scrollToSection('experience');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    await tester.sendKeyEvent(LogicalKeyboardKey.keyA);
    await fixture.reflow();
    await fixture.settle();

    expect(fixture.controller.scrollController.offset, closeTo(1300, 0.5));
    expect(fixture.controller.activeSection, 'experience');
  });
}

void _noOpScrollKeyTest() {
  testWidgets(
    'an ignored Space stops the old animation before releasing guard',
    (tester) async {
      final fixture = ScrollNavigationFixture(tester);
      await fixture.mount();
      await fixture.readAt(3500);
      fixture.backToTopFocus.requestFocus();
      await tester.pump();
      fixture.controller.scrollToSection('home');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      final interruptedOffset = fixture.controller.scrollController.offset;

      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      expect(
        fixture.controller.scrollController.offset,
        closeTo(interruptedOffset, 0.5),
      );
      await fixture.reflow();
      await fixture.settle();

      expect(
        fixture.controller.scrollController.offset,
        closeTo(interruptedOffset + 400, 0.5),
      );
      expect(fixture.controller.activeSection, isNot('home'));
    },
  );
}

void _deepLinkTests() {
  testWidgets(
    'an initial deep link stays at its measured chapter after reflow',
    (tester) async {
      final fixture = ScrollNavigationFixture(
        tester,
        initialSection: 'packages',
      );
      await fixture.mount();
      expect(fixture.controller.scrollController.offset, closeTo(3600, 0.5));
      fixture.controller.markGeometryDirty();
      await fixture.reflow();
      await fixture.settle();

      expect(fixture.controller.scrollController.offset, closeTo(4000, 0.5));
      expect(fixture.controller.activeSection, 'packages');
      expect(fixture.history.pushes, isEmpty);
    },
  );

  testWidgets('popstate supersedes animation and a queued reading anchor', (
    tester,
  ) async {
    final fixture = ScrollNavigationFixture(tester);
    await fixture.mount();
    await fixture.readAt(3500);
    fixture.controller.scrollToSection('experience');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    fixture.controller.markGeometryDirty();
    fixture.history.popTo('writing');
    await fixture.reflow();
    await fixture.settle();

    expect(fixture.controller.scrollController.offset, closeTo(4900, 0.5));
    expect(fixture.controller.activeSection, 'writing');
    expect(fixture.history.pushes, ['experience']);
  });
}
