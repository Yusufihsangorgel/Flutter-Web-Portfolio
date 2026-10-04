import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_web_portfolio/app/domain/repositories/language_repository.dart';
import 'package:flutter_web_portfolio/app/features/language/application/language_context.dart';
import 'package:flutter_web_portfolio/app/features/language/application/language_cubit.dart';

final class _Repository implements LanguageRepository {
  @override
  Set<String> get supportedLanguages => const {'en', 'tr'};

  @override
  Future<String> getSelectedLanguage() async => 'en';

  @override
  Future<Map<String, dynamic>> getTranslations(String languageCode) async => {
    if (languageCode == 'tr') 'nav': {'home': 'Ana sayfa'},
    'accessibility': {'retry': languageCode},
  };

  @override
  Future<void> saveSelectedLanguage(String languageCode) async {}
}

void main() {
  testWidgets('context.strings rebuilds with the active language', (
    tester,
  ) async {
    final cubit = (await tester.runAsync(() async {
      final cubit = LanguageCubit(languageRepository: _Repository());
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
