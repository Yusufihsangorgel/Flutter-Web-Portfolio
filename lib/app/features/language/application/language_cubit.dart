import 'dart:developer' as dev;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_web_portfolio/app/domain/repositories/language_repository.dart';
import 'package:flutter_web_portfolio/app/utils/web_url_strategy.dart'
    as url_strategy;

enum LanguageStatus { initial, loading, ready, failure }

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
      translations = const <String, dynamic>{},
      errorMessage = null;

  final LanguageStatus status;
  final String languageCode;
  final Map<String, dynamic> translations;
  final String? errorMessage;

  Locale get locale => Locale(languageCode);

  LanguageState copyWith({
    LanguageStatus? status,
    String? languageCode,
    Map<String, dynamic>? translations,
    String? errorMessage,
    bool clearError = false,
  }) => LanguageState(
    status: status ?? this.status,
    languageCode: languageCode ?? this.languageCode,
    translations: translations ?? this.translations,
    errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
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

/// Owns locale selection and the currently loaded translation document.
///
/// Locale changes are serialized so a slower request can never overwrite a
/// newer user choice. This Cubit is the sole localization state source.
final class LanguageCubit extends Cubit<LanguageState> {
  factory LanguageCubit({required LanguageRepository languageRepository}) =>
      LanguageCubit._(languageRepository);

  LanguageCubit._(this._languageRepository)
    : super(const LanguageState.initial());

  final LanguageRepository _languageRepository;
  int _operationId = 0;

  String get currentLanguage => state.languageCode;

  Locale get currentLocale => state.locale;

  Set<String> get supportedLanguages => _languageRepository.supportedLanguages;

  String getText(String key, {String defaultValue = ''}) {
    final parts = key.split('.');
    dynamic current = state.translations;
    for (final part in parts) {
      if (current is Map<String, dynamic> && current.containsKey(part)) {
        current = current[part];
      } else {
        return defaultValue;
      }
    }
    return current?.toString() ?? defaultValue;
  }

  Future<void> initialize() => loadSavedLanguage();

  Future<void> loadSavedLanguage() async {
    try {
      final savedLanguage = await _languageRepository.getSelectedLanguage();
      await changeLanguage(savedLanguage);
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

  /// Applies an explicit user language choice.
  ///
  /// Flutter Web's SkWasm renderer can lose its scene while rebuilding the
  /// complete text tree across writing directions. The browser path therefore
  /// validates and persists the requested catalog, then performs one clean
  /// document reload. Native targets keep the in-process locale transition.
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
      state.copyWith(status: LanguageStatus.loading, clearError: true),
    );

    try {
      final translations = await _languageRepository.getTranslations(
        languageCode,
      );
      if (translations.isEmpty) {
        throw StateError('Translation document is empty for $languageCode');
      }
      if (isClosed || operationId != _operationId) return;
      await _languageRepository.saveSelectedLanguage(languageCode);

      if (isClosed || operationId != _operationId) return;
      if (reloadOnWeb &&
          url_strategy.reloadPageForLanguageChange(
            preserveSection: preserveSection,
          )) {
        return;
      }
      url_strategy.setHtmlLang(languageCode);
      _emitState(
        LanguageState(
          status: LanguageStatus.ready,
          languageCode: languageCode,
          translations: Map<String, dynamic>.unmodifiable(translations),
        ),
      );
    } catch (error, stackTrace) {
      if (isClosed || operationId != _operationId) return;
      dev.log(
        'Failed to change language to $languageCode',
        name: 'LanguageCubit',
        error: error,
        stackTrace: stackTrace,
      );
      _emitState(
        state.copyWith(
          status: LanguageStatus.failure,
          errorMessage: error.toString(),
        ),
      );
    }
  }

  void _emitState(LanguageState nextState) {
    if (isClosed || nextState == state) return;
    emit(nextState);
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
