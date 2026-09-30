import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_web_portfolio/app/controllers/scroll_controller.dart';
import 'package:flutter_web_portfolio/app/widgets/portfolio_link.dart';
import 'package:url_launcher/link.dart';

import '../helpers/narrative_fixture.dart';

void main() {
  group('PortfolioLink', () {
    testWidgets('publishes its URL as a semantic link', (tester) async {
      final semantics = tester.ensureSemantics();
      final uri = Uri.parse('https://example.invalid/profile');
      try {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: PortfolioLink(
                uri: uri,
                semanticLabel: 'Open profile',
                child: const Text('Profile'),
              ),
            ),
          ),
        );

        final node = tester.getSemantics(find.bySemanticsLabel('Open profile'));
        expect(node.getSemanticsData().flagsCollection.isLink, isTrue);
        expect(node.getSemanticsData().linkUrl, uri);
      } finally {
        semantics.dispose();
      }
    });

    testWidgets('stays focusable and reports keyboard focus to semantics', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      final focusNode = FocusNode();
      addTearDown(focusNode.dispose);
      try {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: PortfolioLink(
                uri: Uri.parse('https://example.invalid/profile'),
                semanticLabel: 'Open profile',
                focusNode: focusNode,
                child: const Text('Profile'),
              ),
            ),
          ),
        );
        final node = find.bySemanticsLabel('Open profile');

        expect(
          tester.getSemantics(node),
          matchesSemantics(
            label: 'Open profile',
            isLink: true,
            isFocusable: true,
            hasFocusAction: true,
            hasTapAction: true,
          ),
        );

        focusNode.requestFocus();
        await tester.pump();
        expect(
          tester.getSemantics(node),
          matchesSemantics(
            label: 'Open profile',
            isLink: true,
            isFocusable: true,
            isFocused: true,
            hasFocusAction: true,
            hasTapAction: true,
          ),
        );
      } finally {
        semantics.dispose();
      }
    });

    testWidgets('takes its name from its content when unlabeled', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      try {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: PortfolioLink(
                uri: Uri.parse('https://example.invalid/profile'),
                child: const Text('Profile'),
              ),
            ),
          ),
        );

        expect(
          tester.getSemantics(find.bySemanticsLabel('Profile')),
          matchesSemantics(
            label: 'Profile',
            isLink: true,
            isFocusable: true,
            hasFocusAction: true,
            hasTapAction: true,
          ),
        );
      } finally {
        semantics.dispose();
      }
    });

    testWidgets('external URLs request a new browsing context', (tester) async {
      final uri = Uri.parse('https://example.invalid/profile');
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PortfolioLink(uri: uri, child: const Text('Profile')),
          ),
        ),
      );

      final link = tester.widget<Link>(find.byType(Link));
      expect(link.uri, uri);
      expect(link.target, LinkTarget.blank);
    });

    testWidgets('mail links stay in the current browsing context', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PortfolioLink(
              uri: Uri(scheme: 'mailto', path: 'hello@example.invalid'),
              child: const Text('Email'),
            ),
          ),
        ),
      );

      expect(tester.widget<Link>(find.byType(Link)).target, LinkTarget.self);
    });

    testWidgets('in-page links publish their hash and scroll to the chapter', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(1200, 800));
      final semantics = tester.ensureSemantics();
      final controller = AppScrollController(narrative: loadNarrativeFixture())
        ..setReduceMotion(true);
      addTearDown(() async {
        await tester.pumpWidget(const SizedBox.shrink());
        await controller.close();
        await tester.binding.setSurfaceSize(null);
      });

      await tester.pumpWidget(
        BlocProvider.value(
          value: controller,
          child: MaterialApp(
            home: CustomScrollView(
              controller: controller.scrollController,
              slivers: [
                SliverToBoxAdapter(
                  child: Column(
                    children: [
                      for (final chapter in controller.narrative.chapters)
                        SizedBox(
                          key: controller.keyFor(chapter.id),
                          height: 900,
                          child: chapter.id.isHome
                              ? PortfolioLink(
                                  uri: Uri.parse('#/packages'),
                                  semanticLabel: 'Packages',
                                  child: const Text('Packages'),
                                )
                              : null,
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
      controller.refreshSectionGeometry();

      final node = tester.getSemantics(find.bySemanticsLabel('Packages'));
      expect(node.getSemanticsData().flagsCollection.isLink, isTrue);
      expect(node.getSemanticsData().linkUrl.toString(), '#/packages');

      await tester.tap(find.text('Packages'));
      await tester.pump();
      expect(controller.activeSection, 'packages');
      expect(
        controller.scrollController.offset,
        controller.geometry.sectionFor('packages')!.top,
      );
      semantics.dispose();
    });

    testWidgets('Enter activates the link', (tester) async {
      var activated = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PortfolioLink(
              uri: Uri.parse('https://example.invalid/profile'),
              semanticLabel: 'Open profile',
              onActivate: () => activated = true,
              child: const Text('Profile'),
            ),
          ),
        ),
      );

      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();

      expect(activated, isTrue);
    });

    testWidgets('Space does not activate the link', (tester) async {
      var activated = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PortfolioLink(
              uri: Uri.parse('https://example.invalid/profile'),
              semanticLabel: 'Open profile',
              onActivate: () => activated = true,
              child: const Text('Profile'),
            ),
          ),
        ),
      );

      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pump();

      expect(activated, isFalse);
    });

    testWidgets('paints the focus ring for keyboard focus', (tester) async {
      final focusNode = FocusNode();
      addTearDown(focusNode.dispose);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PortfolioLink(
              uri: Uri.parse('https://example.invalid/profile'),
              semanticLabel: 'Open profile',
              focusNode: focusNode,
              child: const Text('Profile'),
            ),
          ),
        ),
      );

      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();

      expect(focusNode.hasFocus, isTrue);
      expect(
        find.descendant(
          of: find.byType(PortfolioLink),
          matching: find.byWidgetPredicate(
            (widget) =>
                widget is CustomPaint && widget.foregroundPainter != null,
          ),
        ),
        findsOneWidget,
      );
    });
  });
}
