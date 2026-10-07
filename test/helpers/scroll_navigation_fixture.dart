import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_web_portfolio/app/controllers/scroll/browser_history.dart';
import 'package:flutter_web_portfolio/app/controllers/scroll_controller.dart';
import 'package:flutter_web_portfolio/app/domain/repositories/language_repository.dart';
import 'package:flutter_web_portfolio/app/features/language/application/language_cubit.dart';
import 'package:flutter_web_portfolio/app/narrative/domain/narrative_document.dart';
import 'package:flutter_web_portfolio/app/widgets/back_to_top_button.dart';

import 'narrative_fixture.dart';

final class ScrollNavigationFixture {
  ScrollNavigationFixture(this.tester, {String initialSection = ''})
    : history = NavigationHistory(initialSection) {
    controller = AppScrollController(
      narrative: loadNarrativeFixture(),
      browserHistory: history,
    );
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox.shrink());
      await controller.close();
      await _closeLanguage();
      homeHeight.dispose();
      backToTopFocus.dispose();
    });
  }

  final WidgetTester tester;
  final NavigationHistory history;
  late final AppScrollController controller;
  final LanguageCubit language = LanguageCubit(
    languageRepository: _LanguageRepository(),
  );
  final ValueNotifier<double> homeHeight = ValueNotifier(900);
  final FocusNode backToTopFocus = FocusNode();

  Future<void> mount() async {
    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider.value(value: controller),
          BlocProvider.value(value: language),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: Stack(
              children: [
                ValueListenableBuilder<double>(
                  valueListenable: homeHeight,
                  builder: (_, height, _) => _document(height),
                ),
                BackToTopButton(focusNode: backToTopFocus),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    controller.refreshSectionGeometry();
  }

  Widget _document(double height) => CustomScrollView(
    controller: controller.scrollController,
    slivers: [
      SliverToBoxAdapter(
        child: Column(
          children: [
            for (final chapter in controller.narrative.chapters)
              SizedBox(
                key: controller.keyFor(chapter.id),
                height: chapter.id == SectionId.home ? height : 900,
              ),
          ],
        ),
      ),
    ],
  );

  Future<void> readAt(double offset) async {
    controller.scrollController.jumpTo(offset);
    await settle();
  }

  /// Pumps until idle and fails fast if frames are still scheduled.
  Future<void> settle() => tester.pumpAndSettle(
    const Duration(milliseconds: 100),
    EnginePhase.sendSemanticsUpdate,
    const Duration(seconds: 5),
  );

  /// The cubit was created on the fake clock, so its close needs a pump.
  Future<void> _closeLanguage() async {
    final closing = language.close();
    await tester.pump();
    await closing;
  }

  Future<void> reflow() async {
    homeHeight.value += 400;
    controller.markGeometryDirty();
    await tester.pump();
  }
}

final class NavigationHistory implements BrowserHistory {
  NavigationHistory(this.hash);

  @override
  String hash;
  final pushes = <String>[];
  final replacements = <String>[];
  void Function(String)? _onPopState;

  @override
  String takeReloadSection() => '';

  @override
  void pushHash(String section) {
    hash = section;
    pushes.add(section);
  }

  @override
  void replaceHash(String section) {
    hash = section;
    replacements.add(section);
  }

  @override
  void Function() onPopState(void Function(String) callback) {
    _onPopState = callback;
    return () => _onPopState = null;
  }

  void popTo(String section) {
    hash = section;
    _onPopState?.call(section);
  }
}

final class _LanguageRepository implements LanguageRepository {
  @override
  Set<String> get supportedLanguages => const {'en'};

  @override
  Future<String> getSelectedLanguage() async => 'en';

  @override
  Future<Map<String, dynamic>> getTranslations(String languageCode) async => {};

  @override
  Future<void> saveSelectedLanguage(String languageCode) async {}
}
