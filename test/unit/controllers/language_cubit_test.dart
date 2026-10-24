import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_web_portfolio/app/features/language/application/language_cubit.dart';

import '../../support/fake_language_repository.dart';

void main() {
  group('LanguageCubit', () {
    test('starts with a deterministic English initial state', () async {
      final cubit = LanguageCubit(
        languageRepository: FakeLanguageRepository(
          supportedLanguages: const {'en', 'tr', 'de'},
        ),
      );
      addTearDown(cubit.close);

      expect(cubit.state.status, LanguageStatus.initial);
      expect(cubit.state.languageCode, 'en');
      expect(cubit.state.translations, isEmpty);
    });

    test('initialize loads and persists the selected language', () async {
      final repository = FakeLanguageRepository(
        supportedLanguages: const {'en', 'tr', 'de'},
        selectedLanguage: 'tr',
        documents: {
          'tr': {
            'screen': {'label': 'Portföy'},
          },
        },
      );
      final cubit = LanguageCubit(languageRepository: repository);
      addTearDown(cubit.close);
      final stateExpectation = expectLater(
        cubit.stream.map((state) => state.status),
        emitsInOrder([LanguageStatus.loading, LanguageStatus.ready]),
      );

      await cubit.initialize();
      await stateExpectation;

      expect(cubit.currentLanguage, 'tr');
      expect(cubit.strings.lookup('screen.label'), 'Portföy');
      expect(repository.savedLanguages, ['tr']);
    });

    test('unsupported language is ignored without emitting state', () async {
      final cubit = LanguageCubit(
        languageRepository: FakeLanguageRepository(
          supportedLanguages: const {'en', 'tr', 'de'},
        ),
      );
      addTearDown(cubit.close);
      final states = <LanguageState>[];
      final subscription = cubit.stream.listen(states.add);
      addTearDown(subscription.cancel);

      await cubit.changeLanguage('ja');

      expect(states, isEmpty);
      expect(cubit.state, const LanguageState.initial());
    });

    test('an explicit language selection updates native targets', () async {
      final repository = FakeLanguageRepository(
        supportedLanguages: const {'en', 'tr', 'de'},
        documents: {
          'en': {
            'screen': {'label': 'Portfolio'},
          },
          'de': {
            'screen': {'label': 'Portfolio auf Deutsch'},
          },
        },
      );
      final cubit = LanguageCubit(languageRepository: repository);
      addTearDown(cubit.close);
      await cubit.initialize();

      await cubit.selectLanguage('de');

      expect(cubit.state.status, LanguageStatus.ready);
      expect(cubit.currentLanguage, 'de');
      expect(cubit.strings.lookup('screen.label'), 'Portfolio auf Deutsch');
      expect(repository.savedLanguages, ['en', 'de']);
    });

    test(
      'applies a valid locale in-process when persistence is unavailable',
      () async {
        final repository = FakeLanguageRepository(
          supportedLanguages: const {'en', 'tr', 'de'},
          documents: {
            'en': {
              'screen': {'label': 'Portfolio'},
            },
            'de': {
              'screen': {'label': 'Portfolio auf Deutsch'},
            },
          },
          behavior: FakeLanguageRepositoryBehavior(
            saveError: StateError('storage blocked'),
          ),
        );
        final cubit = LanguageCubit(languageRepository: repository);
        addTearDown(cubit.close);
        await cubit.initialize();

        await cubit.selectLanguage('de');

        expect(cubit.state.status, LanguageStatus.ready);
        expect(cubit.currentLanguage, 'de');
        expect(cubit.strings.lookup('screen.label'), 'Portfolio auf Deutsch');
        expect(
          cubit.state.errorMessage,
          'Your language preference could not be saved. '
          'This language will remain active for this visit.',
        );
        expect(cubit.state.errorMessage, isNot(contains('storage blocked')));
        expect(repository.savedLanguages, isEmpty);
      },
    );

    test('uses a localized, non-technical persistence warning', () async {
      final repository = FakeLanguageRepository(
        supportedLanguages: const {'en', 'tr', 'de'},
        selectedLanguage: 'de',
        documents: {
          'de': {
            'accessibility': {
              'language_not_saved':
                  'Die Sprachauswahl konnte nicht gespeichert werden.',
            },
          },
        },
        behavior: FakeLanguageRepositoryBehavior(
          saveError: StateError('internal storage implementation detail'),
        ),
      );
      final cubit = LanguageCubit(languageRepository: repository);
      addTearDown(cubit.close);

      await cubit.initialize();

      expect(cubit.state.status, LanguageStatus.ready);
      expect(
        cubit.state.errorMessage,
        'Die Sprachauswahl konnte nicht gespeichert werden.',
      );
      expect(cubit.state.errorMessage, isNot(contains('internal storage')));
    });

    test(
      'empty translation document fails without replacing good data',
      () async {
        final repository = FakeLanguageRepository(
          supportedLanguages: const {'en', 'tr', 'de'},
          documents: {
            'en': {
              'screen': {'label': 'Portfolio'},
            },
            'tr': <String, dynamic>{},
          },
        );
        final cubit = LanguageCubit(languageRepository: repository);
        addTearDown(cubit.close);
        await cubit.initialize();

        await cubit.changeLanguage('tr');

        expect(cubit.state.status, LanguageStatus.ready);
        expect(cubit.state.languageCode, 'en');
        expect(cubit.strings.lookup('screen.label'), 'Portfolio');
        expect(
          cubit.state.errorMessage,
          'That language could not be loaded. '
          'Your current language is still active.',
        );
        expect(repository.savedLanguages, ['en']);
      },
    );

    test(
      'rejects an incomplete matching-locale catalog before persistence',
      () async {
        final repository = FakeLanguageRepository(
          supportedLanguages: const {'en', 'tr', 'de'},
          selectedLanguage: 'tr',
          documents: {
            'en': {
              'portfolio_content': {'required': 'present'},
            },
            'tr': {'locale': 'tr', 'portfolio_content': <String, dynamic>{}},
          },
        );
        final cubit = LanguageCubit(
          languageRepository: repository,
          validateTranslations: (translations) {
            final content = translations['portfolio_content'];
            if (content is! Map<String, dynamic> ||
                content['required'] != 'present') {
              throw const FormatException('incomplete portfolio overlay');
            }
          },
        );
        addTearDown(cubit.close);

        await cubit.initialize();

        expect(cubit.state.status, LanguageStatus.ready);
        expect(cubit.state.languageCode, 'en');
        expect(repository.selectedLanguage, 'en');
        expect(repository.savedLanguages, ['en']);
        expect(cubit.state.errorMessage, isNull);
      },
    );

    test(
      'a broken saved catalog deterministically falls back to English',
      () async {
        final repository = FakeLanguageRepository(
          supportedLanguages: const {'en', 'tr', 'de'},
          selectedLanguage: 'tr',
          documents: {
            'en': {
              'screen': {'label': 'Portfolio'},
            },
            'tr': <String, dynamic>{},
          },
        );
        final cubit = LanguageCubit(languageRepository: repository);
        addTearDown(cubit.close);

        await cubit.initialize();

        expect(cubit.state.status, LanguageStatus.ready);
        expect(cubit.state.languageCode, 'en');
        expect(cubit.strings.lookup('screen.label'), 'Portfolio');
        expect(repository.selectedLanguage, 'en');
        expect(repository.savedLanguages, ['en']);
      },
    );

    _registerLatestWinsTest();
    _registerStaleSuccessFirstTest();
    _registerStaleErrorTest();
    _registerOrderedPersistenceTest();
    _registerClosePersistenceTest();
    _registerClosedLoadTest();
    _registerArbitraryLookupTest();
    _registerLanguageMetadataTests();
  });
}

FakeLanguageRepository _languageRepository(
  FakeLanguageRepositoryBehavior behavior,
) => FakeLanguageRepository(
  supportedLanguages: const {'en', 'tr', 'de'},
  documents: {
    'tr': {
      'screen': {'label': 'Türkçe'},
    },
    'de': {
      'screen': {'label': 'Deutsch'},
    },
  },
  behavior: behavior,
);

Future<void> _drainLanguageWork(
  LanguageCubit cubit,
  List<Future<void>> pending,
  List<(Object, StackTrace)> errors,
) async {
  try {
    await Future.wait(pending, eagerError: false);
  } finally {
    try {
      await cubit.close();
    } on Object catch (error, stack) {
      errors.add((error, stack));
    }
  }
  expect(errors, isEmpty);
}

void _registerLatestWinsTest() {
  test(
    'the latest language request wins even when responses reorder',
    () async {
      final tr = FakeLanguageRepositoryGate();
      final de = FakeLanguageRepositoryGate();
      final repository = _languageRepository(
        FakeLanguageRepositoryBehavior(loadGates: {'tr': tr, 'de': de}),
      );
      final cubit = LanguageCubit(languageRepository: repository);
      final pending = <Future<void>>[];
      final errors = <(Object, StackTrace)>[];
      void record(Object error, StackTrace stack) => errors.add((error, stack));
      addTearDown(() async {
        tr.release();
        de.release();
        await _drainLanguageWork(cubit, pending, errors);
      });

      final staleSelection = cubit
          .changeLanguage('tr')
          .then<void>((_) {}, onError: record);
      pending.add(staleSelection);
      await tr.started;
      final latestSelection = cubit
          .changeLanguage('de')
          .then<void>((_) {}, onError: record);
      pending.add(latestSelection);
      await de.started;
      expect(repository.savedLanguages, isEmpty);
      de.release();
      await latestSelection;
      final latestState = cubit.state;
      tr.release();
      await staleSelection;

      expect(cubit.state, same(latestState));
      expect(cubit.state.status, LanguageStatus.ready);
      expect(cubit.currentLanguage, 'de');
      expect(cubit.strings.lookup('screen.label'), 'Deutsch');
      expect(repository.savedLanguages, ['de']);
    },
  );
}

void _registerStaleSuccessFirstTest() {
  test('stale success first cannot replace the latest request', () async {
    final tr = FakeLanguageRepositoryGate();
    final de = FakeLanguageRepositoryGate();
    final repository = _languageRepository(
      FakeLanguageRepositoryBehavior(loadGates: {'tr': tr, 'de': de}),
    );
    final cubit = LanguageCubit(languageRepository: repository);
    final pending = <Future<void>>[];
    final errors = <(Object, StackTrace)>[];
    void record(Object error, StackTrace stack) => errors.add((error, stack));
    addTearDown(() async {
      tr.release();
      de.release();
      await _drainLanguageWork(cubit, pending, errors);
    });

    final staleSelection = cubit
        .changeLanguage('tr')
        .then<void>((_) {}, onError: record);
    pending.add(staleSelection);
    await tr.started;
    final latestSelection = cubit
        .changeLanguage('de')
        .then<void>((_) {}, onError: record);
    pending.add(latestSelection);
    await de.started;
    tr.release();
    await staleSelection;
    expect(cubit.state.status, LanguageStatus.loading);
    expect(repository.savedLanguages, isEmpty);
    de.release();
    await latestSelection;

    expect(cubit.state.status, LanguageStatus.ready);
    expect(cubit.currentLanguage, 'de');
    expect(cubit.strings.lookup('screen.label'), 'Deutsch');
    expect(repository.savedLanguages, ['de']);
  });
}

void _registerStaleErrorTest() {
  test('a stale load error cannot overwrite a newer valid state', () async {
    final tr = FakeLanguageRepositoryGate();
    final de = FakeLanguageRepositoryGate();
    final repository = _languageRepository(
      FakeLanguageRepositoryBehavior(
        loadGates: {'tr': tr, 'de': de},
        loadErrors: {'tr': StateError('stale catalog')},
      ),
    );
    final cubit = LanguageCubit(languageRepository: repository);
    final pending = <Future<void>>[];
    final errors = <(Object, StackTrace)>[];
    void record(Object error, StackTrace stack) => errors.add((error, stack));
    addTearDown(() async {
      tr.release();
      de.release();
      await _drainLanguageWork(cubit, pending, errors);
    });

    final staleSelection = cubit
        .changeLanguage('tr')
        .then<void>((_) {}, onError: record);
    pending.add(staleSelection);
    await tr.started;
    final latestSelection = cubit
        .changeLanguage('de')
        .then<void>((_) {}, onError: record);
    pending.add(latestSelection);
    await de.started;
    de.release();
    await latestSelection;
    final latestState = cubit.state;
    tr.release();
    await staleSelection;

    expect(cubit.state, same(latestState));
    expect(cubit.state.status, LanguageStatus.ready);
    expect(cubit.state.errorMessage, isNull);
    expect(cubit.strings.lookup('screen.label'), 'Deutsch');
    expect(repository.savedLanguages, ['de']);
  });
}

void _registerOrderedPersistenceTest() {
  test(
    'persistence is ordered and a stale save cannot overwrite the latest choice',
    () async {
      final tr = FakeLanguageRepositoryGate();
      final de = FakeLanguageRepositoryGate();
      final repository = _languageRepository(
        FakeLanguageRepositoryBehavior(saveGates: {'tr': tr, 'de': de}),
      );
      final cubit = LanguageCubit(languageRepository: repository);
      final pending = <Future<void>>[];
      final errors = <(Object, StackTrace)>[];
      void record(Object error, StackTrace stack) => errors.add((error, stack));
      addTearDown(() async {
        tr.release();
        de.release();
        await _drainLanguageWork(cubit, pending, errors);
      });

      final staleSelection = cubit
          .changeLanguage('tr')
          .then<void>((_) {}, onError: record);
      pending.add(staleSelection);
      await tr.started;
      final latestSelection = cubit
          .changeLanguage('de')
          .then<void>((_) {}, onError: record);
      pending.add(latestSelection);
      await Future<void>(() {});
      expect(de.hasStarted, isFalse);
      tr.release();
      await de.started;
      expect(repository.saveEvents, ['start:tr', 'finish:tr', 'start:de']);
      de.release();
      await Future.wait([staleSelection, latestSelection]);

      expect(repository.saveEvents, [
        'start:tr',
        'finish:tr',
        'start:de',
        'finish:de',
      ]);
      expect(repository.savedLanguages, ['tr', 'de']);
      expect(repository.selectedLanguage, 'de');
      expect(cubit.state.status, LanguageStatus.ready);
      expect(cubit.currentLanguage, 'de');
      expect(cubit.strings.lookup('screen.label'), 'Deutsch');
    },
  );
}

void _registerClosePersistenceTest() {
  test('close waits for already queued persistence', () async {
    final tr = FakeLanguageRepositoryGate();
    final repository = _languageRepository(
      FakeLanguageRepositoryBehavior(saveGates: {'tr': tr}),
    );
    final cubit = LanguageCubit(languageRepository: repository);
    final pending = <Future<void>>[];
    final errors = <(Object, StackTrace)>[];
    void record(Object error, StackTrace stack) => errors.add((error, stack));
    addTearDown(() async {
      tr.release();
      await _drainLanguageWork(cubit, pending, errors);
    });

    final selection = cubit
        .changeLanguage('tr')
        .then<void>((_) {}, onError: record);
    pending.add(selection);
    await tr.started;
    var closeCompleted = false;
    final closing = cubit.close().then<void>((_) {
      closeCompleted = true;
    }, onError: record);
    pending.add(closing);

    // Observe one event turn after pending microtasks while the save stays gated.
    await Future<void>(() {});
    expect(errors, isEmpty);
    expect(closeCompleted, isFalse);
    expect(repository.savedLanguages, isEmpty);
    tr.release();
    await closing;
    final closedState = cubit.state;
    await selection;

    expect(closeCompleted, isTrue);
    expect(cubit.isClosed, isTrue);
    expect(cubit.state, same(closedState));
    expect(repository.savedLanguages, ['tr']);
    expect(repository.selectedLanguage, 'tr');
  });
}

void _registerClosedLoadTest() {
  test('late load after close has no state or persistence effect', () async {
    final tr = FakeLanguageRepositoryGate();
    final repository = _languageRepository(
      FakeLanguageRepositoryBehavior(loadGates: {'tr': tr}),
    );
    final cubit = LanguageCubit(languageRepository: repository);
    final pending = <Future<void>>[];
    final errors = <(Object, StackTrace)>[];
    void record(Object error, StackTrace stack) => errors.add((error, stack));
    addTearDown(() async {
      tr.release();
      await _drainLanguageWork(cubit, pending, errors);
    });
    final states = <LanguageState>[];
    final subscription = cubit.stream.listen(states.add);
    addTearDown(subscription.cancel);

    final selection = cubit
        .changeLanguage('tr')
        .then<void>((_) {}, onError: record);
    pending.add(selection);
    await tr.started;
    final closing = cubit.close().then<void>((_) {}, onError: record);
    pending.add(closing);
    await closing;
    expect(errors, isEmpty);
    final closedState = cubit.state;
    final closedStates = List<LanguageState>.of(states);
    tr.release();
    await selection;

    expect(cubit.state, same(closedState));
    expect(states, closedStates);
    expect(repository.savedLanguages, isEmpty);
    expect(repository.saveEvents, isEmpty);
  });
}

void _registerArbitraryLookupTest() {
  test('strings.lookup resolves deliberate arbitrary fixture keys', () async {
    final repository = FakeLanguageRepository(
      supportedLanguages: const {'en', 'tr', 'de'},
      documents: {
        'en': {
          'hero': {'title': 'Flutter Web'},
        },
      },
    );
    final cubit = LanguageCubit(languageRepository: repository);
    addTearDown(cubit.close);
    await cubit.initialize();

    expect(cubit.strings.lookup('hero.title'), 'Flutter Web');
    expect(
      cubit.strings.lookup('hero.missing', defaultValue: 'Fallback'),
      'Fallback',
    );
  });
}

void _registerLanguageMetadataTests() {
  group('language metadata', () {
    test('returns localized names for every supported public locale', () {
      expect(LanguageCubit.getLanguageName('tr'), 'Türkçe');
      expect(LanguageCubit.getLanguageName('en'), 'English');
      expect(LanguageCubit.getLanguageName('de'), 'Deutsch');
      expect(LanguageCubit.getLanguageName('fr'), 'Français');
      expect(LanguageCubit.getLanguageName('es'), 'Español');
      expect(LanguageCubit.getLanguageName('ar'), 'العربية');
      expect(LanguageCubit.getLanguageName('hi'), 'हिन्दी');
    });

    test('returns safe fallbacks for unknown locale codes', () {
      expect(LanguageCubit.getLanguageName('ja'), 'Unknown');
    });
  });
}
