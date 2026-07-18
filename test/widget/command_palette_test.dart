import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_web_portfolio/app/controllers/scroll_controller.dart';
import 'package:flutter_web_portfolio/app/domain/repositories/language_repository.dart';
import 'package:flutter_web_portfolio/app/features/language/application/language_cubit.dart';
import 'package:flutter_web_portfolio/app/widgets/command_palette.dart';
import '../helpers/portfolio_fixture.dart';
import '../helpers/narrative_fixture.dart';

final class _PaletteLanguageRepository implements LanguageRepository {
  @override
  Set<String> get supportedLanguages => const {'en'};

  @override
  Future<String> getSelectedLanguage() async => 'en';

  @override
  Future<Map<String, dynamic>> getTranslations(String languageCode) async => {
    'nav': {
      'home': 'Home',
      'about': 'About',
      'experience': 'Experience',
      'proof': 'Open Source',
      'blog': 'Blog',
      'projects': 'Work',
      'contact': 'Contact',
    },
  };

  @override
  Future<void> saveSelectedLanguage(String languageCode) async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late LanguageCubit language;
  late AppScrollController scroll;

  setUp(() async {
    language = LanguageCubit(languageRepository: _PaletteLanguageRepository());
    scroll = AppScrollController(narrative: loadNarrativeFixture());
    await language.initialize();
    addTearDown(() async {
      await language.close();
      await scroll.close();
    });
  });

  Widget buildSubject() => RepositoryProvider.value(
    value: loadPortfolioFixture(),
    child: MultiBlocProvider(
      providers: [
        BlocProvider.value(value: language),
        BlocProvider.value(value: scroll),
      ],
      child: const MaterialApp(home: Scaffold(body: CommandPalette())),
    ),
  );

  group('CommandPalette', () {
    testWidgets('renders the search field and navigation commands', (
      tester,
    ) async {
      await tester.pumpWidget(buildSubject());
      await tester.pump();

      expect(find.byType(CommandPalette), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('Go to Home'), findsOneWidget);
    });

    testWidgets('filters navigation commands by query', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pump();

      await tester.enterText(find.byType(TextField), 'work');
      await tester.pump();

      expect(find.text('Go to Work'), findsOneWidget);
      expect(find.text('Go to Home'), findsNothing);
    });
  });
}
