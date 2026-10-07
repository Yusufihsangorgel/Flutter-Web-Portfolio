import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_web_portfolio/app/features/language/application/language_context.dart';
import 'package:flutter_web_portfolio/app/features/language/application/language_cubit.dart';

import '../../../support/fake_language_repository.dart';

void main() {
  testWidgets('context.strings rebuilds with the active language', (
    tester,
  ) async {
    final cubit = (await tester.runAsync(() async {
      final cubit = LanguageCubit(
        languageRepository: FakeLanguageRepository(
          supportedLanguages: const {'en', 'tr'},
          documents: const {
            'en': {
              'accessibility': {'retry': 'en'},
            },
            'tr': {
              'nav': {'home': 'Ana sayfa'},
              'accessibility': {'retry': 'tr'},
            },
          },
        ),
      );
      await cubit.initialize();
      return cubit;
    }))!;
    addTearDown(() => tester.runAsync(cubit.close));

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: BlocProvider.value(
          value: cubit,
          child: Builder(
            builder: (context) => Text(
              '${context.strings.navHome}|${context.strings.accessibilityRetry}',
            ),
          ),
        ),
      ),
    );
    expect(find.text('Home|en'), findsOneWidget);

    await tester.runAsync(() => cubit.changeLanguage('tr'));
    await tester.pump();

    expect(find.text('Ana sayfa|tr'), findsOneWidget);
  });
}
