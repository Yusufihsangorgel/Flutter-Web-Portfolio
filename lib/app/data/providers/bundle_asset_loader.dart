import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_web_portfolio/app/core/logging/app_logger.dart';
import 'package:flutter_web_portfolio/app/domain/providers/asset_loader.dart';

final class BundleAssetLoader implements AssetLoader {
  BundleAssetLoader({AppLogger? logger})
    : _logger = logger ?? createAppLogger();

  final AppLogger _logger;

  @override
  Future<Map<String, dynamic>> loadNarrative() => _loadLoggedObject(
    'assets/presentation/narrative.json',
    description: 'Narrative presentation',
  );

  @override
  Future<Map<String, dynamic>> loadPortfolio() => _loadLoggedObject(
    'assets/content/portfolio.json',
    description: 'Portfolio content',
  );

  Future<Map<String, dynamic>> _loadLoggedObject(
    String path, {
    required String description,
  }) async {
    try {
      return await _loadObject(path, description: description);
    } catch (error, stackTrace) {
      _logger.error(
        'Failed to load asset $path',
        error: error,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  Future<Map<String, dynamic>> _loadObject(
    String path, {
    required String description,
  }) async {
    final jsonString = await rootBundle.loadString(path);
    final document = json.decode(jsonString);
    if (document case final Map<String, dynamic> object) {
      return object;
    }
    throw FormatException('$description must be a JSON object.');
  }

  @override
  Future<Map<String, dynamic>> loadTranslations(String languageCode) async {
    var path = 'assets/i18n/$languageCode.json';
    try {
      final translations = await _loadObject(
        path,
        description: '$languageCode interface catalog',
      );
      if (languageCode == 'en') return translations;

      path = 'assets/content/locales/$languageCode.json';
      final portfolioLocalization = await _loadObject(
        path,
        description: '$languageCode portfolio localization',
      );
      return mergeCatalogs(
        languageCode: languageCode,
        interfaceCatalog: translations,
        portfolioLocalization: portfolioLocalization,
      );
    } catch (error, stackTrace) {
      _logger.error(
        'Failed to load asset $path',
        error: error,
        stackTrace: stackTrace,
      );
      return {};
    }
  }

  @visibleForTesting
  static Map<String, dynamic> mergeCatalogs({
    required String languageCode,
    required Map<String, dynamic> interfaceCatalog,
    required Map<String, dynamic> portfolioLocalization,
  }) {
    if (portfolioLocalization['locale'] != languageCode) {
      throw FormatException(
        'Portfolio localization locale does not match $languageCode.',
      );
    }
    return <String, dynamic>{
      ...interfaceCatalog,
      'portfolio_content': portfolioLocalization,
    };
  }
}
