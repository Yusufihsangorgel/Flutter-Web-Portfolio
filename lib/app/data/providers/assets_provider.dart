import 'dart:convert';
import 'dart:developer' as dev;

import 'package:flutter/services.dart';
import 'package:flutter_web_portfolio/app/domain/providers/i_assets_provider.dart';

/// Loads and decodes bundled JSON from assets/.
final class AssetsProvider implements IAssetsProvider {
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
        name: 'AssetsProvider',
        error: e,
      );
      return {};
    }
  }
}
