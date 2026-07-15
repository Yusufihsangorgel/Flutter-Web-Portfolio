import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_web_portfolio/app/controllers/scene_director.dart';
import 'package:flutter_web_portfolio/app/controllers/scroll_controller.dart';
import 'package:flutter_web_portfolio/app/domain/repositories/i_language_repository.dart';
import 'package:flutter_web_portfolio/app/features/language/application/language_cubit.dart';
import 'package:flutter_web_portfolio/app/modules/home/sections/proof_section.dart';
import 'package:flutter_web_portfolio/app/widgets/cinematic_focusable.dart';
import '../helpers/portfolio_fixture.dart';

final class _ProofLanguageRepository implements ILanguageRepository {
  @override
  Map<String, String> getSupportedLanguages() => const {'en': 'EN'};

  @override
  Future<String> getSelectedLanguage() async => 'en';

  @override
  Future<Map<String, dynamic>> getTranslations(String languageCode) async => {
    'nav': {'proof': 'Open Source'},
    'proof_section': {'title': 'Open Source'},
  };

  @override
  Future<void> saveSelectedLanguage(String languageCode) async {}
}

void main() {
  late LanguageCubit language;
  late AppScrollController scroll;
  late SceneDirector scene;

  setUp(() async {
    scroll = AppScrollController();
    scene = SceneDirector(scrollController: scroll);
    language = LanguageCubit(languageRepository: _ProofLanguageRepository());
    await language.initialize();
    addTearDown(() async {
      await scene.close();
      await scroll.close();
      await language.close();
    });
    expect(scroll.activeSection, 'home');
  });

  Widget buildSubject() => RepositoryProvider.value(
    value: loadPortfolioFixture(),
    child: MultiBlocProvider(
      providers: [
        BlocProvider.value(value: language),
        BlocProvider.value(value: scroll),
        BlocProvider.value(value: scene),
      ],
      child: const MaterialApp(
        home: Scaffold(body: SingleChildScrollView(child: ProofSection())),
      ),
    ),
  );

  testWidgets('renders verified open-source contributions', (tester) async {
    await tester.pumpWidget(buildSubject());
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('Open Source'), findsOneWidget);
    expect(
      find.text('Make Firebase core loading deterministic on WebKit'),
      findsOneWidget,
    );
    expect(
      find.text('Treat SQLite TRUE and 1 defaults as the same schema'),
      findsOneWidget,
    );
    expect(
      find.text('Wait for web rendering before the first-frame event'),
      findsOneWidget,
    );
    expect(find.text('PULL REQUEST'), findsNWidgets(5));
    expect(find.textContaining('testimonial'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('configures the Flutter engine patch as an accessible link', (
    tester,
  ) async {
    await tester.pumpWidget(buildSubject());
    await tester.pump(const Duration(seconds: 1));

    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is CinematicFocusable &&
            widget.semanticRole == CinematicControlRole.link &&
            widget.semanticLabel?.contains('Open pull request') == true &&
            widget.semanticLabel?.contains('first-frame event') == true,
      ),
      findsOneWidget,
    );
  });

  testWidgets('keeps every evidence plate visible on a narrow viewport', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(buildSubject());
    await tester.pump(const Duration(seconds: 1));

    expect(
      find.text('Make Firebase core loading deterministic on WebKit'),
      findsOneWidget,
    );
    expect(
      find.text('Wait for web rendering before the first-frame event'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });
}
