import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_web_portfolio/app/controllers/scene_director.dart';
import 'package:flutter_web_portfolio/app/controllers/scroll_controller.dart';
import 'package:flutter_web_portfolio/app/core/constants/durations.dart';
import 'package:flutter_web_portfolio/app/domain/repositories/language_repository.dart';
import 'package:flutter_web_portfolio/app/features/language/application/language_cubit.dart';
import 'package:flutter_web_portfolio/app/features/render_quality/application/render_quality_controller.dart';
import 'package:flutter_web_portfolio/app/modules/home/home_view.dart';

import '../helpers/narrative_fixture.dart';
import '../helpers/portfolio_fixture.dart';

Future<AppScrollController> _mountHome(
  WidgetTester tester,
  LanguageCubit language, {
  bool reducedMotion = false,
}) async {
  // Home and about only: test fonts overflow the denser chapters.
  final portfolio = loadPortfolioFixture(
    mutate: (json) {
      for (final key in [
        'experience',
        'contributions',
        'systems',
        'packages',
        'writing',
      ]) {
        json[key] = <dynamic>[];
      }
    },
  );
  final narrative = loadNarrativeFixture(
    activeSections: portfolio.activeSections,
  );
  final scroll = AppScrollController(narrative: narrative);
  final scene = SceneDirector(scrollController: scroll);
  final quality = RenderQualityController();
  addTearDown(() async {
    await tester.pumpWidget(const SizedBox.shrink());
    await quality.close();
    await scene.close();
    await scroll.close();
    await tester.binding.setSurfaceSize(null);
  });
  await tester.binding.setSurfaceSize(const Size(1200, 800));
  await tester.pumpWidget(
    MultiRepositoryProvider(
      providers: [
        RepositoryProvider.value(value: portfolio),
        RepositoryProvider.value(value: narrative),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider.value(value: language),
          BlocProvider.value(value: scroll),
          BlocProvider.value(value: scene),
          BlocProvider.value(value: quality),
        ],
        child: MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(
              size: const Size(1200, 800),
              disableAnimations: reducedMotion,
            ),
            child: const HomeView(),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
  return scroll;
}

FocusNode _mainFocus(WidgetTester tester) => tester
    .widget<Focus>(find.byKey(const ValueKey('main-content-focus-target')))
    .focusNode!;

FocusNode _skipFocus(WidgetTester tester) => tester
    .widget<Focus>(find.widgetWithText(Focus, 'Skip to content').first)
    .focusNode!;

Future<ScrollPosition> _activateSkipLink(
  WidgetTester tester,
  AppScrollController scroll,
) async {
  _skipFocus(tester).requestFocus();
  await tester.pump();
  expect(_skipFocus(tester).hasPrimaryFocus, isTrue);
  await tester.sendKeyEvent(LogicalKeyboardKey.enter);
  return scroll.scrollController.position;
}

const _tick = Duration(milliseconds: 1);

// Margin for the controller's end-of-frame settle after a scroll.
const _settle = Duration(milliseconds: 500);

// Runs the remaining section scroll and the controller's settle frame.
Future<void> _finishScroll(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(AppDurations.sectionScroll + _tick);
  await tester.pump(_settle);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final bound = AppDurations.sectionScroll * 2;
  final halfScroll = AppDurations.sectionScroll ~/ 2;
  late LanguageCubit language;

  // Outside the fake clock so closing can await its persistence queue.
  setUp(() async {
    language = LanguageCubit(languageRepository: _LanguageRepository());
    await language.initialize();
    addTearDown(language.close);
  });

  testWidgets('focus moves into main content once the skip scroll ends', (
    tester,
  ) async {
    final scroll = await _mountHome(tester, language);
    final position = await _activateSkipLink(tester, scroll);
    await tester.pump();
    await tester.pump(halfScroll);
    expect(position.isScrollingNotifier.value, isTrue);
    expect(_mainFocus(tester).hasPrimaryFocus, isFalse);

    await tester.pump(AppDurations.sectionScroll);
    expect(position.isScrollingNotifier.value, isFalse);
    expect(position.pixels, greaterThan(0));
    expect(_mainFocus(tester).hasPrimaryFocus, isTrue);
    await tester.pump(_settle);
  });

  testWidgets('an interrupted skip scroll still moves focus', (tester) async {
    final scroll = await _mountHome(tester, language);
    final position = await _activateSkipLink(tester, scroll);
    await tester.pump();
    await tester.pump(halfScroll);
    expect(_mainFocus(tester).hasPrimaryFocus, isFalse);

    position.jumpTo(position.pixels);
    await tester.pump();
    expect(_mainFocus(tester).hasPrimaryFocus, isTrue);
    await _finishScroll(tester);
  });

  testWidgets('a skip scroll without frames moves focus at the time bound', (
    tester,
  ) async {
    final scroll = await _mountHome(tester, language);
    final position = await _activateSkipLink(tester, scroll);
    await tester.binding.delayed(bound - _tick);
    expect(position.isScrollingNotifier.value, isTrue);
    expect(_mainFocus(tester).hasPrimaryFocus, isFalse);

    await tester.binding.delayed(_tick);
    expect(_mainFocus(tester).hasPrimaryFocus, isTrue);
    await _finishScroll(tester);
  });

  testWidgets('focus dropped during the scroll still lands in main content', (
    tester,
  ) async {
    final scroll = await _mountHome(tester, language);
    await _activateSkipLink(tester, scroll);
    _skipFocus(tester).unfocus();
    await tester.pump();
    expect(_mainFocus(tester).hasPrimaryFocus, isFalse);

    await _finishScroll(tester);
    expect(_mainFocus(tester).hasPrimaryFocus, isTrue);
  });

  testWidgets('skip focus does not steal a later keyboard selection', (
    tester,
  ) async {
    final scroll = await _mountHome(tester, language);
    await _activateSkipLink(tester, scroll);
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    final selected = FocusManager.instance.primaryFocus;
    expect(selected, isNot(same(_skipFocus(tester))));

    await _finishScroll(tester);
    await tester.binding.delayed(bound);
    expect(FocusManager.instance.primaryFocus, same(selected));
    expect(_mainFocus(tester).hasPrimaryFocus, isFalse);
  });

  testWidgets('unmounting during the skip scroll cancels the pending focus', (
    tester,
  ) async {
    final scroll = await _mountHome(tester, language);
    await _activateSkipLink(tester, scroll);
    await tester.pump();
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(_settle);
    expect(tester.takeException(), isNull);
  });

  testWidgets('reduced motion jumps to the target and focuses at once', (
    tester,
  ) async {
    final scroll = await _mountHome(tester, language, reducedMotion: true);
    final position = await _activateSkipLink(tester, scroll);
    expect(position.isScrollingNotifier.value, isFalse);
    expect(position.pixels, greaterThan(0));
    await tester.pump();
    expect(_mainFocus(tester).hasPrimaryFocus, isTrue);
    await tester.pump(_settle);
  });
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
