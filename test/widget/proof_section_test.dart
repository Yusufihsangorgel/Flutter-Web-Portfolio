import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_web_portfolio/app/controllers/scene_director.dart';
import 'package:flutter_web_portfolio/app/controllers/scroll_controller.dart';
import 'package:flutter_web_portfolio/app/domain/repositories/i_language_repository.dart';
import 'package:flutter_web_portfolio/app/features/language/application/language_cubit.dart';
import 'package:flutter_web_portfolio/app/modules/home/sections/proof_section.dart';

final class _ProofLanguageRepository implements ILanguageRepository {
  @override
  Map<String, String> getSupportedLanguages() => const {'en': 'EN'};

  @override
  Future<String> getSelectedLanguage() async => 'en';

  @override
  Future<Map<String, dynamic>> getTranslations(String languageCode) async => {
    'nav': {'proof': 'Approach'},
    'proof_section': {
      'title': 'How I Work',
      'subtitle': 'A practical approach',
    },
    'cv_data': {
      'proof': [
        {
          'title': 'Own the product',
          'detail': 'Stay close to the problem.',
          'verification': 'Product before ceremony',
        },
        {
          'title': 'Design for real conditions',
          'detail': 'Build for unreliable networks.',
          'verification': 'Resilience by design',
        },
        {
          'title': 'Keep it maintainable',
          'detail': 'Make the next change easier.',
          'verification': 'Built for the next change',
        },
      ],
    },
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

  Widget buildSubject() => MultiBlocProvider(
    providers: [
      BlocProvider.value(value: language),
      BlocProvider.value(value: scroll),
      BlocProvider.value(value: scene),
    ],
    child: const MaterialApp(
      home: Scaffold(body: SingleChildScrollView(child: ProofSection())),
    ),
  );

  testWidgets('renders practical working principles', (tester) async {
    await tester.pumpWidget(buildSubject());
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('How I Work'), findsOneWidget);
    expect(find.text('Own the product'), findsOneWidget);
    expect(find.text('Design for real conditions'), findsOneWidget);
    expect(find.text('Keep it maintainable'), findsOneWidget);
    expect(find.textContaining('testimonial'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('keeps every evidence card visible on a narrow viewport', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(buildSubject());
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('Own the product'), findsOneWidget);
    expect(find.text('Design for real conditions'), findsOneWidget);
    expect(find.text('Keep it maintainable'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
