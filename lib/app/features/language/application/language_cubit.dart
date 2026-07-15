import 'dart:developer' as dev;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_web_portfolio/app/domain/repositories/i_language_repository.dart';
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
  LanguageCubit({required ILanguageRepository languageRepository})
    : _languageRepository = languageRepository,
      super(const LanguageState.initial());

  final ILanguageRepository _languageRepository;
  int _operationId = 0;

  String get currentLanguage => state.languageCode;

  Locale get currentLocale => state.locale;

  Map<String, String> get languageInfo => {
    'code': currentLanguage,
    'name': getLanguageName(currentLanguage),
    'flag': getLanguageFlag(currentLanguage),
  };

  Map<String, String> get supportedLanguages =>
      _languageRepository.getSupportedLanguages();

  Map<String, dynamic> get cvData => switch (state.translations['cv_data']) {
    final Map<String, dynamic> data => data,
    _ => const <String, dynamic>{},
  };

  String get appName =>
      state.translations['app_name']?.toString() ?? 'Portfolio';

  List<String> get activeSections {
    final data = cvData;
    return [
      'home',
      if (data['personal_info'] is Map) 'about',
      if (data['experiences'] case final List l when l.isNotEmpty) 'experience',
      if (data['proof'] case final List l when l.isNotEmpty) 'proof',
      if (data['projects'] case final List l when l.isNotEmpty) 'projects',
    ];
  }

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

  Future<void> changeLanguage(String languageCode) async {
    if (!supportedLanguages.containsKey(languageCode)) return;
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

  static const _languageData = <String, (String name, String flag)>{
    'tr': ('T\u00FCrk\u00E7e', '\u{1F1F9}\u{1F1F7}'),
    'en': ('English', '\u{1F1EC}\u{1F1E7}'),
    'de': ('Deutsch', '\u{1F1E9}\u{1F1EA}'),
    'fr': ('Fran\u00E7ais', '\u{1F1EB}\u{1F1F7}'),
    'es': ('Espa\u00F1ol', '\u{1F1EA}\u{1F1F8}'),
    'ar': ('\u0627\u0644\u0639\u0631\u0628\u064A\u0629', '\u{1F1F8}\u{1F1E6}'),
    'hi': ('\u0939\u093F\u0928\u094D\u0926\u0940', '\u{1F1EE}\u{1F1F3}'),
  };

  static String getLanguageName(String languageCode) =>
      _languageData[languageCode]?.$1 ?? 'Unknown';

  static String getLanguageFlag(String languageCode) =>
      _languageData[languageCode]?.$2 ?? '\u{1F310}';
}
