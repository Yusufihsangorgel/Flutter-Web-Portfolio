import 'dart:developer' as dev;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_web_portfolio/app/core/l10n/app_strings.g.dart';
import 'package:flutter_web_portfolio/app/core/theme/locale_font_loader.dart';
import 'package:flutter_web_portfolio/app/domain/repositories/language_repository.dart';
import 'package:flutter_web_portfolio/app/utils/language_browser.dart';

enum LanguageStatus { initial, loading, ready, failure }

typedef TranslationDocumentValidator =
    void Function(Map<String, Object?> translations);

@immutable
final class LanguageState {
  const LanguageState({
    required this.status,
    required this.languageCode,
    required this.translations,
    this.errorMessage,
  });

  const LanguageState.initial()
    : status = LanguageStatus.initial,
      languageCode = 'en',
      translations = const <String, Object?>{},
      errorMessage = null;

  final LanguageStatus status;
  final String languageCode;
  final Map<String, Object?> translations;
  final String? errorMessage;

  Locale get locale => Locale(languageCode);

  LanguageState copyWith({
    LanguageStatus? status,
    String? languageCode,
    Map<String, Object?>? translations,
    String? errorMessage,
  }) => LanguageState(
    status: status ?? this.status,
    languageCode: languageCode ?? this.languageCode,
    translations: translations ?? this.translations,
    errorMessage: errorMessage ?? this.errorMessage,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LanguageState &&
          status == other.status &&
          languageCode == other.languageCode &&
          identical(translations, other.translations) &&
          errorMessage == other.errorMessage;

  @override
  int get hashCode => Object.hash(
    status,
    languageCode,
    identityHashCode(translations),
    errorMessage,
  );
}

final class LanguageCubit extends Cubit<LanguageState> {
  factory LanguageCubit({
    required LanguageRepository languageRepository,
    TranslationDocumentValidator? validateTranslations,
    LanguageBrowser browser = const WebLanguageBrowser(),
    LocaleFontLoader fontLoader = const NoopLocaleFontLoader(),
    Duration fontLoadTimeout = const Duration(seconds: 3),
  }) => LanguageCubit._(
    languageRepository,
    validateTranslations,
    browser,
    fontLoader,
    fontLoadTimeout,
  );

  LanguageCubit._(
    this._languageRepository,
    this._validateTranslations,
    this._browser,
    this._fontLoader,
    this._fontLoadTimeout,
  ) : super(const LanguageState.initial());

  final LanguageRepository _languageRepository;
  final TranslationDocumentValidator? _validateTranslations;
  final LanguageBrowser _browser;
  final LocaleFontLoader _fontLoader;
  final Duration _fontLoadTimeout;
  int _operationId = 0;
  Future<void> _persistenceQueue = Future<void>.value();

  String get currentLanguage => state.languageCode;

  Locale get currentLocale => state.locale;

  AppStrings get strings => AppStrings(state.translations);

  Set<String> get supportedLanguages => _languageRepository.supportedLanguages;

  String getText(String key, {String defaultValue = ''}) =>
      strings.lookup(key, defaultValue: defaultValue);

  Future<void> initialize() => loadSavedLanguage();

  Future<void> loadSavedLanguage() async {
    try {
      final savedLanguage = await _languageRepository.getSelectedLanguage();
      await changeLanguage(savedLanguage);
      if (state.status != LanguageStatus.ready ||
          state.languageCode != savedLanguage) {
        await changeLanguage('en');
      }
    } catch (error, stackTrace) {
      dev.log(
        'Failed to load saved language',
        name: 'LanguageCubit',
        error: error,
        stackTrace: stackTrace,
      );
      await changeLanguage('en');
    }
  }

  /// Reload web after selection to preserve the renderer across direction changes.
  Future<void> selectLanguage(String languageCode, {String? preserveSection}) =>
      changeLanguage(
        languageCode,
        reloadOnWeb: true,
        preserveSection: preserveSection,
      );

  Future<void> changeLanguage(
    String languageCode, {
    bool reloadOnWeb = false,
    String? preserveSection,
  }) async {
    if (!supportedLanguages.contains(languageCode)) return;
    if (state.status == LanguageStatus.ready &&
        state.languageCode == languageCode) {
      return;
    }

    final operationId = ++_operationId;
    _emitState(
      LanguageState(
        status: LanguageStatus.loading,
        languageCode: state.languageCode,
        translations: state.translations,
      ),
    );

    try {
      final translations = await _languageRepository.getTranslations(
        languageCode,
      );
      if (translations.isEmpty) {
        throw StateError('Translation document is empty for $languageCode');
      }
      _validateTranslations?.call(translations);
      if (isClosed || operationId != _operationId) return;
      final persistenceError = await _persistLanguage(languageCode);

      if (isClosed || operationId != _operationId) return;
      if (reloadOnWeb &&
          persistenceError == null &&
          _browser.reloadForLanguageChange(preserveSection: preserveSection)) {
        return;
      }
      await _loadLocaleFont(languageCode);
      if (isClosed || operationId != _operationId) return;
      _browser.setDocumentLanguage(languageCode);
      _emitState(
        LanguageState(
          status: LanguageStatus.ready,
          languageCode: languageCode,
          translations: Map<String, Object?>.unmodifiable(translations),
          errorMessage: persistenceError == null
              ? null
              : _persistenceWarning(translations),
        ),
      );
    } catch (error, stackTrace) {
      _handleLanguageFailure(languageCode, operationId, error, stackTrace);
    }
  }

  /// Waits for the language's font so the switch does not flash missing glyphs.
  /// A slow or failed fetch is logged and never blocks the switch.
  Future<void> _loadLocaleFont(String languageCode) async {
    try {
      await _fontLoader.loadForLanguage(languageCode).timeout(_fontLoadTimeout);
    } on Object catch (error, stackTrace) {
      dev.log(
        'Locale font for $languageCode was not ready; continuing without it',
        name: 'LanguageCubit',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  void _handleLanguageFailure(
    String languageCode,
    int operationId,
    Object error,
    StackTrace stackTrace,
  ) {
    if (isClosed || operationId != _operationId) return;
    dev.log(
      'Failed to change language to $languageCode',
      name: 'LanguageCubit',
      error: error,
      stackTrace: stackTrace,
    );
    _emitState(
      state.copyWith(
        status: state.translations.isEmpty
            ? LanguageStatus.failure
            : LanguageStatus.ready,
        errorMessage: _languageChangeWarning(state.translations),
      ),
    );
  }

  void _emitState(LanguageState nextState) {
    if (isClosed || nextState == state) return;
    emit(nextState);
  }

  /// Serialize writes to preserve the latest selection.
  Future<Object?> _persistLanguage(String languageCode) async {
    Object? persistenceError;
    _persistenceQueue = _persistenceQueue.then((_) async {
      try {
        await _languageRepository.saveSelectedLanguage(languageCode);
      } on Object catch (error, stackTrace) {
        persistenceError = error;
        dev.log(
          'Failed to persist language $languageCode; applying it for this session',
          name: 'LanguageCubit',
          error: error,
          stackTrace: stackTrace,
        );
      }
    });
    await _persistenceQueue;
    return persistenceError;
  }

  String _persistenceWarning(Map<String, Object?> translations) {
    final accessibility = translations['accessibility'];
    if (accessibility is Map<String, Object?>) {
      final localized = accessibility['language_not_saved'];
      if (localized is String && localized.trim().isNotEmpty) {
        return localized.trim();
      }
    }
    return 'Your language preference could not be saved. '
        'This language will remain active for this visit.';
  }

  String _languageChangeWarning(Map<String, Object?> translations) {
    final accessibility = translations['accessibility'];
    if (accessibility is Map<String, Object?>) {
      final localized = accessibility['language_change_failed'];
      if (localized is String && localized.trim().isNotEmpty) {
        return localized.trim();
      }
    }
    return 'That language could not be loaded. '
        'Your current language is still active.';
  }

  @override
  Future<void> close() async {
    await _persistenceQueue;
    return super.close();
  }

  static const _languageNames = <String, String>{
    'tr': 'T\u00FCrk\u00E7e',
    'en': 'English',
    'de': 'Deutsch',
    'fr': 'Fran\u00E7ais',
    'es': 'Espa\u00F1ol',
    'ar': '\u0627\u0644\u0639\u0631\u0628\u064A\u0629',
    'hi': '\u0939\u093F\u0928\u094D\u0926\u0940',
  };

  static String getLanguageName(String languageCode) =>
      _languageNames[languageCode] ?? 'Unknown';
}
