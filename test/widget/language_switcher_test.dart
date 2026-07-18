import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_web_portfolio/app/controllers/scene_director.dart';
import 'package:flutter_web_portfolio/app/controllers/scroll_controller.dart';
import 'package:flutter_web_portfolio/app/domain/repositories/language_repository.dart';
import 'package:flutter_web_portfolio/app/features/language/application/language_cubit.dart';
import 'package:flutter_web_portfolio/app/widgets/language_switcher.dart';

import '../helpers/narrative_fixture.dart';

final class _SwitcherLanguageRepository implements LanguageRepository {
  String selectedLanguage = 'en';

  @override
  Set<String> get supportedLanguages => const {'en', 'tr'};

  @override
  Future<String> getSelectedLanguage() async => selectedLanguage;

  @override
  Future<Map<String, dynamic>> getTranslations(String languageCode) async => {
    'accessibility': {'language_menu': 'Language menu'},
  };

  @override
  Future<void> saveSelectedLanguage(String languageCode) async {
    selectedLanguage = languageCode;
  }
}

void main() {
  late LanguageCubit language;
  late _SwitcherLanguageRepository repository;
  late AppScrollController scroll;
  late SceneDirector scene;

  setUp(() async {
    repository = _SwitcherLanguageRepository();
    language = LanguageCubit(languageRepository: repository);
    scroll = AppScrollController(narrative: loadNarrativeFixture());
    scene = SceneDirector(scrollController: scroll);
    await language.initialize();
    addTearDown(() async {
      await scene.close();
      await scroll.close();
      await language.close();
    });
  });

  Widget buildSubject() => MultiBlocProvider(
    providers: [
      BlocProvider.value(value: language),
      BlocProvider.value(value: scroll),
      BlocProvider.value(value: scene),
    ],
    child: const MaterialApp(
      home: Scaffold(
        body: Align(alignment: Alignment.topRight, child: LanguageSwitcher()),
      ),
    ),
  );

  testWidgets('uses a compact language code instead of emoji flags', (
    tester,
  ) async {
    await tester.pumpWidget(buildSubject());
    await tester.pump();

    expect(find.text('EN'), findsOneWidget);
    expect(find.text('🇬🇧'), findsNothing);
    expect(find.byTooltip('Language menu: English'), findsOneWidget);
  });

  testWidgets('keeps every available language readable in the menu', (
    tester,
  ) async {
    await tester.pumpWidget(buildSubject());
    await tester.pump();

    await tester.tap(find.byTooltip('Language menu: English'));
    await tester.pumpAndSettle();

    expect(find.text('English'), findsOneWidget);
    expect(find.text('Türkçe'), findsOneWidget);
    expect(find.text('TR'), findsOneWidget);
    expect(find.byIcon(Icons.check_rounded), findsOneWidget);
    expect(find.text('🇹🇷'), findsNothing);
  });
}
