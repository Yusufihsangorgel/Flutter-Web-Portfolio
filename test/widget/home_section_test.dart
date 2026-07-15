import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_web_portfolio/app/controllers/scroll_controller.dart';
import 'package:flutter_web_portfolio/app/domain/repositories/i_language_repository.dart';
import 'package:flutter_web_portfolio/app/features/language/application/language_cubit.dart';
import 'package:flutter_web_portfolio/app/modules/home/sections/home_section.dart';
import '../helpers/portfolio_fixture.dart';
import '../helpers/narrative_fixture.dart';

final class _HomeLanguageRepository implements ILanguageRepository {
  @override
  Map<String, String> getSupportedLanguages() => const {'en': 'English'};

  @override
  Future<String> getSelectedLanguage() async => 'en';

  @override
  Future<Map<String, dynamic>> getTranslations(String languageCode) async => {
    'home_section': {
      'view_work': 'View selected work',
      'view_github': 'GitHub',
      'based_in': 'Based in',
      'working_since': 'Working since',
      'focus': 'Focus',
    },
  };

  @override
  Future<void> saveSelectedLanguage(String languageCode) async {}
}

void main() {
  late LanguageCubit language;
  late AppScrollController scroll;

  setUp(() async {
    language = LanguageCubit(languageRepository: _HomeLanguageRepository());
    scroll = AppScrollController(narrative: loadNarrativeFixture());
    await language.initialize();
    addTearDown(() async {
      await language.close();
      await scroll.close();
    });
  });

  Widget buildSubject({
    required bool includeWork,
    required bool includeGithub,
    void Function(Map<String, dynamic> json)? mutate,
  }) {
    final portfolio = loadPortfolioFixture(
      mutate: (json) {
        if (!includeWork) json['systems'] = <dynamic>[];
        if (!includeGithub) {
          final profile = json['profile']! as Map<String, dynamic>;
          (profile['links']! as List<dynamic>).removeWhere(
            (link) => (link as Map<String, dynamic>)['id'] == 'github',
          );
        }
        mutate?.call(json);
      },
    );
    return RepositoryProvider.value(
      value: portfolio,
      child: MultiBlocProvider(
        providers: [
          BlocProvider.value(value: language),
          BlocProvider.value(value: scroll),
        ],
        child: const MaterialApp(
          home: Scaffold(body: SingleChildScrollView(child: HomeSection())),
        ),
      ),
    );
  }

  testWidgets('shows only actions backed by configured portfolio data', (
    tester,
  ) async {
    await tester.pumpWidget(
      buildSubject(includeWork: false, includeGithub: true),
    );
    await tester.pump(const Duration(milliseconds: 1));

    expect(find.text('View selected work'), findsNothing);
    expect(find.text('GitHub'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });

  testWidgets('does not render no-op hero actions', (tester) async {
    await tester.pumpWidget(
      buildSubject(includeWork: false, includeGithub: false),
    );
    await tester.pump(const Duration(milliseconds: 1));

    expect(find.text('View selected work'), findsNothing);
    expect(find.text('GitHub'), findsNothing);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });

  testWidgets(
    'renders configured display-name parts without parsing identity',
    (tester) async {
      await tester.pumpWidget(
        buildSubject(
          includeWork: true,
          includeGithub: true,
          mutate: (json) {
            final profile = json['profile']! as Map<String, dynamic>;
            final site = json['site']! as Map<String, dynamic>;
            profile['name'] = 'Canonical Identity Unrelated To Display';
            profile['display_name'] = <String, dynamic>{
              'primary': 'EXPLICIT PRIMARY',
              'accent': 'Explicit Accent',
              'navigation': 'Explicit Navigation',
              'accessible': 'Explicit Accessible Identity',
            };
            site['title'] =
                'Canonical Identity Unrelated To Display — Software Engineer';
          },
        ),
      );
      await tester.pump(const Duration(milliseconds: 1));

      expect(find.text('EXPLICIT PRIMARY'), findsOneWidget);
      expect(find.text('Explicit Accent'), findsOneWidget);
      expect(
        find.text('Canonical Identity Unrelated To Display'),
        findsNothing,
      );
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    },
  );
}
