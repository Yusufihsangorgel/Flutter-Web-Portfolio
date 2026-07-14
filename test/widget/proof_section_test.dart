import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_web_portfolio/app/controllers/scene_director.dart';
import 'package:flutter_web_portfolio/app/controllers/scroll_controller.dart';
import 'package:flutter_web_portfolio/app/domain/repositories/i_language_repository.dart';
import 'package:flutter_web_portfolio/app/features/language/application/language_cubit.dart';
import 'package:flutter_web_portfolio/app/modules/home/sections/proof_section.dart';
import 'package:flutter_web_portfolio/app/widgets/border_light_card.dart';

final class _ProofLanguageRepository implements ILanguageRepository {
  @override
  Map<String, String> getSupportedLanguages() => const {'en': 'EN'};

  @override
  Future<String> getSelectedLanguage() async => 'en';

  @override
  Future<Map<String, dynamic>> getTranslations(String languageCode) async => {
    'nav': {'proof': 'Proof'},
    'proof_section': {
      'title': 'Engineering Proof',
      'subtitle': 'Inspectable evidence',
    },
    'cv_data': {
      'proof': [
        {
          'title': 'Dual-runtime delivery',
          'detail': 'Wasm primary with a JavaScript fallback.',
          'verification': 'Inspect the build manifest',
        },
        {
          'title': 'Measured in the browser',
          'detail': 'Live runtime telemetry.',
          'verification': 'Open Engineering Lab',
        },
        {
          'title': 'Production hardened',
          'detail': 'Headers and browser tests.',
          'verification': 'Inspect tests and Nginx config',
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

  testWidgets('renders inspectable evidence without named endorsements', (
    tester,
  ) async {
    await tester.pumpWidget(buildSubject());
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('Engineering Proof'), findsOneWidget);
    expect(find.text('Dual-runtime delivery'), findsOneWidget);
    expect(find.text('Measured in the browser'), findsOneWidget);
    expect(find.text('Production hardened'), findsOneWidget);
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

    expect(find.byType(BorderLightCard), findsNWidgets(3));
    expect(tester.takeException(), isNull);
  });
}
