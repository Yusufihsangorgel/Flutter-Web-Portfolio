import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_web_portfolio/app/controllers/scroll_controller.dart';
import 'package:flutter_web_portfolio/app/core/l10n/app_strings.g.dart';
import 'package:flutter_web_portfolio/app/features/language/application/language_cubit.dart';
import 'package:flutter_web_portfolio/app/modules/home/sections/home_section.dart';
import 'package:flutter_web_portfolio/app/widgets/portfolio_footer.dart';
import 'package:flutter_web_portfolio/app/widgets/portfolio_link.dart';
import 'package:url_launcher/link.dart';

import '../helpers/narrative_fixture.dart';
import '../helpers/portfolio_fixture.dart';
import '../support/fake_language_repository.dart';

const _resumeHref = 'resume.pdf';
const _sections = [HomeSection(), PortfolioFooter()];

void main() {
  for (final locale in ['en', 'tr', 'de', 'fr', 'es', 'ar', 'hi']) {
    group('locale $locale', () {
      final subject = _ResumeSubject(locale: locale, enabled: true);
      setUp(subject.initialize);
      for (final section in _sections) {
        _registerEnabledLink(subject, section);
      }
    });
  }
  for (final enabled in [null, false]) {
    group('resume_enabled $enabled', () {
      final subject = _ResumeSubject(locale: 'en', enabled: enabled);
      setUp(subject.initialize);
      for (final section in _sections) {
        _registerDisabledLink(subject, section);
      }
    });
  }
}

void _registerEnabledLink(_ResumeSubject subject, Widget section) {
  testWidgets(
    '${section.runtimeType} exposes the ${subject.locale} resume link',
    (tester) async {
      final semantics = tester.ensureSemantics();
      try {
        await _pumpSubject(tester, subject, section);
        final label = AppStrings(subject.translations).documentsResumePdf;
        final finder = find.byWidgetPredicate(
          (widget) => widget is PortfolioLink && widget.semanticLabel == label,
        );
        expect(finder, findsOneWidget);
        expect(
          tester.widget<PortfolioLink>(finder).uri.toString(),
          _resumeHref,
        );
        // The VM stub has no document.baseURI; browser tests assert the
        // resolved URL and new-tab target in a real HTML document.
        final destination = Uri.parse(_resumeHref);
        final data = tester
            .getSemantics(find.bySemanticsLabel(label))
            .getSemanticsData();
        expect(data.flagsCollection.isLink, isTrue);
        expect(data.linkUrl, destination);
        final browserLink = tester.widget<Link>(
          find.descendant(of: finder, matching: find.byType(Link)),
        );
        expect(browserLink.uri, destination);
        expect(browserLink.target, LinkTarget.self);
        expect(tester.takeException(), isNull);
      } finally {
        semantics.dispose();
      }
    },
  );
}

void _registerDisabledLink(_ResumeSubject subject, Widget section) {
  testWidgets(
    '${section.runtimeType} omits the resume when enabled=${subject.enabled}',
    (tester) async {
      await _pumpSubject(tester, subject, section);
      expect(
        find.byWidgetPredicate(
          (widget) => widget is PortfolioLink && widget.uri.path == _resumeHref,
        ),
        findsNothing,
      );
      expect(tester.takeException(), isNull);
    },
  );
}

Future<void> _pumpSubject(
  WidgetTester tester,
  _ResumeSubject subject,
  Widget section,
) async {
  await tester.binding.setSurfaceSize(const Size(1400, 1000));
  addTearDown(() async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.binding.setSurfaceSize(null);
  });
  await tester.pumpWidget(subject.build(section));
}

/// Built in `setUp`, outside the test's fake clock, so closing the cubits in
/// tear-down does not wait on work queued inside that clock.
class _ResumeSubject {
  _ResumeSubject({required this.locale, required this.enabled});

  final String locale;
  final bool? enabled;
  late Map<String, dynamic> translations;
  late LanguageCubit language;
  late AppScrollController scroll;

  Future<void> initialize() async {
    translations =
        jsonDecode(File('assets/i18n/$locale.json').readAsStringSync())
            as Map<String, dynamic>;
    language = LanguageCubit(
      languageRepository: FakeLanguageRepository(
        selectedLanguage: locale,
        supportedLanguages: {'en', locale},
        documents: {locale: translations},
      ),
    );
    scroll = AppScrollController(narrative: loadNarrativeFixture());
    await language.initialize();
    addTearDown(() async {
      await language.close();
      await scroll.close();
    });
  }

  Widget build(Widget section) => RepositoryProvider.value(
    value: loadPortfolioFixture(
      mutate: (json) {
        final site = json['site']! as Map<String, dynamic>;
        if (enabled == null) {
          site.remove('resume_enabled');
        } else {
          site['resume_enabled'] = enabled;
        }
      },
    ),
    child: MultiBlocProvider(
      providers: [
        BlocProvider.value(value: language),
        BlocProvider.value(value: scroll),
      ],
      child: MaterialApp(
        home: Scaffold(body: SingleChildScrollView(child: section)),
      ),
    ),
  );
}
