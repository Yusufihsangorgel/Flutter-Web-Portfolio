import 'dart:convert';
import 'dart:developer' as dev;

import 'package:flutter/services.dart';
import 'package:flutter_web_portfolio/app/domain/providers/asset_loader.dart';

/// Decodes the portfolio, narrative, and locale documents from `rootBundle`.
final class BundleAssetLoader implements AssetLoader {
  @override
  Future<Map<String, dynamic>> loadNarrative() => _loadObject(
    'assets/presentation/narrative.json',
    description: 'Narrative presentation',
  );

  @override
  Future<Map<String, dynamic>> loadPortfolio() => _loadObject(
    'assets/content/portfolio.json',
    description: 'Portfolio content',
  );

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
    try {
      final jsonString = await rootBundle.loadString(
        'assets/i18n/$languageCode.json',
      );
      final translations = json.decode(jsonString) as Map<String, dynamic>;
      return translations;
    } catch (e) {
      dev.log(
        'Failed to load translations for $languageCode',
        name: 'BundleAssetLoader',
        error: e,
      );
      return {};
    }
  }
}
